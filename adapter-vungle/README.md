# CloudX Vungle Adapter for iOS

The CloudX Vungle Adapter enables monetization through the Vungle advertising network in your iOS applications using the CloudX SDK.

## Features

- **Complete Ad Format Support**: Interstitial, Rewarded, Banner/MREC, Native, and App Open ads
- **Header Bidding Integration**: Real-time bidding capabilities with bid token support
- **Advanced Error Handling**: Comprehensive error mapping and retry logic
- **Privacy Compliant**: Full support for GDPR, CCPA, and ATT requirements
- **Performance Optimized**: Minimal impact on app startup and runtime performance

## Requirements

- iOS 12.0+
- Xcode 16.0+
- CloudX iOS SDK
- VungleAds SDK 7.4.0+

## Installation

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'CloudXVungleAdapter'
```

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/cloudx-xenoss/CloudXVungleAdapter.git", from: "1.0.0")
```

## Quick Start

1. Initialize the CloudX SDK with Vungle configuration
2. Configure your Vungle App ID and placement IDs
3. Load and show ads using CloudX's standard API

For detailed integration instructions, please refer to the CloudX documentation.

## Supported Ad Formats

| Format | Class | Supported Sizes |
|--------|-------|-----------------|
| Interstitial | `CLXVungleInterstitial` | Fullscreen |
| Rewarded | `CLXVungleRewarded` | Fullscreen |
| Banner | `CLXVungleBanner` | 320x50, 300x50, 728x90 |
| MREC | `CLXVungleBanner` | 300x250 |
| Native | `CLXVungleNative` | Custom layouts |
| App Open | `CLXVungleAppOpen` | Fullscreen |

## Privacy & Compliance

This adapter automatically handles:
- GDPR consent forwarding
- CCPA compliance
- ATT integration
- SKAdNetwork attribution
- Privacy manifest requirements

## Support

For technical support, please contact: support@cloudx.com

## License

Copyright (c) 2024 CloudX, Inc. All rights reserved.
