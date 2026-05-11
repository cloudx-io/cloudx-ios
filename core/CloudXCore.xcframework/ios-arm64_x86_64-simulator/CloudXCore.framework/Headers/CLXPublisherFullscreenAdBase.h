/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherFullscreenAdBase.h
 * @brief Base class for fullscreen ad implementations (interstitial and rewarded)
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXFullscreenAd.h>
#import <CloudXCore/CLXAdEventReporting.h>

@class CLXSDKConfigAdUnit;
@class CLXAdNetworkFactories;
@class CLXSettings;
@class CLXConfigImpressionModel;
@class CLXBidAdSourceResponse;
@class CLXAd;
@class CLXError;
@class CLXBidTokenSource;
@class CLXAdapterInterstitial;
@class CLXAdapterRewarded;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base class containing all shared logic for fullscreen ads.
 * Subclasses must implement abstract methods to specialize behavior for interstitial vs rewarded.
 */
@interface CLXPublisherFullscreenAdBase : NSObject <CLXFullscreenAd>

/**
 * Initializes a fullscreen ad with the given parameters.
 * @param adUnit The ad unit configuration (nil if SDK not initialized, will be resolved on load)
 * @param publisherID The publisher ID
 * @param userID The user ID
 * @param rewardedCallbackUrl The rewarded callback URL
 * @param impModel The impression model (nil if SDK not initialized, will be created on load)
 * @param adFactories The ad network factories
 * @param bidTokenSources Dictionary of bid token sources
 * @param bidRequestTimeout Timeout in seconds for bid requests (0 = use session default)
 * @param reportingService The reporting service
 * @param settings The settings instance
 */
- (instancetype)initWithAdUnit:(nullable CLXSDKConfigAdUnit *)adUnit
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(nullable CLXConfigImpressionModel *)impModel
                      adFactories:(nullable CLXAdNetworkFactories *)adFactories
                  bidTokenSources:(NSDictionary<NSString *, CLXBidTokenSource *> *)bidTokenSources
               bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                reportingService:(id<CLXAdEventReporting>)reportingService
                        settings:(CLXSettings *)settings;

/**
 * Loads the fullscreen ad.
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
 * Shows the fullscreen ad from the provided view controller.
 * @param viewController The view controller from which to show the ad
 * @param placement Optional placement identifier for tracking
 * @param customData Optional custom data for tracking (e.g., "level:5,coins:100")
 */
- (void)showFromViewController:(UIViewController *)viewController
                     placement:(nullable NSString *)placement
                    customData:(nullable NSString *)customData;

/**
 * Convenience method - shows the ad without placement/customData.
 */
- (void)showFromViewController:(UIViewController *)viewController;

// Abstract methods to be implemented by subclasses

/**
 * Returns the ad type for bid requests (CLXAdTypeInterstitial or CLXAdTypeRewarded).
 */
- (NSInteger)adType NS_REQUIRES_SUPER;

/**
 * Creates an adapter instance from the bid response data.
 * @param outError On failure, populated with the reason creation failed
 * @return The created adapter, or nil if creation fails
 */
- (nullable id)createAdapterWithAdId:(NSString *)adId
                              bidId:(NSString *)bidId
                                 adm:(NSString *)adm
                       adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                burl:(nullable NSString *)burl
                             network:(NSString *)network
                               error:(NSError * _Nullable *)outError NS_REQUIRES_SUPER;

/**
 * Returns the current adapter for metrics and display.
 */
- (nullable id)getCurrentAdapter NS_REQUIRES_SUPER;

/**
 * Clears the current adapter reference after cleanup.
 */
- (void)clearCurrentAdapter NS_REQUIRES_SUPER;

/**
 * Sets up the adapter delegate and initiates loading with timeout protection.
 */
- (void)setupAdapterAndLoad:(id)adapter NS_REQUIRES_SUPER;

/**
 * Shows the ad using the current adapter.
 */
- (void)showCurrentAdapterFromViewController:(UIViewController *)viewController NS_REQUIRES_SUPER;

/**
 * Strong-captures the publisher delegate at enqueue time, dispatches to the
 * main queue, and notifies the delegate of successful load.
 *
 * Subclasses MUST capture `self.delegate` strongly BEFORE `dispatch_async`
 * and pass it to the with-delegate variant of the notify method, so a
 * publisher releasing its delegate between enqueue and main-queue drain
 * cannot drop the callback.
 */
- (void)enqueueLoadSuccess NS_REQUIRES_SUPER;

/**
 * Strong-captures the publisher delegate at enqueue time, dispatches to the
 * main queue, and notifies the delegate of load failure. See -enqueueLoadSuccess.
 */
- (void)enqueueLoadFailure:(CLXError *)error NS_REQUIRES_SUPER;

/**
 * Strong-captures the publisher delegate at enqueue time, dispatches to the
 * main queue, and notifies the delegate of show failure. See -enqueueLoadSuccess.
 */
- (void)enqueueShowFailure:(CLXError *)error NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

