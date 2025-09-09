/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CacheAdQueue.h
 * @brief Cache ad queue implementation
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AdEventReporting;
@protocol CacheableAd;
@protocol CLXAppSessionService;

/**
 * Error types for cache ad queue operations
 */
typedef NS_ENUM(NSInteger, CacheAdQueueError) {
    CacheAdQueueErrorAdIsNil = 0,
    CacheAdQueueErrorFailToLoad,
    CacheAdQueueErrorTimeout,
    CacheAdQueueErrorQueueIsOverflow,
    CacheAdQueueErrorFailToCreateAd
};

/**
 * Cache ad queue for managing a sorted queue of cacheable ads
 */
@interface CLXCacheAdQueue : NSObject

/**
 * Maximum capacity of the queue
 */
@property (nonatomic, assign) NSInteger maxCapacity;

/**
 * Whether there is enough space in the queue
 */
@property (nonatomic, readonly) BOOL isEnoughSpace;

/**
 * Whether the queue is empty
 */
@property (nonatomic, readonly) BOOL isEmpty;

/**
 * Whether the queue has items
 */
@property (nonatomic, readonly) BOOL hasItems;

/**
 * The first ad in the queue
 */
@property (nonatomic, readonly, nullable) id<CacheableAd> first;

/**
 * Initialize a new cache ad queue
 * @param maxCapacity Maximum capacity of the queue
 * @param reportingService Service for reporting events
 * @param placementID Placement identifier
 * @return Initialized cache ad queue
 */
- (instancetype)initWithMaxCapacity:(NSInteger)maxCapacity
                   reportingService:(id<AdEventReporting>)reportingService
                        placementID:(NSString *)placementID;

/**
 * Enqueue an ad with price and load timeout
 * @param price Price of the ad
 * @param loadTimeout Load timeout in seconds
 * @param bidID Bid identifier
 * @param ad Ad to enqueue
 * @param completion Completion block called when operation completes
 */
- (void)enqueueAdWithPrice:(double)price
                loadTimeout:(NSTimeInterval)loadTimeout
                      bidID:(NSString *)bidID
                         ad:(nullable id<CacheableAd>)ad
                 completion:(void (^)(NSError * _Nullable error))completion;

/**
 * Pop an ad from the queue
 * @return The popped ad or nil if queue is empty
 */
- (nullable id<CacheableAd>)popAd;

/**
 * Remove an ad from the queue
 * @param ad Ad to remove
 */
- (void)removeAd:(id<CacheableAd>)ad;

/**
 * Destroy the queue and clean up resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 