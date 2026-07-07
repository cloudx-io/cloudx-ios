/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file PublisherBanner.h
 * @brief Publisher banner implementation
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBanner.h>
#import <CloudXCore/CLXBannerAdView.h>
#import <CloudXCore/CLXAdapterAdViewFactory.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>
#import <CloudXCore/CLXBannerDelegate.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXAdRevenueDelegate.h>

@class CLXEnvironmentConfig;

NS_ASSUME_NONNULL_BEGIN


/**
 * PublisherBanner implements the CloudXBanner protocol and handles banner ad loading,
 * bidding, and lifecycle management.
 */
@interface CLXPublisherBanner : NSObject <CLXBanner>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for banner ad events.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * Delegate for revenue events (impression-level revenue data).
 */
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;

/**
 * The type of banner ad.
 */
@property (nonatomic, readonly) CLXBannerType bannerType;

/**
 * Settings instance for configuration (injected for testability).
 */
@property (nonatomic, strong, readonly) CLXSettings *settings;

/**
 * Flag to indicate if the banner is currently visible on screen.
 */
@property (nonatomic, assign, readonly) BOOL isVisible;

/**
 * The refresh interval in seconds.
 */
@property (nonatomic, assign, readonly) NSTimeInterval refreshSeconds;

/**
 * Flag to indicate if there is a pending refresh queued.
 */
@property (nonatomic, assign, readonly) BOOL hasPendingRefresh;

/**
 * The ad unit ID for this banner.
 */
@property (nonatomic, copy, readonly) NSString *adUnitId;

/**
 * Initializes a new PublisherBanner with the given parameters.
 * @param adUnit The ad unit configuration (nil if SDK not initialized, will be resolved on load)
 * @param userID The user ID
 * @param publisherID The publisher ID
 * @param suspendPreloadWhenInvisible Whether to suspend preloading when not visible
 * @param delegate The delegate to receive events
 * @param bannerType The type of banner
 * @param impModel The impression model (nil if SDK not initialized, will be created on load)
 * @param adFactories Dictionary of banner ad factories (injected for testability, falls back to CloudXCore if empty)
 * @param bidderSignalsProviders Dictionary of bidder signals providers (injected for testability, falls back to CloudXCore if empty)
 * @param bidRequestTimeout Timeout in seconds for bid requests (0 = use session default)
 * @param settings The settings instance for configuration (injected for testability)
 * @return Initialized PublisherBanner instance
 */
- (instancetype)initWithAdUnit:(nullable CLXSDKConfigAdUnit *)adUnit
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXBannerDelegate>)delegate
                             bannerType:(CLXBannerType)bannerType
                               impModel:(nullable CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, CLXAdapterAdViewFactory *> *)adFactories
                           bidderSignalsProviders:(NSDictionary<NSString *, CLXAdapterBidderSignalsProvider *> *)bidderSignalsProviders
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                              settings:(CLXSettings *)settings;

/**
 * Starts auto-refresh for the banner.
 * Auto-refresh will continue based on the ad unit configuration until stopped.
 */
- (void)startAutoRefresh;

/**
 * Stops auto-refresh for the banner.
 * The banner will no longer automatically refresh until startAutoRefresh is called again.
 */
- (void)stopAutoRefresh;

@end

NS_ASSUME_NONNULL_END
