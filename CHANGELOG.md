# CloudX iOS SDK Changelog

All notable changes to the CloudX iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## Mintegral adapter 8.1.3.0 - 2026-08-28

Install: `pod 'CloudXMintegralAdapter', '8.1.3.0'`

Compatibility-line release for apps pinned to MintegralAdSDK 8.1.3. New integrations should use the 8.1.5.x line.

### Changed
- **Backport of the 8.1.5.0 adapter for MintegralAdSDK 8.1.3** — Same Banner, MREC, Interstitial, Rewarded, Native and App Open support, built against MintegralAdSDK 8.1.3. Requires `CloudXCore >= 3.5.0`.

---

## TaurusX adapter 1.18.2.0 - 2026-08-28

Install: `pod 'CloudXTaurusXAdapter', '~> 1.18.2.0'`

### Changed
- **Certified with TaurusX SDK 1.18.2** — Updates the bundled TaurusX SDK from 1.18.1. No integration change is required: `CloudXCore >= 3.5.0` and iOS 13.0 are unchanged from `1.18.1.0`, and the supported formats (Banner, MREC, Interstitial, Rewarded, Native) are unchanged.

---

## Singular connector 12.6.0.0 - 2026-08-26

### Added
- **`CloudXSingularConnector` 12.6.0.0** — Forwards CloudX ad revenue to Singular automatically, once per won impression, all formats. Install: `pod 'CloudXSingularConnector', '~> 12.6.0.0'`. Requires `CloudXCore >= 3.6.0` and your existing Singular integration (`Singular-SDK >= 12.6.0`).
- **Reports `CloudX` as the ad platform** — The winning bidder rides in the network-name field, and ad-format names match the Android connector, so cross-platform Singular reports group into one bucket per format.

---

## GAM Prebid integration 1.0.0 - 2026-08-26

Install: `pod 'CloudXGAMPrebid', '~> 1.0'`

### Added
- First release, for publishers who run Google Ad Manager as their primary ad server. Run a CloudX auction, attach the returned key-values to your own GAM request, and let GAM decide. Banner, MREC, interstitial, rewarded and native are supported.
- Requires CloudXCore >= 3.8.0 and Google Mobile Ads SDK 13.x (`~> 13.0`). GMA is weak-linked — your app supplies and initializes it, and the pod is never bundled with a copy.
- Calling `notifyGamResponse:` on every GAM load success and `notifyGamRequestFailed` on every failure is required. Skip either and the auction settles on its TTL as an expiry, losing the real outcome and the GAM response id that joins it to your Ad Manager reporting.
- A GAM load that resolves to a different ad no longer tears down the creative GAM is still displaying, and a loss between dispatch and show no longer fails the pending fullscreen ad. Dispatch is validated before the ad is claimed (`CLXGamTokenRegistry`, `CLXGamAdFormat`).

---

## MobileFuse adapter 1.11.0.1 - 2026-08-24

Install: `pod 'CloudXMobileFuseAdapter', '~> 1.11.0.1'`

### Fixed
- **Reading the MobileFuse SDK version no longer blocks the calling thread** — Removes a stall on the bid-token path. MobileFuseSDK 1.11.0 and `CloudXCore >= 3.5.0` are unchanged.

---

## Google Waterfall adapter 12.14.0.3 - 2026-08-26

Install: `pod 'CloudXGoogleWaterfallAdapter', '12.14.0.3'`

Compatibility-line release for apps pinned to Google Mobile Ads SDK 12.14.0. New integrations should use the 13.6.0.x line.

### Changed
- **Google adapter startup no longer delays CloudX SDK initialization** — Same change as 13.6.0.4, for Google Mobile Ads SDK 12.14.0. Requires `CloudXCore` 3.7.0 or newer.

---

## Google Waterfall adapter 13.6.0.4 - 2026-08-26

Install: `pod 'CloudXGoogleWaterfallAdapter', '~> 13.6.0.4'`

### Changed
- **Google adapter startup no longer delays CloudX SDK initialization** — The Google Mobile Ads SDK now starts in the background instead of holding up your `initialize` call. A missing `GADApplicationIdentifier` in your Info.plist still fails initialization straight away.
- **An ad requested in the moment right after initialization may no-fill once** — Google demand is ready as soon as its background start finishes. A request landing before then returns a fast no-fill for that one request instead of waiting, and the next request is served normally.
- **Requires Google Mobile Ads SDK 13.6.0 exactly** — Requires `CloudXCore` 3.7.0 or newer.

