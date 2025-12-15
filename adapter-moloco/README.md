# CloudX Moloco Adapter

Moloco adapter for CloudX iOS SDK.

Requires iOS 14.0+ and Xcode 14.0+.

## Installation

### CocoaPods

```ruby
pod 'CloudXMolocoAdapter'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXMolocoAdapter-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXMolocoAdapter.xcframework` into your Xcode project
3. Add Moloco SDK manually

## Info.plist Configuration

### App Tracking Transparency (iOS 14+)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Project Configuration

**Linker Flags:** Add `-ObjC` to Other Linker Flags in Build Settings.

## Support

For support, contact mobile@cloudx.io
