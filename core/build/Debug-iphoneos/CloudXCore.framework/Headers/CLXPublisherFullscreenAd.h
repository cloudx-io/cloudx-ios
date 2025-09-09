/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file PublisherFullscreenAd.h
 * @brief Publisher fullscreen ad implementation (interstitial and rewarded)
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXInterstitial.h>
#import <CloudXCore/CLXRewardedInterstitial.h>
#import <CloudXCore/CLXInterstitialDelegate.h>
#import <CloudXCore/CLXRewardedDelegate.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXAdNetworkFactories.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AdEventReporting;

/**
 * PublisherFullscreenAd implements both CloudXInterstitial and CloudXRewardedInterstitial protocols.
 * It handles interstitial and rewarded ad loading, caching, and lifecycle management.
 */
@interface CLXPublisherFullscreenAd : NSObject <CLXInterstitial, CLXRewardedInterstitial>

/**
 * Delegate for interstitial ad events.
 */
@property (nonatomic, weak, nullable) id<CLXInterstitialDelegate> interstitialDelegate;

/**
 * Delegate for rewarded ad events.
 */
@property (nonatomic, weak, nullable) id<CLXRewardedDelegate> rewardedDelegate;

/**
 * Flag to indicate if the ad is ready to be shown.
 */
@property (nonatomic, readonly) BOOL isReady;

/**
 * Initializes a new PublisherFullscreenAd with the given parameters.
 * @param interstitialDelegate The delegate for interstitial events (can be nil for rewarded)
 * @param rewardedDelegate The delegate for rewarded events (can be nil for interstitial)
 * @param placement The placement configuration
 * @param publisherID The publisher ID
 * @param userID The user ID
 * @param rewardedCallbackUrl Optional callback URL for rewarded ads
 * @param cacheSize The cache size for ads
 * @param adFactories The ad network factories
 * @param waterfallMaxBackOffTime Maximum backoff time for waterfall
 * @param bidTokenSources Dictionary of bid token sources
 * @param bidRequestTimeout Bid request timeout
 * @param reportingService The reporting service
 * @param adType The type of ad (interstitial or rewarded)
 * @return Initialized PublisherFullscreenAd instance
 */
- (instancetype)initWithInterstitialDelegate:(nullable id<CLXInterstitialDelegate>)interstitialDelegate
                            rewardedDelegate:(nullable id<CLXRewardedDelegate>)rewardedDelegate
                                   placement:(CLXSDKConfigPlacement *)placement
                                publisherID:(NSString *)publisherID
                                     userID:(nullable NSString *)userID
                        rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                                  cacheSize:(NSInteger)cacheSize
                                adFactories:(nullable CLXAdNetworkFactories *)adFactories
                     waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                              bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                           bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                            reportingService:(id<CLXAdEventReporting>)reportingService
                                    settings:(CLXSettings *)settings
                                     adType:(NSInteger)adType;

@end

NS_ASSUME_NONNULL_END 