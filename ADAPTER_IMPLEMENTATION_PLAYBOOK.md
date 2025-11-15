# CloudX iOS Adapter Implementation Playbook
## Principal Engineer's Guide to Building Network Adapters at Scale

**Version:** 1.0  
**Last Updated:** 2024  
**Author:** CloudX Platform Engineering  
**Classification:** Internal - Engineering Reference

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 1: Research & Audit](#phase-1-research--audit)
3. [Phase 2: Architecture & Design](#phase-2-architecture--design)
4. [Phase 3: Implementation](#phase-3-implementation)
5. [Phase 4: Distribution & Release](#phase-4-distribution--release)
6. [Phase 5: Testing & Validation](#phase-5-testing--validation)
7. [Reference Implementations](#reference-implementations)
8. [Appendix: Templates & Checklists](#appendix-templates--checklists)

---

## Executive Summary

This playbook documents the battle-tested process for implementing CloudX iOS network adapters at scale. It synthesizes learnings from our Meta adapter (most robust implementation) and InMobi adapter (most recent implementation) into a repeatable methodology.

### Success Metrics
- **Implementation Time:** 4-6 hours for experienced engineer
- **Code Quality:** 100% protocol conformance, comprehensive error handling
- **Distribution:** CocoaPods + SPM + Manual (3 methods)
- **Documentation:** Production-ready README, inline docs
- **CI/CD:** Fully automated release pipeline

### Prerequisites
- Deep understanding of CloudX Core SDK architecture
- Familiarity with target ad network's SDK and documentation
- Access to competitor adapter implementations (AppLovin MAX, Unity, AdMob)
- iOS development expertise (Objective-C, Swift, Xcode)

---

## Phase 1: Research & Audit

### 1.1 Competitive Analysis

**Objective:** Understand how industry leaders implement adapters for the target network.

#### Step 1: Identify Reference Implementations

Research and obtain the following implementations:

1. **AppLovin MAX Adapter** (Priority: Highest)
   - Location: `AppLovinMediationXXXAdapter` pods
   - Why: Most comprehensive, production-tested patterns
   - Focus: Factory patterns, error handling, lifecycle management

2. **Unity Ads Mediation Adapter**
   - Location: Unity Ads SDK packages
   - Why: Clean architecture, good documentation
   - Focus: SDK initialization, ad format support

3. **AdMob Mediation Adapter**
   - Location: Google Mobile Ads SDK
   - Why: Google's best practices, robust error handling
   - Focus: Privacy compliance, consent management

#### Step 2: Install and Examine Source Code

```bash
# Create temporary audit directory
mkdir -p /tmp/adapter-audit
cd /tmp/adapter-audit

# Install adapters via CocoaPods for inspection
pod init
# Edit Podfile to include target adapters
pod install

# Examine source code structure
find Pods/ -name "*XXXAdapter*" -type d
```

#### Step 3: Document Key Findings

Create an audit document covering:

**A. SDK Integration**
- Initialization API and requirements
- Account ID / API key patterns
- SDK version compatibility
- Threading requirements (main thread, background)

**B. Ad Format Support**
- Supported formats (Interstitial, Banner, Rewarded, Native)
- Loading mechanisms (waterfall vs. programmatic)
- Bid token generation (if applicable)
- Ad lifecycle callbacks

**C. Error Handling**
- Error codes and their meanings
- Retry strategies
- Timeout handling
- Network failure scenarios

**D. Privacy & Compliance**
- GDPR consent integration
- CCPA compliance
- COPPA support
- ATT (App Tracking Transparency) handling
- Privacy manifest requirements (iOS 17+)

**E. Architecture Patterns**
- Factory pattern usage
- Protocol conformance
- Delegate patterns
- Singleton vs. instance-based design

### 1.2 Network SDK Documentation Review

**Objective:** Understand the official SDK capabilities and requirements.

#### Official Documentation Checklist

- [ ] **Getting Started Guide**
  - Minimum iOS version
  - Xcode version requirements
  - SDK installation methods (CocoaPods, SPM, Manual)
  
- [ ] **Integration Guide**
  - Account ID / Placement ID formats
  - SDK initialization API
  - Privacy settings configuration
  
- [ ] **Ad Formats Documentation**
  - Interstitial ads API
  - Banner ads API (sizes, refresh)
  - Rewarded video ads API
  - Native ads API (if applicable)
  
- [ ] **Header Bidding / Programmatic**
  - Bid token generation API
  - Bid response handling
  - Waterfall fallback support
  
- [ ] **Privacy & Compliance**
  - GDPR compliance methods
  - CCPA compliance methods
  - COPPA methods
  - Required Info.plist entries
  - SKAdNetwork IDs
  
- [ ] **Error Handling**
  - Error codes documentation
  - Status enums
  - Failure reasons
  
- [ ] **Changelog & Migration Guides**
  - Breaking changes
  - Deprecated APIs
  - Version compatibility matrix

### 1.3 CloudX Architecture Audit

**Objective:** Understand CloudX Core protocols and patterns.

#### Review Meta Adapter (Gold Standard)

```bash
cd cloudx-ios/adapter-meta
```

**Key Files to Study:**

1. **Initializer Pattern**
   - `Sources/CloudXMetaAdapter/Initializers/CLXMetaInitializer.h/m`
   - Conformance to `CLXAdNetworkInitializer`
   - SDK initialization with configuration
   - Privacy settings integration

2. **Bid Token Source**
   - `Sources/CloudXMetaAdapter/CLXMetaBidTokenSource.h/m`
   - Conformance to `CLXBidTokenSource`
   - Token generation and caching
   - Error handling for token failures

3. **Ad Format Adapters**
   - Interstitial: `CLXMetaInterstitial.h/m`
   - Banner: `CLXMetaBanner.h/m`
   - Rewarded: `CLXMetaRewarded.h/m`
   - Native: `CLXMetaNative.h/m`

4. **Factory Pattern**
   - `CLXMetaInterstitialFactory.h/m`
   - `CLXMetaBannerFactory.h/m`
   - `CLXMetaRewardedFactory.h/m`
   - `CLXMetaNativeFactory.h/m`

5. **Error Handling**
   - `CLXMetaErrorHandler.h/m`
   - Network error → CloudX error mapping
   - Localized error messages
   - Recovery suggestions

6. **Base/Utilities**
   - `CLXMetaBaseFactory.h/m` (shared utilities)
   - Logger integration
   - Constants and configuration

#### CloudX Core Protocols Reference

Study these protocols in `cloudx-ios/core/Sources/CloudXCore/`:

1. **`CLXAdNetworkInitializer`**
   ```objc
   @protocol CLXAdNetworkInitializer
   @property (nonatomic, strong, readonly) NSString *sdkVersion;
   @property (nonatomic, strong, readonly) NSString *network;
   - (void)initializeWithConfig:(CLXBidderConfig *)config 
                      completion:(void (^)(BOOL success, NSError *error))completion;
   @end
   ```

2. **`CLXBidTokenSource`**
   ```objc
   @protocol CLXBidTokenSource
   @property (nonatomic, strong, readonly) NSString *network;
   - (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> *token, 
                                            NSError *error))completion;
   @end
   ```

3. **Ad Format Protocols**
   - `CLXAdapterInterstitial` + `CLXAdapterInterstitialDelegate`
   - `CLXAdapterBanner` + `CLXAdapterBannerDelegate`
   - `CLXAdapterRewarded` + `CLXAdapterRewardedDelegate`
   - `CLXAdapterNative` + `CLXAdapterNativeDelegate`

4. **Factory Protocols**
   - `CLXAdapterInterstitialFactory`
   - `CLXAdapterBannerFactory`
   - `CLXAdapterRewardedFactory`
   - `CLXAdapterNativeFactory`

### 1.4 Audit Deliverable Template

Create: `<NETWORK>_ADAPTER_AUDIT_FINDINGS.md`

```markdown
# <NETWORK> Adapter Audit Findings

## 1. Competitor Analysis

### AppLovin MAX Adapter
- **Package:** AppLovinMediation<Network>Adapter
- **Version:** X.X.X
- **Key Insights:**
  - [Initialization pattern]
  - [Factory design]
  - [Error handling approach]

### Unity Adapter
[Similar structure]

### AdMob Adapter
[Similar structure]

## 2. Network SDK Analysis

### SDK Version
- **Current:** X.X.X
- **Minimum iOS:** XX.X
- **CocoaPods:** `pod '<NetworkSDK>', '~> X.X'`

### Initialization
- **API:** `[NetworkSDK initWithAccountID:...]`
- **Thread:** Main thread required
- **Configuration:** [Key configuration options]

### Ad Formats
[Document each format's API]

### Header Bidding
- **Bid Token API:** `[NetworkSDK getToken]`
- **Token Format:** [Base64, JSON, etc.]

## 3. CloudX Integration Requirements

### Protocols to Implement
- [x] CLXAdNetworkInitializer
- [x] CLXBidTokenSource
- [x] CLXAdapterInterstitial + Factory
- [x] CLXAdapterBanner + Factory
- [x] CLXAdapterRewarded + Factory
- [ ] CLXAdapterNative + Factory (if supported)

### Special Considerations
- [Privacy requirements]
- [Threading considerations]
- [Known issues or workarounds]

## 4. Recommended Architecture

[Proposed structure based on findings]
```

---

## Phase 2: Architecture & Design

### 2.1 Naming Conventions

**Adapter Name Pattern:**

```
CloudX<Network>Adapter
```

Examples:
- ✅ `CloudXInMobiAdapter`
- ✅ `CloudXUnityAdapter`
- ✅ `CloudXIronSourceAdapter`
- ✅ `CloudXMintegralAdapter`

**Class Name Pattern:**

```
CLX<Network><Component>
```

Examples:
- `CLXInMobiInitializer`
- `CLXInMobiInterstitial`
- `CLXInMobiBidTokenSource`
- `CLXUnityBannerFactory`

**File Organization:**

```
adapter-<network>/
├── Sources/CloudX<Network>Adapter/
│   ├── Base/
│   │   ├── CLX<Network>BaseFactory.h/.m
│   ├── Initializers/
│   │   ├── CLX<Network>Initializer.h/.m
│   ├── BidTokenSource/
│   │   ├── CLX<Network>BidTokenSource.h/.m
│   ├── Utils/
│   │   ├── CLX<Network>ErrorHandler.h/.m
│   ├── Interstitial/
│   │   ├── CLX<Network>Interstitial.h/.m
│   │   ├── CLX<Network>InterstitialFactory.h/.m
│   ├── Banner/
│   │   ├── CLX<Network>Banner.h/.m
│   │   ├── CLX<Network>BannerFactory.h/.m
│   ├── Rewarded/
│   │   ├── CLX<Network>Rewarded.h/.m
│   │   ├── CLX<Network>RewardedFactory.h/.m
│   ├── Native/ (optional)
│   │   ├── CLX<Network>Native.h/.m
│   │   ├── CLX<Network>NativeFactory.h/.m
│   ├── CloudX<Network>Adapter.h (umbrella)
│   ├── Info.plist
│   ├── PrivacyInfo.xcprivacy
│   └── module.modulemap
├── Package.swift
├── Podfile
├── build_frameworks.sh
├── release-<network>-local.sh
├── README.md
└── LICENSE
```

**Note:** The podspec exists in two locations:
- `cloudx-ios-private/adapter-<network>/CloudX<Network>Adapter.podspec` - For local development
- `cloudx-ios/adapter-<network>/CloudX<Network>Adapter.podspec` - For public binary distribution

### 2.2 Architecture Decisions

#### Decision 1: Source vs. Binary Distribution

**Meta Adapter Pattern (RECOMMENDED):**

- **Development:** Source-based (via `.podspec` with `source_files`)
- **Production:** Binary xcframework (via `-remote.podspec` with `vendored_frameworks`)

**Rationale:**
- Source distribution: Easier debugging during development
- Binary distribution: Protects IP, faster integration, smaller repo size

#### Decision 2: Static vs. Dynamic Framework

**Recommendation:** Static Framework

**Rationale:**
- iOS App Store prefers static linking
- Reduces app launch time
- Avoids framework embedding issues
- Matches CloudXCore pattern

#### Decision 3: Dependency Management

**Network SDK as External Dependency:**

```ruby
# ✅ CORRECT - Network SDK as peer dependency
s.dependency 'CloudXCore'
s.dependency '<NetworkSDK>', '~> X.X'
```

**Never bundle the network SDK inside the adapter:**
- Violates most network SDK terms of service
- Creates versioning conflicts
- Increases binary size unnecessarily

#### Decision 4: Threading Model

**Main Thread for SDK Calls:**

```objc
// ✅ CORRECT
dispatch_async(dispatch_get_main_queue(), ^{
    [NetworkSDK initWithAccountID:accountID];
});
```

**Rationale:**
- Most ad network SDKs require main thread
- Prevents threading issues and crashes
- Consistent with Meta adapter pattern

### 2.3 System Design Document Template

Create: `<NETWORK>_ADAPTER_SYSTEM_DESIGN.md`

```markdown
# <Network> Adapter System Design

## 1. Overview

### Adapter Name
CloudXMediation<Network>Adapter

### Network SDK
- **Name:** <NetworkSDK>
- **Version:** X.X.X
- **CocoaPods:** pod '<NetworkSDK>', '~> X.X'

### Supported Ad Formats
- [x] Interstitial
- [x] Banner
- [x] Rewarded Video
- [ ] Native (if applicable)

## 2. Component Design

### 2.1 Initializer (CLX<Network>Initializer)

**Purpose:** Initialize network SDK with CloudX configuration

**Protocol:** CLXAdNetworkInitializer

**Key Methods:**
```objc
- (void)initializeWithConfig:(CLXBidderConfig *)config 
                  completion:(void (^)(BOOL, NSError *))completion;
```

**Implementation Notes:**
- Extract account ID from config
- Configure privacy settings (GDPR, CCPA, COPPA)
- Initialize on main thread
- Register factories with CloudXCore
- Handle initialization errors

### 2.2 Bid Token Source (CLX<Network>BidTokenSource)

**Purpose:** Generate bid tokens for header bidding

**Protocol:** CLXBidTokenSource

**Implementation Notes:**
- Call network SDK token API
- Include IDFA (if available)
- Format: [describe format]
- Cache strategy: [describe caching]
- Error handling: [describe error cases]

### 2.3 Ad Format Adapters

[Document each ad format's design]

### 2.4 Error Handler (CLX<Network>ErrorHandler)

**Purpose:** Map network errors to CloudX error codes

**Mapping Table:**
| Network Error | CloudX Error | Retry? |
|---------------|--------------|--------|
| NO_FILL | CLXErrorCodeNoFill | Yes |
| NETWORK_ERROR | CLXErrorCodeNetworkError | Yes |
| [etc.] | [etc.] | [etc.] |

## 3. Data Flow

[Diagrams showing initialization, ad loading, bid token flow]

## 4. Privacy & Compliance

### GDPR
[Implementation approach]

### CCPA
[Implementation approach]

### ATT
[Implementation approach]

### Privacy Manifest
[Required disclosures]

## 5. Testing Strategy

[Unit tests, integration tests, manual testing]

## 6. Deployment

[Release process, versioning strategy]
```

---

## Phase 3: Implementation

### 3.1 Project Setup

#### Step 1: Create Adapter Directory Structure

```bash
cd cloudx-ios
mkdir -p adapter-<network>/Sources/CloudX<Network>Adapter/{Base,Initializers,BidTokenSource,Utils,Interstitial,Banner,Rewarded,Native}
```

#### Step 2: Create Podfile

**File:** `adapter-<network>/Podfile`

```ruby
platform :ios, '14.0'
use_frameworks! :linkage => :static

target 'CloudX<Network>Adapter' do
  pod 'CloudXCore', :path => '../core'
  pod '<NetworkSDK>', '~> X.X.X'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

#### Step 3: Create module.modulemap

**File:** `adapter-<network>/Sources/CloudX<Network>Adapter/module.modulemap`

```
framework module CloudX<Network>Adapter {
  umbrella header "CloudX<Network>Adapter.h"
  
  export *
  module * { export * }
}
```

#### Step 4: Create Info.plist

**File:** `adapter-<network>/Sources/CloudX<Network>Adapter/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
</dict>
</plist>
```

#### Step 5: Create PrivacyInfo.xcprivacy

**File:** `adapter-<network>/Sources/CloudX<Network>Adapter/PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeDeviceID</string>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising</string>
            </array>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <true/>
        </dict>
    </array>
    <key>NSPrivacyTracking</key>
    <true/>
    <key>NSPrivacyTrackingDomains</key>
    <array>
        <string><network-domain>.com</string>
    </array>
</dict>
</plist>
```

### 3.2 Core Infrastructure Implementation

#### Component 1: Base Factory

**Purpose:** Shared utilities for all factories

**File:** `CLX<Network>BaseFactory.h`

```objc
#import <Foundation/Foundation.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLX<Network>BaseFactory : NSObject

@property (nonatomic, strong, readonly) CLXLogger *logger;

- (long long)extractPlacementID:(NSString *)placementIDString;
- (BOOL)validateBidPayload:(nullable NSString *)bidPayload;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>BaseFactory.m`

```objc
#import "CLX<Network>BaseFactory.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLX<Network>BaseFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLX<Network>BaseFactory"];
    }
    return self;
}

- (long long)extractPlacementID:(NSString *)placementIDString {
    if (!placementIDString || placementIDString.length == 0) {
        [self.logger error:@"Empty placement ID provided"];
        return 0;
    }
    
    long long placementID = [placementIDString longLongValue];
    
    if (placementID <= 0) {
        [self.logger error:[NSString stringWithFormat:@"Invalid placement ID: %@", placementIDString]];
        return 0;
    }
    
    return placementID;
}

- (BOOL)validateBidPayload:(nullable NSString *)bidPayload {
    if (!bidPayload) {
        return YES; // Valid for waterfall
    }
    
    if (bidPayload.length == 0) {
        [self.logger warning:@"Empty bid payload for header bidding"];
        return NO;
    }
    
    return YES;
}

@end
```

#### Component 2: Error Handler

**Purpose:** Centralized error mapping

**File:** `CLX<Network>ErrorHandler.h`

```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

@interface CLX<Network>ErrorHandler : NSObject

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>ErrorHandler.m`

```objc
#import "CLX<Network>ErrorHandler.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLX<Network>ErrorHandler

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeUnknown;
    NSString *description = networkError.localizedDescription ?: @"Unknown error";
    NSString *recoverySuggestion = nil;
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: %@", 
                   context, placementID ?: @"N/A", description]];
    
    // Map network-specific errors to CloudX errors
    switch (networkError.code) {
        case NetworkErrorNoFill:
            cloudXCode = CLXErrorCodeNoFill;
            description = @"No fill for ad request";
            shouldRetry = YES;
            break;
            
        case NetworkErrorNetworkFailure:
            cloudXCode = CLXErrorCodeNetworkError;
            description = @"Network connectivity issue";
            shouldRetry = YES;
            break;
            
        // Add more error mappings
            
        default:
            cloudXCode = CLXErrorCodeUnknown;
            description = [NSString stringWithFormat:@"Unknown error: %ld", (long)networkError.code];
            break;
    }
    
    return [CLXError errorWithCode:cloudXCode
                       description:description
                recoverySuggestion:recoverySuggestion
                          userInfo:@{
                              NSUnderlyingErrorKey: networkError,
                              @"ShouldRetry": @(shouldRetry)
                          }];
}

@end
```

#### Component 3: Initializer

**File:** `CLX<Network>Initializer.h`

```objc
#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLX<Network>Initializer : NSObject <CLXAdNetworkInitializer>

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (instancetype)createInstance;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>Initializer.m`

```objc
#import "CLX<Network>Initializer.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXError.h>
#import <NetworkSDK/NetworkSDK.h>
#import "CLX<Network>InterstitialFactory.h"
#import "CLX<Network>BannerFactory.h"
#import "CLX<Network>RewardedFactory.h"

@interface CLX<Network>Initializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;
@end

@implementation CLX<Network>Initializer

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"X.X.X";

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLX<Network>Initializer alloc] init];
}

