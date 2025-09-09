/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CachedRewarded.h
 * @brief Cached rewarded wrapper that implements CacheableAd protocol
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXCacheableAd.h>
#import <CloudXCore/CLXAdapterRewarded.h>

@class CLXBidResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 * CachedRewarded is a wrapper class that implements CacheableAd protocol
 * and wraps adapter rewarded instances to provide caching functionality.
 */
@interface CLXCachedRewarded : NSObject <CLXCacheableAd>

/**
 * The wrapped adapter rewarded instance
 */
@property (nonatomic, strong, readonly) id<CLXAdapterRewarded> rewarded;

/**
 * The delegate for the wrapped rewarded
 */
@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;

/**
 * Network name of the ad
 */
@property (nonatomic, readonly) NSString *network;

/**
 * Impression ID of the ad
 */
@property (nonatomic, copy) NSString *impressionID;

/**
 * Bid response containing all bids from the auction that created this cached ad
 */
@property (nonatomic, strong, nullable) CLXBidResponse *bidResponse;

/**
 * Initializes a new CachedRewarded with the given rewarded and delegate
 * @param rewarded The adapter rewarded to wrap
 * @param delegate The delegate for the rewarded
 * @return Initialized CachedRewarded instance
 */
- (instancetype)initWithRewarded:(id<CLXAdapterRewarded>)rewarded
                        delegate:(id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 