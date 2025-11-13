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
  pod 'CloudXMediationPrebidAdapter', '~> 0.1.0'       
end
```

### ⚠️ Important: Xcode 15+ Configuration

**If using CocoaPods with Xcode 15 or later**, you must disable User Script Sandboxing in your Xcode project:

1. Select your project in Xcode
2. Select your app target  
3. Go to **Build Settings**
4. Search for "User Script Sandboxing"
5. Set **ENABLE_USER_SCRIPT_SANDBOXING** to **No**

This is required for CocoaPods to properly embed dynamic frameworks. This is a standard requirement for all iOS SDKs that use dynamic frameworks (including AppLovin SDK, Firebase, Google Mobile Ads, etc.).

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
- **Automated Releases**: GitHub Actions automatically build, test, and publish releases when tags are pushed