+ (NSString *)sdkVersion {
    return kSDKVersion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLX<Network>Initializer sdkVersion];
        _network = @"<network>";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLX<Network>Initializer"];
    }
    return self;
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    [self.logger debug:@"Initializing adapter"];
    
    if (isInitialized) {
        [self.logger info:@"SDK already initialized"];
        if (completion) completion(YES, nil);
        return;
    }
    
    // Extract account ID
    NSString *accountID = config.initializationData[@"accountID"];
    if (!accountID || accountID.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"Missing accountID"];
        [self.logger error:@"Failed to initialize: missing accountID"];
        if (completion) completion(NO, error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Configure privacy settings
            [self configurePrivacySettings];
            
            // Initialize SDK
            [NetworkSDK initWithAccountID:accountID];
            
            // Register factories
            [self registerFactories];
            
            isInitialized = YES;
            [self.logger info:@"SDK initialized successfully"];
            
            if (completion) completion(YES, nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInternalError
                                         description:exception.reason ?: @"Unknown error"];
            [self.logger error:[NSString stringWithFormat:@"Initialization failed: %@", exception.reason]];
            if (completion) completion(NO, error);
        }
    });
}

- (void)configurePrivacySettings {
    CLXSettings *settings = [CLXSettings sharedInstance];
    
    // GDPR
    if (settings.gdprConsentAvailable) {
        [NetworkSDK setGDPRConsent:settings.gdprConsentAccepted];
    }
    
    // CCPA
    if (settings.usPrivacyString) {
        [NetworkSDK setCCPAString:settings.usPrivacyString];
    }
    
    // COPPA
    if (settings.coppaEnabled) {
        [NetworkSDK setCOPPAEnabled:settings.coppaEnabled];
    }
}

