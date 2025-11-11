# CloudX iOS SDK

The CloudX iOS SDK is a comprehensive mobile advertising solution that provides programmatic advertising capabilities for iOS applications. This unified repository contains the complete CloudX iOS SDK ecosystem including the core SDK and various adapter implementations.

## Quick Start

### CocoaPods Installation

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  
  # CloudX SDK 
  pod 'CloudXSDK', '~> 0.1.0'
  
  # Optional: CloudX Mediation Adapters (at least one is needed to show ads)
  pod 'CloudXMediationMetaAdapter', '~> 0.1.0'         
  pod 'CloudXMediationVungleAdapter', '~> 0.1.0'       
  pod 'CloudXMediationPrebidAdapter', '~> 0.1.0'       
end
```

### Swift Package Manager

Add this repository URL to your Xcode project:
```
https://github.com/cloudx-io/cloudx-ios
```

## Components

- **[`core/`](core/README.md)** - The foundational CloudXSDK written in Objective-C that provides the base functionality for programmatic advertising *(source-based distribution)*
- **[`adapter-meta/`](adapter-meta/README.md)** - CloudXMediationMetaAdapter for Meta Audience Network integration *(framework-based distribution)*
- **[`adapter-vungle/`](adapter-vungle/README.md)** - CloudXMediationVungleAdapter for Vungle/Liftoff advertising with header bidding support *(source-based distribution)*
- **[`adapter-cloudx/`](adapter-cloudx/README.md)** - CloudXMediationPrebidAdapter for header bidding integration with CloudX's programmatic platform *(source-based distribution)*
- **[`demo-app-objc/`](demo-app-objc/)** - Complete Objective-C demo application showcasing CloudX SDK integration and usage patterns
- **[`demo-app-swift/`](demo-app-swift/)** - Complete Swift demo application demonstrating CloudX SDK implementation in Swift projects

For detailed installation instructions and usage examples, please refer to the individual component READMEs linked above.

## Release Strategy

This repository uses **component-specific releases** with **tagged distribution** to provide both organizational clarity and distribution flexibility.

### Component-Specific Releases

- **CloudXSDK**: Source-based distribution with tags like `v0.1.0-sdk`
- **CloudXMediationMetaAdapter**: Framework-based distribution with tags like `v0.1.0-meta`
- **CloudXMediationVungleAdapter**: Source-based distribution with tags like `v0.1.0-vungle`
- **CloudXMediationPrebidAdapter**: Source-based distribution with tags like `v0.1.0-prebid`
- **Individual Versioning**: Each component maintains its own version to allow independent updates
- **Clear Release Assets**: Each release provides the appropriate distribution format for that component

#### Release Tag Format
```
v0.1.0-sdk      # SDK release (source distribution)
v0.1.0-meta     # Meta Adapter release (framework distribution)
v0.1.0-vungle   # Vungle Adapter release (source distribution)
v0.1.0-prebid   # Prebid Adapter release (source distribution)
```

#### Distribution Methods
- **Core SDK**: Direct source integration via CocoaPods/SPM for easier debugging and customization
- **Meta Adapter**: Pre-built xcframework for faster build times and simplified integration
- **Vungle Adapter**: Direct source integration via CocoaPods/SPM for easier debugging and full transparency
- **Automated Releases**: GitHub Actions automatically build, test, and publish releases when tags are pushed

### Release Assets

Each component release provides the appropriate assets for its distribution method:

#### Core SDK Assets (Source Distribution)
- Direct source file access via CocoaPods/SPM
- No binary downloads required
- Full source code availability for debugging

#### Meta Adapter Assets (Framework Distribution) 
```
CloudXMediationMetaAdapter-v0.1.0.xcframework.zip  # Static xcframework for integration
```

#### Benefits
- **Optimized Distribution**: Each component uses the most appropriate distribution method
- **Independent Updates**: Components can be updated independently without affecting others
- **Developer Choice**: Use source or framework distribution based on your needs
- **Automated Pipeline**: Releases are automatically built and published via GitHub Actions

## Documentation

For detailed documentation, installation instructions, and usage examples, please refer to the individual component READMEs:

- **[Core SDK](core/README.md)** - Detailed core SDK documentation and installation
- **[Meta Adapter](adapter-meta/README.md)** - Meta (Facebook Audience Network) integration guide and setup
- **[Vungle Adapter](adapter-vungle/README.md)** - Vungle (Liftoff) integration guide with header bidding support
- **[Prebid Adapter](adapter-cloudx/README.md)** - Prebid integration guide and configuration
- **Demo Apps** - Explore the demo application directories for complete integration examples

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes in the appropriate component directory
4. Add tests for your changes
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the individual LICENSE files in each component directory for details.

## Support

For technical support and questions:
- Create an issue in this repository
- Contact the CloudX team at [support email]
- Check the documentation in each component's README

## Changelog

See [RELEASES](https://github.com/cloudx-xenoss/cloudexchange.ios.sdk/releases) for detailed changelog and version history.
