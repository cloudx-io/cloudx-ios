/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CacheAdService.h
 * @brief Cache ad service implementation
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBidAdSourceProtocol;
@protocol CLXAdEventReporting;
@protocol CacheableAd;
@class CLXSDKConfigPlacement;
@class CLXSettings;

/**
 * Cache ad service that manages a queue of cached ads
 */
@interface CLXCacheAdService : NSObject

/**
 * Whether the service has ads available
 */
@property (nonatomic, readonly) BOOL hasAds;

/**
 * The first ad in the cache
 */
@property (nonatomic, readonly, nullable) id<CacheableAd> first;

/**
 * Initialize a new cache ad service
 * @param placement Placement configuration
 * @param bidAdSource Bid ad source for requesting ads
 * @param waterfallMaxBackOffTime Maximum backoff time for waterfall
 * @param cacheSize Size of the cache
 * @param bidLoadTimeout Timeout for bid loading
 * @param reportingService Service for reporting events
 * @param createCacheableAd Block to create cacheable ads
 * @return Initialized cache ad service
 */
- (instancetype)initWithPlacement:(CLXSDKConfigPlacement *)placement
                      bidAdSource:(nullable id<CLXBidAdSourceProtocol>)bidAdSource
            waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                          cacheSize:(NSInteger)cacheSize
                     bidLoadTimeout:(NSTimeInterval)bidLoadTimeout
                   reportingService:(id<CLXAdEventReporting>)reportingService
                           settings:(CLXSettings *)settings
                            adType:(NSInteger)adType
                  createCacheableAd:(id<CacheableAd> _Nullable (^)(id _Nullable destroyable))createCacheableAd;

/**
 * Destroy the cache ad service and clean up resources
 */
- (void)destroy;

/**
 * Pop an ad from the cache
 * @return The popped ad or nil if cache is empty
 */
- (nullable id<CacheableAd>)popAd;

/**
 * Report an error with an ad
 * @param ad The ad that had an error
 */
- (void)adError:(id)ad;

@end

NS_ASSUME_NONNULL_END 