- (void)registerFactories {
    [[CloudXCore shared] registerAdNetworkFactory:[CLX<Network>InterstitialFactory createInstance] 
                                        forAdType:CLXAdTypeInterstitial];
    [[CloudXCore shared] registerAdNetworkFactory:[CLX<Network>BannerFactory createInstance] 
                                        forAdType:CLXAdTypeBanner];
    [[CloudXCore shared] registerAdNetworkFactory:[CLX<Network>RewardedFactory createInstance] 
                                        forAdType:CLXAdTypeRewarded];
}

@end
```

#### Component 4: Bid Token Source

**File:** `CLX<Network>BidTokenSource.h`

```objc
#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLX<Network>BidTokenSource : NSObject <CLXBidTokenSource>

@property (nonatomic, strong, readonly) NSString *network;

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>BidTokenSource.m`

```objc
#import "CLX<Network>BidTokenSource.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <NetworkSDK/NetworkSDK.h>
#import "CLX<Network>Initializer.h"

@interface CLX<Network>BidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLX<Network>BidTokenSource

+ (instancetype)sharedInstance {
    static CLX<Network>BidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLX<Network>BidTokenSource"];
        _network = @"<network>";
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, 
                                         NSError * _Nullable))completion {
    
    [self.logger debug:@"Getting bid token"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (![CLX<Network>Initializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"SDK not initialized"];
                [self.logger error:@"Cannot generate token - SDK not initialized"];
                if (completion) completion(nil, error);
                return;
            }
            
            // Get token from network SDK
            NSString *bidToken = [NetworkSDK getToken];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
            }
            
            tokenDict[@"network"] = self.network;
            
            [self.logger info:[NSString stringWithFormat:@"Token generated with %lu keys", 
                              (unsigned long)tokenDict.count]];
            
            if (completion) completion([tokenDict copy], nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                         description:exception.reason ?: @"Token generation failed"];
            [self.logger error:[NSString stringWithFormat:@"Token generation failed: %@", exception.reason]];
            if (completion) completion(nil, error);
        }
    });
}

