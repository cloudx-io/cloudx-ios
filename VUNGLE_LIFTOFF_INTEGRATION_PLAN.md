# CloudX iOS Vungle/Liftoff Adapter Integration Plan

**Document Version:** 1.0  
**Author:** Principal Engineer  
**Date:** 2025-09-14  
**Target:** CloudX iOS SDK Objective-C Integration

---

## Executive Summary

This document outlines the comprehensive integration plan for creating a production-ready Vungle/Liftoff adapter (`adapter-liftoff`) for the CloudX iOS SDK. The adapter will mirror the existing `adapter-meta` architecture while implementing full support for VungleAds SDK integration across all ad formats: Interstitial, Rewarded, Banner/Inline/MREC, Native, and App Open ads.

## 1. Project Architecture Overview

### 1.1 Directory Structure
Based on the existing `adapter-meta` pattern, the `adapter-liftoff` will follow this structure:

```
cloudx-ios/adapter-liftoff/
├── CloudXLiftoffAdapter.podspec
├── Package.swift
├── LICENSE
├── README.md
├── build_frameworks.sh
├── Podfile
├── CloudXLiftoffAdapter.xcodeproj/
├── CloudXLiftoffAdapter.xcworkspace/
├── CloudXLiftoffAdapter.framework/
├── CloudXLiftoffAdapter.xcframework/
└── Sources/
    └── CloudXLiftoffAdapter/
        ├── CloudXLiftoffAdapter.h          # Umbrella header
        ├── Info.plist
        ├── module.modulemap
        ├── Base/
        │   ├── CLXLiftoffBaseFactory.h/.m
        ├── Initializers/
        │   ├── CLXLiftoffInitializer.h/.m
        ├── Utils/
        │   ├── CLXLiftoffErrorHandler.h/.m
        ├── BidTokenSource/
        │   ├── CLXLiftoffBidTokenSource.h/.m
        ├── Interstitial/
        │   ├── CLXLiftoffInterstitial.h/.m
        │   ├── CLXLiftoffInterstitialFactory.h/.m
        ├── Rewarded/
        │   ├── CLXLiftoffRewarded.h/.m
        │   ├── CLXLiftoffRewardedFactory.h/.m
        ├── Banner/
        │   ├── CLXLiftoffBanner.h/.m
        │   ├── CLXLiftoffBannerFactory.h/.m
        ├── Native/
        │   ├── CLXLiftoffNative.h/.m
        │   ├── CLXLiftoffNativeFactory.h/.m
        └── AppOpen/
            ├── CLXLiftoffAppOpen.h/.m
            ├── CLXLiftoffAppOpenFactory.h/.m
```

## 2. Core Dependencies & Requirements

### 2.1 System Requirements
- **Xcode:** ≥ 16.0
- **iOS Deployment Target:** ≥ 12.0 (arm64 & simulator)
- **Swift Version:** 5.9+
- **CocoaPods:** ≥ 1.13.0

### 2.2 Third-Party Dependencies
- **VungleAdsSDK:** Latest stable version (7.4.x+)
- **CloudXCore:** Internal dependency

### 2.3 Privacy & Compliance Requirements
- SKAdNetwork IDs integration
- Privacy Manifest compliance
- ATT (App Tracking Transparency) support
- GDPR/CCPA compliance
- app-ads.txt validation

## 3. CloudX Core Protocol Implementation

### 3.1 Adapter Protocols to Implement
Based on analysis of the CloudX core, each adapter must implement:

- **CLXAdapterInterstitial** - Fullscreen interstitial ads
- **CLXAdapterRewarded** - Rewarded video ads  
- **CLXAdapterBanner** - Banner/MREC/Inline ads
- **CLXAdapterNative** - Native ad content
- **CLXAdNetworkInitializer** - SDK initialization

### 3.2 Factory Pattern Implementation
Each ad format requires a factory implementing the respective factory protocol:

- **CLXAdapterInterstitialFactory**
- **CLXAdapterRewardedFactory** 
- **CLXAdapterBannerFactory**
- **CLXAdapterNativeFactory**

### 3.3 Delegate Protocol Compliance
All adapters must properly implement delegate callbacks:

- Load success/failure callbacks
- Show success/failure callbacks
- Impression tracking
- Click tracking
- Close/dismiss callbacks
- Reward callbacks (for rewarded ads)
- Expiration callbacks

## 4. VungleAds SDK Integration Details

### 4.1 SDK Initialization
```objc
// CLXLiftoffInitializer.m implementation
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    NSString *appId = [config.extras objectForKey:@"app_id"];
    [VungleAds initWithAppId:appId completion:^(NSError * _Nullable error) {
        completion(error == nil, error);
    }];
}
```

### 4.2 Ad Format Implementations

