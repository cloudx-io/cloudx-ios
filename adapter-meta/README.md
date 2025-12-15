# CloudX Meta Adapter

Meta Audience Network adapter for CloudX iOS SDK.

Requires iOS 13.0+ and Xcode 15.3+.

## Installation

### CocoaPods

```ruby
pod 'CloudXMetaAdapter'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXMetaAdapter-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXMetaAdapter.xcframework` into your Xcode project

## Info.plist Configuration

### SKAdNetwork IDs (Required for iOS 14.5+)

Both Meta SKAdNetwork IDs are required for Meta to make bids:

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
</array>
```

### App Tracking Transparency (iOS 14+)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Project Configuration

**Linker Flags:** Add `-ObjC` to Other Linker Flags in Build Settings.

**Bitcode:** Meta SDK does not support Bitcode. Set Enable Bitcode to `NO`.

## Support

For support, contact mobile@cloudx.io