@end
```

### 3.3 Ad Format Implementation Pattern

#### Interstitial Adapter Template

**File:** `CLX<Network>Interstitial.h`

```objc
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NetworkSDK/NetworkSDK.h>
#import <CloudXCore/CLXAdapterInterstitial.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLX<Network>Interstitial : NSObject <NetworkSDKInterstitialDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) long long placementID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, strong, nullable) NetworkInterstitial *interstitial;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>Interstitial.m`

```objc
#import "CLX<Network>Interstitial.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLX<Network>ErrorHandler.h"
#import "CLX<Network>Initializer.h"

@interface CLX<Network>Interstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation CLX<Network>Interstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = placementID;
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLX<Network>Initializer sdkVersion];
        _network = @"<network>";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLX<Network>Interstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement:%lld, BidID:%@", 
                           placementID, bidID]];
        
        _interstitial = [[NetworkInterstitial alloc] initWithPlacementID:placementID];
        _interstitial.delegate = self;
    }
    return self;
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement:%lld", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.interstitial loadWithBidPayload:self.bidPayload];
        } else {
            [self.interstitial load];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = self.interstitial && [self.interstitial isReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial"];
        
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitial showFromViewController:viewController];
        });
    } else {
        [self.logger error:@"Cannot show - ad not ready"];
        
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdNotReady
                                     description:@"Interstitial not ready"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:error];
        }
    }
}

#pragma mark - NetworkSDKInterstitialDelegate

- (void)interstitialDidLoad:(NetworkInterstitial *)interstitial {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitial:(NetworkInterstitial *)interstitial didFailWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLX<Network>ErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Load"
                                                            placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
    }
}

- (void)interstitialDidPresent:(NetworkInterstitial *)interstitial {
    [self.logger info:@"Did present"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)interstitialDidDismiss:(NetworkInterstitial *)interstitial {
    [self.logger info:@"Did dismiss"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)interstitialDidClick:(NetworkInterstitial *)interstitial {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

@end
```

**File:** `CLX<Network>InterstitialFactory.h`

```objc
#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import "CLX<Network>BaseFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLX<Network>InterstitialFactory : CLX<Network>BaseFactory <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
```

**File:** `CLX<Network>InterstitialFactory.m`

```objc
#import "CLX<Network>InterstitialFactory.h"
#import "CLX<Network>Interstitial.h"
#import <CloudXCore/CLXError.h>

@implementation CLX<Network>InterstitialFactory

+ (instancetype)createInstance {
    return [[CLX<Network>InterstitialFactory alloc] init];
}

- (NSString *)network {
    return @"<network>";
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                           bidPayload:(nullable NSString *)bidPayload
                                                bidID:(NSString *)bidID
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial - AdId:%@", adId]];
    
    long long placementID = [self extractPlacementID:adId];
    if (placementID == 0) {
        [self.logger error:@"Invalid placement ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid placement ID"];
            [delegate didFailToLoadWithInterstitial:nil error:error];
        }
        return nil;
    }
    
    CLX<Network>Interstitial *interstitial = 
        [[CLX<Network>Interstitial alloc] initWithBidPayload:bidPayload
                                                 placementID:placementID
                                                       bidID:bidID
                                                    delegate:delegate];
    
    return interstitial;
}

@end
```

**Repeat similar pattern for Banner, Rewarded, and Native ad formats.**

### 3.4 Umbrella Header

**File:** `CloudX<Network>Adapter.h`

```objc
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double CloudX<Network>AdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudX<Network>AdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudX<Network>AdapterRegister(void);

// Public headers
#import "CLX<Network>Initializer.h"
#import "CLX<Network>BidTokenSource.h"
#import "CLX<Network>ErrorHandler.h"
#import "CLX<Network>BaseFactory.h"

// Ad Format Factories
#import "CLX<Network>InterstitialFactory.h"
#import "CLX<Network>BannerFactory.h"
#import "CLX<Network>RewardedFactory.h"
// #import "CLX<Network>NativeFactory.h" // If applicable
```

