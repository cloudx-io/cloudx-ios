# CloudX iOS SDK

> **Modern programmatic advertising for iOS applications**

CloudX iOS SDK provides a complete mobile advertising solution with real-time bidding, multiple ad formats, and seamless integration. Built for performance and ease of use.

---

## 🚀 Quick Start

Get started in 3 simple steps:

### 1. Install via CocoaPods

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  # Core SDK
  pod 'CloudXCore'
  
  # Optional: Adapters
  pod 'CloudXMetaAdapter'
  pod 'CloudXVungleAdapter'
end
```

### 2. Initialize the SDK

```swift
import CloudXCore

CloudXCore.shared.initializeSDK(withAppKey: "YOUR_APP_KEY") { error in
    if error == nil {
        print("CloudX SDK ready!")
    }
}
```

### 3. Load Your First Ad

```swift
let banner = CloudXCore.shared.createBanner(
    withPlacement: "YOUR_PLACEMENT_ID",
    viewController: self,
    delegate: self,
    tmax: 10.0
)
```

---

## 📚 Documentation

**Complete documentation is available on our Mintlify docs site:**

### Essential Guides

- **[Installation Guide](https://docs.cloudx.io/ios/installation)** - Setup instructions, requirements, and Info.plist configuration
- **[Quickstart Guide](https://docs.cloudx.io/ios/quickstart)** - Initialize the SDK and load your first ads (banner, interstitial, rewarded)
- **[Configuration Guide](https://docs.cloudx.io/ios/configuration)** - Privacy settings, targeting, logging, and advanced options

### Additional Resources

- **[API Reference](https://docs.cloudx.io/api-reference/ios-api)** - Complete API documentation
- **[Dashboard](https://app.cloudx.io)** - Manage placements and view analytics
- **[Support](mailto:hello@cloudx.io)** - Contact our team

---

## 💡 Features

- **Multiple Ad Formats** - Banner (320×50), MREC (300×250), Interstitial, Rewarded
- **Real-Time Bidding** - Server-side header bidding for maximum yield
- **Privacy Compliant** - Built-in support for GDPR, CCPA, COPPA, and ATT
- **SwiftUI Support** - Works seamlessly with both UIKit and SwiftUI
- **Binary Distribution** - Fast compilation with pre-built xcframeworks
- **Comprehensive Adapters** - Integration with industry-standard ad networks

---

## 📦 What's Included

This repository contains the CloudX iOS SDK ecosystem with binary distributions:

### Core Components

- **`core/`** - CloudXCore framework (binary xcframework)
  - Main SDK with bidding engine and ad serving
  - CocoaPods: `pod 'CloudXCore'`

- **`renderer-cloudx/`** - CloudXRenderer framework (binary xcframework)
  - Creative rendering with MRAID support
  - CocoaPods: `pod 'CloudXRenderer'`

### Adapters

- **`adapter-meta/`** - Meta Audience Network adapter (binary xcframework)
  - CocoaPods: `pod 'CloudXMetaAdapter'`
  
- **`adapter-vungle/`** - Vungle adapter (binary xcframework)
  - CocoaPods: `pod 'CloudXVungleAdapter'`

### Demo Applications

- **`demo-app-objc/`** - Complete Objective-C demo application
- **`demo-app-swift/`** - Complete Swift demo application

Both demos showcase all ad formats, privacy controls, and integration patterns.

---

## 📋 Requirements

- **iOS**: 14.0 or higher
- **Xcode**: 15.3 or higher
- **Swift**: 5.9+ (if using Swift)
- **CocoaPods**: 1.10+ or Swift Package Manager

### ⚠️ Xcode 15+ Users

If using CocoaPods with Xcode 15+, disable User Script Sandboxing:

1. Select your project target
2. Go to **Build Settings**
3. Search for "User Script Sandboxing"
4. Set **ENABLE_USER_SCRIPT_SANDBOXING** to **No**

This is required for CocoaPods to embed dynamic frameworks properly (standard for all iOS SDKs using dynamic frameworks).

---

## 🔄 Installation Methods

### CocoaPods (Recommended)

```ruby
pod 'CloudXCore', '~> 1.2.0'
pod 'CloudXMetaAdapter', '~> 1.2.0'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/cloudx-io/cloudx-ios", from: "1.2.0")
]
```

**Note**: Some adapters may not be available via SPM. Use CocoaPods for full adapter support.

---

## 🏷️ Release Strategy

This repository uses **component-specific releases** with semantic versioning:

- **CloudXCore**: `v1.2.0-core`
- **CloudXMetaAdapter**: `v1.2.0-meta`
- **CloudXRenderer**: `v1.2.0-renderer`
- **CloudXVungleAdapter**: `v1.2.0-vungle`

Each component maintains independent versioning for flexible updates.

---

## 🛠️ Support

Need help? We're here for you:

- 📧 **Email**: [hello@cloudx.io](mailto:hello@cloudx.io)
- 📖 **Documentation**: [docs.cloudx.io](https://docs.cloudx.io)
- 🐛 **Issues**: [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)
- 💬 **Dashboard**: [app.cloudx.io](https://app.cloudx.io)

---

## 📄 License

CloudX iOS SDK is licensed under the **Business Source License 1.1**.

See [LICENSE](LICENSE) for details.

---

## 🔗 Links

- **Documentation**: [docs.cloudx.io/ios](https://docs.cloudx.io/ios/installation)
- **GitHub**: [github.com/cloudx-io/cloudx-ios](https://github.com/cloudx-io/cloudx-ios)
- **Website**: [cloudx.io](https://cloudx.io)
- **Blog**: [cloudx.io/blog](https://cloudx.io/blog)

---

<p align="center">
  <strong>Made with ❤️ by CloudX</strong>
  <br>
  Empowering mobile monetization
</p>
