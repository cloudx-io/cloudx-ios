# CloudX Mintegral Adapter for iOS

[![Version](https://img.shields.io/cocoapods/v/CloudXMintegralAdapter.svg?style=flat)](https://cocoapods.org/pods/CloudXMintegralAdapter)
[![License](https://img.shields.io/cocoapods/l/CloudXMintegralAdapter.svg?style=flat)](https://cocoapods.org/pods/CloudXMintegralAdapter)
[![Platform](https://img.shields.io/cocoapods/p/CloudXMintegralAdapter.svg?style=flat)](https://cocoapods.org/pods/CloudXMintegralAdapter)

The CloudX Mintegral Adapter enables publishers to monetize their iOS applications through the CloudX SDK using Mintegral's advertising network.

## Features

- ✅ Interstitial ads
- ✅ Banner ads
- ✅ Rewarded video ads
- ✅ Header bidding support
- ✅ GDPR and CCPA compliant
- ✅ iOS 14.0+ support

## Requirements

- iOS 14.0+
- Xcode 15.0+
- CloudXCore SDK
- Mintegral SDK 7.6+

## Installation

### CocoaPods

Add the following line to your `Podfile`:

```ruby
pod 'CloudXMintegralAdapter', '~> 1.0'
```

Then run:

```bash
pod install
```

### Swift Package Manager

Add the CloudX iOS repository to your project:

```
https://github.com/cloudx-io/cloudx-ios.git
```

Then select `CloudXMintegralAdapter` as a dependency.

### Manual Installation

1. Download the latest `CloudXMintegralAdapter.xcframework.zip` from the [Releases](https://github.com/cloudx-io/cloudx-ios/releases) page
2. Extract the xcframework
3. Drag `CloudXMintegralAdapter.xcframework` into your Xcode project
4. Ensure "Embed & Sign" is selected for the framework

## Configuration

### 1. Initialize CloudX SDK

Initialize the CloudX SDK with your Mintegral credentials:

```objective-c
#import <CloudXCore/CloudXCore.h>
#import <CloudXMintegralAdapter/CloudXMintegralAdapter.h>

// Initialize CloudX SDK
CLXConfiguration *config = [[CLXConfiguration alloc] init];
config.publisherID = @"YOUR_PUBLISHER_ID";

// Add Mintegral initializer
CLXMintegralInitializer *mintegralInitializer = [CLXMintegralInitializer createInstance];
[config addInitializer:mintegralInitializer 
        initializationData:@{
            @"appID": @"YOUR_MINTEGRAL_APP_ID",
            @"appKey": @"YOUR_MINTEGRAL_APP_KEY"
        }];

// Initialize SDK
[[CloudXCore shared] initializeWithConfiguration:config 
                                      completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"CloudX SDK initialized successfully");
    } else {
        NSLog(@"CloudX SDK initialization failed: %@", error);
    }
}];
```

### 2. Add Mintegral Bid Token Source

Register the Mintegral bid token source for header bidding:

```objective-c
CLXMintegralBidTokenSource *bidTokenSource = [CLXMintegralBidTokenSource createInstance];
[[CloudXCore shared] registerBidTokenSource:bidTokenSource];
```

### 3. Load and Show Ads

#### Interstitial Ads

```objective-c
// Ad ID format: placementID_unitID
NSString *adID = @"YOUR_PLACEMENT_ID_YOUR_UNIT_ID";

[[CloudXCore shared] loadInterstitialAd:adID 
                             completion:^(BOOL success, NSError *error) {
    if (success) {
        [[CloudXCore shared] showInterstitialAd:adID 
                                 fromViewController:self];
    }
}];
```

#### Banner Ads

```objective-c
// Ad ID format: placementID_unitID
NSString *adID = @"YOUR_PLACEMENT_ID_YOUR_UNIT_ID";
CGSize bannerSize = CGSizeMake(320, 50);

[[CloudXCore shared] loadBannerAd:adID 
                              size:bannerSize 
                        completion:^(UIView *bannerView, NSError *error) {
    if (bannerView) {
        [self.view addSubview:bannerView];
    }
}];
```

#### Rewarded Video Ads

```objective-c
// Ad ID format: placementID_unitID
NSString *adID = @"YOUR_PLACEMENT_ID_YOUR_UNIT_ID";

[[CloudXCore shared] loadRewardedAd:adID 
                         completion:^(BOOL success, NSError *error) {
    if (success) {
        [[CloudXCore shared] showRewardedAd:adID 
                             fromViewController:self 
                                     completion:^(BOOL didReward) {
            if (didReward) {
                // User earned reward
            }
        }];
    }
}];
```

## Privacy Configuration

### GDPR Compliance

```objective-c
[[CLXSettings sharedInstance] setGDPRConsentAccepted:YES];
```

### CCPA Compliance

```objective-c
[[CLXSettings sharedInstance] setUSPrivacyString:@"1YNN"];
```

## Info.plist Configuration

Add the following keys to your `Info.plist`:

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>KBD757YWX3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>WG4VFF78ZM.skadnetwork</string>
    </dict>
    <!-- Add other Mintegral SKAdNetwork IDs -->
</array>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Troubleshooting

### Common Issues

#### 1. Adapter not initialized

**Error:** `SDK not initialized`

**Solution:** Ensure you've initialized the CloudX SDK with the Mintegral initializer before loading ads.

#### 2. Invalid ad ID format

**Error:** `Invalid ad ID format. Expected: placementID_unitID`

**Solution:** Use the correct format: `placementID_unitID` (e.g., `"123456_78910"`)

#### 3. No fill

**Error:** `No fill for ad request`

**Solution:** This is normal ad network behavior. Implement fallback logic to request ads from other networks.

### Debug Logging

Enable debug logging to troubleshoot issues:

```objective-c
[[CLXLogger sharedInstance] setLogLevel:CLXLogLevelDebug];
```

## Sample App

Check out the demo app in the CloudX iOS repository for complete integration examples:

```bash
cd demo-app-objc
pod install
open CloudXDemo.xcworkspace
```

## Support

- **Documentation:** [CloudX iOS SDK Documentation](https://docs.cloudx.io/ios)
- **Issues:** [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)
- **Email:** support@cloudx.com

## License

CloudXMintegralAdapter is available under the Business Source License 1.1. See the [LICENSE](LICENSE) file for more info.

## Changelog

### Version 1.0.0
- Initial release
- Support for Interstitial, Banner, and Rewarded ads
- Header bidding support
- GDPR and CCPA compliance

