# CloudX Meta Adapter

Meta Audience Network adapter for CloudX iOS SDK.

## Requirements

- iOS 13.0+
- **Xcode 16.0+** (Meta Audience Network SDK 6.21.x)
- Swift 6.0+

## Installation

### CocoaPods

```ruby
pod 'CloudXMetaAdapter'
```

```bash
pod install --repo-update
```

### Manual

1. Download `CloudXMetaAdapter-v{version}.xcframework.zip` from [Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Unzip and drag `CloudXMetaAdapter.xcframework` into your Xcode project

## Info.plist Configuration

### SKAdNetwork IDs (Required for iOS 14.5+)

Both Meta SKAdNetwork IDs are required for Meta to make bids:

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

### App Tracking Transparency (iOS 14+)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

## Project Configuration

**Linker Flags:** Add `-ObjC` to Other Linker Flags in Build Settings.

**Bitcode:** Meta SDK does not support Bitcode. Set Enable Bitcode to `NO`.

## ⚠️ Critical: Meta SDK 6.21.0 SceneDelegate Crash

### The Problem

Meta Audience Network SDK 6.21.0 has an internal bug that causes crashes when used in apps with `SceneDelegate` (iOS 13+ scene-based lifecycle). The crash occurs during banner ad display with the following error:

```
*** -[NSProxy doesNotRecognizeSelector:observeScreenOrientationChanges:] called!
```

**Stack trace:**
```
-[FBDisplayAdController startListeningToDeviceOrientationChanges:dataModel:]
-[FBDisplayAdController startAdFromRootViewController:animated:]
-[FBAdView displayAdControllerLoaded:]
```

This is an **internal Meta SDK bug** where their `FBDisplayAdController` creates an `NSProxy` for orientation observation that isn't properly configured to forward the `observeScreenOrientationChanges:` selector.

### Root Cause

The crash occurs because Meta SDK's internal orientation handling has issues with the modern `UIScene`-based app lifecycle. When an app uses `SceneDelegate`:
- `[UIApplication sharedApplication].keyWindow` returns `nil` or behaves differently
- Window/scene relationships are more complex
- Meta SDK's internal proxy mechanism fails to properly set up orientation observation

### Solution: Remove SceneDelegate

The **only reliable fix** is to use the old-style `AppDelegate`-only pattern (without `SceneDelegate`), which is how other major mediation SDKs configure their demo apps.

#### Step 1: Remove SceneDelegate files
Delete `SceneDelegate.h` and `SceneDelegate.m` from your project.

#### Step 2: Remove UIApplicationSceneManifest from Info.plist
Remove the entire `UIApplicationSceneManifest` section from your `Info.plist`:

```xml
<!-- DELETE THIS ENTIRE SECTION -->
<key>UIApplicationSceneManifest</key>
<dict>
    ...
</dict>
```

#### Step 3: Add required keys to Info.plist
Ensure your `Info.plist` has these keys (that were previously auto-generated):

```xml
<key>UIMainStoryboardFile</key>
<string>Main</string>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

#### Step 4: Update AppDelegate
Add the `window` property and set up your root view controller:

```objc
// AppDelegate.h
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

// AppDelegate.m
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Create window and set root view controller
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[YourRootViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    return YES;
}
```

**Swift:**
```swift
// AppDelegate.swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = YourRootViewController()
        window?.makeKeyAndVisible()
        return true
    }
}
```

#### Step 5: Update Build Settings (if using Xcode 14+)
If your project uses `GENERATE_INFOPLIST_FILE = YES`, you may need to either:
- Set it to `NO` and maintain all keys in Info.plist manually, OR
- Ensure all `INFOPLIST_KEY_*` settings are correct in Build Settings

### Xcode Warning

After removing SceneDelegate, you'll see this warning:
```
CLIENT OF UIKIT REQUIRES UPDATE: This process does not adopt UIScene lifecycle. This will become an assert in a future version.
```

This warning is **expected** and does not affect functionality. It's simply Apple's deprecation notice for the old app lifecycle pattern.

### Why Other Workarounds Don't Work

We tried several other approaches that **did NOT fix** the crash:

1. ❌ Adding `window` property getter to return scene's key window
2. ❌ Creating a separate delegate class for `FBAdViewDelegate`  
3. ❌ Implementing `observeScreenOrientationChanges:` on delegate/adapter
4. ❌ Deferring `FBAdView` creation to main thread
5. ❌ Setting frame before loading

The **only solution** that works is removing `SceneDelegate` entirely.

## Support

For support, contact mobile@cloudx.io
