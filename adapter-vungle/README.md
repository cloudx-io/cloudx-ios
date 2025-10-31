# CloudX Vungle (Liftoff) Adapter for iOS

Vungle adapter for CloudX Core iOS SDK - provides monetization through the Liftoff/Vungle advertising network with support for header bidding and waterfall integrations.

## Prerequisites

- Use Xcode 16.0 or higher  
- Target iOS 12.0 or higher
- **CloudX Core SDK** - Required base SDK
- **VungleAds SDK 7.4.0+** - Automatically installed as dependency
- **iOS 14+**: SKAdNetwork configuration required for proper attribution and revenue optimization

## 🛠️ Installation

### 📦 CocoaPods

Vungle adapter for CloudX SDK is available through [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

Open your project's `Podfile` and add this line to your app's target:
```ruby
pod 'CloudXVungleAdapter'
```

Install the pod from command line using:
```bash
pod install --repo-update
```
- Installing via CocoaPods should handle the project configuration, but if you run into any issues building, running, or seeing ads, check the Project Configuration / Troubleshooting steps below

### 📦 Swift Package Manager

Import the Swift Package into your Xcode project via the following URL:
```bash
https://github.com/cloudx-io/cloudx-ios
```
Select the `CloudXVungleAdapter` product when adding the package to your target.

### 📦 Manual  
1. Navigate to the releases and open the latest release: [Releases](https://github.com/cloudx-io/cloudx-ios/releases)  
2. 📥 Download the `CloudXVungleAdapter-v{version}.xcframework.zip` file from the release (if available)
3. 🗂️ Unzip the download then drag and drop `CloudXVungleAdapter.xcframework` into your Xcode project
4. Manually add VungleAds SDK 7.4.0+ (available via CocoaPods or [Vungle's GitHub](https://github.com/Vungle/VungleAdsSDK-iOS))
5. Follow the Project Configuration / Troubleshooting steps below

## 📄 Update your Info.plist

### 🚨 Required SKAdNetwork IDs for iOS 14+ Attribution

**All Vungle/Liftoff SKAdNetwork IDs are required for Vungle to make bids on iOS 14+ devices and maximize your ad revenue.**

<details>
<summary>Click to expand - Copy and paste into your Info.plist</summary>

```xml
<key>SKAdNetworkItems</key>
<array>
    <!-- Vungle/Liftoff Primary IDs -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ludvb6z3bs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wg4vff78zm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>737z793b9f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yclnxrl5pm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t38b2kh725.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9rd848q2bz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n6fk4nfna4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>kbd757ywx3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9t245vhmpl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4468km3ulz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2u9pt9hc89.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m8dbw4sv7c.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c6k4g5qg8m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mlmmfzh3r3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>578prtvx9j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4dzt52r2t5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>e5fvkxwrpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8s468mfl3y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>av6w8kgt66.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>klf5c3l5u5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ppxm28t8ap.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>424m5254lk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>uw77j35x4d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>578prtvx9j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>zmvfpc5aq8.skadnetwork</string>
    </dict>
</array>
```

</details>

> **Important:** Keep this list updated by checking [Vungle's SKAdNetwork documentation](https://support.vungle.com/hc/en-us/articles/360002925791-Integrate-Vungle-SDK-for-iOS) for the latest IDs.

For more information, see [Apple's SKAdNetwork documentation](https://developer.apple.com/documentation/storekit/skadnetwork).

## ✨ Automatic Features

The CloudX Vungle adapter automatically handles:

- ✅ **Header Bidding Integration**: Automatic bid token generation for real-time bidding auctions
- ✅ **Waterfall Support**: Seamless fallback to waterfall ad requests when not using bidding
- ✅ **App Tracking Transparency Integration**: Automatically respects your app's ATT permission status
- ✅ **Complete Ad Format Support**: Interstitial, Rewarded, Banner, MREC, Native, and App Open ads
- ✅ **Server Reward Validation**: Supports Vungle's server-side reward validation for rewarded ads
- ✅ **Comprehensive Error Handling**: Automatic error mapping with retry logic and rate limiting
- ✅ **Timeout Management**: Configurable timeouts (default 30s) to prevent hung ad requests
- ✅ **Memory Management**: Automatic cleanup and lifecycle management to prevent leaks
- ✅ **Privacy Compliance**: GDPR, CCPA, and iOS privacy framework support

**No additional configuration required** - the adapter integrates seamlessly with CloudX Core SDK.

## 📱 Supported Ad Formats

| Format | Class | Supported Sizes | Use Case |
|--------|-------|-----------------|----------|
| **Interstitial** | `CLXVungleInterstitial` | Fullscreen | Natural app breaks, level completion |
| **Rewarded** | `CLXVungleRewarded` | Fullscreen | Opt-in rewards, extra lives, currency |
| **Banner** | `CLXVungleBanner` | 320x50, 728x90 | Persistent screen placement |
| **MREC** | `CLXVungleBanner` | 300x250 | Medium rectangle, in-content |
| **Native** | `CLXVungleNative` | Custom layouts | Blend with app content |
| **App Open** | `CLXVungleAppOpen` | Fullscreen | App launch, return from background |

## 🧰 Project Configuration / Troubleshooting

### **1. Linker Flags**  
Add the following to your project's Other Linker Flags in Build Settings:  
```
-ObjC
```

### **2. Required Frameworks**

The following frameworks are required by Vungle SDK (automatically linked via CocoaPods):
- Foundation
- UIKit
- WebKit
- AVFoundation
- CoreMedia
- AudioToolbox
- CFNetwork
- CoreGraphics
- CoreTelephony
- SystemConfiguration
- StoreKit

If integrating manually, ensure these are linked in your project.

### **3. App Transport Security (ATS)**  

Vungle SDK requires network access for ad delivery. Most modern ads use HTTPS, but if needed, update your Info.plist:
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

📱 Vungle SDK requires iOS 12.0+. Ensure your deployment target is set correctly in your project settings.

### **6. Bitcode**  

🚫 Vungle SDK does not support Bitcode. If you encounter issues during archive or validation, disable Bitcode:

Go to your target → Build Settings → Set **Enable Bitcode** to `NO`.

### **7. Module Support**

The adapter uses module imports for proper framework integration. Ensure modules are enabled:
- Build Settings → **Defines Module** = `YES`
- Build Settings → **Enable Modules (C and Objective-C)** = `YES`

## 📚 Configuration in CloudX SDK

### Initializing with Vungle

The CloudX SDK handles Vungle initialization automatically. Configure your Vungle App ID in your CloudX configuration:

**Objective-C:**
```objective-c
// Vungle App ID is configured in CloudX bidding configuration
// The adapter will automatically initialize Vungle SDK when CloudX SDK initializes

// Check if Vungle is initialized
if ([CLXVungleInitializer isInitialized]) {
    NSLog(@"Vungle SDK is ready");
}
```

**Swift:**
```swift
// Vungle App ID is configured in CloudX bidding configuration
// The adapter will automatically initialize Vungle SDK when CloudX SDK initializes

// Check if Vungle is initialized
if CLXVungleInitializer.isInitialized() {
    print("Vungle SDK is ready")
}
```

### Vungle Placement IDs

Each ad format requires a Vungle placement ID configured in your Liftoff Monetize dashboard. These placement IDs are provided through CloudX's ad request configuration.

## 🎯 Testing Your Integration

### Test Mode

During development, you can enable test mode in the Liftoff Monetize dashboard:

1. Log in to your [Liftoff Monetize account](https://publisher.vungle.com/)
2. Navigate to your app settings
3. Enable **Test Mode** for your app
4. Test ads will show $100 bids in the auction

**Important:** Disable test mode before releasing to production.

### Verifying Ad Delivery

To verify Vungle ads are loading correctly:

1. **Check Logs**: Enable CloudX debug logging to see Vungle adapter activity
2. **Monitor Callbacks**: Implement CloudX ad delegates to receive load/show callbacks
3. **Dashboard Metrics**: Check your Liftoff Monetize dashboard for impression counts

## 🔧 Advanced Configuration

### Custom Timeout

Default timeout for ad loading is 30 seconds. You can customize this if needed through CloudX configuration.

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

The adapter automatically forwards GDPR consent signals from CloudX Core to Vungle SDK. No additional configuration required.

### CCPA Compliance

CCPA consent is automatically handled when you configure CloudX Core SDK with user privacy preferences.

### ATT (App Tracking Transparency)

The adapter respects iOS ATT permissions automatically. When a user denies tracking, Vungle receives the appropriate signal for non-personalized ads.

### Privacy Manifest

✅ This adapter includes Apple's required Privacy Manifest for App Store compliance (iOS 17+).

## 🐛 Common Issues & Solutions

### Issue: Ads Not Loading

**Solutions:**
1. Verify Vungle App ID is correctly configured in CloudX configuration
2. Check that SKAdNetwork IDs are in Info.plist
3. Ensure placement IDs match your Liftoff Monetize dashboard
4. Check console logs for initialization errors
5. Verify internet connectivity

### Issue: "SDK Not Initialized" Error

**Solutions:**
1. Ensure CloudX Core SDK is initialized before requesting ads
2. Check that Vungle App ID is present in configuration
3. Wait for CloudX initialization callback before loading ads

### Issue: Bid Token Generation Fails

**Solutions:**
1. Verify Vungle SDK initialized successfully
2. Check network connectivity
3. Review console logs for specific error messages

### Issue: Rewarded Ads Not Granting Rewards

**Solutions:**
1. Verify `userRewardWithRewarded:` delegate callback is implemented
2. Check that user watched ad completely before closing
3. Ensure server-side validation is configured correctly (if using)

## 📖 Additional Resources

- **Liftoff/Vungle Integration Guide**: [https://support.vungle.com/hc/en-us/articles/360002925791](https://support.vungle.com/hc/en-us/articles/360002925791)
- **SKAdNetwork IDs**: [https://support.vungle.com/hc/en-us/articles/360002925791](https://support.vungle.com/hc/en-us/articles/360002925791)
- **CloudX Core Documentation**: [../core/README.md](../core/README.md)
- **Liftoff Monetize Dashboard**: [https://publisher.vungle.com/](https://publisher.vungle.com/)

## 📊 SDK Version Information

- **Adapter Version**: 1.0.0
- **Vungle SDK Version**: 7.4.0+
- **Minimum iOS Version**: 12.0
- **Minimum Xcode Version**: 16.0

## 🆘 Support

For technical support and questions:

- **CloudX Support**: support@cloudx.com
- **Vungle Support**: [https://support.vungle.com/](https://support.vungle.com/)
- **Create an Issue**: [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)

## 📄 License

Copyright (c) 2024 CloudX, Inc. All rights reserved.

This adapter is licensed under the Business Source License 1.1. See the LICENSE file for details.
