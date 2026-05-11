/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdNetworkFactories.h
 * @brief Ad network factories container
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdNetworkInitializer;
@class CLXAdapterBannerFactory;
@class CLXAdapterInterstitialFactory;
@class CLXAdapterRewardedFactory;
@class CLXAdapterNativeFactory;
@class CLXBidTokenSource;

/**
 * CLXAdNetworkFactories is a container for all ad network factories and components.
 * It mirrors the Swift AdNetworkFactories struct and provides access to all adapter components.
 */
@interface CLXAdNetworkFactories : NSObject

/**
 * Bid token sources for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXBidTokenSource *> *bidTokenSources;

/**
 * Initializers for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXAdNetworkInitializer *> *initializers;

/**
 * Interstitial factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXAdapterInterstitialFactory *> *interstitials;

/**
 * Rewarded interstitial factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXAdapterRewardedFactory *> *rewardedInterstitials;

/**
 * Banner factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXAdapterBannerFactory *> *banners;

/**
 * Native factories for each adapter network.
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, CLXAdapterNativeFactory *> *native;

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
- (instancetype)initWithBidTokenSources:(NSDictionary<NSString *, CLXBidTokenSource *> *)bidTokenSources
                           initializers:(NSDictionary<NSString *, CLXAdNetworkInitializer *> *)initializers
                          interstitials:(NSDictionary<NSString *, CLXAdapterInterstitialFactory *> *)interstitials
                   rewardedInterstitials:(NSDictionary<NSString *, CLXAdapterRewardedFactory *> *)rewardedInterstitials
                                 banners:(NSDictionary<NSString *, CLXAdapterBannerFactory *> *)banners
                                   native:(NSDictionary<NSString *, CLXAdapterNativeFactory *> *)native;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END 