---

## Google Waterfall adapter 13.6.0.3 - 2026-08-21

Install: `pod 'CloudXGoogleWaterfallAdapter', '~> 13.6.0.3'`

### Changed
- **Fullscreen ads now prefetch through Google's ad-preloading API** — Interstitial, rewarded, and app-open ads are preloaded by the Google Mobile Ads SDK, not the adapter; `CLXGoogleWaterfallFullscreenLoader` is removed. Banner, MREC, and native are unchanged, and no publisher action is needed.
- **Requires Google Mobile Ads SDK 13.6.0 exactly** — The preloading API is only available on that version, so the adapter pins it. Requires `CloudXCore >= 3.7.0`.

---

## InMobi adapter 11.4.1.0 - 2026-08-18

Install: `pod 'CloudXInMobiAdapter', '~> 11.4.1.0'`

### Changed
- **Improved audio handling for MRAID 3 creatives** — Certified with InMobiSDK 11.4.1, which resolves cases where an ad could interrupt audio your app was already playing.
- **No integration change required** — `CloudXCore >= 3.5.0` and iOS 13.0 are unchanged from `11.3.0.0`.

---

## Meta adapter 6.22.0.0 - 2026-08-12

Install: `pod 'CloudXMetaAdapter', '~> 6.22.0.0'`

### Changed
- **Requires iOS 15** — Certified with Meta Audience Network 6.22.0, which requires iOS 15.0. Apps that still support iOS 13 or 14 should stay on `CloudXMetaAdapter 6.21.1.0`, which keeps working with the current CloudX SDK and every other network.
- **New Meta ad formats** — Audience Network 6.22 adds eCommerce and catalog formats, chained ads on iOS, and playable improvements. Meta serves these; no integration change is needed beyond updating the adapter.

---

## Google Waterfall adapter 13.6.0.2 - 2026-08-11

### Added
- **Google Ad Manager demand** — `CLXGoogleWaterfallPlacementTypeGam` placements load via the GAM request surface (banner, MREC, interstitial); revenue measured from realized GAM revenue history. Install: `pod 'CloudXGoogleWaterfallAdapter', '~> 13.6.0.2'`; requires `CloudXCore >= 3.7.0`.

### Changed
- **Realized-price bookkeeping moved into `CloudXCore`** — The adapter's `CLXGoogleWaterfallRealizedPriceStore` header is removed; `CloudXCore` 3.7.0 now keeps this history using the same storage keys. No publisher action needed.

---

## Google Waterfall adapter 12.14.0.2 - 2026-08-11

### Added
- **Google Ad Manager demand (12.14.0)** — Same support as 13.6.0.2 (`CLXGoogleWaterfallPlacementTypeGam` placements; `CLXGoogleWaterfallRealizedPriceStore` now in core), for Google Mobile Ads SDK 12.14.0. Install: `pod 'CloudXGoogleWaterfallAdapter', '12.14.0.2'`; requires `CloudXCore >= 3.7.0`.

---

## TaurusX adapter 1.18.1.0 - 2026-08-03

### Added
- **TaurusX adapter released** — `CloudXTaurusXAdapter` 1.18.1.0 (`TaurusxAdsSDK = 1.18.1`, requires `CloudXCore >= 3.5.0`). Supports Banner, MREC, Interstitial, Rewarded, and Native ads. Install: `pod 'CloudXTaurusXAdapter', '~> 1.18.1.0'`.

---

## Adjust connector 5.0.0.0 - 2026-08-04

### Added
- **`CloudXAdjustConnector` 5.0.0.0** — Forwards CloudX ad revenue to Adjust automatically, once per won impression, all formats. Install: `pod 'CloudXAdjustConnector', '~> 5.0.0.0'`. Requires `CloudXCore >= 3.6.0` and your existing Adjust integration (`Adjust >= 5.0.0`).
- **Removed pre-release symbols** — `CloudXAdjustConnectorVersionNumber` and `CloudXAdjustConnectorVersionString` were dropped before first publication; `CLXAdjustConnectorVersion` reports the version. No consumer impact.

---

## Pangle adapter 8.2.0.7.0 - 2026-07-30

