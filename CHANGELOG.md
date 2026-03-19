# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

*No unreleased changes*

---

## [2.2.3] - 2026-03-19

### Fixed
- **Unity Ads Network Name Casing** — Fixed case-sensitivity mismatch between server bidder config (`unityAds`) and SDK adapter registration (`unityads`), which prevented the Unity Ads adapter from receiving initialization parameters (e.g., `game_id`) (#444)

---

## [2.2.2] - 2026-03-16

### Added
- **Manual Privacy API** — `setHasUserConsent:` and `setDoNotSell:` for publisher-controlled privacy consent (#390)
- **Click Notifications** — SDK now sends click notifications to server (#430)
- **Session Init Event** — SDK sends session initialization event after SDK initialization (#431)
- **Adapter Metadata in Config** — Adapter metadata included in config/init requests (#439)
- **Non-Bid Error Reporting** — Parse seatNonBid and nbr for actionable no-bid diagnostics (#415)
- **Per-Metric Config Gating** — Individual metric types can be gated via server config (#440)
- **Mintegral Adapter** — Mintegral adapter promoted to standard release flow (#421)

### Fixed
- **Banner Error Propagation** — Preserve server diagnostic messages in banner error callbacks (#414)
- **Fullscreen Silent Load Failure** — Fix silent load failure when fullscreen ad is in SHOWING state (#412)
- **Fullscreen Failure Callbacks** — Fix nil adUnitId in fullscreen ad failure callbacks (#410)
- **Mintegral Deployment Target** — Aligned Mintegral adapter deployment target to iOS 13.0 (#429)
- **Mintegral Adapter Hardening** — Fixed privacy handling, init retry, and removed unnecessary dispatch wrapping (#419)
- **Renderer Impression Tracking** — Fixed viewability bugs in CloudX Renderer (#416)

### Changed
- **Geo Service Refactor** — Refactored geo service to align with cross-platform GeoApi/GeoService/GeoInfo architecture (#382)
- **ILRD Enhancements** — Added auction correlation and SDK identity to ILRD tracking (#437)
- **Mintegral SDK** — Upgraded from 8.0.7 to 8.0.8 (#420)
- **Removed Moloco Adapter** — Removed beta Moloco adapter from codebase (#428)

---

## [2.2.1-beta] - 2026-03-05

### Added
- **ILRD (Impression Level Revenue Data)** - Internal tracking of third-party impression-level revenue data for analytics (#405)

### Changed
- **Test Infrastructure** - Comprehensive test audit: separated integration tests from unit tests and enforced FIRST principles (#406)
- **Win/Loss Retry Tests** - Un-quarantined win/loss retry tests with mock network service (#408)

---

## [2.2.0-beta] - 2026-02-25

### Added
- **IDFV Tracking** - IDFV (ifv) now included in config init and bid requests for DAU/MAU analytics (#399)
- **Adapter Init Error Tracking** - SDK now sends error events when adapter initialization fails (#335)
- **Win/Loss Payload Parity** - Aligned iOS win/loss notification payloads with Android (#332)

### Fixed
- **Duplicate didHideAd Callback** - Fixed fullscreen ads firing didHideAd twice on close (#404)
- **Adapter Code Resolution** - Fixed adaptercode resolution for SDK >= 2.1 after SSP ext.cloudx migration (#402)
- **Thread Safety** - Fixed thread safety crash in bid token dictionary construction (#401)
- **Double Revenue Callback** - Fixed CloudX renderer test rewarded ads firing revenue callback twice (#394)
- **Silent Failures** - Audited and fixed silent failures across core SDK (#384)
- **Adapter Creation Errors** - Real adapter creation errors now propagate through bid waterfall (#387)

### Deprecated
- `createBanner(adUnitId:viewController:)` — use `createBanner(adUnitId:)` instead. The SDK now resolves the presenting view controller automatically. (#400)
- `createMREC(adUnitId:viewController:)` — use `createMREC(adUnitId:)` instead. The SDK now resolves the presenting view controller automatically. (#400)

### Changed
- **JIT ViewController Resolution** - Banner/MREC ads now resolve the presenting view controller at use time instead of storing a weak reference (#400)
- **Removed Fullscreen Force-Close Timer** - Removed the timer-based force-close mechanism for fullscreen ads (#403)
- **Adapter Rewrites** - InMobi (#381), Vungle (#380), and Mintegral (#379) adapters fully rewritten
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
