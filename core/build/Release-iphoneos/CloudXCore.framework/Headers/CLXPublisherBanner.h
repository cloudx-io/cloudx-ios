/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file PublisherBanner.h
 * @brief Publisher banner implementation
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXBanner.h>
#import <CloudXCore/CLXBannerAdView.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXBannerDelegate.h>
#import <CloudXCore/CLXSettings.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AdEventReporting;

/**
 * PublisherBanner implements the CloudXBanner protocol and handles banner ad loading,
 * bidding, and lifecycle management.
 */
@interface CLXPublisherBanner : NSObject <CLXBanner, CLXAdapterBannerDelegate>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for banner ad events.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate, CLXAdapterBannerDelegate> delegate;

/**
 * The type of banner ad.
 */
@property (nonatomic, readonly) CLXBannerType bannerType;

/**
 * Flag to indicate if the banner is ready to be shown.
 */
@property (nonatomic, assign, readonly) BOOL isReady;

/**
 * Settings instance for configuration (injected for testability).
 */
@property (nonatomic, strong, readonly) CLXSettings *settings;

/**
 * Initializes a new PublisherBanner with the given parameters.
 * @param viewController The view controller where the banner will be displayed
 * @param placement The placement configuration
 * @param userID The user ID
 * @param publisherID The publisher ID
 * @param suspendPreloadWhenInvisible Whether to suspend preloading when not visible
 * @param delegate The delegate to receive events
 * @param bannerType The type of banner
 * @param waterfallMaxBackOffTime Maximum backoff time for waterfall
 * @param impModel The impression model
 * @param adFactories Dictionary of banner ad factories
 * @param bidTokenSources Dictionary of bid token sources
 * @param bidRequestTimeout Bid request timeout
 * @param reportingService The reporting service
 * @param settings The settings instance for configuration (injected for testability)
 * @param tmax Maximum timeout value
 * @return Initialized PublisherBanner instance
 */
- (instancetype)initWithViewController:(UIViewController *)viewController
                             placement:(CLXSDKConfigPlacement *)placement
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXBannerDelegate>)delegate
                             bannerType:(CLXBannerType)bannerType
                   waterfallMaxBackOffTime:(NSTimeInterval)waterfallMaxBackOffTime
                                  impModel:(CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *)adFactories
                           bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                         reportingService:(id<AdEventReporting>)reportingService
                              settings:(CLXSettings *)settings
                                     tmax:(nullable NSNumber *)tmax;

@end

NS_ASSUME_NONNULL_END 