### Changed
- **Pangle** `CloudXPangleAdapter` → `~> 8.2.0.7.0` (Ads-Global 8.2.0.7). Install: `pod 'CloudXPangleAdapter', '~> 8.2.0.7.0'`; requires `CloudXCore >= 3.5.0`.

---

## AppsFlyer connector 6.15.0.0 - 2026-08-03

### Added
- **`CloudXAppsFlyerConnector` 6.15.0.0** — Forwards CloudX ad revenue to AppsFlyer automatically, once per won impression, all formats. Install: `pod 'CloudXAppsFlyerConnector', '~> 6.15.0.0'`. Requires `CloudXCore >= 3.6.0` and your existing AppsFlyer integration.
- **Removed pre-release symbols** — `CloudXAppsFlyerConnectorVersionNumber` and `CloudXAppsFlyerConnectorVersionString` were dropped before first publication; `CLXAppsFlyerConnectorVersion` reports the version. No consumer impact.

## Google Waterfall adapter 12.14.0.1 - 2026-07-29

### Fixed
- **Prefetched Google ads could be shown after expiring (12.14.0)** — Backport of the 13.6.0.1 fix for Google Mobile Ads SDK 12.14.0; fills now expire and refresh before stale, preventing blank renders. Install: `pod 'CloudXGoogleWaterfallAdapter', '12.14.0.1'`; requires `CloudXCore >= 3.5.0`.

---

## [Unreleased]

### Added
- **Global ad-revenue delegate** — New `+[CloudXCore addAdRevenueDelegate:]` / `removeAdRevenueDelegate:` API registers a global `CLXAdRevenueDelegate` that fires for every CloudX-won impression across all ad objects and formats — the surface analytics and MMP SDKs attach to, with no per-ad wiring.
- **AppsFlyer ad-revenue connector** — New `CloudXAppsFlyerConnector` pod automatically forwards impression-level ad revenue for every CloudX-won impression (Banner, MREC, Interstitial, Rewarded, Native, App Open) to AppsFlyer. Add `pod 'CloudXAppsFlyerConnector'` to your Podfile; the module self-registers onto the global ad-revenue delegate at load — no publisher glue code — and stays inert if your app doesn't use AppsFlyer. Requires `CloudXCore >= 3.6.0` and `AppsFlyerFramework >= 6.15.0`: the integrated `logAdRevenue` API was introduced in AppsFlyer SDK 6.15.0, and AppsFlyer 6.14.x and below use a separate legacy AdRevenue connector that this module does not consume. If an older AppsFlyer is linked at runtime, the module logs a skip and never crashes.

---

## [3.8.0] - 2026-08-24

Install: `pod 'CloudXCore', '~> 3.8'`

### Added
- **Video in banner and MREC ads now starts muted** — Video creatives in banner and MREC placements begin playback muted; a creative can only unmute in response to a user tap on its own controls.
### Fixed
- **Revenue and click callbacks always delivered** — Ads with incomplete bid metadata could serve and earn while the revenue and click callbacks were silently skipped. These callbacks now always fire, so your ILRD matches CloudX reporting.
- **Calling `load()` on a visible banner no longer leaks the replaced ad** — Publisher-driven banner/MREC refresh via `load()` leaked the previous ad's web view and media resources for the rest of the session. The replaced ad now tears down correctly.
- **Video impressions tracked when viewability measurement fails to start** — Some VAST video ads rendered and played but were never counted as impressions. They now bill and fire their tracking beacons correctly.
- **Long tracking URLs no longer dropped** — VAST tracking beacons with URLs up to 10KB now fire; previously URLs over 2KB were silently dropped.
- **Faster handling of concurrent network responses** — Network completions are no longer processed one at a time, so one slow response can no longer delay other finished requests during init and bidding.

---

## [3.7.0] - 2026-08-11

Install: `pod 'CloudXCore', '~> 3.7'`

### Added
- **AdMob and Google Ad Manager bids in the Trusted Arbiter** — New `CLXArbiterBid` factories `adMob(adUnitId:)` and `gam(adUnitId:)`, no price required: CloudX prices the bid from revenue reported via `reportRevenueData`. Optional per-impression USD override.
- **`CLXRevenuePlatformGAM`** — Report Google Ad Manager revenue through `reportRevenueData`; GAM paid events now also feed arbiter bid pricing.

### Changed
- **Adapter-facing `CLXBidRoute` native routing** — Headers used by CloudX adapters gained native routing support (`CLXBidRoute`, `CLXNativeParsedAdKey`). Internal to CloudX adapters; no publisher action needed.

