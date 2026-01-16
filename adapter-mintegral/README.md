# CloudX Mintegral Adapter

> **BETA**: This adapter is in beta and not yet production-ready.
> 
> Use at your own risk. Not available on CocoaPods trunk.

Mintegral adapter for CloudX iOS SDK with header bidding support.

Requires iOS 15.0+ and Xcode 16.0+.

## Status

| Feature | Status |
|---------|--------|
| Banner | Tested |
| MREC | Tested |
| Interstitial | Tested |
| Rewarded | Tested |
| Header Bidding | Supported |
| CocoaPods Trunk | Not yet available (BETA) |

## Installation

### CocoaPods (GitHub Reference)

Since this adapter is in **BETA**, it is NOT available on CocoaPods trunk.
Add to your Podfile with a direct GitHub reference:

```ruby
# For tagged beta release
pod 'CloudXMintegralAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.3.0-mintegral'

# Or for latest development
pod 'CloudXMintegralAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :branch => 'develop'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXMintegralAdapter-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXMintegralAdapter.xcframework` into your Xcode project
3. Add Mintegral SDK 8.0+ to your project

## Dependencies

- CloudXCore (matching version)
- Mintegral SDK 8.0+ with bidding modules:
  - `MintegralAdSDK/BidBannerAd`
  - `MintegralAdSDK/BidNewInterstitialAd`
  - `MintegralAdSDK/BidRewardVideoAd`

## Info.plist Configuration

### SKAdNetwork IDs (Required for iOS 14+)

<details>
<summary>Click to expand Mintegral SKAdNetwork IDs</summary>

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
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>737z793b9f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mtkv5xtk9e.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z4gj7hsk7h.skadnetwork</string>
    </dict>
</array>
```

</details>

### App Tracking Transparency (iOS 14+)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Project Configuration

**Linker Flags:** Add `-ObjC` to Other Linker Flags in Build Settings.

**Bitcode:** Mintegral SDK does not support Bitcode. Set Enable Bitcode to `NO`.

## Mintegral SDK Configuration

The adapter automatically configures:
- Channel code for CloudX attribution
- GDPR consent (IAB TCF 2.0)
- CCPA compliance (US Privacy String)

## Support

For support, contact mobile@cloudx.io

## Changelog

### 1.3.0 (BETA)
- Initial beta release
- Banner, MREC, Interstitial, and Rewarded ad formats
- Header bidding support with enhanced bid tokens
- Thread safety improvements
- Mintegral SDK 8.0.x compatibility
