/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Server-driven knobs that gate adapter lifecycle race-safety fixes.
 *
 * Parsed from the `raceSafetyConfig` object on the SDK init response. Absent
 * keys fall through to the SDK-published defaults (see `+defaultConfig`). Server
 * can explicitly send `0` for either delay to kill-switch back to legacy
 * synchronous destroy without a client release.
 *
 * CXD-1182: deferred destroy defaults are ACTIVE (500ms) so host apps without
 * server-side config still benefit from the race-safety fix.
 */
CLX_PUBLIC
@interface CLXSDKRaceSafetyConfig : NSObject

/**
 * @brief Milliseconds to hold a fullscreen adapter alive after `close` before
 * invoking `-destroy` and nilling the ivar.
 *
 * Values > 0 schedule the destroy block via `dispatch_after` on the main queue.
 * 0 means destroy runs inline on the close thread (legacy kill-switch). If a new
 * load begins during the window the pending destroy fires immediately, so
 * delays never accumulate across auctions.
 */
@property (nonatomic, readonly) NSInteger fullscreenDestroyDelayMs;

/**
 * @brief Milliseconds to hold the previous banner adapter alive after a swap
 * before invoking `-destroy` and `-removeFromSuperview`.
 *
 * 0 means the teardown runs inline (legacy kill-switch).
 */
@property (nonatomic, readonly) NSInteger bannerSwapDestroyDelayMs;

/**
 * @brief Milliseconds to hold the previous native adapter alive after a reload
 * before invoking `-destroy`, so a late partner impression/click for the old
 * ad still lands on its frozen wrapper instead of being dropped.
 *
 * Values > 0 schedule the destroy via `dispatch_after` on the main queue; a new
 * load during the window flushes the pending destroy immediately so delays
 * never accumulate across auctions. 0 means destroy runs inline on the reload
 * thread (legacy kill-switch).
 */
@property (nonatomic, readonly) NSInteger nativeDestroyDelayMs;

/**
 * @brief When YES, Mintegral banners skip assigning `self.mintegralBannerView.viewController`
 * at show time and re-resolve the top VC just-in-time from the shared proxy.
 *
 * Default NO. Opt-in server-side; additive JIT resolution cannot reduce
 * information for any consumer when inactive.
 */
@property (nonatomic, readonly) BOOL mintegralJITViewControllerEnabled;

- (instancetype)initWithFullscreenDestroyDelayMs:(NSInteger)fullscreenDestroyDelayMs
                          bannerSwapDestroyDelayMs:(NSInteger)bannerSwapDestroyDelayMs
                              nativeDestroyDelayMs:(NSInteger)nativeDestroyDelayMs
                   mintegralJITViewControllerEnabled:(BOOL)mintegralJITViewControllerEnabled NS_DESIGNATED_INITIALIZER;

/**
 * @brief Source-compatible initializer predating the native deferred-destroy
 * knob (CXD-1182 shipped fullscreen + banner only). Forwards with
 * `nativeDestroyDelayMs` set to the SDK default (500ms).
 */
- (instancetype)initWithFullscreenDestroyDelayMs:(NSInteger)fullscreenDestroyDelayMs
                          bannerSwapDestroyDelayMs:(NSInteger)bannerSwapDestroyDelayMs
                   mintegralJITViewControllerEnabled:(BOOL)mintegralJITViewControllerEnabled;

/**
 * @brief SDK-published defaults used when the server omits `raceSafetyConfig`
 *        or when `configFromDictionary:` receives nil / a non-dictionary.
 *
 * Current values: fullscreenDestroyDelayMs = 500, bannerSwapDestroyDelayMs =
 * 500, nativeDestroyDelayMs = 500, mintegralJITViewControllerEnabled = NO.
 */
+ (instancetype)defaultConfig;

/**
 * @brief Parses a `CLXSDKRaceSafetyConfig` from a JSON dictionary.
 * @param dict The `raceSafetyConfig` object from the SDK init response. May be nil.
 * @return A config whose fields mirror the server payload, or nil if `dict` is
 *         nil / not a dictionary. Absent or wrong-type fields fall back to
 *         `+defaultConfig` values. Explicit `0` for a delay is honored as a
 *         kill-switch.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dict;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