### Fixed
- **Core-only integrations initialize again** — Apps integrating `CloudXCore` with no adapter pods failed to initialize (error 201) and could not run auctions. Both now work.
- **Banner and MREC views no longer leak** — Auto-refreshing inline ad views could be retained for the rest of the session, causing unbounded memory growth in long-running apps. They now release correctly.
- **Releasing an ad without `destroy()` now cleans up** — Dropping your last reference to an ad object without calling `destroy()` now tears down the ad and its resources; previously they leaked silently.
- **Rare crash during ad cleanup fixed** — A narrow internal race could abort the process while an ad's resources were being released.
- **Portrait native creatives render at their reported aspect ratio** — Vertical (e.g. 9:16) creatives in the SDK native template no longer appear letterboxed in a landscape box. The template view for a portrait creative is now taller (320x548 instead of 320x250).
- **No-bid auctions no longer log at ERROR** — A normal no-bid outcome now logs at DEBUG, so error logs and crash-tooling alerts only reflect genuine failures.

---

## [3.6.0] - 2026-07-28

Install: `pod 'CloudXCore', '~> 3.6'`

### Added
- **Report impression-level revenue from your own mediation platform** — Forward paid events to CloudX with `reportRevenueData(_:)`. AdMob, InMobi, and TopOn are built in.
- **App-wide ad-revenue delegate** — Receive impression-level revenue for every CloudX-won impression from one `CLXAdRevenueDelegate` instead of per ad. Register with `addAdRevenueDelegate(_:)`.
- **AppsFlyer ad-revenue connector** — Forward CloudX impression revenue to AppsFlyer. Install: `pod 'CloudXAppsFlyerConnector', '~> 1.0.0'`. Requires `AppsFlyerFramework >= 6.15.0`.
- **Adjust ad-revenue connector** — Forward CloudX impression revenue to Adjust. Install: `pod 'CloudXAdjustConnector', '~> 1.0.0'`. Requires `Adjust >= 5.0.0`.

### Fixed
- **Banner and MREC creatives could render blank on the CloudX renderer** — Creatives could fail on first load and after refresh, surfacing as blank impressions. They now render correctly.
- **HTML rewarded creatives were rejected on the CloudX renderer** — The renderer accepted only VAST rewarded creatives, so HTML rewarded ads failed to load. HTML rewarded creatives now render.

### Removed
- **Internal headers removed from the `CloudXCore.h` umbrella** — Internal implementation headers were removed from the umbrella; none was linkable, so no integration is affected. Report revenue through `reportRevenueData(_:)` and the public revenue types.

---

## Google Waterfall adapter 13.6.0.1 - 2026-07-21

### Fixed
- **Prefetched Google ads could be shown after they expired** — Prefetched fills now expire and refresh in the background before going stale, preventing blank renders. Install: `pod 'CloudXGoogleWaterfallAdapter', '~> 13.6.0.1'`. Requires `CloudXCore >= 3.5.0`.

---

## Off-line adapter releases (-core34) - 2026-07-16

Off-line builds of three adapters for publishers still on `CloudXCore` 3.4.x. Each works with `CloudXCore` 3.4.5 or 3.4.6 and is **not** compatible with `CloudXCore` 3.5.x.

- **Google Waterfall** — `pod 'CloudXGoogleWaterfallAdapter', '13.0.0.0-core34'`. Backed by Google Mobile Ads SDK 13.0.0. Requires `CloudXCore >= 3.4.6, < 3.5` (works with 3.4.6, not 3.5.x).
- **Unity Ads** — `pod 'CloudXUnityAdsAdapter', '4.16.5.0-core34'`. Backed by UnityAds 4.16.5. Requires `CloudXCore >= 3.4.5, < 3.5` (works with 3.4.5/3.4.6, not 3.5.x). Reward is granted on completed ad watch; UnityAds 4.16.5 provides no ad-expiry callback, so expired creatives are not signaled.
- **Moloco** — `pod 'CloudXMolocoAdapter', '4.3.0.0-core34'`. Backed by MolocoSDKiOS 4.3.0. Requires `CloudXCore >= 3.4.5, < 3.5` (works with 3.4.5/3.4.6, not 3.5.x).

---

## MobileFuse adapter 1.11.0.0 - 2026-07-08

