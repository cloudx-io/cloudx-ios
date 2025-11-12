/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAd.h
 * @brief Ad data object containing metadata about a loaded ad
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXAd represents metadata about a loaded ad (similar to MAAd in MAX SDK).
 * Contains information about the ad's network, placement, revenue, etc.
 * This is a pure data object - it does not control ad lifecycle.
 */
@interface CLXAd : NSObject

/**
 * The placement name for this ad
 */
@property (nonatomic, readonly, nullable) NSString *placementName;

/**
 * The placement identifier for this ad
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 * The bidder/network that won this ad
 */
@property (nonatomic, readonly, nullable) NSString *bidder;

/**
 * The external placement identifier from the ad network
 */
@property (nonatomic, readonly, nullable) NSString *externalPlacementId;

/**
 * Revenue information for this ad impression
 */
@property (nonatomic, readonly, nullable) NSNumber *revenue;



/**
 * Initializes a CLXAd with the provided metadata
 */
- (instancetype)initWithPlacementName:(nullable NSString *)placementName
                          placementId:(nullable NSString *)placementId
                               bidder:(nullable NSString *)bidder
                  externalPlacementId:(nullable NSString *)externalPlacementId
                              revenue:(nullable NSNumber *)revenue;

/**
 * Factory method to create CLXAd from bid response data
 */
+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId;

/**
 * Factory method to create CLXAd from bid response data with original placement name
 */
+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId placementName:(NSString *)placementName;

@end

NS_ASSUME_NONNULL_END 