---

## Phase 4: Distribution & Release

### 4.1 CocoaPods Specification

#### Private Repo Podspec (Local Development)

**File:** `cloudx-ios-private/adapter-<network>/CloudX<Network>Adapter.podspec`

```ruby
Pod::Spec.new do |s|
  s.name = 'CloudX<Network>Adapter'
  s.version = '1.0.0'
  s.summary = 'CloudX Adapter for <Network> iOS SDK'
  s.description = 'The CloudX <Network> Adapter enables publishers to monetize their iOS applications through the CloudX SDK.'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.source_files = 'Sources/CloudX<Network>Adapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudX<Network>Adapter/**/*.h'
  s.resource_bundles = {
    'CloudX<Network>Adapter' => ['Sources/CloudX<Network>Adapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore'
  s.dependency '<NetworkSDK>', '~> X.X'

  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
```

#### Public Repo Podspec (Binary Distribution)

**File:** `cloudx-ios/adapter-<network>/CloudX<Network>Adapter.podspec`

```ruby
Pod::Spec.new do |s|
  s.name = 'CloudX<Network>Adapter'
  s.version = '1.0.0'
  s.summary = 'CloudX Adapter for <Network> iOS SDK'
  s.description = 'Pre-built xcframework for CloudX <Network> adapter'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = {
    :http => "https://github.com/cloudx-io/cloudx-ios/releases/download/v#{s.version}-<network>/CloudX<Network>Adapter-v#{s.version}.xcframework.zip",
    :type => "zip",
    :flatten => false
  }

  s.ios.deployment_target = '14.0'
  
  s.vendored_frameworks = 'CloudX<Network>Adapter.xcframework'
  s.preserve_paths = 'CloudX<Network>Adapter.xcframework'

  s.dependency 'CloudXCore'
  s.dependency '<NetworkSDK>', '~> X.X'

  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CloudX<Network>Adapter',
    'OTHER_LDFLAGS' => '-framework CloudX<Network>Adapter',
    'DEFINES_MODULE' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
```

### 4.2 Swift Package Manager

**File:** `adapter-<network>/Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudX<Network>Adapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudX<Network>Adapter",
            targets: ["CloudX<Network>Adapter"]
        ),
    ],
    dependencies: [
        .package(path: "../core")
    ],
    targets: [
        .target(
            name: "CloudX<Network>Adapter",
            dependencies: [],
            path: "Sources/CloudX<Network>Adapter",
            publicHeadersPath: ".",
            cSettings: [
                .define("DEFINES_MODULE", to: "YES"),
                .define("CLANG_ENABLE_MODULES", to: "YES"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedFramework("AdSupport"),
                .linkedFramework("AppTrackingTransparency", .when(platforms: [.iOS])),
            ]
        ),
    ]
)
```

**Update Root Package.swift:**

Add to `cloudx-ios/Package.swift`:

```swift
.library(
    name: "CloudX<Network>Adapter",
    targets: ["CloudX<Network>Adapter"]
),

// In targets:
.binaryTarget(
    name: "CloudX<Network>Adapter",
    url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v1.0.0-<network>/CloudX<Network>Adapter-v1.0.0.xcframework.zip",
    checksum: "0000000000000000000000000000000000000000000000000000000000000000"
)
```

### 4.3 Build Script

**File:** `build_frameworks.sh`

```bash
#!/bin/bash
set -e

FRAMEWORK_NAME="CloudX<Network>Adapter"
BUILD_DIR="build"
XCFRAMEWORK_PATH="${FRAMEWORK_NAME}.xcframework"

echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${XCFRAMEWORK_PATH}"
rm -f "${XCFRAMEWORK_PATH}.zip"

echo "📦 Installing CocoaPods dependencies..."
pod install

echo "🏗️  Building for iOS device (arm64)..."
xcodebuild archive \
  -workspace "${FRAMEWORK_NAME}.xcworkspace" \
  -scheme "${FRAMEWORK_NAME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${BUILD_DIR}/ios.xcarchive" \
  -sdk iphoneos \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ENABLE_BITCODE=NO \
  | tee xcodebuild-ios.log | xcpretty || cat xcodebuild-ios.log

echo "🏗️  Building for iOS Simulator (arm64 + x86_64)..."
xcodebuild archive \
  -workspace "${FRAMEWORK_NAME}.xcworkspace" \
  -scheme "${FRAMEWORK_NAME}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${BUILD_DIR}/ios-sim.xcarchive" \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ENABLE_BITCODE=NO \
  | tee xcodebuild-sim.log | xcpretty || cat xcodebuild-sim.log

echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "${BUILD_DIR}/ios-sim.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "${XCFRAMEWORK_PATH}"

echo "📝 Setting up module map in XCFramework..."
for arch_dir in "${XCFRAMEWORK_PATH}"/*/; do
    HEADERS_DIR="${arch_dir}Headers"
    if [ -d "${HEADERS_DIR}" ]; then
        cp "Sources/${FRAMEWORK_NAME}/module.modulemap" "${HEADERS_DIR}/"
        echo "✅ Copied module.modulemap to ${HEADERS_DIR}"
    fi
done

echo "🗜️  Compressing XCFramework..."
zip -r "${XCFRAMEWORK_PATH}.zip" "${XCFRAMEWORK_PATH}"

echo "✅ Build complete!"
echo "📦 XCFramework: ${XCFRAMEWORK_PATH}"
echo "📦 Zip: ${XCFRAMEWORK_PATH}.zip"

CHECKSUM=$(swift package compute-checksum "${XCFRAMEWORK_PATH}.zip")
echo "🔐 SwiftPM Checksum: ${CHECKSUM}"
```

Make executable:
```bash
chmod +x build_frameworks.sh
```

### 4.4 Release Script (Local)

**File:** `release-<network>-local.sh`

