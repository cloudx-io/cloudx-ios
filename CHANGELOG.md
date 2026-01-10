# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Breaking Changes
- **Test mode is now server-controlled** - Removed `testMode` parameter from `initializeSDKWithAppKey:completion:`
  - To enable test mode, whitelist your device IFA on the CloudX server dashboard
  - The SDK now logs the device IFA at INFO level during initialization for easy copy/paste
  - Server returns `deviceConfig.test` value which is passed through to bid requests

### Changed
- **Device config parsing** - SDK now parses `deviceConfig` from server init response:
  - `test`: Integer value passed to bid requests (0 = production, non-zero = test mode)
  - `debug`: Boolean to enable verbose logging remotely
- **Adapter initializer protocol** - Added `testMode:` parameter to `CLXAdNetworkInitializer` protocol
- **Meta adapter** - Now uses server-controlled test mode instead of client-side flag

---

## [1.3.0] - 2025-12-14

### Added
- **Banner Refresh Retry** - Banners now automatically retry loading after failure when hidden
- **Mintegral Adapter v8.0** - Updated Mintegral adapter 
- **InMobi Native Impression Callbacks** - Added missing native ad impression tracking

### Fixed
- **App Extension Compatibility** - SDK now works correctly in App Extensions (no UIApplication calls)
- **InMobi Fullscreen Ads** - Fixed stuck fullscreen ads issue
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
[[CloudXCore shared] initializeSDKWithAppKey:@"YOUR_APP_KEY"
                                  completion:^(BOOL success, CLXError *error) {
    if (success) {
        NSLog(@"CloudX SDK initialized!");
    }
}];

// Create and load a banner ad
CLXBannerAdView *banner = [[CloudXCore shared] createBannerWithPlacement:@"PLACEMENT_ID"
                                                           viewController:self
                                                                 delegate:self];
[self.view addSubview:banner];
[banner load];
```

### Documentation

For complete documentation, visit [docs.cloudx.io/ios](https://docs.cloudx.io/ios/installation)
