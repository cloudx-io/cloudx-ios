# CloudX Meta Adapter
Meta adapter for CloudX Core iOS SDK

## Prerequisites

- Use Xcode 15.3 or higher  
- Target iOS 13.0 or higher
- **iOS 14.5+ Users**: Requires Meta Audience Network SDK 6.2.1+ for proper monetization
- **Build with Xcode 12+** (iOS SDK 14+) for iOS 14.5+ support

## 🛠️ Installation

### 📦 CocoaPods

Meta adapter for CloudX SDK is available though [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

Open your project's `Podfile` and add this line to your app's target
```ruby
pod 'CloudXMetaAdapter'
```

Install the pod from command line using:
```bash
pod install --repo-update
```
- Installing via Cocoapods should handle the project configuration, but if you run into any issues building, running, or seeing ads, check the Project Configuration / Troubleshooting steps below

### 📦 Swift Package Manager

Import the Swift Package into your XCode project via the following url
```bash
https://github.com/cloudx-xenoss/cloudx-ios
```
- ⚠️ Meta (FBAudienceNetwork) is **not available via Swift Package Manager**. You must manually download and integrate the **dynamic** (not static) framework.
- FBAudienceNetwork manual installation instructions are found here [FBAudienceNetwork Installation Instructions](https://developers.facebook.com/docs/audience-network/setting-up/platform-setup/ios/add-sdk) 
- NOTE: Follow the Project Configuration / Troubleshooting steps in the section below for additional setup setups

### 📦 Manual  
1. Navigate to the releases and open the latest release (or whichever release you would like): [Releases](https://github.com/cloudx-xenoss/cloudx-ios/releases)  
2. 📥 Download the `CloudXMetaAdapter-v{version}.xcframework.zip` file from the release  
3. 🗂️ Unzip the download then drag and drop `CloudXMetaAdapter.xcframework` into your XCode project
4. Follow the Project Configuration / Troubleshooting steps in the section below for additional setup setups

## 📄 Update your Info.plist

### 🚨 Required SKAdNetwork IDs for iOS 14.5+

***Both Meta SKAdNetwork IDs are required for Meta to make bids on iOS 14.5+ devices***
```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
</array>
```

For more information, see [Apple's SKAdNetwork documentation](https://developer.apple.com/documentation/storekit/skadnetwork).

## ✨ Automatic Features

The CloudX Meta adapter automatically handles:

- ✅ **App Tracking Transparency Integration**: Automatically configures Meta's Advertiser Tracking Enabled (ATE) flag based on your app's ATT permission status
- ✅ **Bid Token Generation**: Creates Meta bidder tokens for programmatic auction participation  
- ✅ **Server Reward Validation**: Supports Meta's server-side reward validation for rewarded ads
- ✅ **iOS 14.5+ Compatibility**: Full support for App Tracking Transparency requirements
- ✅ **Comprehensive Logging**: Detailed logs for debugging and monitoring ad performance

**No additional configuration required** - the adapter integrates seamlessly with CloudX Core SDK's tracking services.

## 🧰 Project Configuration / Troubleshooting

**1. Linker Flags**  
Add the following to your project's Other Linker Flags in Build Settings:  
`-ObjC`

**2. Enable Objective-C Exceptions (Recommended)**
- Some older versions of Meta SDKs expect Obj-C exceptions to be enabled.
- Go to Build Settings
- Set Enable Objective-C Exceptions (GCC_ENABLE_OBJC_EXCEPTIONS) to YES


**3. App Transport Security (ATS)**  
If your app communicates with non-HTTPS servers for ads (less common), update your Info.plist to allow exceptions:  
```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
⚠️ *Note: Only do this if absolutely necessary.*


**4. NSUserTrackingUsageDescription (iOS 14+)**  
If your app targets iOS 14+, and you want access to the IDFA, you must add a usage description in your Info.plist:
```
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

**5. Minimum Deployment Target**  
📱 As of recent versions, Meta SDK requires iOS 11.0+. Set this in your project's deployment target.


**6. Bitcode (Optional)**  
🚫 Meta SDK does not support Bitcode. If you're running into issues during archive or validation, disable Bitcode:  

Go to your target → Build Settings → Set **Enable Bitcode** to `NO`.
