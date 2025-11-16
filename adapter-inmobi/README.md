# CloudX InMobi Mediation Adapter for iOS

InMobi adapter for CloudX Core iOS SDK - provides monetization through the InMobi advertising network with support for header bidding and waterfall integrations.

## Prerequisites

- Use Xcode 16.0 or higher  
- Target iOS 12.0 or higher
- **CloudX Core SDK** - Required base SDK
- **InMobi SDK 10.8+** - Automatically installed as dependency
- **iOS 14+**: SKAdNetwork configuration required for proper attribution and revenue optimization

## 🛠️ Installation

### 📦 CocoaPods

InMobi adapter for CloudX SDK is available through [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

Open your project's `Podfile` and add this line to your app's target:
```ruby
pod 'CloudXInMobiAdapter'
```

Install the pod from command line using:
```bash
pod install --repo-update
```

Installing via CocoaPods should handle the project configuration, but if you run into any issues building, running, or seeing ads, check the Project Configuration / Troubleshooting steps below.

### 📦 Swift Package Manager

Import the Swift Package into your Xcode project via the following URL:
```bash
https://github.com/cloudx-io/cloudx-ios
```

Select the `CloudXInMobiAdapter` product when adding the package to your target.

### 📦 Manual  

1. Navigate to the releases and open the latest release: [Releases](https://github.com/cloudx-io/cloudx-ios/releases)  
2. 📥 Download the `CloudXInMobiAdapter-v{version}.xcframework.zip` file from the release
3. 🗂️ Unzip the download then drag and drop `CloudXInMobiAdapter.xcframework` into your Xcode project
4. Manually add InMobi SDK 10.8+ (available via CocoaPods)
5. Follow the Project Configuration / Troubleshooting steps below

## 📄 Update your Info.plist

### 🚨 Required SKAdNetwork IDs for iOS 14+ Attribution

**InMobi SKAdNetwork IDs are required for InMobi to make bids on iOS 14+ devices and maximize your ad revenue.**

```xml
<key>SKAdNetworkItems</key>
<array>
    <!-- InMobi SKAdNetwork IDs -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yclnxrl5pm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tl55sbb4fm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t38b2kh725.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>prcb7njmu6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ppxm28t8ap.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mlmmfzh3r3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>klf5c3l5u5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hs6bdukanm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c6k4g5qg8m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9t245vhmpl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9rd848q2bz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>737z793b9f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6xzpu9s2p8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5lm9lj6jb7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4468km3ulz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3rd42ekr43.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2u9pt9hc89.skadnetwork</string>
    </dict>
</array>
```

> **Important:** Keep this list updated by checking [InMobi's SKAdNetwork documentation](https://support.inmobi.com/) for the latest IDs.

For more information, see [Apple's SKAdNetwork documentation](https://developer.apple.com/documentation/storekit/skadnetwork).

## ✨ Automatic Features

The CloudX InMobi adapter automatically handles:

- ✅ **Header Bidding Integration**: Automatic bid token generation for real-time bidding auctions
- ✅ **Waterfall Support**: Seamless fallback to waterfall ad requests when not using bidding
- ✅ **App Tracking Transparency Integration**: Automatically respects your app's ATT permission status
- ✅ **Complete Ad Format Support**: Interstitial, Rewarded, Banner, MREC, and Native ads
- ✅ **Comprehensive Error Handling**: Automatic error mapping with retry logic
- ✅ **Timeout Management**: Configurable timeouts (default 30s) to prevent hung ad requests
- ✅ **Memory Management**: Automatic cleanup and lifecycle management to prevent leaks
- ✅ **Privacy Compliance**: GDPR, CCPA, and iOS privacy framework support

**No additional configuration required** - the adapter integrates seamlessly with CloudX Core SDK.

## 📱 Supported Ad Formats

| Format | Class | Supported Sizes | Use Case |
|--------|-------|-----------------|----------|
| **Interstitial** | `CLXInMobiInterstitial` | Fullscreen | Natural app breaks, level completion |
| **Rewarded** | `CLXInMobiRewarded` | Fullscreen | Opt-in rewards, extra lives, currency |
| **Banner** | `CLXInMobiBanner` | 320x50, 728x90 | Persistent screen placement |
| **MREC** | `CLXInMobiBanner` | 300x250 | Medium rectangle, in-content |
| **Native** | `CLXInMobiNative` | Custom layouts | Blend with app content |

## 🧰 Project Configuration / Troubleshooting

### **1. Linker Flags**  

Add the following to your project's Other Linker Flags in Build Settings:  
```
-ObjC
```

### **2. Required Frameworks**

The following frameworks are required by InMobi SDK (automatically linked via CocoaPods):
- Foundation
- UIKit
- WebKit
- AVFoundation
- CoreGraphics
- CoreTelephony
- SystemConfiguration
- StoreKit
- AdSupport

If integrating manually, ensure these are linked in your project.

### **3. App Transport Security (ATS)**  

InMobi SDK requires network access for ad delivery. Most modern ads use HTTPS, but if needed, update your Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

⚠️ *Note: Only add this if you experience connectivity issues with ads.*

### **4. NSUserTrackingUsageDescription (iOS 14+)**  

If your app targets iOS 14+ and you want access to IDFA for personalized ads, add a usage description in your Info.plist:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

### **5. Minimum Deployment Target**  

📱 InMobi SDK requires iOS 12.0+. Ensure your deployment target is set correctly in your project settings.

### **6. Bitcode**  

🚫 InMobi SDK does not support Bitcode. If you encounter issues during archive or validation, disable Bitcode:

Go to your target → Build Settings → Set **Enable Bitcode** to `NO`.

### **7. Module Support**

The adapter uses module imports for proper framework integration. Ensure modules are enabled:
- Build Settings → **Defines Module** = `YES`
- Build Settings → **Enable Modules (C and Objective-C)** = `YES`

## 📚 Configuration in CloudX SDK

### Initializing with InMobi

The CloudX SDK handles InMobi initialization automatically. Configure your InMobi Account ID in your CloudX configuration:

**Objective-C:**
```objective-c
// InMobi Account ID is configured in CloudX bidding configuration
// The adapter will automatically initialize InMobi SDK when CloudX SDK initializes

// Check if InMobi is initialized
if ([CLXInMobiInitializer isInitialized]) {
    NSLog(@"InMobi SDK is ready");
}
```

**Swift:**
```swift
// InMobi Account ID is configured in CloudX bidding configuration
// The adapter will automatically initialize InMobi SDK when CloudX SDK initializes

// Check if InMobi is initialized
if CLXInMobiInitializer.isInitialized() {
    print("InMobi SDK is ready")
}
```

### InMobi Placement IDs

Each ad format requires an InMobi placement ID (64-bit integer) configured in your InMobi dashboard. These placement IDs are provided through CloudX's ad request configuration.

## 🎯 Testing Your Integration

### Test Mode

During development, InMobi automatically serves test ads in DEBUG builds and simulator environments. No additional configuration is required.

**Important:** Production builds on real devices will show live ads.

### Verifying Ad Delivery

To verify InMobi ads are loading correctly:

1. **Check Logs**: Enable CloudX debug logging to see InMobi adapter activity
2. **Monitor Callbacks**: Implement CloudX ad delegates to receive load/show callbacks
3. **Dashboard Metrics**: Check your InMobi dashboard for impression counts

## 🔧 Advanced Configuration

### Custom Timeout

Default timeout for ad loading is 30 seconds. This is configured automatically by the adapter.

### Error Handling

The adapter provides comprehensive error handling with automatic retry suggestions:

| Error Type | Retry Suggested | Delay |
|-----------|----------------|-------|
| No Fill | Yes | 30 seconds |
| Network Error | Yes | 5 seconds |
| Timeout | Yes | 10 seconds |
| Invalid Placement | No | Check configuration |
| Not Initialized | No | Check SDK setup |

Error details are available in the CloudX error callbacks with retry metadata.

## 🔒 Privacy & Compliance

### GDPR Compliance

The adapter automatically forwards GDPR consent signals from CloudX Core to InMobi SDK. No additional configuration required.

### CCPA Compliance

CCPA consent is automatically handled when you configure CloudX Core SDK with user privacy preferences.

### ATT (App Tracking Transparency)

The adapter respects iOS ATT permissions automatically. When a user denies tracking, InMobi receives the appropriate signal for non-personalized ads.

### Privacy Manifest

✅ This adapter includes Apple's required Privacy Manifest for App Store compliance (iOS 17+).

## 🐛 Common Issues & Solutions

### Issue: Ads Not Loading

**Solutions:**
1. Verify InMobi Account ID is correctly configured in CloudX configuration
2. Check that SKAdNetwork IDs are in Info.plist
3. Ensure placement IDs match your InMobi dashboard
4. Check console logs for initialization errors
5. Verify internet connectivity

### Issue: "SDK Not Initialized" Error

**Solutions:**
1. Ensure CloudX Core SDK is initialized before requesting ads
2. Check that InMobi Account ID is present in configuration
3. Wait for CloudX initialization callback before loading ads

### Issue: Bid Token Generation Fails

**Solutions:**
1. Verify InMobi SDK initialized successfully
2. Check network connectivity
3. Review console logs for specific error messages

### Issue: Rewarded Ads Not Granting Rewards

**Solutions:**
1. Verify reward delegate callback is implemented
2. Check that user watched ad completely before closing
3. Ensure InMobi placement is configured for rewarded ads

## 📖 Additional Resources

- **InMobi Integration Guide**: [https://support.inmobi.com/monetize/ios-sdk/integration-guidelines](https://support.inmobi.com/monetize/ios-sdk/integration-guidelines)
- **SKAdNetwork IDs**: [https://support.inmobi.com/](https://support.inmobi.com/)
- **CloudX Core Documentation**: [../core/README.md](../core/README.md)
- **InMobi Dashboard**: [https://www.inmobi.com/](https://www.inmobi.com/)

## 📊 SDK Version Information

- **Adapter Version**: 1.0.0
- **InMobi SDK Version**: 10.8.8+
- **Minimum iOS Version**: 12.0
- **Minimum Xcode Version**: 14.0

## 🆘 Support

For technical support and questions:

- **CloudX Support**: support@cloudx.com
- **InMobi Support**: [https://support.inmobi.com/](https://support.inmobi.com/)
- **Create an Issue**: [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)

## 📄 License

Copyright (c) 2024 CloudX, Inc. All rights reserved.

This adapter is licensed under the Business Source License 1.1. See the LICENSE file for details.

## 🏗️ Adapter Architecture

This adapter follows industry-standard naming conventions:

- **Pod Name**: `CloudXInMobiAdapter` 
- **Class Prefix**: `CLXInMobi*` (e.g., `CLXInMobiInterstitial`, `CLXInMobiBanner`)
- **Framework Name**: `CloudXInMobiAdapter`

The adapter implements CloudX's protocol-based architecture for seamless integration with CloudX Core SDK.

