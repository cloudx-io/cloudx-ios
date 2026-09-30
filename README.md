# CloudX iOS SDK

AI-powered mobile advertising for iOS.

**[Integration Guide →](https://docs.cloudx.io/en/ios/integration)**

## Demo apps

[`demo-app-swift/`](demo-app-swift/) and [`demo-app-objc/`](demo-app-objc/) are the same demo in Swift and Objective-C. Each integrates the SDK and its network adapters and opens on an Options screen that picks a demo flow:

```
Options  ──  General      ──>  the CloudX integration demo
         ├─  First Look   ──>  CloudX-first interstitial with AdMob fallback
         └─  Arbiter/TPA  ──>  CloudX and AdMob in parallel, Trusted Arbiter picks
```

General has an Init tab that initializes the SDK, Banner, Interstitial and Rewarded on the other bottom tabs, and App Open, MREC, Native, Key-Values and Settings under More. First Look loads a CloudX interstitial first. It loads the AdMob test interstitial only if CloudX cannot fill or initialize. Arbiter/TPA loads the CloudX and AdMob interstitials at the same time and lets Trusted Arbiter pick which one to show. The Options screen makes no SDK calls and closes once you pick a flow, so it shows again only when the app starts from scratch. General initializes CloudX from its Init tab; First Look and Arbiter/TPA initialize CloudX and Google Mobile Ads when their screen opens.

First Look prepares another CloudX-first pass after an interstitial closes. If both sources fail, it retries with increasing delays. The AdMob app ID and interstitial ID are Google's test IDs; replace them with your own IDs before using this flow or Arbiter/TPA in a production app. The interstitial ID is in `Configuration/AdMobDemoConfig` and the app ID is the `GADApplicationIdentifier` in `Info.plist`.

The First Look flow lives in [`demo-app-swift/CloudXSwiftRemotePods/Ads/FirstLook/`](demo-app-swift/CloudXSwiftRemotePods/Ads/FirstLook/) and [`demo-app-objc/CloudXObjCRemotePods/Ads/FirstLook/`](demo-app-objc/CloudXObjCRemotePods/Ads/FirstLook/): `FirstLookInterstitialController` and its two sources, `CloudXFirstLookSource` and `AdMobFirstLookSource`. Copy all three together. Both sources log through the demo's `DemoAppLogger`; swap in your own logging when you copy them. The host screen, `Views/FirstLook/FirstLookViewController` in each demo, connects the controller to the Show button and status text. It brings up both SDKs through `DemoSdkStartup`, which starts Google Mobile Ads, requests App Tracking Transparency, then initializes CloudX and waits up to 15 seconds for the result. A failed load or show is retried with a 2 to 60 second backoff through `RetryScheduler`.

Arbiter/TPA (Trusted Arbiter, third-party arbitration) is the other way to run CloudX next to AdMob. Both interstitials load in parallel. Once both have settled, loaded or failed, the loaded ones become bids and the CloudX arbiter call returns the platform to show. The winner is stored, so Show displays it with no network call; if no winner is prepared, a real app carries on without an ad. After the ad closes, each platform without a fill reloads, one that still holds an ad keeps it, and a new round runs. The SDK owns the arbiter's timeout and fallback, so the demo neither times the call out nor compares prices: a single bid wins without a service call.

AdMob bids carry no price. CloudX prices them from the revenue the app reports after each AdMob impression, so every AdMob paid event goes to `reportRevenueData`. That call is a required part of the integration. The status line shows what it returned. Google's test ad unit reports a value of 0, which CloudX does not keep as a price. If CloudX does not initialize, AdMob is the only candidate and wins each round without an arbiter call. The flow covers the interstitial; rewarded follows the same controller with the rewarded calls, while banner, MREC and native arbitrate first and then render the winner, which this demo does not show. The pattern is documented in the [Trusted Arbiter guide](https://docs.cloudx.io/en/ios/trusted-arbiter).

To integrate it, copy `ArbiterInterstitialController` from [`demo-app-swift/CloudXSwiftRemotePods/Ads/Arbiter/`](demo-app-swift/CloudXSwiftRemotePods/Ads/Arbiter/) or [`demo-app-objc/CloudXObjCRemotePods/Ads/Arbiter/`](demo-app-objc/CloudXObjCRemotePods/Ads/Arbiter/). It holds every load, show, arbiter and revenue call of the flow and logs through the demo's `DemoAppLogger`; swap in your own logging when you copy it. The host screen, `Views/Arbiter/ArbiterViewController` in each demo, brings up both SDKs the same way as First Look, retries with a 2 to 60 second backoff when neither platform fills or a show fails, and connects the controller to the Show button and status text.

Trusted Arbiter is enabled per ad unit on the CloudX side. The flow uses `demo-interstitial-1`, the demo interstitial it is enabled for, instead of the interstitial General uses. No code in this repository can turn it on for your own ad units. When the arbiter service is not available for your app, the SDK decides a round with more than one bid locally: the highest comparable price wins, and an AdMob bid with no revenue history yet cannot win against CloudX.

```sh
cd demo-app-swift   # or demo-app-objc
pod install
open *.xcworkspace
```