```bash
#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_step() { echo -e "${BLUE}🔄 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
FULL_VERSION="v${VERSION}-<network>"

echo "🚀 Starting CloudX<Network>Adapter v${VERSION} local release..."

# Check authentication
if [ -z "$COCOAPODS_TRUNK_TOKEN" ]; then
    print_error "COCOAPODS_TRUNK_TOKEN not set"
fi

print_step "🗖 Checking clean state"
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory not clean"
fi

print_step "𝔠 Switch to Xcode 16.1"
sudo xcode-select -s /Applications/Xcode_16.1.app

print_step "🤠 Clean build artifacts"
rm -rf build ~/Library/Developer/Xcode/DerivedData

print_step "🛠 Install CocoaPods"
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods not installed"
fi

print_step "📀 Build static xcframework"
bash build_frameworks.sh

print_step "📦 Rename framework with version"
mv CloudX<Network>Adapter.xcframework.zip CloudX<Network>Adapter-v$VERSION.xcframework.zip

print_step "🔢 Compute SwiftPM checksum"
CHECKSUM=$(swift package compute-checksum CloudX<Network>Adapter-v$VERSION.xcframework.zip)
echo "checksum=$CHECKSUM"

print_step "📝 Update podspec and Package.swift"
# Update public repo podspec
cd ..
cd cloudx-ios/adapter-<network>
sed -i '' "s/s\.version.*=.*/s.version = '$VERSION'/" CloudX<Network>Adapter.podspec
sed -i '' "s|releases/download/v[^/]*/|releases/download/${FULL_VERSION}/|" CloudX<Network>Adapter.podspec

# Update Package.swift
cd ../..
sed -i '' "s|url: \".*CloudX<Network>Adapter.*\",|url: \"https://github.com/cloudx-io/cloudx-ios/releases/download/$FULL_VERSION/CloudX<Network>Adapter-v$VERSION.xcframework.zip\",|" Package.swift
sed -i '' "s|checksum: \".*\"|checksum: \"$CHECKSUM\"|" Package.swift

cd cloudx-ios-private/adapter-<network>

print_step "📊 Create GitHub release"
cd ..

cat > release_notes.md << EOF
CloudX<Network>Adapter v$VERSION SDK release (static xcframework)

## Installation

### CocoaPods
\`\`\`ruby
pod 'CloudX<Network>Adapter', '~> $VERSION'
\`\`\`

### Swift Package Manager
Add repository: https://github.com/cloudx-io/cloudx-ios

### Manual Installation
Download CloudX<Network>Adapter-v$VERSION.xcframework.zip from this release.

## SwiftPM Checksum
$CHECKSUM
EOF

gh release create "$FULL_VERSION" \
  --title "CloudX<Network>Adapter v$VERSION" \
  --notes-file release_notes.md \
  --latest

print_step "📦 Upload xcframework to release"
gh release upload "$FULL_VERSION" \
  adapter-<network>/CloudX<Network>Adapter-v$VERSION.xcframework.zip

cd adapter-<network>

print_step "🧪 Validate podspec"
cd ../../cloudx-ios/adapter-<network>
pod spec lint CloudX<Network>Adapter.podspec --allow-warnings --skip-import-validation --verbose
cd ../../cloudx-ios-private/adapter-<network>

print_step "📤 Push podspec to CocoaPods trunk"
mkdir -p ~/.cocoapods/trunk
echo '{"trunk":{"token":"'$COCOAPODS_TRUNK_TOKEN'"}}' > ~/.cocoapods/trunk/me.json

for i in {1..5}; do
    if pod trunk push CloudX<Network>Adapter.podspec --allow-warnings --skip-import-validation --verbose; then
        echo "✅ Pod trunk push succeeded"
        break
    else
        if [ $i -lt 5 ]; then
            echo "Retrying in 30 seconds..."
            sleep 30
        else
            print_error "Pod trunk push failed after all retries"
        fi
    fi
done

cd ..
print_success "CloudX<Network>Adapter v$VERSION release completed!"
echo "🔗 GitHub Release: https://github.com/cloudx-io/cloudx-ios/releases/tag/$FULL_VERSION"
echo "📦 CocoaPods: https://cocoapods.org/pods/CloudX<Network>Adapter"

rm -f release_notes.md
```

Make executable:
```bash
chmod +x release-<network>-local.sh
```

### 4.5 GitHub Actions Workflow

**File:** `.github/workflows/<network>-release.yml`

```yaml
name: Release CloudX<Network>Adapter

on:
  push:
    tags:
      - 'v*-<network>'

jobs:
  release:
    runs-on: macos-latest
    permissions:
      contents: write

    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      COCOAPODS_TRUNK_TOKEN: ${{ secrets.COCOAPODS_TRUNK_TOKEN }}

    steps:
      - name: 𝔠 Debug available Xcode versions
        run: ls -la /Applications/ | grep -i xcode

      - name: 𝔠 Switch to Xcode 16.1
        run: sudo xcode-select -s /Applications/Xcode_16.1.app

      - name: 🗖 Checkout repo
        uses: actions/checkout@v4

      - name: 🤠 Clean build artifacts
        run: |
          rm -rf build
          rm -rf ~/Library/Developer/Xcode/DerivedData

      - name: 🛠 Install CocoaPods
        run: sudo gem install cocoapods --no-document

      - name: 🔢 Extract version from tag
        id: version
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          VERSION_NO_SUFFIX=${VERSION%-<network>}
          echo "version=$VERSION_NO_SUFFIX" >> $GITHUB_OUTPUT
          echo "full_version=$GITHUB_REF_NAME" >> $GITHUB_OUTPUT

      - name: 📀 Build static xcframework
        run: |
          cd cloudx-ios-private/adapter-<network>
          bash build_frameworks.sh

      - name: 📦 Rename framework with version
        run: |
          cd cloudx-ios-private/adapter-<network>
          VERSION=${{ steps.version.outputs.version }}
          mv CloudX<Network>Adapter.xcframework.zip CloudX<Network>Adapter-v$VERSION.xcframework.zip

      - name: 🔢 Compute SwiftPM checksum
        id: checksum
        run: |
          cd cloudx-ios-private/adapter-<network>
          VERSION=${{ steps.version.outputs.version }}
          CHECKSUM=$(swift package compute-checksum CloudX<Network>Adapter-v$VERSION.xcframework.zip)
          echo "checksum=$CHECKSUM" >> $GITHUB_OUTPUT

      - name: 📝 Update podspec and Package.swift
        run: |
          VERSION=${{ steps.version.outputs.version }}
          FULL_VERSION=${{ steps.version.outputs.full_version }}
          
          # Update public repo podspec
          cd cloudx-ios/adapter-<network>
          sed -i '' "s/s\.version.*=.*/s.version = '$VERSION'/" CloudX<Network>Adapter.podspec
          sed -i '' "s|releases/download/v[^/]*/|releases/download/${FULL_VERSION}/|" CloudX<Network>Adapter.podspec
          
          # Update Package.swift
          cd ../..
          sed -i '' "s|url: \".*CloudX<Network>Adapter.*\",|url: \"https://github.com/cloudx-io/cloudx-ios/releases/download/$FULL_VERSION/CloudX<Network>Adapter-v$VERSION.xcframework.zip\",|" Package.swift
          sed -i '' "s|checksum: \".*\"|checksum: \"${{ steps.checksum.outputs.checksum }}\"|" Package.swift

      - name: 📊 Create GitHub release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          VERSION=${{ steps.version.outputs.version }}
          FULL_VERSION=${{ steps.version.outputs.full_version }}
          
          cat > release_notes.md << EOF
          CloudX<Network>Adapter v$VERSION SDK release
          
          ## Installation
          
          ### CocoaPods
          \`\`\`ruby
          pod 'CloudX<Network>Adapter', '~> $VERSION'
          \`\`\`
          
          ### Swift Package Manager
          Add repository: https://github.com/cloudx-io/cloudx-ios
          
          ### Manual Installation
          Download CloudX<Network>Adapter-v$VERSION.xcframework.zip
          
          ## SwiftPM Checksum
          ${{ steps.checksum.outputs.checksum }}
          EOF
          
          gh release create "$FULL_VERSION" \
            --title "CloudX<Network>Adapter v$VERSION" \
            --notes-file release_notes.md \
            --latest

      - name: 📦 Upload xcframework to release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          VERSION=${{ steps.version.outputs.version }}
          FULL_VERSION=${{ steps.version.outputs.full_version }}
          
          gh release upload "$FULL_VERSION" \
            cloudx-ios-private/adapter-<network>/CloudX<Network>Adapter-v$VERSION.xcframework.zip

      - name: 🧪 Validate podspec
        run: |
          cd cloudx-ios/adapter-<network>
          pod spec lint CloudX<Network>Adapter.podspec --allow-warnings --skip-import-validation --skip-tests --verbose

      - name: ⏳ Wait for CloudXCore dependency
        run: |
          echo "🔍 Checking for CloudXCore dependency availability..."
          
          if pod trunk info CloudXCore > /dev/null 2>&1; then
            echo "✅ CloudXCore is available"
          else
            echo "❌ CloudXCore not found"
            exit 1
          fi

      - name: 📤 Push podspec to CocoaPods trunk
        run: |
          mkdir -p ~/.cocoapods/trunk
          echo '{"trunk":{"token":"${{ secrets.COCOAPODS_TRUNK_TOKEN }}"}}' > ~/.cocoapods/trunk/me.json
          cd cloudx-ios/adapter-<network>
          
          for i in {1..5}; do
            if pod trunk push CloudX<Network>Adapter.podspec --allow-warnings --skip-import-validation --skip-tests --verbose; then
              echo "✅ Pod trunk push succeeded"
              break
            else
              if [ $i -lt 5 ]; then
                sleep 30
              else
                exit 1
              fi
            fi
          done

      - name: 📌 Upload xcodebuild logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: xcodebuild-logs
          path: |
            adapter-<network>/xcodebuild-ios.log
            adapter-<network>/xcodebuild-sim.log
```