#### 4.2.1 Interstitial Ads
- Use `VungleInterstitial` class
- Implement `VungleInterstitialDelegate`
- Handle full lifecycle: init → load → present → callbacks → cleanup

#### 4.2.2 Rewarded Ads
- Use `VungleRewarded` class
- Implement `VungleRewardedDelegate`
- Handle reward callback properly

#### 4.2.3 Banner Ads
- Use `VungleBannerView` (not deprecated `VungleBanner`)
- Support standard sizes: 320x50, 300x50, 728x90
- Support MREC: 300x250
- Handle view attachment/detachment

#### 4.2.4 Native Ads
- Use `VungleNative` class
- Implement `VungleNativeDelegate`
- Handle asset population and view registration
- Support MediaView for video content

#### 4.2.5 App Open Ads
- Leverage `VungleInterstitial` with App Open placement configuration
- Separate factory and adapter class for clarity

## 5. Error Handling & Mapping Strategy

### 5.1 Error Domain
```objc
extern NSString * const CLXLiftoffAdapterErrorDomain;
```

### 5.2 Error Code Mapping
Following the `CLXMetaErrorHandler` pattern:

| VungleAds Error | CloudX Error Code | Description |
|----------------|------------------|-------------|
| Initialization failure | `CLXErrorNetworkInitFailed` | SDK init failed |
| No fill | `CLXErrorNoFill` | No ad available |
| Load timeout | `CLXErrorTimeout` | Load timeout exceeded |
| Show failure | `CLXErrorShowFailed` | Presentation failed |
| Invalid placement | `CLXErrorConfiguration` | Bad placement ID |

### 5.3 Error Handler Implementation
```objc
@interface CLXLiftoffErrorHandler : NSObject

+ (NSError *)handleVungleError:(NSError *)error
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(NSString *)placementID;

+ (NSTimeInterval)suggestedDelayForError:(NSError *)error;
+ (BOOL)isRetryableError:(NSError *)error;
+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode;

@end
```

## 6. Bidding Integration

### 6.1 Bid Token Source
Implement `CLXBidTokenSource` protocol for header bidding:

```objc
@interface CLXLiftoffBidTokenSource : NSObject <CLXBidTokenSource>
+ (instancetype)sharedInstance;
+ (instancetype)createInstance;
@end
```

### 6.2 Bid Payload Handling
- Support bid payload in ad creation
- Pass `nil` for waterfall requests
- Handle bid payload validation

## 7. Factory Pattern Implementation

### 7.1 Base Factory
```objc
@interface CLXLiftoffBaseFactory : NSObject

+ (NSString *)resolveLiftoffPlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                            fallbackAdId:(NSString *)adId 
                                  logger:(CLXLogger *)logger;

@end
```

### 7.2 Format-Specific Factories
Each format factory implements the CloudX factory protocol and creates appropriate adapter instances with proper initialization.

## 8. Threading & State Management

### 8.1 Threading Requirements
- All VungleAds SDK calls must occur on main thread
- CloudX callbacks dispatched appropriately
- Thread-safe state management

### 8.2 State Machine
Each adapter follows the state pattern:
```
idle → loading → loaded → showing → closed → destroyed
```

### 8.3 Lifecycle Management
- Proper cleanup on destroy
- No retain cycles
- Memory leak prevention

## 9. Logging & Metrics Integration

### 9.1 CloudX Logger Integration
- Use `CLXLogger` for consistent logging
- Log level compliance with CloudX standards
- Structured logging for debugging

### 9.2 Metrics Collection
Track key performance indicators:
- Initialization success/failure rates
- Load success/failure rates by format
- Show success/failure rates
- Time-to-load metrics
- Time-to-show metrics
- Fill rates
- Error distribution

## 10. Testing Strategy

### 10.1 Unit Testing
- Adapter lifecycle testing
- Error handling validation
- Factory pattern testing
- Delegate callback verification

### 10.2 Integration Testing
- End-to-end ad serving
- Format-specific testing matrix
- Error scenario testing
- Memory leak testing

### 10.3 Test Mode Support
- Test device registration
- Test placement configuration
- Debug logging for QA

## 11. Configuration & Setup

### 11.1 CocoaPods Integration
```ruby
# CloudXLiftoffAdapter.podspec
Pod::Spec.new do |s|
  s.name = 'CloudXLiftoffAdapter'
  s.version = '1.0.0'
  s.summary = 'Liftoff/Vungle Adapter for CloudX iOS SDK'
  s.dependency 'CloudXCore'
  s.dependency 'VungleAdsSDK'
  s.platform = :ios, '12.0'
  # ... additional configuration
end
```

