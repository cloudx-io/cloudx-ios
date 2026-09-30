# CloudX iOS SDK

AI-powered mobile advertising for iOS.

**[Integration Guide →](https://docs.cloudx.io/en/ios/integration)**

## Demo apps

[`demo-app-swift/`](demo-app-swift/) and [`demo-app-objc/`](demo-app-objc/) are the same demo in Swift and Objective-C. Each integrates the SDK and its network adapters and opens on an Options screen that picks a demo flow:

```
Options  ──  General      ──>  the CloudX integration demo
         ├─  First Look   ──>  CloudX-first interstitial with AdMob fallback (Swift demo)
         └─  Arbiter/TPA  (not available yet)
```

General has an Init tab that initializes the SDK, Banner, Interstitial and Rewarded on the other bottom tabs, and App Open, MREC, Native, Key-Values and Settings under More. First Look loads a CloudX interstitial first. It loads the AdMob test interstitial only if CloudX cannot fill or initialize. It is in the Swift demo for now; the Objective-C demo gets it next. The Options screen makes no SDK calls and closes once you pick a flow, so it shows again only when the app starts from scratch. General initializes CloudX from its Init tab; First Look initializes CloudX and Google Mobile Ads when its screen opens.

First Look prepares another CloudX-first pass after an interstitial closes. If both sources fail, it retries with increasing delays. The AdMob app ID and interstitial ID are Google's test IDs; replace them with your own IDs before using this flow in a production app.

The First Look flow lives in [`demo-app-swift/CloudXSwiftRemotePods/Ads/FirstLook/`](demo-app-swift/CloudXSwiftRemotePods/Ads/FirstLook/): `FirstLookInterstitialController.swift` and its two sources, `CloudXFirstLookSource.swift` and `AdMobFirstLookSource.swift`. Copy all three together. Both sources log through the demo's `DemoAppLogger`; swap in your own logging when you copy them. The host screen, `Views/FirstLook/FirstLookViewController.swift`, starts Google Mobile Ads, requests App Tracking Transparency and then initializes CloudX, waits up to 15 seconds for the CloudX initialization result, retries a failed load or show with a 2 to 60 second backoff, and connects the controller to the Show button and status text.

```sh
cd demo-app-swift   # or demo-app-objc
pod install
open *.xcworkspace
```
