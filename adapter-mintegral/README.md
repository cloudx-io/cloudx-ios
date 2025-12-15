# CloudX Mintegral Adapter

Mintegral adapter for CloudX iOS SDK.

Requires iOS 14.0+ and Xcode 15.0+.

## Installation

### CocoaPods

```ruby
pod 'CloudXMintegralAdapter'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXMintegralAdapter-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXMintegralAdapter.xcframework` into your Xcode project

## Info.plist Configuration

### SKAdNetwork IDs

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
</array>
```

### App Tracking Transparency (iOS 14+)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Project Configuration

**Linker Flags:** Add `-ObjC` to Other Linker Flags in Build Settings.

## Support

For support, contact mobile@cloudx.io
