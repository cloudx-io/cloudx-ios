/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdNetworkFactories.h
 * @brief Ad network factories container
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdNetworkInitializer;
@protocol CLXAdapterBannerFactory;
@protocol CLXAdapterInterstitialFactory;
@protocol CLXAdapterRewardedFactory;
@protocol CLXAdapterNativeFactory;
@protocol CLXBidTokenSource;

/**
 * CLXAdNetworkFactories is a container for all ad network factories and components.
 * It mirrors the Swift AdNetworkFactories struct and provides access to all adapter components.
 */
@interface CLXAdNetworkFactories : NSObject

/**
 * Bid token sources for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources;

/**
 * Initializers for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXAdNetworkInitializer>> *initializers;

/**
 * Interstitial factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXAdapterInterstitialFactory>> *interstitials;

/**
 * Rewarded interstitial factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXAdapterRewardedFactory>> *rewardedInterstitials;

/**
 * Banner factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *banners;

/**
 * Native factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *native;

/**
 * Helper property to check if all fields are empty.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/**
 * Initializes the factories container with the provided dictionaries.
 * @param bidTokenSources Dictionary of bid token sources
 * @param initializers Dictionary of initializers
 * @param interstitials Dictionary of interstitial factories
 * @param rewardedInterstitials Dictionary of rewarded interstitial factories
 * @param banners Dictionary of banner factories
 * @param native Dictionary of native factories
 * @return Initialized CLXAdNetworkFactories instance
 */
- (instancetype)initWithBidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                           initializers:(NSDictionary<NSString *, id<CLXAdNetworkInitializer>> *)initializers
                          interstitials:(NSDictionary<NSString *, id<CLXAdapterInterstitialFactory>> *)interstitials
                   rewardedInterstitials:(NSDictionary<NSString *, id<CLXAdapterRewardedFactory>> *)rewardedInterstitials
                                 banners:(NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *)banners
                                   native:(NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *)native;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END 