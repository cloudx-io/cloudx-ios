# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-02-04

This release introduces a new initialization API with `CLXInitializationConfiguration` and renames several `CLXAd` properties to align with the Android SDK. Update your initialization code and any code accessing ad metadata properties.

### Added
- **New initialization API** with `CLXInitializationConfiguration` builder pattern
- `CLXSdkConfiguration` returned in initialization completion callback
- `CLXAd.networkPlacement` property for network-specific placement ID
- `CLXAd.adFormat` property for the ad format type
- `setPlacement:` and `setCustomData:` methods on `CLXBannerAdView` for tracking
- `show:placement:customData:` overloads on fullscreen ads for tracking
- `revenueDelegate` property on `CLXBannerAdView` for ad revenue callbacks

### Breaking Changes
- Replaced `initializeSDKWithAppKey:testMode:completion:` with `initializeWithConfiguration:completion:`
- Initialization completion now returns `CLXSdkConfiguration` instead of `BOOL success`
- Renamed `CLXAd.placementId` to `adUnitId`
- Renamed `CLXAd.placementName` to `adUnitName`
- Renamed `CLXAd.bidder` to `networkName`
- Renamed `CLXAd.externalPlacementId` to `networkPlacement`
- Removed `testMode` parameter - test mode is now server-controlled via the CloudX dashboard
- Removed deprecated privacy methods (`setCCPAPrivacyString:`, `setIsUserConsent:`, `setIsDoNotSell:`) - privacy is now handled automatically via GPP/TCF
- Removed native ad support (`createNativeAdWithPlacement:viewController:delegate:`)

### Changed
- Meta Audience Network SDK updated from 6.20.1 to 6.21.0
- Vungle SDK updated from 7.4.0 to 7.6.0
- InMobi SDK updated from 10.8 to 11.1

### Fixed
- All `load` and `show` calls now guarantee callbacks on the main thread
- Ad reload now works correctly in `onAdHidden` and `onAdDisplayFailed` callbacks

---

## [1.3.0] - 2025-12-14

### Added
- **Banner Refresh Retry** - Banners now automatically retry loading after failure when hidden

### Fixed
- **App Extension Compatibility** - SDK now works correctly in App Extensions (no UIApplication calls)
- **Rewarded Delegate Callbacks** - Fixed callback ordering bug
- **Symbol Collisions** - All category methods now prefixed with `clx_` to prevent conflicts

### Changed
- **CloudXCore now distributed as Dynamic Framework** - Enables crash symbolication for SDK issues

---

## [1.2.1] - 2025-12-04

### Added
- **Visual Debugger Button** - New debugging tool for development and QA
- **High-ROI Key-Value Targeting Examples** - Enhanced demo apps with targeting signal examples

### Fixed
- Corrected vendored_frameworks paths in podspecs

---

## [1.2.0] - 2025-11-26

### 🚀 First Official Release

The **CloudX iOS SDK** is a comprehensive mobile advertising solution that provides programmatic advertising capabilities for iOS applications.

### Features

#### Ad Formats
- **Banner Ads** (320×50) - Standard banner advertisements
- **MREC Ads** (300×250) - Medium rectangle advertisements  
- **Interstitial Ads** - Full-screen advertisements

#### Core Capabilities
- **Server-Side Header Bidding** - Real-time programmatic auction with multiple demand sources
- **Unified Auction** - Single SDK manages bidding across all integrated demand partners
- **Privacy Compliance** - Built-in support for GDPR, CCPA, and App Tracking Transparency (ATT)
- **Comprehensive Analytics** - Session tracking, impression metrics, and revenue reporting

#### Developer Experience
- **Simple Integration** - Initialize once, create ads with a single method call
- **Delegate-Based Callbacks** - Clear lifecycle events for ad loading, display, and errors
- **Test Mode** - Built-in test mode for development and QA
- **Flexible Logging** - Configurable log verbosity for debugging

#### Architecture
- **Static XCFramework Distribution** - Fast app launch times, no dSYM warnings
- **Modular Adapter System** - Add only the demand partners you need
- **iOS 15.0+** - Modern iOS support with Swift and Objective-C compatibility

### Components

| Component | Description |
|-----------|-------------|
| **CloudXCore** | Core SDK with programmatic advertising engine |
| **CloudXMetaAdapter** | Meta Audience Network integration |
| **CloudXVungleAdapter** | Vungle/Liftoff integration with header bidding |
| **CloudXRenderer** | Creative rendering engine for CloudX demand |

### Installation

```ruby
# Podfile
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks! :linkage => :static
  
  pod 'CloudXCore'
  pod 'CloudXMetaAdapter'      # Optional
  pod 'CloudXVungleAdapter'    # Optional
  pod 'CloudXRenderer'         # For CloudX demand
end
```

### Quick Start

```objc
// Initialize SDK
CLXInitializationConfiguration *config =
    [CLXInitializationConfiguration configurationWithAppKey:@"YOUR_APP_KEY"
        builderBlock:nil];
[[CloudXCore shared] initializeWithConfiguration:config
                                      completion:^(CLXSdkConfiguration *sdkConfig, CLXError *error) {
    if (sdkConfig) {
        NSLog(@"CloudX SDK initialized!");
    }
}];

// Create and load a banner ad
CLXBannerAdView *banner = [[CloudXCore shared] createBannerWithPlacement:@"AD_UNIT_ID"
                                                           viewController:self
                                                                 delegate:self];
[self.view addSubview:banner];
[banner load];
```

### Documentation

For complete documentation, visit [docs.cloudx.io/ios](https://docs.cloudx.io/ios/installation)
