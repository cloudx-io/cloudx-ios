/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAd.h
 * @brief Ad data object containing metadata about a loaded ad
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdFormat.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXAd represents metadata about a loaded ad (similar to MAAd in MAX SDK).
 * Contains information about the ad's network, placement, revenue, etc.
 * This is a pure data object - it does not control ad lifecycle.
 *
 * Property naming aligns with Android SDK CloudXAd interface:
 * - adUnitId: CloudX ad unit identifier
 * - networkName: The winning bidder/network name
 * - networkPlacement: Network-specific placement ID (e.g., Meta placement ID, Mintegral ad_unit_id)
 * - revenue: Revenue for this impression
 */
@interface CLXAd : NSObject

#pragma mark - Primary Properties (aligned with Android SDK)

/**
 * The CloudX ad unit identifier (e.g., "EWaeXDSmKYbs220gM5hTv")
 */
@property (nonatomic, readonly, nullable) NSString *adUnitId;

/**
 * The winning bidder/network name (e.g., "meta", "vungle", "mintegral")
 */
@property (nonatomic, readonly, nullable) NSString *networkName;

/**
 * The network-specific placement identifier.
 * Each network uses different terminology:
 * - Meta: placement_id (e.g., "24378279391783950_24942654725346411")
 * - Vungle: placement_id
 * - InMobi: placement_id
 * - Mintegral: ad_unit_id (note: Mintegral also has a separate placement_id)
 */
@property (nonatomic, readonly, nullable) NSString *networkPlacement;

/**
 * Revenue information for this ad impression
 */
@property (nonatomic, readonly, nullable) NSNumber *revenue;

/**
 * The ad format type (banner, mrec, interstitial, rewarded, native)
 */
@property (nonatomic, readonly) CLXAdFormat adFormat;

/**
 * The placement identifier set by the publisher at show time (fullscreen) or load time (banner)
 */
@property (nonatomic, readonly, nullable) NSString *placement;

#pragma mark - Additional Properties (iOS-specific)

/**
 * The human-readable ad unit name (e.g., "demo-mrec-1")
 * Note: Not present in Android CloudXAd interface, but useful for logging
 */
@property (nonatomic, readonly, nullable) NSString *adUnitName;

#pragma mark - Deprecated Properties (use new names above)

/**
 * @deprecated Use `adUnitName` instead
 */
@property (nonatomic, readonly, nullable) NSString *placementName __attribute__((deprecated("Use adUnitName instead")));

/**
 * @deprecated Use `adUnitId` instead
 */
@property (nonatomic, readonly, nullable) NSString *placementId __attribute__((deprecated("Use adUnitId instead")));

/**
 * @deprecated Use `networkName` instead
 */
@property (nonatomic, readonly, nullable) NSString *bidder __attribute__((deprecated("Use networkName instead")));

/**
 * @deprecated Use `networkPlacement` instead
 */
@property (nonatomic, readonly, nullable) NSString *externalPlacementId __attribute__((deprecated("Use networkPlacement instead")));

#pragma mark - Initializers

/**
 * Initializes a CLXAd with the provided metadata
 */
- (instancetype)initWithAdUnitName:(nullable NSString *)adUnitName
                          adUnitId:(nullable NSString *)adUnitId
                       networkName:(nullable NSString *)networkName
                  networkPlacement:(nullable NSString *)networkPlacement
                           revenue:(nullable NSNumber *)revenue
                          adFormat:(CLXAdFormat)adFormat
                         placement:(nullable NSString *)placement;

/**
 * @deprecated Use initWithAdUnitName:adUnitId:networkName:networkPlacement:revenue: instead
 */
- (instancetype)initWithPlacementName:(nullable NSString *)placementName
                          placementId:(nullable NSString *)placementId
                               bidder:(nullable NSString *)bidder
                  externalPlacementId:(nullable NSString *)externalPlacementId
                              revenue:(nullable NSNumber *)revenue __attribute__((deprecated("Use initWithAdUnitName:adUnitId:networkName:networkPlacement:revenue: instead")));

/**
 * Factory method to create CLXAd from bid response data
 */
+ (instancetype)adFromBid:(id)bid
              placementId:(NSString *)placementId
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement;

/**
 * Factory method to create CLXAd from bid response data with original placement name
 */
+ (instancetype)adFromBid:(id)bid
              placementId:(NSString *)placementId
            placementName:(NSString *)placementName
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement;

@end

NS_ASSUME_NONNULL_END 