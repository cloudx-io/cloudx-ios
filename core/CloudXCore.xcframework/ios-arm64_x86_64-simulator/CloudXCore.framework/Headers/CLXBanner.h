/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBanner.h
 * @brief Banner ad protocol
 *
 * Note: Banners do not expose isReady. Load state is communicated via delegate
 * callbacks, matching the Android SDK. isDestroyed is provided to check if the
 * banner is still valid.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXBanner is a protocol for banner ads in the CloudX SDK.
 * Defines banner-specific properties and functionality.
 *
 * Banners are separate from fullscreen ads and do not share a common protocol.
 */
@protocol CLXBanner <NSObject>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for banner ad events.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * The type of banner ad.
 */
@property (nonatomic, readonly) CLXBannerType bannerType;

/**
 * Loads the banner ad.
 */
- (void)load;

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
 * Timing: banner refreshes pick up the current stored values on each auction.
 *
 * @param key Parameter key. Empty keys are ignored.
 * @param value Value to store, or nil to remove the key.
 */
- (void)setExtraParameter:(NSString *)key value:(nullable id)value NS_SWIFT_NAME(setExtraParameter(_:value:));

/**
 * Destroys the banner ad and releases resources.
 */
- (void)destroy;

/**
 * Starts auto-refresh for the banner ad.
 */
- (void)startAutoRefresh;

/**
 * Stops auto-refresh for the banner ad.
 */
- (void)stopAutoRefresh;

/**
 * Indicates whether the banner ad has been destroyed and can no longer be used.
 */
@property (nonatomic, readonly) BOOL isDestroyed;

@end

NS_ASSUME_NONNULL_END 