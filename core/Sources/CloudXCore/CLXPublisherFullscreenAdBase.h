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

@class CLXSDKConfigPlacement;
@class CLXAdNetworkFactories;
@class CLXSettings;
@class CLXConfigImpressionModel;
@class CLXBidAdSourceResponse;
@class CLXAd;
@class CLXError;
@protocol CLXBidTokenSource;
@protocol CLXAdapterInterstitial;
@protocol CLXAdapterRewarded;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base class containing all shared logic for fullscreen ads.
 * Subclasses must implement abstract methods to specialize behavior for interstitial vs rewarded.
 */
@interface CLXPublisherFullscreenAdBase : NSObject <CLXFullscreenAd>

/**
 * Initializes a fullscreen ad with the given parameters.
 * @param placement The placement configuration (nil if SDK not initialized, will be resolved on load)
 * @param publisherID The publisher ID
 * @param userID The user ID
 * @param rewardedCallbackUrl The rewarded callback URL
 * @param impModel The impression model (nil if SDK not initialized, will be created on load)
 * @param adFactories The ad network factories
 * @param waterfallMaxBackOffTime Maximum backoff time for waterfall
 * @param bidTokenSources Dictionary of bid token sources
 * @param bidRequestTimeout Bid request timeout
 * @param reportingService The reporting service
 * @param settings The settings instance
 */
- (instancetype)initWithPlacement:(nullable CLXSDKConfigPlacement *)placement
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(nullable CLXConfigImpressionModel *)impModel
                      adFactories:(nullable CLXAdNetworkFactories *)adFactories
         waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                  bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
               bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                reportingService:(id<CLXAdEventReporting>)reportingService
                        settings:(CLXSettings *)settings;

/**
 * Loads the fullscreen ad.
 */
- (void)load;

/**
 * Shows the fullscreen ad from the provided view controller.
 * @param viewController The view controller from which to show the ad
 */
- (void)showFromViewController:(UIViewController *)viewController;

// Abstract methods to be implemented by subclasses

/**
 * Returns the ad type for bid requests (CLXAdTypeInterstitial or CLXAdTypeRewarded).
 */
- (NSInteger)adType NS_REQUIRES_SUPER;

/**
 * Creates an adapter instance from the bid response data.
 * @return The created adapter, or nil if creation fails
 */
- (nullable id)createAdapterWithAdId:(NSString *)adId
                              bidId:(NSString *)bidId
                                 adm:(NSString *)adm
                       adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                burl:(nullable NSString *)burl
                             network:(NSString *)network NS_REQUIRES_SUPER;

/**
 * Returns the current adapter for metrics and display.
 */
- (nullable id)getCurrentAdapter NS_REQUIRES_SUPER;

/**
 * Sets up the adapter delegate and initiates loading with timeout protection.
 */
- (void)setupAdapterAndLoad:(id)adapter NS_REQUIRES_SUPER;

/**
 * Shows the ad using the current adapter.
 */
- (void)showCurrentAdapterFromViewController:(UIViewController *)viewController NS_REQUIRES_SUPER;

/**
 * Notifies the delegate of successful load.
 */
- (void)notifyLoadSuccess NS_REQUIRES_SUPER;

/**
 * Notifies the delegate of load failure.
 */
- (void)notifyLoadFailure:(CLXError *)error NS_REQUIRES_SUPER;

/**
 * Notifies the delegate of show failure.
 */
- (void)notifyShowFailure:(CLXError *)error NS_REQUIRES_SUPER;

/**
 * Notifies the delegate that the ad was force closed by timeout.
 */
- (void)notifyForceClose NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END



