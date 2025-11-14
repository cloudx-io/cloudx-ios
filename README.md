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
  
  # Optional: CloudX Adapters (at least one is needed to show ads)
  pod 'CloudXMetaAdapter', '~> 1.2.0'
  pod 'CloudXRenderer', '~> 1.2.0'       
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

- **[`core/`](core/README.md)** - CloudXCore framework providing the foundational SDK functionality for programmatic advertising *(binary xcframework distribution)*
- **[`adapter-meta/`](adapter-meta/README.md)** - CloudXMetaAdapter for Meta Audience Network integration *(binary xcframework distribution)*
- **[`renderer-cloudx/`](renderer-cloudx/README.md)** - CloudXRenderer for rendering creative content with MRAID support *(binary xcframework distribution)*
- **[`demo-app-objc/`](demo-app-objc/)** - Complete Objective-C demo application showcasing CloudX SDK integration and usage patterns
- **[`demo-app-swift/`](demo-app-swift/)** - Complete Swift demo application demonstrating CloudX SDK implementation in Swift projects

For detailed installation instructions and usage examples, please refer to the individual component READMEs linked above.

## Release Strategy

This repository uses **component-specific releases** with **tagged distribution** to provide both organizational clarity and distribution flexibility.

### Component-Specific Releases

- **CloudXCore**: Binary xcframework distribution with tags like `v1.2.0-core`
- **CloudXMetaAdapter**: Binary xcframework distribution with tags like `v1.2.0-meta`
- **CloudXRenderer**: Binary xcframework distribution with tags like `v1.2.0-renderer`
- **Individual Versioning**: Each component maintains its own version to allow independent updates
- **Clear Release Assets**: Each release provides the appropriate xcframework binary for that component

#### Release Tag Format
```
v1.2.0-core      # Core SDK release (binary xcframework)
v1.2.0-meta      # Meta Adapter release (binary xcframework)
v1.2.0-renderer  # Renderer release (binary xcframework)
```

#### Distribution Methods
- **CloudXCore**: Pre-built xcframework for core SDK functionality
- **CloudXMetaAdapter**: Pre-built xcframework for Meta Audience Network integration
- **CloudXRenderer**: Pre-built xcframework for creative rendering with MRAID support
- **CocoaPods Installation**: All components distributed via CocoaPods with git+tag references

