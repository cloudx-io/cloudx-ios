# CloudX iOS SDK

The CloudX iOS SDK is a comprehensive mobile advertising solution that provides programmatic advertising capabilities for iOS applications. This monorepo contains the complete CloudX iOS SDK ecosystem including the core SDK and various adapter implementations.

### Components

- **[`core/`](core/README.md)** - The foundational CloudX Core SDK written in Objective-C that provides the base functionality for programmatic advertising
- **[`adapter-meta/`](adapter-meta/README.md)** - Meta (Facebook Audience Network) adapter for integrating Meta's advertising platform
- **[`adapter-cloudx/`](adapter-cloudx/README.md)** - Prebid adapter for header bidding integration with CloudX's programmatic platform
- **[`demo-app-objc/`](demo-app-objc/)** - Complete Objective-C demo application showcasing CloudX SDK integration and usage patterns
- **[`demo-app-swift/`](demo-app-swift/)** - Complete Swift demo application demonstrating CloudX SDK implementation in Swift projects

For detailed installation instructions and usage examples, please refer to the individual component READMEs linked above.

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

## Documentation

For detailed documentation, installation instructions, and usage examples, please refer to the individual component READMEs:

- **[Core SDK](core/README.md)** - Detailed core SDK documentation and installation
- **[Meta Adapter](adapter-meta/README.md)** - Meta integration guide and setup
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