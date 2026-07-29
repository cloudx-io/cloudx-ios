//
//  CLXRevenueData.h
//  CloudXCore
//
//  Impression-level revenue reported by a publisher via -[CloudXCore reportRevenueData:].
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXRevenuePlatform.h>
#import <CloudXCore/CLXRevenuePrecision.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Builder for constructing CLXRevenueData instances.
 *
 * All properties are optional metadata; the required values (platform, revenue,
 * adFormat) are passed to the factory method. Set them inside the builder block.
 */
CLX_PUBLIC
@interface CLXRevenueDataBuilder : NSObject

/** ISO 4217 currency code of the revenue (e.g. "USD"), if known. */
@property (nonatomic, copy, nullable) NSString *currencyCode;
/** Precision of the reported revenue, if known. When nil, precision is omitted from the payload. */
@property (nonatomic, strong, nullable) CLXRevenuePrecision *precision;
/** Winning ad network name, if known. */
@property (nonatomic, copy, nullable) NSString *networkName;
/** Mediation-platform ad unit id, if known. */
@property (nonatomic, copy, nullable) NSString *adUnitId;
/** Network-side ad unit or placement id, if known. */
@property (nonatomic, copy, nullable) NSString *thirdPartyAdPlacementId;
/** Creative id from the ad network, if known. */
@property (nonatomic, copy, nullable) NSString *creativeId;
/** Network placement identifier, if known. */
@property (nonatomic, copy, nullable) NSString *networkPlacement;
/** User's country (ISO 3166-1 alpha-2), if known. */
@property (nonatomic, copy, nullable) NSString *countryCode;
/** User segment string, if known. */
@property (nonatomic, copy, nullable) NSString *userSegment;

@end

/**
 * Impression-level revenue reported by a publisher via -[CloudXCore reportRevenueData:].
 *
 * Publishers use this object to forward paid events from any mediation
 * platform into the SDK. Use the builder-block factory to create an instance:
 * @code
 * CLXRevenueData *data =
 *     [CLXRevenueData revenueDataWithPlatform:CLXRevenuePlatformAdMob
 *                                     revenue:adValue.value.doubleValue
 *                                    adFormat:@"banner"
 *                                builderBlock:^(CLXRevenueDataBuilder *builder) {
 *                                    builder.currencyCode = adValue.currencyCode;
 *                                }];
 * @endcode
 */
CLX_PUBLIC
@interface CLXRevenueData : NSObject

/** Mediation platform that reported the impression. */
@property (nonatomic, copy, readonly) CLXRevenuePlatform platform;
/**
 * Raw revenue amount for this impression, as reported by the mediation SDK.
 * Non-finite values are stored as 0.0.
 */
@property (nonatomic, assign, readonly) double revenue;
/** Raw ad format string (e.g. "banner", "mrec", "interstitial", "rewarded"). */
@property (nonatomic, copy, readonly) NSString *adFormat;
/** ISO 4217 currency code of revenue (e.g. "USD"), if known. */
@property (nonatomic, copy, readonly, nullable) NSString *currencyCode;
/** Precision of the reported revenue, if known. */
@property (nonatomic, copy, readonly, nullable) CLXRevenuePrecision *precision;
/** Winning ad network name, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *networkName;
/** Mediation-platform ad unit id, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitId;
/** Network-side ad unit or placement id, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *thirdPartyAdPlacementId;
/** Creative id from the ad network, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *creativeId;
/** Network placement identifier, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *networkPlacement;
/** User's country (ISO 3166-1 alpha-2), if known. */
@property (nonatomic, copy, readonly, nullable) NSString *countryCode;
/** User segment string, if known. */
@property (nonatomic, copy, readonly, nullable) NSString *userSegment;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 * Creates revenue data with the required fields.
 *
 * @param platform Mediation platform that reported the impression.
 * @param revenue Raw revenue amount reported by the mediation SDK.
 * @param adFormat Raw ad format string.
 */
+ (instancetype)revenueDataWithPlatform:(CLXRevenuePlatform)platform
                                revenue:(double)revenue
                               adFormat:(NSString *)adFormat
    NS_SWIFT_NAME(revenueData(platform:revenue:adFormat:));

/**
 * Creates revenue data with the required fields and a builder block for optional metadata.
 *
 * @param platform Mediation platform that reported the impression.
 * @param revenue Raw revenue amount reported by the mediation SDK.
 * @param adFormat Raw ad format string.
 * @param builderBlock Block to set optional metadata via the builder.
 */
+ (instancetype)revenueDataWithPlatform:(CLXRevenuePlatform)platform
                                revenue:(double)revenue
                               adFormat:(NSString *)adFormat
                           builderBlock:(nullable void (^)(CLXRevenueDataBuilder *builder))builderBlock
    NS_SWIFT_NAME(revenueData(platform:revenue:adFormat:builderBlock:));

@end

NS_ASSUME_NONNULL_END
