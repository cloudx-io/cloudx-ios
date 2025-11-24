# CloudX Moloco Adapter for iOS

CloudX Moloco Adapter enables publishers to monetize their iOS applications through the Moloco advertising network via the CloudX SDK.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [CocoaPods](#cocoapods)
  - [Swift Package Manager](#swift-package-manager)
  - [Manual Installation](#manual-installation)
- [Integration](#integration)
- [Ad Formats](#ad-formats)
- [Privacy](#privacy)
- [Troubleshooting](#troubleshooting)
- [Support](#support)

## Requirements

- iOS 14.0+
- Xcode 14.0+
- CloudXCore SDK
- Moloco SDK 1.0+

## Installation

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'CloudXCore'
pod 'CloudXMolocoAdapter'
```

Then run:

```bash
pod install
```

### Swift Package Manager

Add the CloudX iOS SDK repository as a package dependency:

```
https://github.com/cloudx-io/cloudx-ios.git
```

Select the `CloudXMolocoAdapter` product.

### Manual Installation

1. Download the latest `CloudXMolocoAdapter.xcframework.zip` from the [Releases page](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip the file
3. Drag `CloudXMolocoAdapter.xcframework` into your Xcode project
4. Ensure "Embed & Sign" is selected for the framework
5. Add the Moloco SDK dependency manually

## Integration

### Initialize the CloudX SDK with Moloco

```swift
import CloudXCore
import CloudXMolocoAdapter

// Configure CloudX SDK
let config = CLXBidderConfig()
config.initializationData = [
    "app_key": "your_moloco_app_key"
]

// Initialize Moloco adapter
let molocoInitializer = CLXMolocoInitializer.createInstance()
molocoInitializer.initialize(with: config) { success, error in
    if success {
        print("Moloco adapter initialized successfully")
    } else {
        print("Failed to initialize Moloco adapter: \(error?.localizedDescription ?? "Unknown error")")
    }
}
```

### Objective-C

```objc
#import <CloudXCore/CloudXCore.h>
#import <CloudXMolocoAdapter/CloudXMolocoAdapter.h>

// Configure CloudX SDK
CLXBidderConfig *config = [[CLXBidderConfig alloc] init];
config.initializationData = @{
    @"app_key": @"your_moloco_app_key"
};

// Initialize Moloco adapter
CLXMolocoInitializer *molocoInitializer = [CLXMolocoInitializer createInstance];
[molocoInitializer initializeWithConfig:config completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Moloco adapter initialized successfully");
    } else {
        NSLog(@"Failed to initialize Moloco adapter: %@", error.localizedDescription);
    }
}];
```

## Ad Formats

The CloudX Moloco Adapter supports the following ad formats:

### Interstitial Ads

Full-screen ads that display at natural transition points in your app.

### Banner Ads

Rectangular ads that appear at the top or bottom of the screen.

Supported sizes:
- 320x50 (Standard Banner)
- 300x250 (Medium Rectangle)
- 728x90 (Leaderboard, iPad)

### Rewarded Video Ads

Full-screen video ads that reward users for watching.

### Native Ads

Customizable ads that match the look and feel of your app.

## Privacy

### App Tracking Transparency (ATT)

The adapter automatically respects the user's ATT authorization status. Request ATT permission before initializing the SDK:

```swift
import AppTrackingTransparency

if #available(iOS 14, *) {
    ATTrackingManager.requestTrackingAuthorization { status in
        // Initialize CloudX SDK after user responds
    }
}
```

### GDPR Compliance

Configure GDPR consent before initializing:

```swift
let settings = CLXSettings.sharedInstance()
settings.gdprConsentAvailable = true
settings.gdprConsentAccepted = true // or false based on user consent
```

### CCPA Compliance

Set the US Privacy String:

```swift
let settings = CLXSettings.sharedInstance()
settings.usPrivacyString = "1YNN" // Your IAB CCPA string
```

### COPPA Compliance

Enable COPPA mode if your app is directed at children:

```swift
let settings = CLXSettings.sharedInstance()
settings.coppaEnabled = true
```

## Troubleshooting

### Common Issues

#### Adapter Not Initializing

**Problem:** Adapter fails to initialize
**Solution:** Verify that:
- You have a valid Moloco app key
- The Moloco SDK is properly installed
- Your app has the required privacy permissions

#### No Ads Filling

**Problem:** Ads fail to load
**Solution:** Check that:
- Your Moloco account is properly configured
- The placement IDs are correct
- Your app meets Moloco's minimum requirements
- Test ads are enabled during development

#### Build Errors

**Problem:** Xcode build failures
**Solution:**
- Clean build folder (Cmd+Shift+K)
- Delete derived data
- Run `pod install` again
- Ensure deployment target is iOS 14.0+

### Enable Debug Logging

```swift
let logger = CLXLogger(category: "MolocoAdapter")
logger.logLevel = .debug
```

## Support

- **Documentation:** [CloudX Documentation](https://docs.cloudx.com)
- **Moloco Support:** [Moloco Developer Portal](https://www.moloco.com/developers)
- **Issues:** [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)
- **Email:** support@cloudx.com

## License

This adapter is licensed under the Business Source License 1.1. See [LICENSE](LICENSE) for details.

## Changelog

### Version 1.0.0
- Initial release
- Support for Interstitial, Banner, Rewarded, and Native ads
- Full privacy compliance (GDPR, CCPA, COPPA, ATT)
- Swift Package Manager and CocoaPods support