---

## Phase 5: Testing & Validation

### 5.1 Unit Testing Strategy

**Create Test Target in Xcode:**

```objc
// CLX<Network>InitializerTests.m
#import <XCTest/XCTest.h>
#import "CLX<Network>Initializer.h"

@interface CLX<Network>InitializerTests : XCTestCase
@end

@implementation CLX<Network>InitializerTests

- (void)testInitializerConformance {
    CLX<Network>Initializer *initializer = [CLX<Network>Initializer createInstance];
    XCTAssertNotNil(initializer);
    XCTAssertTrue([initializer conformsToProtocol:@protocol(CLXAdNetworkInitializer)]);
}

- (void)testSDKVersion {
    NSString *version = [CLX<Network>Initializer sdkVersion];
    XCTAssertNotNil(version);
    XCTAssertTrue(version.length > 0);
}

- (void)testNetworkIdentifier {
    CLX<Network>Initializer *initializer = [CLX<Network>Initializer createInstance];
    XCTAssertEqualObjects(initializer.network, @"<network>");
}

@end
```

### 5.2 Integration Testing

**Manual Test Checklist:**

1. **SDK Initialization**
   - [ ] Initialize with valid account ID
   - [ ] Initialize with invalid account ID (error handling)
   - [ ] Initialize twice (idempotency)
   - [ ] Initialize without GDPR consent
   - [ ] Initialize with GDPR consent granted
   - [ ] Initialize with GDPR consent denied

2. **Bid Token Generation**
   - [ ] Generate token before initialization (error handling)
   - [ ] Generate token after initialization
   - [ ] Generate token with IDFA available
   - [ ] Generate token with IDFA unavailable
   - [ ] Generate token multiple times (consistency)

3. **Interstitial Ads**
   - [ ] Load waterfall ad
   - [ ] Load programmatic ad with bid payload
   - [ ] Load with invalid placement ID
   - [ ] Show before load completes
   - [ ] Show after successful load
   - [ ] Show after load fails
   - [ ] Verify all delegate callbacks
   - [ ] Test ad click flow

4. **Banner Ads**
   - [ ] Load and display 320x50 banner
   - [ ] Load and display 300x250 banner
   - [ ] Load and display adaptive banner
   - [ ] Handle banner refresh
   - [ ] Test banner click
   - [ ] Test banner expand/collapse

5. **Rewarded Ads**
   - [ ] Load rewarded ad
   - [ ] Show rewarded ad
   - [ ] Verify reward callback
   - [ ] Test complete view (user completes video)
   - [ ] Test early dismissal (user closes early)
   - [ ] Verify no reward on early dismissal

6. **Privacy Compliance**
   - [ ] GDPR consent flow
   - [ ] CCPA opt-out flow
   - [ ] COPPA mode
   - [ ] ATT permission request
   - [ ] Verify no tracking without consent

### 5.3 Demo App Integration

**Add to Demo App Podfile:**

```ruby
pod 'CloudX<Network>Adapter', :path => '../adapter-<network>'
```

**Test Configuration:**

```objc
// In demo app initialization
CLXBidderConfig *config = [[CLXBidderConfig alloc] init];
config.initializationData = @{
    @"accountID": @"<test-account-id>"
};

CLX<Network>Initializer *initializer = [CLX<Network>Initializer createInstance];
[initializer initializeWithConfig:config completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"<Network> adapter initialized successfully");
    } else {
        NSLog(@"<Network> adapter initialization failed: %@", error);
    }
}];
```

### 5.4 Validation Checklist

**Before Release:**

- [ ] All ad formats load successfully
- [ ] All delegate callbacks fire correctly
- [ ] Error handling works for all error cases
- [ ] Privacy settings are respected
- [ ] Build succeeds for device and simulator
- [ ] XCFramework structure is correct
- [ ] CocoaPods spec validation passes
- [ ] SwiftPM checksum is correct
- [ ] Documentation is complete and accurate
- [ ] No compiler warnings
- [ ] No linter errors
- [ ] GitHub Actions workflow succeeds

---

## Reference Implementations

### Meta Adapter (Gold Standard)

The Meta adapter is our most robust implementation. Key learnings:

1. **FBAudienceNetwork as External Dependency**
   - Never bundle Meta SDK in adapter
   - Use `use_frameworks!` in Podfile
   - Remove from link phase in post_install

2. **Error Handling**
   - Comprehensive error mapping
   - Detailed logging at all stages
   - Recovery suggestions for common errors

3. **Privacy Compliance**
   - Full GDPR support
   - CCPA compliance
   - ATT integration
   - Privacy manifest included

4. **Build Process**
   - Static framework distribution
   - Proper module map setup
   - XCFramework with correct headers
   - Automated release pipeline

**File Structure Reference:**

