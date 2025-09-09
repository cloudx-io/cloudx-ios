/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CachedInterstitial.h
 * @brief Cached interstitial wrapper that implements CacheableAd protocol
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXCacheableAd.h>
#import <CloudXCore/CLXAdapterInterstitial.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CachedInterstitial is a wrapper class that implements CacheableAd protocol
 * and wraps adapter interstitial instances to provide caching functionality.
 */
@interface CLXCachedInterstitial : NSObject <CLXCacheableAd>

/**
 * The wrapped adapter interstitial instance
 */
@property (nonatomic, strong, readonly) id<CLXAdapterInterstitial> interstitial;

/**
 * The delegate for the wrapped interstitial
 */
@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/**
 * Network name of the ad
 */
@property (nonatomic, readonly) NSString *network;

/**
 * Impression ID of the ad
 */
@property (nonatomic, copy) NSString *impressionID;

/**
 * Initializes a new CachedInterstitial with the given interstitial and delegate
 * @param interstitial The adapter interstitial to wrap
 * @param delegate The delegate for the interstitial
 * @return Initialized CachedInterstitial instance
 */
- (instancetype)initWithInterstitial:(id<CLXAdapterInterstitial>)interstitial
                            delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 