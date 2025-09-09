/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CacheableAd.h
 * @brief Cacheable ad protocol
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidResponse;

/**
 * Protocol for ads that can be cached
 */
@protocol CLXCacheableAd <CLXDestroyable>

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
 * Load the ad with timeout
 * @param timeout Timeout in seconds
 * @param completion Completion block called when loading completes
 */
- (void)loadWithTimeout:(NSTimeInterval)timeout
             completion:(void (^)(NSError * _Nullable error))completion;

/**
 * Show the ad from a view controller
 * @param viewController View controller to show the ad from
 */
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END 