```
adapter-meta/
├── Sources/CloudXMetaAdapter/
│   ├── Base/
│   │   └── CLXMetaBaseFactory.h/.m
│   ├── Initializers/
│   │   └── CLXMetaInitializer.h/.m
│   ├── CLXMetaBidTokenSource.h/.m
│   ├── CLXMetaErrorHandler.h/.m
│   ├── Interstitial/
│   │   ├── CLXMetaInterstitial.h/.m
│   │   └── CLXMetaInterstitialFactory.h/.m
│   ├── Banner/
│   │   ├── CLXMetaBanner.h/.m
│   │   └── CLXMetaBannerFactory.h/.m
│   ├── Rewarded/
│   │   ├── CLXMetaRewarded.h/.m
│   │   └── CLXMetaRewardedFactory.h/.m
│   ├── Native/
│   │   ├── CLXMetaNative.h/.m
│   │   └── CLXMetaNativeFactory.h/.m
│   ├── CloudXMetaAdapter.h
│   ├── Info.plist
│   ├── PrivacyInfo.xcprivacy
│   └── module.modulemap
├── CloudXMetaAdapter.podspec
├── CloudXMetaAdapter-remote.podspec
├── Podfile
├── build_frameworks.sh
├── release-meta-local.sh
└── README.md
```

### InMobi Adapter (Most Recent)

The InMobi adapter demonstrates:

1. **Simplified Naming**
   - `CloudXInMobiAdapter` (no "Mediation" in name)
   - `CLXInMobi*` class prefix

2. **Complete Ad Format Coverage**
   - Interstitial, Banner, Rewarded, Native
   - Programmatic + Waterfall support

3. **Comprehensive Documentation**
   - 800+ line README
   - Installation for all distribution methods
   - SKAdNetwork IDs
   - Troubleshooting guide

4. **Release Automation**
   - Local release script
   - GitHub Actions workflow
   - Automated CocoaPods push
   - SwiftPM integration

---

## Appendix: Templates & Checklists

### A. Implementation Checklist

**Phase 1: Research (Est. 1-2 hours)**
- [ ] Install and examine AppLovin MAX adapter
- [ ] Install and examine Unity adapter
- [ ] Install and examine AdMob adapter
- [ ] Review network SDK documentation
- [ ] Document audit findings
- [ ] Create architecture design doc

**Phase 2: Setup (Est. 30 minutes)**
- [ ] Create directory structure
- [ ] Create Podfile
- [ ] Create module.modulemap
- [ ] Create Info.plist
- [ ] Create PrivacyInfo.xcprivacy
- [ ] Create LICENSE file

**Phase 3: Core Implementation (Est. 2-3 hours)**
- [ ] Implement Base Factory
- [ ] Implement Error Handler
- [ ] Implement Initializer
- [ ] Implement Bid Token Source
- [ ] Test initialization flow

**Phase 4: Ad Formats (Est. 1-2 hours)**
- [ ] Implement Interstitial + Factory
- [ ] Implement Banner + Factory
- [ ] Implement Rewarded + Factory
- [ ] Implement Native + Factory (if applicable)
- [ ] Create Umbrella Header

**Phase 5: Distribution (Est. 1 hour)**
- [ ] Create private repo podspec (source-based)
- [ ] Create public repo podspec (binary-based)
- [ ] Create Package.swift
- [ ] Create build_frameworks.sh
- [ ] Create release script
- [ ] Create GitHub Actions workflow
- [ ] Update root Package.swift

**Phase 6: Documentation (Est. 1 hour)**
- [ ] Create comprehensive README
- [ ] Document prerequisites
- [ ] Document installation methods
- [ ] Document configuration
- [ ] Document troubleshooting
- [ ] Document privacy requirements

**Phase 7: Testing (Est. 1-2 hours)**
- [ ] Unit tests
- [ ] Integration testing
- [ ] Demo app integration
- [ ] Privacy compliance testing
- [ ] Build validation

**Phase 8: Release (Est. 30 minutes)**
- [ ] Run build script
- [ ] Validate podspec
- [ ] Test local release script
- [ ] Push to GitHub
- [ ] Tag release
- [ ] Verify GitHub Actions
- [ ] Verify CocoaPods publication

### B. File Creation Order

Optimal implementation sequence:

1. Directory structure
2. Podfile + module.modulemap + plists
3. Base Factory
4. Error Handler
5. Initializer
6. Bid Token Source
7. Interstitial (adapter + factory)
8. Banner (adapter + factory)
9. Rewarded (adapter + factory)
10. Native (adapter + factory)
11. Umbrella header
12. Podspecs
13. Package.swift
14. Build script
15. Release script
16. GitHub Actions
17. README
18. LICENSE

### C. Common Pitfalls & Solutions

| Pitfall | Solution |
|---------|----------|
| Network SDK not on main thread | Wrap all SDK calls in `dispatch_async(dispatch_get_main_queue(), ^{})` |
| Bundling network SDK in adapter | Declare as peer dependency in podspec |
| Missing privacy manifest | Always include PrivacyInfo.xcprivacy for iOS 17+ |
| Incorrect error mapping | Map all network errors to CloudX error codes |
| Forgetting factory registration | Register all factories in initializer |
| Missing -ObjC linker flag | Add to user_target_xcconfig in podspec |
| Static framework issues | Use `use_frameworks! :linkage => :static` |
| Module not found errors | Ensure module.modulemap is copied to xcframework |
| CocoaPods push failures | Check license file path, validate podspec first |
| SwiftPM checksum mismatch | Recompute after any xcframework changes |

### D. Quality Standards

**Code Quality:**
- 100% protocol conformance
- Comprehensive error handling
- Detailed logging at all stages
- No compiler warnings
- No force unwrapping (Swift)
- Thread-safe implementations

**Documentation Quality:**
- Inline comments for complex logic
- Header documentation for all public APIs
- README with all installation methods
- Troubleshooting guide
- Privacy compliance documentation

**Testing Quality:**
- Unit tests for core components
- Integration tests for ad formats
- Manual testing in demo app
- Privacy compliance testing
- Error scenario testing

**Release Quality:**
- Clean git history
- Semantic versioning
- Automated CI/CD
- CocoaPods validation
- SwiftPM validation

---

## Conclusion

This playbook represents the distilled knowledge from building multiple CloudX iOS adapters. Following this methodology ensures:

1. **Consistency:** All adapters follow the same architecture
2. **Quality:** Comprehensive testing and validation
3. **Speed:** Reduce implementation time from days to hours
4. **Maintainability:** Well-documented, modular code
5. **Scalability:** Repeatable process for any ad network

**Key Success Factors:**

1. Start with thorough research
2. Follow Meta adapter patterns
3. Use industry-standard naming
4. Implement complete error handling
5. Test exhaustively before release
6. Document comprehensively
7. Automate the release pipeline

**Estimated Timeline:**

- **Research & Design:** 2-3 hours
- **Implementation:** 4-6 hours
- **Testing & Documentation:** 2-3 hours
- **Release Setup:** 1-2 hours
- **Total:** 9-14 hours for experienced engineer

**Next Adapters to Implement:**

Priority order based on market share:
1. Unity Ads
2. IronSource
3. AppLovin
4. Chartboost
5. Vungle
6. AdColony

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Maintainer:** CloudX Platform Engineering  
**Questions:** Contact platform-engineering@cloudx.com

