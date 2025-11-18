# Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0-rc.1] - 2024-11-16

### Release Candidate

First release candidate for v1.2.0 with all active adapters.

### Components

- **CloudXCore** v1.2.0-rc.1 - Core SDK with programmatic advertising capabilities
- **CloudXMetaAdapter** v1.2.0-rc.1 - Meta (Facebook Audience Network) adapter
- **CloudXRenderer** v1.2.0-rc.1 - CloudX rendering engine for header bidding
- **CloudXVungleAdapter** v1.2.0-rc.1 - Vungle/Liftoff adapter with header bidding support

### Distribution

- All components distributed as XCFrameworks for optimal performance
- Binary distribution for faster integration and smaller build times
- Available via CocoaPods and Swift Package Manager

### Testing

This is a release candidate for testing purposes. Please verify:
- Banner and interstitial ad formats
- SDK version reporting (should show 1.2.0-rc.1)
- All adapter integrations
- No crashes or memory leaks

### Installation

```ruby
# CocoaPods - Git URL (Release Candidate)
pod 'CloudXCore', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-core'
pod 'CloudXMetaAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-meta'
pod 'CloudXRenderer', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-renderer'
pod 'CloudXVungleAdapter', :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => 'v1.2.0-rc.1-vungle'
```

### Notes

- This is a pre-release version for testing
- Not recommended for production use
- Stable v1.2.0 will follow after RC testing period