### Added
- **MobileFuse adapter** — New `CloudXMobileFuseAdapter` serving Banner, MREC, Interstitial, and Rewarded. Install: `pod 'CloudXMobileFuseAdapter', '~> 1.11.0.0'`. Backed by MobileFuse SDK 1.11.0; requires `CloudXCore >= 3.5.0`.

---

## [3.5.0] - 2026-07-07

Adapters now version independently of `CloudXCore`. Each adapter pod uses `<network-sdk-version>.<adapter-revision>` (e.g. `pod 'CloudXVungleAdapter', '~> 7.7.4.0'`) and is tied to one exact network SDK version per release. `CloudXCore` continues on SDK semver (`pod 'CloudXCore', '~> 3.5'`).

### Breaking Changes
- **Adapter pods no longer share the `CloudXCore` version.** Existing pins on the old unified line (`~> 3.4`, `~> 3.x`) will not resolve new adapter releases. Update each adapter pin independently, for example `pod 'CloudXMintegralAdapter', '~> 8.1.5.0'`.
- **`CloudXMagniteAdapterV2` replaces `CloudXMagniteAdapter` for independent versioning.** Install `pod 'CloudXMagniteAdapterV2', '~> 1.0.0.0'` to move to the new version line; the legacy pod remains on the old line. No source changes — the import name is unchanged.
- **`CloudXRenderer` is no longer a separate pod.** Its functionality is built into `CloudXCore`; remove any direct `CloudXRenderer` dependency from your Podfile.

### Added
- **App Open ad format** — New `CLXAppOpen` ad class for full-screen ads shown while your app loads or returns to the foreground. Create with `createAppOpen(adUnitId:)`. Supported on the Google Waterfall, Mintegral, Pangle, and Vungle adapters.
- **VAST video interstitials and rewarded on the CloudX renderer** — The CloudX renderer now serves VAST video interstitial and rewarded creatives, with Open Measurement (OMID) video measurement. Rollout is controlled server-side; no integration change is required.
- **HTML rewarded on the CloudX renderer** — HTML rewarded creatives now render through the CloudX renderer, completing the fullscreen HTML support introduced for interstitials in 3.4.5. Server-side rollout; no integration change required.
- **Native ads on Digital Turbine, Mintegral, Pangle, Verve, and Google Waterfall** — These adapters now serve Native creatives, standalone and native-in-banner / native-in-MREC.
- **Google Waterfall — Interstitial and Rewarded** — `CloudXGoogleWaterfallAdapter` now serves fullscreen Interstitial and Rewarded creatives, in addition to Banner, MREC, Native, and App Open.
- **In-app App Store sheet for install-ad clickthroughs** — Tapping an install-campaign ad now opens an in-app App Store product sheet instead of leaving your app, for CloudX-rendered creatives that declare the advertised app.
- **Fullscreen HTML interstitial clickthrough** — Fullscreen HTML interstitials rendered by the CloudX renderer now navigate on tap.
- **`CloudXMagniteAdapterV2` 1.0.0.1** — the new independent-versioned Magnite pod. Install: `pod 'CloudXMagniteAdapterV2', '~> 1.0.0.0'`. Backed by MagniteSDK 1.0.0.

### Changed — Adapter releases
- **Vungle** `CloudXVungleAdapter` → `~> 7.7.4.0` (VungleAds 7.7.4).
- **Mintegral** `CloudXMintegralAdapter` → `~> 8.1.5.0` (MintegralAdSDK 8.1.5).
- **Unity Ads** `CloudXUnityAdsAdapter` → `~> 4.19.0.0` (UnityAds 4.19.0).
- **Verve** `CloudXVerveAdapter` → `~> 3.9.0.0` (HyBid 3.9.0).
- **Digital Turbine** `CloudXDigitalTurbineAdapter` → `~> 8.4.8.0` (Fyber Marketplace SDK 8.4.8).
- **Google Waterfall** `CloudXGoogleWaterfallAdapter` → `~> 13.6.0.0` (Google Mobile Ads SDK 13.6.0 — a major-version upgrade from 12.x).
- **InMobi** `CloudXInMobiAdapter` → `~> 11.3.0.0` (InMobiSDK 11.3.0).
- **Meta** `CloudXMetaAdapter` → `~> 6.21.1.0` (FBAudienceNetwork 6.21.1).
- **Moloco** `CloudXMolocoAdapter` → `~> 4.8.0.0` (MolocoSDKiOS 4.8.0).
- **Pangle** `CloudXPangleAdapter` → `~> 7.9.1.3.0` (Ads-Global 7.9.1.3).