### 11.2 Swift Package Manager Support
```swift
// Package.swift
let package = Package(
    name: "CloudXLiftoffAdapter",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "CloudXLiftoffAdapter", targets: ["CloudXLiftoffAdapter"])
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../core"),
        .package(url: "https://github.com/Vungle/VungleAdsSDK-SwiftPackageManager.git", from: "7.4.0")
    ]
)
```

## 12. Privacy & Compliance Implementation

### 12.1 SKAdNetwork Integration
- Maintain current SKAdNetwork ID list
- Automated updates via build scripts
- Validation against Liftoff's official list

### 12.2 Privacy Manifest
- Include VungleAds SDK privacy manifest
- Document required reasoning APIs
- Maintain compliance with App Store requirements

### 12.3 Consent Management
- GDPR consent forwarding
- CCPA compliance
- COPPA support for child-directed content

## 13. Build System Integration

### 13.1 Xcode Project Configuration
- Static framework generation
- Module map configuration
- Header visibility management
- Build script integration

### 13.2 CI/CD Integration
- Automated testing pipeline
- Framework building and distribution
- Version management
- Release automation

## 14. Documentation Requirements

### 14.1 Technical Documentation
- API reference documentation
- Integration guide
- Migration guide (if applicable)
- Troubleshooting guide

### 14.2 Sample Code
- Basic integration examples
- Advanced configuration examples
- Error handling examples
- Test mode setup examples

## 15. Performance Considerations

### 15.1 Memory Management
- Proper object lifecycle management
- Avoid retain cycles
- Efficient view hierarchy management
- Memory pressure handling

### 15.2 Network Optimization
- Connection reuse where possible
- Request timeout configuration
- Retry logic implementation
- Bandwidth-aware loading

## 16. Quality Assurance Matrix

### 16.1 Format Testing Matrix
| Format | Load | Show | Impression | Click | Close | Reward |
|--------|------|------|------------|-------|-------|---------|
| Interstitial | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| Rewarded | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Banner 320x50 | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| MREC 300x250 | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| Leaderboard 728x90 | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| Native | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| App Open | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |

### 16.2 Edge Case Testing
- Network connectivity issues
- App backgrounding/foregrounding
- Memory pressure scenarios
- Device rotation (for banner ads)
- Rapid load/show cycles
- Concurrent ad requests

## 17. Rollout Strategy

### 17.1 Development Phases
1. **Phase 1:** Core infrastructure and interstitial implementation
2. **Phase 2:** Rewarded and banner implementations
3. **Phase 3:** Native and App Open implementations
4. **Phase 4:** Testing, optimization, and documentation
5. **Phase 5:** Production rollout and monitoring

### 17.2 Risk Mitigation
- Feature flags for gradual rollout
- A/B testing framework integration
- Rollback procedures
- Performance monitoring
- Error rate monitoring

## 18. Maintenance & Support

### 18.1 Version Management
- Semantic versioning strategy
- Dependency update procedures
- Breaking change communication
- Migration path documentation

### 18.2 Support Procedures
- Issue escalation process
- Debug information collection
- Performance monitoring
- User feedback integration

## 19. Success Metrics

### 19.1 Technical Metrics
- Crash rate < 0.1%
- Load success rate > 95%
- Show success rate > 98%
- Memory usage within acceptable limits
- Network efficiency optimization

### 19.2 Business Metrics
- Revenue impact measurement
- Fill rate improvement
- eCPM performance
- User experience metrics
- Partner satisfaction scores

## 20. Implementation Timeline

### 20.1 Estimated Timeline
- **Week 1-2:** Project setup and core infrastructure
- **Week 3-4:** Interstitial and rewarded implementation
- **Week 5-6:** Banner and native implementation
- **Week 7:** App Open and testing
- **Week 8:** Documentation and final testing
- **Week 9:** Production deployment preparation
- **Week 10:** Rollout and monitoring

### 20.2 Resource Requirements
- 1 Senior iOS Engineer (primary)
- 1 QA Engineer (testing)
- 1 DevOps Engineer (CI/CD setup)
- Technical PM oversight

## 21. Conclusion

This integration plan provides a comprehensive roadmap for implementing a production-ready Vungle/Liftoff adapter for the CloudX iOS SDK. By following the established patterns from the `adapter-meta` implementation and adhering to CloudX's architectural principles, we ensure consistency, maintainability, and high performance.

The modular approach allows for incremental development and testing, while the comprehensive error handling and monitoring ensure production reliability. The plan accounts for all technical requirements, compliance needs, and operational considerations necessary for a successful integration.

---

**Next Steps:**
1. Review and approval of this integration plan
2. Resource allocation and timeline confirmation
3. Development environment setup
4. Implementation phase kickoff

**Document Status:** Ready for Review  
**Approval Required:** Technical Lead, Product Manager, QA Lead
