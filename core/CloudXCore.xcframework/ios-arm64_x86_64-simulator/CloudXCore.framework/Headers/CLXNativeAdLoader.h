/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXAdapterNativeVideoOptions.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXNativeAdView;
@protocol CLXNativeAdDelegate;
@protocol CLXAdRevenueDelegate;

/**
 * Loads and manages native ads for a single ad unit.
 *
 * @note Native ads currently only support Meta Audience Network (FAN).
 *       Loading a native ad unit whose winning bid comes from an unsupported
 *       adapter will fail with a load error. Additional adapter support
 *       (Mintegral, Pangle, etc.) is planned for future releases.
 */
CLX_PUBLIC
@interface CLXNativeAdLoader : NSObject

#pragma mark - Properties

@property (nonatomic, weak, nullable) id<CLXNativeAdDelegate> nativeAdDelegate;
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;
@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *customData;
@property (nonatomic, copy, readonly) NSString *adUnitIdentifier;

#pragma mark - Video Configuration

/**
 * Video configuration properties control playback behavior for native video ads.
 *
 * These properties are adapter-dependent. Not all adapters support native video
 * or honor these settings. When the winning adapter does not support a given
 * property, the value is silently ignored — no error is raised.
 *
 * Currently supported by: Meta Audience Network (FAN).
 * All properties must be set before calling loadAd.
 */

/**
 * When YES, prevents video ads from entering fullscreen when tapped.
 * Default is NO (fullscreen enabled).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL disableVideoFullScreen;

/**
 * When YES, starts video playback with sound on.
 * Default is NO (muted).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL startVideoUnmuted;

/**
 * When YES, hides video media controls (play/pause, mute/unmute).
 * Default is NO (controls visible).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL hideVideoMediaControls;

#pragma mark - Initialization

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Ad Loading

/**
 * Load a native ad. If the ad unit is configured for template rendering server-side,
 * the SDK creates a template view and delivers it via the delegate (Flow A).
 * Otherwise, the view parameter in the delegate callback is nil (Flow C -- late binding).
 */
- (void)loadAd;

/**
 * Load a native ad and render it into the provided view (Flow B -- manual binding).
 * @param adView The native ad view to render into. Must not be nil.
 */
- (void)loadAdIntoAdView:(CLXNativeAdView *)adView;

#pragma mark - Rendering

/**
 * Render a previously loaded ad into a view (for late-binding flow).
 * @param adView The native ad view to render into
 * @param ad The ad to render (must have been received via didLoadNativeAd:forAd:)
 * @return YES if rendering succeeded, NO if the ad is expired or invalid
 */
- (BOOL)renderNativeAdView:(CLXNativeAdView *)adView withAd:(CLXAd *)ad;

#pragma mark - Lifecycle

/**
 * Destroy a loaded ad and release all resources.
 * Must be called for every loaded ad to prevent memory leaks.
 * @param ad The ad to destroy
 */
- (void)destroyAd:(CLXAd *)ad;

/**
 * Destroy the loader and all associated resources.
 */
- (void)destroy;

#pragma mark - Extra Parameters

/**
 * Sets or clears an extra parameter attached to future bid requests for this ad.
 *
 * Supported value types: NSString, NSNumber (including boolean), NSArray,
 * and NSDictionary keyed by NSString. Pass nil to remove the key. Invalid
 * values are ignored and logged — they never fail ad loading.
 *
 * Reserved floor keys:
 * - `minFloor` — single-round publisher floor in USD CPM. Accepts an
 *   NSNumber or decimal NSString (e.g. `@"1.25"`).
 * - `minFloors` — per-round floor overrides. Accepts an NSArray of
 *   NSNumber / decimal NSString values, or a JSON-array NSString
 *   (e.g. `@"[1.2, 0.95]"`).
 *
 * Values are captured at call time. If you pass an NSDictionary or NSArray
 * and later mutate it, earlier bid requests are unaffected — call
 * setExtraParameter:value: again to push updates.
 *
 * Mixed-validity containers: an NSDictionary keeps its valid entries and
 * drops the invalid ones; an NSArray is all-or-nothing — any invalid
 * element discards the entire array, to preserve positional ordering for
 * keys like `minFloors`.
 *
 * Timing: native ads use the values current at the time of `loadAd`;
 * changes after that take effect on the next `loadAd` call.
 *
 * @param key Parameter key. Empty keys are ignored.
 * @param value Value to store, or nil to remove the key.
 */
- (void)setExtraParameter:(NSString *)key
                    value:(nullable id)value NS_SWIFT_NAME(setExtraParameter(_:value:));

/**
 * Sets or clears an adapter-level parameter for this native ad. The value is
 * forwarded to the underlying native ad adapter and is NOT sent in the bid
 * request.
 *
 * Use `setExtraParameter:value:` instead to send a value as an auction signal,
 * including per-request floor overrides (`minFloor` / `minFloors`).
 *
 * @param key Parameter key. Empty keys are ignored.
 * @param value Value to store, or nil to remove the key.
 */
- (void)setLocalExtraParameterForKey:(NSString *)key value:(nullable id)value;

@end

NS_ASSUME_NONNULL_END
