# CloudX Renderer

Rendering adapter for CloudX mediation that handles ad markup rendering with MRAID 3.0 and VAST 4.0 support.

## Installation

### CocoaPods

```ruby
pod 'CloudXRenderer'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXRenderer-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXRenderer.xcframework` into your Xcode project

## Supported Formats

| Format | Description |
|--------|-------------|
| **Banner** | 320x50, 728x90, custom sizes |
| **MREC** | 300x250 |
| **Interstitial** | Full-screen display ads |

## Basic Integration

**Objective-C:**
```objc
CloudXRendererBanner *banner = [[CloudXRendererBanner alloc] 
    initWithAdm:adMarkup
    hasClosedButton:YES
    type:CLXBannerTypeMREC
    viewController:self
    delegate:self];

[banner load];
```

**Swift:**
```swift
let banner = CloudXRendererBanner(
    adm: adMarkup,
    hasClosedButton: true,
    type: .mrec,
    viewController: self,
    delegate: self
)

banner.load()
```

## Support

For support, contact mobile@cloudx.io
