# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

*No unreleased changes*

---

## [3.2.0] - 2026-04-22

### Added
- **Magnite Adapter** — New `CloudXMagniteAdapter` supporting Banner (320x50), MREC (300x250), Interstitial, and Rewarded ad formats via `MagniteSDK`. Install via `pod 'CloudXMagniteAdapter', '~> 3.2.0'`. Includes IAB TCF (GDPR) and CCPA privacy handling.

### Fixed
- **`winLossNotificationURL` tolerance** — Fixed an issue where an explicitly empty `winLossNotificationURL` in the SDK initialization response could prevent the SDK from initializing cleanly. An empty string now disables win/loss tracking gracefully, consistent with how missing fields are handled.

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
