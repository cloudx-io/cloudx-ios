# CloudX iOS SDK

Requires iOS 14.0+.

## Installation

### CocoaPods

```ruby
platform :ios, '14.0'

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
- **[Mintegral Adapter](adapter-mintegral/README.md)** - Mintegral integration
- **[Moloco Adapter](adapter-moloco/README.md)** - Moloco integration

## Support

For support, contact mobile@cloudx.io
