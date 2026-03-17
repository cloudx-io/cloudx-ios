# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

*No unreleased changes*

---

## [2.2.2] - 2026-03-16

### Added
- **Manual Privacy API** — `setHasUserConsent:` and `setDoNotSell:` for publisher-controlled privacy consent
- **Click Notifications** — SDK now sends click notifications to server
- **Session Init Event** — SDK sends session initialization event after SDK initialization
- **Adapter Metadata in Config** — Adapter metadata included in config/init requests
- **Non-Bid Error Reporting** — Actionable no-bid error diagnostics via seatNonBid parsing
- **Per-Metric Config Gating** — Individual metric types can be gated via server config
- **Unity Ads Adapter** — New adapter for Unity Ads with interstitial, rewarded, and banner support
- **Mintegral Adapter** — Mintegral adapter promoted to standard release flow

### Fixed
- **Banner Error Propagation** — Preserve server diagnostic messages in banner error callbacks
- **Fullscreen Silent Load Failure** — Fix silent load failure when fullscreen ad is in SHOWING state
- **Fullscreen Failure Callbacks** — Fix nil adUnitId in fullscreen ad failure callbacks
- **Mintegral Deployment Target** — Aligned Mintegral adapter deployment target to iOS 13.0
- **Mintegral Adapter Hardening** — Fixed privacy handling, init retry, and removed unnecessary dispatch wrapping
- **Renderer Impression Tracking** — Fixed viewability bugs in CloudX Renderer

### Changed
- **Geo Service Refactor** — Refactored geo service architecture for cross-platform alignment
- **ILRD Enhancements** — Added auction correlation and SDK identity to ILRD tracking
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
