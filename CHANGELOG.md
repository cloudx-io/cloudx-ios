# CloudX iOS SDK Changelog

## [1.2.0] - TBD

### Major Breaking Change: Public API No Longer Returns `nil`

#### Overview
**All public SDK `create` methods now ALWAYS return a non-nil object.** Validation errors that previously resulted in `nil` returns are now deferred and reported via delegate callbacks when `load()` is called.

This brings iOS behavior into full parity with industry-standard SDKs and improves error handling consistency.

#### What Changed

##### Public API Methods (CloudXCore)
- `createBannerWithPlacement:viewController:delegate:` - Now ALWAYS returns non-nil `CLXBannerAdView`
- `createMRECWithPlacement:viewController:delegate:` - Now ALWAYS returns non-nil `CLXBannerAdView`
- `createInterstitialWithPlacement:` - Now ALWAYS returns non-nil `CLXInterstitial`
- `createRewardedWithPlacement:` - Now ALWAYS returns non-nil `CLXRewarded`

##### Error Handling
- Validation errors (missing placement, no adapters registered, etc.) are now reported via delegate methods:
  - Banner/MREC: `failToLoadWithAd:error:` (from `CLXAdDelegate` protocol)
  - Interstitial: `failToLoadWithAd:error:` (from `CLXAdDelegate` protocol)
  - Rewarded: `failToLoadWithAd:error:` (from `CLXAdDelegate` protocol)

##### Internal Changes
- **All adapter factories** (`CLXMolocoBannerFactory`, `CLXMetaBannerFactory`, `CLXInMobiBannerFactory`, `CLXVungleBannerFactory`, etc.) now ALWAYS return non-nil adapter instances
- **All adapters** defer validation to their `load()` method
- Added `deferredError` property to `CLXPublisherBanner` and `CLXPublisherFullscreenAdBase` for validation error handling
- Created `CLXAdapterErrorMapper` utility for standardized error code mapping

#### Migration Guide

**Before (v1.1.x):**
```objc
CLXBannerAdView *banner = [[CloudXCore shared] createBannerWithPlacement:@"placement_id"
                                                             viewController:self
                                                                   delegate:self];
if (!banner) {
    NSLog(@"Failed to create banner");
    return;
}
[self.view addSubview:banner];
[banner load];
```

**After (v1.2.0):**
```objc
// create() now ALWAYS returns non-nil
CLXBannerAdView *banner = [[CloudXCore shared] createBannerWithPlacement:@"placement_id"
                                                             viewController:self
                                                                   delegate:self];
[self.view addSubview:banner];
[banner load];  // Errors reported via delegate

// Handle errors in delegate method:
- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"Banner load failed: %@", error.localizedDescription);
}
```

#### Benefits

1. **Simpler Integration**: No nil checks required after `create()` calls
2. **Better Error Messages**: Validation errors include detailed context and error codes
3. **Consistent Behavior**: Matches behavior of modern ad SDKs
4. **Pre-initialization Support**: Can create ads before SDK initialization completes - they queue automatically

#### Affected Adapters

All adapters have been refactored to support this pattern:
- ✅ Moloco (Banner, Interstitial, Rewarded, Native)
- ✅ Meta (Banner, Interstitial, Rewarded, Native)
- ✅ InMobi (Banner, Interstitial, Rewarded, Native)
- ✅ Vungle (Banner, Interstitial, Rewarded, Native, AppOpen)

#### Backward Compatibility

The `nullable` annotations remain on public API methods for backward compatibility, but in practice, `nil` will never be returned in v1.3.0+. Publishers should update their integration code to remove nil checks.

---

## [1.2.0] - Previous Release

(Previous changelog entries...)

