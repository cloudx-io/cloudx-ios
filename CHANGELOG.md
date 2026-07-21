# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Global ad-revenue delegate** — New `+[CloudXCore addAdRevenueDelegate:]` / `removeAdRevenueDelegate:` API registers a global `CLXAdRevenueDelegate` that fires for every CloudX-won impression across all ad objects and formats — the surface analytics and MMP SDKs attach to, with no per-ad wiring.
- **AppsFlyer ad-revenue connector** — New `CloudXAppsFlyerConnector` pod automatically forwards impression-level ad revenue for every CloudX-won impression (Banner, MREC, Interstitial, Rewarded, Native, App Open) to AppsFlyer. Add `pod 'CloudXAppsFlyerConnector'` to your Podfile; the module self-registers onto the global ad-revenue delegate at load — no publisher glue code — and stays inert if your app doesn't use AppsFlyer. Requires `CloudXCore >= 3.6.0` and `AppsFlyerFramework >= 6.15.0`: the integrated `logAdRevenue` API was introduced in AppsFlyer SDK 6.15.0, and AppsFlyer 6.14.x and below use a separate legacy AdRevenue connector that this module does not consume. If an older AppsFlyer is linked at runtime, the module logs a skip and never crashes.

---

## [3.4.5] - 2026-06-12

