# CloudX iOS SDK

**AI-powered mobile advertising for iOS.** Maximize revenue with intelligent ad optimization and real-time bidding.

[![Platform](https://img.shields.io/badge/platform-iOS%2014.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-green.svg)](https://cocoapods.org)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-orange.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-BSL%201.1-lightgrey.svg)](LICENSE)

---

## 🚀 Get Started in 30 Seconds

### Install

```ruby
# Add to your Podfile
pod 'CloudXCore'
```

```bash
pod install
```

### Initialize & Load

```swift
import CloudXCore

// 1. Initialize (in AppDelegate)
// Production: testMode defaults to false
CloudXCore.shared.initializeSDK(appKey: "YOUR_APP_KEY") { success, error in
    print(success ? "Ready!" : "Error: \(error!)")
}

// Development/QA: Enable test mode for testing
// CloudXCore.shared.initializeSDK(appKey: "YOUR_APP_KEY", testMode: true) { success, error in
//     print(success ? "Test mode enabled" : "Error: \(error!)")
// }

// 2. Create banner ad (in ViewController)
let banner = CloudXCore.shared.createBanner(
    withPlacement: "YOUR_PLACEMENT_ID",
    viewController: self,
    delegate: self,
    tmax: 10.0
)
view.addSubview(banner)
```

**That's it.** You're monetizing.

---

## 📚 Complete Documentation

**Everything you need is in our docs** →

### **[📖 Read the Full iOS Documentation](https://docs.cloudx.io/ios/installation)**

Detailed guides for every step:

- **[Installation Guide](https://docs.cloudx.io/ios/installation)** - Setup, requirements, Info.plist configuration
- **[Quickstart Guide](https://docs.cloudx.io/ios/quickstart)** - All ad formats with code examples
- **[Configuration Guide](https://docs.cloudx.io/ios/configuration)** - Privacy, targeting, advanced features

---

## ⚡ Key Features

- **AI-Optimized Yield** - Intelligent ad selection maximizes your revenue
- **Multiple Ad Formats** - Banner, MREC, interstitial, and rewarded video
- **Real-Time Bidding** - Server-side header bidding with dynamic optimization
- **Privacy First** - GDPR, CCPA, COPPA, and ATT compliant out of the box
- **SwiftUI Ready** - Works seamlessly with UIKit and SwiftUI
- **Lightning Fast** - Optimized for performance and user experience

---

## ⚠️ Important: Xcode 15+ Setup

**If using CocoaPods with Xcode 15+**, disable User Script Sandboxing:

1. Select your project target
2. Build Settings → Search "User Script Sandboxing"  
3. Set **ENABLE_USER_SCRIPT_SANDBOXING** to **No**

This is required for all iOS SDKs using dynamic frameworks.

---

## 📦 Ad Formats

Load any ad format in 3 lines:

```swift
// Banner (320×50)
let banner = CloudXCore.shared.createBanner(withPlacement: "...", viewController: self, delegate: self)

// Interstitial
let interstitial = CloudXCore.shared.createInterstitial(withPlacement: "...", viewController: self, delegate: self)

// Rewarded
let rewarded = CloudXCore.shared.createRewarded(withPlacement: "...", viewController: self, delegate: self)
```

**[→ See complete examples in the Quickstart Guide](https://docs.cloudx.io/ios/quickstart)**

---

## 🎯 What's Included

### SDK Components (via CocoaPods)

```ruby
pod 'CloudXCore'           # Core SDK (required)
pod 'CloudXMetaAdapter'    # Meta Audience Network
pod 'CloudXVungleAdapter'  # Vungle
pod 'CloudXRenderer'       # Creative renderer
```

### Demo Apps

- `demo-app-swift/` - Swift example app
- `demo-app-objc/` - Objective-C example app

Both include all ad formats, privacy controls, and best practices.

---

## 📋 Requirements

- iOS 14.0+
- Xcode 15.3+
- Swift 5.9+ or Objective-C
- CocoaPods 1.10+ or Swift Package Manager

---

## 🛠️ Need Help?

- **📖 Documentation** - [docs.cloudx.io/ios](https://docs.cloudx.io/ios/installation)
- **💬 Support** - [hello@cloudx.io](mailto:hello@cloudx.io)
- **🐛 Issues** - [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)
- **📊 Dashboard** - [app.cloudx.io](https://app.cloudx.io)

---

## 🔗 Resources

- [iOS Installation Guide](https://docs.cloudx.io/ios/installation)
- [iOS Quickstart Guide](https://docs.cloudx.io/ios/quickstart)
- [iOS Configuration Guide](https://docs.cloudx.io/ios/configuration)
- [API Reference](https://docs.cloudx.io/api-reference/ios-api)
- [CloudX Website](https://cloudx.io)

---

<p align="center">
  <strong>Start monetizing in minutes</strong>
  <br>
  <a href="https://docs.cloudx.io/ios/installation">Read the Documentation →</a>
</p>
