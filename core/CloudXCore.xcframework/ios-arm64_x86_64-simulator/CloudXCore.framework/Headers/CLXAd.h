/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAd.h
 * @brief Ad data object containing metadata about a loaded ad
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAd;

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
CLX_PUBLIC
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
 * Revenue for this ad impression, in USD, per impression (not CPM).
 *
 * For a CloudX bid this is the bid-time estimate of what the impression will pay,
 * and `revenuePrecision` is "estimated". When the ad source reports impression-level
 * revenue of its own — today the Google AdMob / Ad Manager and AppLovin MAX
 * adapters — this is that realized value instead, and
 * `revenuePrecision` carries the precision the source reported, or "undefined"
 * when the source reported a precision the SDK does not recognize.
 */
@property (nonatomic, readonly, nullable) NSNumber *revenue;

/**
 * The ad format type (banner, mrec, interstitial, rewarded, native, app open)
 */
@property (nonatomic, readonly) CLXAdFormat adFormat;

/**
 * The placement identifier set by the publisher at show time (fullscreen) or load time (banner)
 */
@property (nonatomic, readonly, nullable) NSString *placement;

/**
 * SDK-defined ad metadata values associated with this loaded ad.
 *
 * Values may be absent depending on ad format, network, auction result, or SDK version.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *adValues;

#pragma mark - Additional Properties (iOS-specific)

/**
 * The human-readable ad unit name (e.g., "demo-mrec-1")
 */
@property (nonatomic, readonly, nullable) NSString *adUnitName;

/**
 * The native ad asset container (native format only).
 * Access individual assets (title, body, media, etc.) and check isExpired through this property.
 * Nil for non-native ad formats.
 */
@property (nonatomic, strong, nullable) CLXNativeAd *nativeAd;

/**
 * Precision of the `revenue` value.
 *
 * "estimated" for a CloudX bid-time figure. For an ad source that reports
 * impression-level revenue, the precision that source reported, as one of
 * "exact", "estimated", "publisher_defined", or "undefined". Sources report
 * precision either as a numeric code or as the token itself; a precision the
 * SDK does not recognize, or one the source left empty, is "undefined".
 */
@property (nonatomic, copy, nullable) NSString *revenuePrecision;

/**
 * The creative identifier for this ad, used for creative-level issue reporting.
 */
@property (nonatomic, copy, nullable) NSString *creativeIdentifier;

/**
 * Time in seconds from ad request to ad response, useful for debugging latency.
 */
@property (nonatomic, assign) NSTimeInterval requestLatency;

#pragma mark - Initializers

/**
 * Initializes a CLXAd with the provided metadata and SDK-defined ad values.
 *
 * Pass nil for adValues when no SDK-defined metadata should be attached.
 */
- (instancetype)initWithAdUnitName:(nullable NSString *)adUnitName
                          adUnitId:(nullable NSString *)adUnitId
                       networkName:(nullable NSString *)networkName
                  networkPlacement:(nullable NSString *)networkPlacement
                           revenue:(nullable NSNumber *)revenue
                          adFormat:(CLXAdFormat)adFormat
                         placement:(nullable NSString *)placement
                          adValues:(nullable NSDictionary<NSString *, NSString *> *)adValues;

/**
 * Factory method to create CLXAd from bid response data
 */
+ (instancetype)adFromBid:(id)bid
                 adUnitId:(NSString *)adUnitId
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement;

/**
 * Factory method to create CLXAd from bid response data with original ad unit name
 */
+ (instancetype)adFromBid:(id)bid
                 adUnitId:(NSString *)adUnitId
               adUnitName:(NSString *)adUnitName
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement;

@end

NS_ASSUME_NONNULL_END 