### Added
- **InMobi native ads** — `CloudXInMobiAdapter` now serves Native creatives, both standalone (via `CLXNativeAdLoader`) and native-in-banner / native-in-MREC. Requires `InMobiSDK >= 11.2.0` (the adapter's minimum was raised from `11.0.0`).
- **Vungle standalone native ads** — `CloudXVungleAdapter` now serves standalone Native creatives via `CLXNativeAdLoader` (native-in-banner / native-in-MREC was already supported).
- **HTML interstitials on the CloudX renderer** — The CloudX renderer now supports fullscreen HTML interstitial creatives with MRAID 3.0, alongside the existing HTML banner / MREC support. Rollout is controlled server-side; no integration change is required.

### Changed
- **Slow ad network SDKs no longer delay CloudX SDK initialization** — Adapter initialization now uses a soft per-network timeout: if an ad network SDK is slow to initialize, CloudX SDK init completes without it and the network automatically joins later auctions once it finishes initializing. Previously a slow network SDK could block init. Networks that have not finished initializing are excluded from auctions they cannot serve, which can improve fill reliability during app startup.

### Fixed
- **Digital Turbine adapter no longer conflicts with another mediation SDK initializing the Fyber SDK** — If your app runs CloudX alongside another mediation SDK that initializes the shared Fyber Marketplace SDK first, the CloudX adapter now detects this and defers instead of re-initializing — previously this could cancel the other SDK's initialization. For the smoothest startup, initialize the other mediation SDK first, wait for its completion callback, then initialize CloudX.
- **Some valid HTML banner creatives were rejected by the renderer** — Fixed an issue where HTML banner / MREC creatives containing failed tracker pixels (e.g. some Media.net creatives) were misclassified as broken and not displayed. These creatives now render normally.
- **Native ad reliability improvements on Meta and Moloco** — Meta native ads now validate the loaded ad before delivery and register all asset views (title, body, icon, media, advertiser) for impression and click tracking, not just the CTA button (also applies to Vungle and Verve native-in-banner). Moloco native ads are no longer delivered when the underlying ad is not renderable.

### Removed
- **Adapter-integration APIs** — Removed from the adapter-facing surface: `clx_isFlexibleSize` (banner adapters), `+isInitialized` (adapter initializers), and per-instance `sdkVersion` (native adapters). These APIs had no function for app integrations; standard publisher integrations are unaffected.

---

## [3.4.4] - 2026-06-02

### Fixed
- **Digital Turbine adapter failed to link on Fyber Marketplace SDK below 8.4.0** — Although 3.4.3 advertised Digital Turbine support down to Fyber `8.0.0`, the shipped adapter binary still failed to link for apps resolving a Fyber SDK below `8.4.0`. The adapter binary now links cleanly across the full `8.x` line — Banner, MREC, Interstitial, and Rewarded work on Fyber `8.0.0`+. Native fill remains available on Fyber SDK `8.4.0`+.
- **Google Waterfall — occasional lost fills on slow mediation responses** — Fixed an issue where a Google Waterfall ad could be discarded when its mediation cascade took longer than expected to respond, even though the ad ultimately filled. Slow-but-successful responses are now delivered, improving Google Waterfall fill reliability.

---

## [3.4.3] - 2026-06-01

### Added
- **Pangle Adapter** — New `CloudXPangleAdapter` supporting Banner/MREC, Interstitial, and Rewarded ad formats. Install via CocoaPods (`pod 'CloudXPangleAdapter', '~> 3.4.3'`). Backed by the Pangle (ByteDance) SDK `Ads-Global ~> 7.9.0`.

### Changed
- **DigitalTurbine adapter — broader Fyber Marketplace SDK compatibility** — `CloudXDigitalTurbineAdapter` now accepts `Fyber_Marketplace_SDK` from `8.0.0` (previously required `>= 8.4.0`), so you can adopt the adapter without forcing a Fyber SDK upgrade. Banner, MREC, Interstitial, and Rewarded work across the full 8.x line; native fill remains available on Fyber SDK 8.4.0+.

### Fixed
- **App Store submission rejection caused by the `itms-services` URL scheme** — Some publishers received an App Store static-analysis rejection because the compiled SDK binary contained the `itms-services` scheme. The scheme has been removed; legitimate App Store redirect creatives still resolve normally, with no change to clickthrough behavior.
- **SDK initialization could fail for some accounts** — Fixed an issue where SDK initialization could fail for publisher accounts that have no organization identifier. Initialization now completes normally for these accounts.

---

## [3.4.2] - 2026-05-29

### Added
- **Google Waterfall Adapter** — New `CloudXGoogleWaterfallAdapter` supporting Banner (320×50) and MREC (300×250) ad formats. Install via CocoaPods (`pod 'CloudXGoogleWaterfallAdapter', '~> 3.4.2'`) or Swift Package Manager (`CloudXGoogleWaterfallAdapter` product). Backed by `Google-Mobile-Ads-SDK 12.14.0`; requires a `GADApplicationIdentifier` entry in your Info.plist. SPM consumers must also add the Google Mobile Ads SPM package (`github.com/googleads/swift-package-manager-google-mobile-ads`).

---

## [3.4.1] - 2026-05-27

### Added
- **Digital Turbine Adapter** — New `CloudXDigitalTurbineAdapter` supporting Banner, MREC, Interstitial, Rewarded, and Native ad formats. Install: `pod 'CloudXDigitalTurbineAdapter', '~> 3.4.1'`. Backed by `Fyber_Marketplace_SDK >= 8.4.0, < 9.0`.

### Fixed
- **Duplicate `didLoadAd` / `didShowAd` callbacks on banner refresh** — When a partner adapter SDK fired its load or impression callback more than once for the same ad, the publisher delegate could receive duplicate `didLoadAd` / `didShowAd` callbacks. The first callback is now treated as canonical and subsequent re-fires from the same adapter are dropped, so the publisher surface emits exactly one load and one impression per ad.

---

## [3.4.0] - 2026-05-22

### Added
- **Verve Adapter** — New `CloudXVerveAdapter` (Banner, MREC, Interstitial, Rewarded, Native). Install: `pod 'CloudXVerveAdapter', '~> 3.4.0'`. Backed by HyBid 3.8.0.
- **Moloco Adapter** — New `CloudXMolocoAdapter` (Banner, MREC, Interstitial, Rewarded, Native). Install: `pod 'CloudXMolocoAdapter', '~> 3.4.0'`. Backed by MolocoSDKiOS `~> 4.6.0`.
- **Non-SDK CloudX-rendered HTML banner and MREC with MRAID 3.0** — HTML banner and MREC creatives can now be served through the CloudX renderer, with MRAID 3.0 support.
- **Native-in-banner and native-in-MREC support** — Native creatives can be served into banner or MREC slots on Meta, Vungle, and Moloco.
- **Per-request extras across all ad-format APIs** — New `setExtraParameter:value:` API on `CLXBanner` / `CLXBannerAdView`, `CLXFullscreenAd` (interstitial + rewarded), and `CLXNativeAdLoader` lets publishers attach arbitrary per-request metadata to outgoing bid requests, including reserved `minFloor` (single-round) and `minFloors` (per-round) keys for publisher-defined bid floors. Supported value types: `NSString`, `NSNumber`, `NSArray`, `NSDictionary`. Banner refreshes pick up the current stored values on each auction.
- **`CLXAd.adValues` property** — New read-only `NSDictionary<NSString *, NSString *>` exposing SDK-defined loaded-ad metadata. Values may be absent depending on ad format and network.

### Changed
- **UnityAds adapter version range** — Widened to accept Unity Ads 4.x patch releases (`>= 4.17.0`, `< 5.0`) so publishers can adopt newer Unity Ads SDK fixes without waiting for an adapter release.
- **Publisher delegate main-queue threading is now documented contract** — All `CLXAdDelegate` callbacks (and protocols that extend it) and `CLXAdRevenueDelegate` callbacks deliver on the main queue and may fire inline relative to the SDK call that triggered them. No runtime change; re-entrant delegate implementations are unaffected.

### Fixed
- **Native ad memory leak during long sessions** — Long-lived publisher integrations that load many native ads no longer accumulate retained observers across native ad refresh cycles.

---

## [3.3.0-beta] - 2026-05-11

### Added
- **Per-request bid floor controls** — Added support for setting bid floors per ad request, including native ad requests.

### Changed
- **Improved ad lifecycle reliability** — Improved callback delivery during fast reloads, ad dismissals, and adapter teardown. This reduces rare cases where display, close, reward, or revenue callbacks could arrive late or be missed.
- **Improved analytics attribution** — Improved impression, click, and win/loss attribution consistency across the full ad lifecycle.
- **Improved renderer routing** — Improved CloudX-rendered creative routing based on the returned creative type.

### Fixed
- **Impression/click analytics replay** — Improved persistence and retry behavior for impression and click analytics without changing existing metrics behavior.
- **Fresh-install persistence reliability** — Fixed an issue where local persistence could fail to initialize correctly on a fresh app install or clean simulator.

---

## [3.2.0] - 2026-04-22

### Added
- **Magnite Adapter** — New `CloudXMagniteAdapter` (Banner, MREC, Interstitial, Rewarded). Install: `pod 'CloudXMagniteAdapter', '~> 3.2.0'`.
- **Richer dashboard telemetry** — Full telemetry overhaul. More robust event capture, new events, and increased observability.

---

## [3.1.0] - 2026-04-16

### Added
- **Meta Reels & Native Ads** — Meta Reels (9:16 vertical video) and other Meta native ad formats are now supported via `CLXPublisherNative`. This release supports Meta native ads only; additional bidder support is coming in a future release.
- **Per-Adapter Initialization Timeout** — SDK initialization now supports per-adapter timeouts for more predictable startup behavior.

### Fixed
- **Xcode 26 Compatibility** — Resolved a build warning when compiling with Xcode 26.

---

## [2.2.9] - 2026-04-09

### Fixed
- **Unity Ads Adapter** — Fixed initialization, privacy consent forwarding, rewarded callbacks, and bid token error handling for improved reliability across regions.

---

## [2.2.8] - 2026-04-03

### Fixed
- **Crash Fix** — Fixed a crash that could occur during concurrent ad event tracking on background threads

---

## [2.2.7] - 2026-04-01

### Fixed
- **Deferred Banner Display** — Fixed an issue where banners loaded before being added to the view hierarchy would fail to render when attached later. The load-then-show pattern now works correctly.

---

## [2.2.6] - 2026-03-30

### Added
- **Privacy Consent for Unity Ads** — Unity Ads adapter now supports GDPR and CCPA privacy consent forwarding
- **`isAdReady` Support** — Fullscreen ad adapters now support `isAdReady` for reliably querying ad availability before calling show

### Fixed
- **Banner Visibility Accuracy** — Fixed an issue where setting `banner.hidden = YES` did not pause ad refresh. Hidden banners could continue loading ads without being impression-eligible, potentially impacting CPMs.
- **Improved Dependency Compatibility** — Widened third-party SDK version constraints (VungleAds, FBAudienceNetwork, InMobiSDK) to prevent CocoaPods dependency conflicts when integrating alongside other mediation SDKs
- **Fullscreen Ad Reliability** — Fixed an issue where ad lifecycle callbacks could be silently lost in rare scenarios
- **iOS 16 Crash Fix** — Fixed a crash on iOS 16 devices related to session tracking

---

## [2.2.4] - 2026-03-26

### Changed
- **Server-Driven Location Controls** — Location coordinate sharing in bid requests is now controlled via the CloudX dashboard (account-scoped). No SDK code changes required for publishers.
- **Improved Bid Request Data** — Content language is now included in bid requests for improved ad targeting

---

## [2.2.3] - 2026-03-19

### Added
- **Unity Ads Adapter** — Unity Ads adapter now available for banner, interstitial, and rewarded ads

### Fixed
- **Unity Ads Initialization** — Fixed an issue where the Unity Ads adapter could fail to initialize correctly in some configurations

---

## [2.2.2] - 2026-03-16

### Added
- **Manual Privacy API** — New `setHasUserConsent:` and `setDoNotSell:` methods for publisher-controlled privacy consent
- **Mintegral Adapter** — Mintegral adapter now available as a standard release

### Fixed
- **Improved Error Visibility** — Increased error visibility for no-bid scenarios, making it easier to diagnose fill rate issues
- **Fullscreen Ad Loading** — Fixed an issue where loading a fullscreen ad while another was showing could silently fail
- **Fullscreen Failure Callbacks** — Fixed missing ad unit ID in fullscreen ad failure callbacks
- **Renderer Impression Tracking** — Fixed viewability tracking accuracy in CloudX Renderer

### Changed
- **Mintegral SDK** — Upgraded from 8.0.7 to 8.0.8

---

## [2.2.1-beta] - 2026-03-05

### Changed
- Internal improvements and stability enhancements

---

## [2.2.0-beta] - 2026-02-25

### Added
- **Adapter Init Error Tracking** - SDK now sends error events when adapter initialization fails
- **Win/Loss Payload Parity** - Aligned iOS win/loss notification payloads with Android

### Fixed
- **Duplicate didHideAd Callback** - Fixed fullscreen ads firing didHideAd twice on close
- **Adapter Code Resolution** - Fixed adaptercode resolution for SDK >= 2.1 after SSP ext.cloudx migration
- **Thread Safety** - Fixed thread safety crash in bid token dictionary construction
- **Double Revenue Callback** - Fixed CloudX renderer test rewarded ads firing revenue callback twice
- **Silent Failures** - Audited and fixed silent failures across core SDK
- **Adapter Creation Errors** - Real adapter creation errors now propagate through bid waterfall

### Deprecated
- `createBanner(adUnitId:viewController:)` — use `createBanner(adUnitId:)` instead. The SDK now resolves the presenting view controller automatically.
- `createMREC(adUnitId:viewController:)` — use `createMREC(adUnitId:)` instead. The SDK now resolves the presenting view controller automatically.

### Changed
- **JIT ViewController Resolution** - Banner/MREC ads now resolve the presenting view controller at use time instead of storing a weak reference
- **Removed Fullscreen Force-Close Timer** - Removed the timer-based force-close mechanism for fullscreen ads
- **Adapter Rewrites** - InMobi, Vungle, and Mintegral adapters fully rewritten
- **Removed Dead Code** - Cleaned up dead database code, endpoint config, A/B test code, and non-deterministic tests

---

## [2.1.0-beta] - 2026-02-10

### Fixed
- Fixed adapter xcframework builds failing with "duplicate interface definition" when CloudXCore is a dynamic framework dependency (added SKIP_INSTALL=YES to CloudXCore podspec)

### Changed
- Removed dead ENABLE_BITCODE=NO settings from all adapter Podfiles and build scripts (bitcode was removed by Apple in Xcode 14)

---

## [2.0.0] - 2026-02-04

This release replaces placement names with **Ad Unit IDs** from the CloudX dashboard. Update your `createBannerWithAdUnitId:`, `createMRECWithAdUnitId:`, `createInterstitialWithAdUnitId:`, and `createRewardedWithAdUnitId:` calls to use the ad unit ID instead of a placement name.

### Added
- Rewarded ads with `createRewardedWithAdUnitId:delegate:` and `CLXRewardedDelegate`
- InMobi adapter (SDK 11.1) with support for banner, MREC, interstitial, and rewarded ads
- `CLXAd.networkPlacement` property for network-specific placement ID

### Breaking Changes
- Renamed `placement` parameter to `adUnitId` in `createBannerWithAdUnitId:`, `createMRECWithAdUnitId:`, `createInterstitialWithAdUnitId:`, `createRewardedWithAdUnitId:`
- Renamed `CLXAd.placement` to `adUnitId`
- Renamed `CLXAd.bidderName` to `networkName`
- Renamed `CLXErrorCodeInvalidPlacement` to `CLXErrorCodeInvalidAdUnit`
- Changed `bannerAdView:didFailWithError:` to include ad unit ID in error
- Removed `testMode` parameter from `initializeSDKWithAppKey:completion:` - test mode is now server-controlled via dashboard

### Changed
- Meta Audience Network SDK updated from 6.17.0 to 6.21.0
- Vungle SDK updated from 7.4.2 to 7.6.0

### Fixed
- Fixed IFA (Identifier for Advertisers) collection
- Fixed country/geo-targeting data collection

---

## [1.3.0] - 2025-12-14

### Added
- **Banner Refresh Retry** - Banners now automatically retry loading after failure when hidden

### Fixed
- **App Extension Compatibility** - SDK now works correctly in App Extensions (no UIApplication calls)
- **Rewarded Delegate Callbacks** - Fixed callback ordering bug
- **Symbol Collisions** - All category methods now prefixed with `clx_` to prevent conflicts

### Changed
- **CloudXCore now distributed as Dynamic Framework** - Enables crash symbolication for SDK issues

---

## [1.2.1] - 2025-12-04

### Added
- **Visual Debugger Button** - New debugging tool for development and QA
- **High-ROI Key-Value Targeting Examples** - Enhanced demo apps with targeting signal examples

### Fixed
- Corrected vendored_frameworks paths in podspecs

---

## [1.2.0] - 2025-11-26

### 🚀 First Official Release

Initial release of the CloudX iOS SDK with support for banner, MREC, and interstitial ads.
