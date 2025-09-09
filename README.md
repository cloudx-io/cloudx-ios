# CloudX iOS SDK

The CloudX iOS SDK is a comprehensive mobile advertising solution that provides programmatic advertising capabilities for iOS applications. This monorepo contains the complete CloudX iOS SDK ecosystem including the core SDK and various adapter implementations.

## Repository Structure

This monorepo is organized into five main components:

```
cloudexchange.ios.sdk/
├── core/                    # CloudX Core SDK (Objective-C)
├── adapter-meta/           # Meta (Facebook) Adapter
├── adapter-cloudx/         # CloudX Prebid Adapter
├── demo-app-objc/          # Objective-C Demo Application
├── demo-app-swift/         # Swift Demo Application
└── README.md              # This file
```

### Components

- **`core/`** - The foundational CloudX Core SDK written in Objective-C that provides the base functionality for programmatic advertising
- **`adapter-meta/`** - Meta (Facebook Audience Network) adapter for integrating Meta's advertising platform
- **`adapter-cloudx/`** - Prebid adapter for header bidding integration with CloudX's programmatic platform
- **`demo-app-objc/`** - Complete Objective-C demo application showcasing CloudX SDK integration and usage patterns
- **`demo-app-swift/`** - Complete Swift demo application demonstrating CloudX SDK implementation in Swift projects

## Installation

Each component can be installed independently using CocoaPods or Swift Package Manager.

### CocoaPods

Add the desired components to your `Podfile`:

```ruby
# Core SDK (required)
pod 'CloudXCore', :git => 'https://github.com/cloudx-xenoss/cloudexchange.ios.sdk.git', :tag => 'core-v1.0.0'

# Meta Adapter (optional)
pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-xenoss/cloudexchange.ios.sdk.git', :tag => 'meta-adapter-v1.0.0'

# CloudX Prebid Adapter (optional)
pod 'CloudXPrebidAdapter', :git => 'https://github.com/cloudx-xenoss/cloudexchange.ios.sdk.git', :tag => 'prebid-adapter-v1.0.0'
```

### Swift Package Manager

Add the repository URL to your Xcode project:
```
https://github.com/cloudx-xenoss/cloudexchange.ios.sdk.git
```

## Release Strategy

This monorepo follows a **unified release strategy** with **separate release assets** to provide both organizational clarity and distribution flexibility.

### Unified Release Strategy

- **Single Release Per Deployment Cycle**: Each release includes all components that have changed since the last release
- **Semantic Versioning**: The entire SDK suite follows semantic versioning (e.g., `v1.2.3`)
- **Coordinated Versioning**: All components are versioned together to ensure compatibility
- **Clear Release Notes**: Each release clearly documents what changed in each component

#### Release Tag Format
```
v1.2.3  # Main SDK suite version
```

#### Release Notes Structure
```markdown
## CloudX iOS SDK v1.2.3

### Core v1.1.2
- Fixed memory leak in bid processing
- Added new configuration options for privacy compliance
- Improved error handling in network requests

### Meta Adapter v1.0.5
- Updated for Meta SDK 6.15.0 compatibility
- Improved error handling for failed ad requests
- Added support for new Meta ad formats

### CloudX Prebid Adapter v2.1.1
- Enhanced header bidding timeout handling
- Fixed issue with bid response parsing
- Added support for video ad formats
```

### Separate Release Assets

Each release provides **separate downloadable assets** for each component, allowing developers to download only what they need:

#### Asset Naming Convention
```
CloudXCore-v1.1.2.zip           # Core SDK binary
CloudXMetaAdapter-v1.0.5.zip    # Meta Adapter binary  
CloudXPrebidAdapter-v2.1.1.zip  # Prebid Adapter binary
CloudXiOSSDK-Complete-v1.2.3.zip # Optional: All components bundled
```

#### Benefits
- **Selective Downloads**: Developers can download only the components they need
- **Reduced App Size**: Avoid including unused adapters
- **Clear Versioning**: Each component's version is clearly indicated in the filename
- **Backward Compatibility**: Easy to identify compatible versions across components

## Development

### Prerequisites

- Xcode 14.0 or later
- iOS 12.0 or later
- CocoaPods 1.10.0 or later (if using CocoaPods)

### Building

Each component can be built independently:

```bash
# Build Core SDK
cd core/
xcodebuild -workspace CloudXCore.xcworkspace -scheme CloudXCore -configuration Release

# Build Meta Adapter  
cd adapter-meta/
xcodebuild -workspace CloudXMetaAdapter.xcworkspace -scheme CloudXMetaAdapter -configuration Release

# Build Prebid Adapter
cd adapter-cloudx/
xcodebuild -workspace CloudXPrebidAdapter.xcworkspace -scheme CloudXPrebidAdapter -configuration Release
```

### Testing

Run tests for each component:

```bash
# Test Core SDK
cd core/
xcodebuild test -workspace CloudXCore.xcworkspace -scheme CloudXCore -destination 'platform=iOS Simulator,name=iPhone 14'

# Test adapters (if test targets exist)
cd adapter-meta/
xcodebuild test -workspace CloudXMetaAdapter.xcworkspace -scheme CloudXMetaAdapter -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Demo Applications

The repository includes two complete demo applications that showcase CloudX SDK integration patterns and best practices.

### Objective-C Demo App (`demo-app-objc/`)

A comprehensive Objective-C demo application that demonstrates:
- CloudX Core SDK integration
- Meta Adapter implementation
- Banner, interstitial, and native ad formats
- Error handling and logging
- Privacy compliance implementation

#### Running the Objective-C Demo
```bash
cd demo-app-objc/
pod install
open CloudXObjCRemotePods.xcworkspace
```

### Swift Demo App (`demo-app-swift/`)

A complete Swift demo application showcasing:
- CloudX SDK integration in Swift projects
- Modern Swift coding patterns
- Ad format implementations
- SDK configuration examples
- Best practices for Swift developers

#### Running the Swift Demo
```bash
cd demo-app-swift/
pod install
open CloudXSwiftRemotePods.xcworkspace
```

### Demo App Features

Both demo applications include:
- **Multiple Ad Formats**: Banner, interstitial, native, and rewarded ads
- **Configuration Examples**: Various SDK configuration scenarios
- **Error Handling**: Comprehensive error handling and logging
- **UI Examples**: Different ad placement and integration patterns
- **Testing Tools**: Built-in testing and debugging features

## Documentation

- **Core SDK**: See `core/README.md` for detailed core SDK documentation
- **Meta Adapter**: See `adapter-meta/README.md` for Meta integration guide
- **Prebid Adapter**: See `adapter-cloudx/README.md` for Prebid integration guide
- **Demo Apps**: Explore the `demo-app-objc/` and `demo-app-swift/` directories for complete integration examples

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