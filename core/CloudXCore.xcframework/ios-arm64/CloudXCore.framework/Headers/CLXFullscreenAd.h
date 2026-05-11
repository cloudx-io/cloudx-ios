/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXFullscreenAd.h
 * @brief Protocol for fullscreen ad formats (interstitial, rewarded)
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for fullscreen ad formats that require explicit show() gating.
 * This protocol is used by interstitial and rewarded ads which need isReady
 * to determine when show() can be called.
 *
 * Note: Load state is communicated via delegate callbacks, matching the Android SDK.
 */
@protocol CLXFullscreenAd <NSObject>

/**
 * Indicates whether the ad is ready to be displayed.
 */
@property (nonatomic, readonly) BOOL isReady;

/**
 * Loads the ad. This method initiates the ad loading process.
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
 * Timing: fullscreen ads use the values current at the time of `load`;
 * changes after that take effect on the next `load` call.
 *
 * @param key Parameter key. Empty keys are ignored.
 * @param value Value to store, or nil to remove the key.
 */
- (void)setExtraParameter:(NSString *)key
                    value:(nullable id)value NS_SWIFT_NAME(setExtraParameter(_:value:));

/**
 * Destroys the ad and cleans up all associated resources.
 * After calling this method, the ad instance should not be used.
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