### Fixed
- **Some bidders were not billed for certain banner impressions** — Native ads rendered in a banner slot (native-in-banner) could be counted without the bidder billing notice, so the bidder was never billed. Impressions are now billed correctly in all cases.
- **Native ads in a banner or MREC slot could report their impression too early** — A native ad in a banner or MREC slot could fire its impression before the ad view was actually visible, especially when preloading off-screen. Impressions now report at the correct time.
- **Stuck fullscreen ad after a rendering crash** — If the web content behind a fullscreen ad crashed after the ad loaded, the user could be left on a stuck fullscreen. The ad now closes automatically and delivers the close callback.
- **Native ads in banner slots could miss impressions with compact layouts** — Fixed an issue where a native ad rendered in a banner slot with the compact template could display without registering an impression.

### Removed
- **`CloudXRenderer` standalone pod** — merged into `CloudXCore`. See Breaking Changes above.

---

## [3.4.6] - 2026-06-29

### Changed
- **`CloudXMolocoAdapter` now supports the full MolocoSDK 4.x line** — The `MolocoSDKiOS` requirement was widened from `~> 4.6.0` to `>= 4.6.0, < 5.0`, so you can adopt newer 4.x Moloco SDK releases. This resolves a CocoaPods dependency conflict that could block integration.

### Fixed
- **Rare crash when an ad finished loading** — Fixed a rare crash that could occur when a banner or fullscreen (interstitial / rewarded) ad finished loading. Affected ads now load and report their result reliably.
- **Duplicate banner impressions after a no-fill refresh** — A banner whose auto-refresh returned no bid could re-display the previous creative and count extra impressions. A no-bid refresh now shows nothing and reports no impression.

---

## [3.4.5] - 2026-06-12

