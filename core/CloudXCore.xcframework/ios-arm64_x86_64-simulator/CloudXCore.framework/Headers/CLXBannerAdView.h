/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerAdView.h
 * @brief Banner ad view class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>
#import <CloudXCore/CLXAdRevenueDelegate.h>
#import <CloudXCore/CLXExport.h>


NS_ASSUME_NONNULL_BEGIN

@protocol CLXBanner;

/**
 * CLXBannerAdView represents a banner ad view in the CloudX SDK.
 * It contains a CLXAd instance for state management and delegates to it for ad lifecycle.
 */
CLX_PUBLIC
@interface CLXBannerAdView : UIView <CLXBannerDelegate, CLXAdDelegate>

/**
 * The underlying banner ad instance that manages state and lifecycle
 */
@property (nonatomic, strong, readonly) CLXAd *ad;

/**
 * A weak reference to the object that implements CLXBannerDelegate protocol.
 * This object will receive events related to the banner ad.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * Delegate that receives revenue events for the banner ad.
 */
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;

/**
 * A boolean indicating whether to suspend preloading the ad when it's not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * The ad unit ID for this banner ad view.
 */
@property (nonatomic, copy, readonly) NSString *adUnitId;

/**
 * The ad format for this banner ad view.
 */
@property (nonatomic, assign, readonly) CLXBannerType adFormat;

/**
 * The placement identifier for this banner ad view.
 *
 * Note: This is currently a stub implementation for MAX SDK compatibility.
 * The value can be set but is not yet used in reporting or analytics.
 * Contact CloudX support if you need this functionality enabled.
 */
@property (nonatomic, copy, nullable) NSString *placement;

/**
 * Custom data for tracking (e.g., "level:5,coins:100").
 */
@property (nonatomic, copy, nullable) NSString *customData;

/**
 * Initializes a new CLXBannerAdView with the given banner and type.
 * The frame of the view is set based on the size of the banner type.
 * @param banner The banner instance
 * @param type The banner type
 * @return Initialized banner ad view
 * @discussion Set the delegate property after initialization to receive events
 */
- (instancetype)initWithBanner:(id<CLXBanner>)banner
                         type:(CLXBannerType)type;

/**
 * Starts banner loading process.
 * Delegates to the underlying ad instance.
 * It should be called once after the banner is created.
 * Banner will be automatically reloaded after each show based on placement settings.
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
- (void)setExtraParameter:(NSString *)key
                    value:(nullable id)value NS_SWIFT_NAME(setExtraParameter(_:value:));

/**
 * Removes the view from its superview and destroys the banner ad.
 * Delegates to the underlying ad instance.
 */
- (void)destroy;

/**
 * Starts auto-refresh for the banner ad.
 * Auto-refresh will continue based on the placement configuration until stopped.
 */
- (void)startAutoRefresh;

/**
 * Stops auto-refresh for the banner ad.
 * The banner will no longer automatically refresh until startAutoRefresh is called again.
 */
- (void)stopAutoRefresh;

@end

NS_ASSUME_NONNULL_END 
