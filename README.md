# CloudX iOS SDK

AI-powered mobile advertising for iOS.

**[Integration Guide →](https://docs.cloudx.io/en/ios/integration)**

## Demo app

[`demo-app-swift/`](demo-app-swift/) is a Swift app that integrates the SDK and its network adapters. It opens on an Options screen that picks a demo flow:

```
Options  ──  General      ──>  the CloudX integration demo
         ├─  First Look   (not available yet)
         └─  Arbiter/TPA  (not available yet)
```

General has an Init tab that initializes the SDK, Banner, Interstitial and Rewarded on the other bottom tabs, and App Open, MREC, Native, Key-Values and Settings under More. The Options screen makes no SDK calls and closes once you pick a flow, so it shows again only when the app starts from scratch.

```sh
cd demo-app-swift
pod install
open CloudXSwiftRemotePods.xcworkspace
```
