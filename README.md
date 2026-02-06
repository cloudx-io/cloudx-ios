# CloudX iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/CloudXCore.svg)](https://cocoapods.org/pods/CloudXCore)

Requires iOS 13.0+.

## Installation

### CocoaPods

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks!

  # Core SDK
  pod 'CloudXCore'

  # Adapters (add as needed)
  pod 'CloudXMetaAdapter'
  pod 'CloudXVungleAdapter'
end
```

```bash
pod install --repo-update
```

## Documentation

- **[Core SDK](core/README.md)** - Initialization, ad integration, and advanced features
- **[Meta Adapter](adapter-meta/README.md)** - Meta Audience Network integration
- **[Vungle Adapter](adapter-vungle/README.md)** - Vungle/Liftoff integration
- **[InMobi Adapter](adapter-inmobi/README.md)** - InMobi integration

## Support

For support, contact mobile@cloudx.io