### Added
- **InMobi native ads** — `CloudXInMobiAdapter` now serves Native creatives, both standalone (via `CLXNativeAdLoader`) and native-in-banner / native-in-MREC. Requires `InMobiSDK >= 11.2.0` (the adapter's minimum was raised from `11.0.0`).
- **Vungle standalone native ads** — `CloudXVungleAdapter` now serves standalone Native creatives via `CLXNativeAdLoader` (native-in-banner / native-in-MREC was already supported).
- **HTML interstitials on the CloudX renderer** — The CloudX renderer now supports fullscreen HTML interstitial creatives with MRAID 3.0, alongside the existing HTML banner / MREC support. Rollout is controlled server-side; no integration change is required.

### Changed
- **Slow ad network SDKs no longer delay CloudX SDK initialization** — A slow network SDK no longer blocks init; CloudX completes without it and the network joins later auctions once ready. Networks not yet initialized are excluded from auctions they cannot serve.

### Fixed
- **Digital Turbine adapter no longer conflicts with another mediation SDK initializing the Fyber SDK** — If another mediation SDK initializes the shared Fyber SDK first, the CloudX adapter now defers instead of re-initializing. For smooth startup, initialize the other SDK first, then CloudX.
- **Some valid HTML banner creatives were rejected by the renderer** — Fixed an issue where HTML banner / MREC creatives containing failed tracker pixels (e.g. some Media.net creatives) were misclassified as broken and not displayed. These creatives now render normally.
- **Native ad reliability improvements on Meta and Moloco** — Meta native ads now validate the loaded ad and register all asset views for impression and click tracking, not just the CTA. Moloco native ads are no longer delivered when the underlying ad is not renderable.

### Removed
- **Adapter-integration APIs** — Removed `clx_isFlexibleSize`, `+isInitialized`, and per-instance `sdkVersion` from the adapter-facing surface. These had no function for app integrations; standard publisher integrations are unaffected.

---

## [3.4.4] - 2026-06-02

### Fixed
- **Digital Turbine adapter failed to link on Fyber Marketplace SDK below 8.4.0** — The adapter binary failed to link on a Fyber SDK below `8.4.0`. It now links across the full `8.x` line — Banner, MREC, Interstitial, and Rewarded work on Fyber `8.0.0`+; native fill remains on `8.4.0`+.
- **Google Waterfall — occasional lost fills on slow mediation responses** — A Google Waterfall ad could be discarded when its mediation cascade responded slowly, even though it ultimately filled. Slow-but-successful responses are now delivered, improving fill reliability.

---

## [3.4.3] - 2026-06-01

### Added
- **Pangle Adapter** — New `CloudXPangleAdapter` supporting Banner/MREC, Interstitial, and Rewarded ad formats. Install via CocoaPods (`pod 'CloudXPangleAdapter', '~> 3.4.3'`). Backed by the Pangle (ByteDance) SDK `Ads-Global ~> 7.9.0`.

### Changed
- **DigitalTurbine adapter — broader Fyber Marketplace SDK compatibility** — `CloudXDigitalTurbineAdapter` now accepts `Fyber_Marketplace_SDK` from `8.0.0` (previously `>= 8.4.0`). Banner, MREC, Interstitial, and Rewarded work across the full 8.x line; native fill remains on Fyber SDK 8.4.0+.

### Fixed
- **App Store submission rejection caused by the `itms-services` URL scheme** — Some publishers received an App Store static-analysis rejection because the SDK binary contained the `itms-services` scheme. The scheme has been removed; legitimate store redirect creatives still resolve normally.
- **SDK initialization could fail for some accounts** — Fixed an issue where SDK initialization could fail for publisher accounts that have no organization identifier. Initialization now completes normally for these accounts.

---

## [3.4.2] - 2026-05-29

### Added
- **Google Waterfall Adapter** — New `CloudXGoogleWaterfallAdapter` supporting Banner (320×50) and MREC (300×250). Install: `pod 'CloudXGoogleWaterfallAdapter', '~> 3.4.2'` or SPM. Backed by `Google-Mobile-Ads-SDK 12.14.0`; requires a `GADApplicationIdentifier` in your Info.plist.

---

## [3.4.1] - 2026-05-27

### Added
- **Digital Turbine Adapter** — New `CloudXDigitalTurbineAdapter` supporting Banner, MREC, Interstitial, Rewarded, and Native ad formats. Install: `pod 'CloudXDigitalTurbineAdapter', '~> 3.4.1'`. Backed by `Fyber_Marketplace_SDK >= 8.4.0, < 9.0`.

### Fixed
- **Duplicate `didLoadAd` / `didShowAd` callbacks on banner refresh** — When a partner adapter SDK fired its load or impression callback more than once, publishers could receive duplicates. The first callback is now canonical and re-fires are dropped, so one load and one impression emit per ad.

---

## [3.4.0] - 2026-05-22

### Added
- **Verve Adapter** — New `CloudXVerveAdapter` (Banner, MREC, Interstitial, Rewarded, Native). Install: `pod 'CloudXVerveAdapter', '~> 3.4.0'`. Backed by HyBid 3.8.0.
- **Moloco Adapter** — New `CloudXMolocoAdapter` (Banner, MREC, Interstitial, Rewarded, Native). Install: `pod 'CloudXMolocoAdapter', '~> 3.4.0'`. Backed by MolocoSDKiOS `~> 4.6.0`.
- **Non-SDK CloudX-rendered HTML banner and MREC with MRAID 3.0** — HTML banner and MREC creatives can now be served through the CloudX renderer, with MRAID 3.0 support.
- **Native-in-banner and native-in-MREC support** — Native creatives can be served into banner or MREC slots on Meta, Vungle, and Moloco.
- **Per-request extras across all ad-format APIs** — New `setExtraParameter:value:` API on `CLXBanner` / `CLXBannerAdView`, `CLXFullscreenAd`, and `CLXNativeAdLoader` attaches per-request metadata to bid requests, including reserved `minFloor` and `minFloors` floor keys.
- **`CLXAd.adValues` property** — New read-only `NSDictionary<NSString *, NSString *>` exposing SDK-defined loaded-ad metadata. Values may be absent depending on ad format and network.

### Changed
- **UnityAds adapter version range** — Widened to accept Unity Ads 4.x patch releases (`>= 4.17.0`, `< 5.0`) so publishers can adopt newer Unity Ads SDK fixes without waiting for an adapter release.
- **Publisher delegate main-queue threading is now documented contract** — All `CLXAdDelegate` and `CLXAdRevenueDelegate` callbacks deliver on the main queue and may fire inline relative to the SDK call that triggered them. No runtime change; re-entrant delegate implementations are unaffected.

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
