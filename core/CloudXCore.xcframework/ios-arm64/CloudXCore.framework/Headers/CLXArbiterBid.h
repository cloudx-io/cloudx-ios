#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXArbiterPlatform.h>
#import <CloudXCore/CLXArbiterPrecision.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;

/**
 * Bid candidate submitted for arbiter.
 *
 * Supported V0 bid inputs expose revenue data for SDK-side fallback selection.
 * The fallback path normalizes supported bid types to per-impression USD before comparing:
 * CloudX and LevelPlay revenue are already per-impression USD; PubMatic price is USD eCPM / CPM.
 * The request payload still preserves each platform's native field names so the backend can apply
 * platform-specific interpretation.
 */
CLX_PUBLIC
@interface CLXArbiterBid : NSObject

/**
 * Locally unique bid identifier.
 */
@property (nonatomic, copy, readonly) NSString *bidId;

/**
 * Platform that produced this bid.
 */
@property (nonatomic, strong, readonly) CLXArbiterPlatform *platform;

/**
 * Concrete platform name for this bid.
 *
 * Built-in bid types mirror platform.name. Custom bids use CLXArbiterPlatform.custom
 * for routing and carry the originating mediation platform here.
 */
@property (nonatomic, copy, readonly) NSString *platformName;

/**
 * Optional platform-specific metadata.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *extras;

/**
 * Creates a CloudX bid candidate from a loaded CloudX ad.
 *
 * Uses CLXAd.revenue as the CloudX per-impression USD comparison value.
 * The SDK does not validate bid authenticity client-side. Production arbiter execution
 * validates CloudX bid data server-side.
 */
+ (instancetype)cloudXBidWithAd:(CLXAd *)ad NS_SWIFT_NAME(cloudX(ad:));

/**
 * Creates a LevelPlay bid candidate.
 *
 * @param networkName LevelPlay's winning ad network name.
 * @param revenue LevelPlay-reported per-impression USD revenue.
 * @param precision LevelPlay precision value.
 * @param extras Optional platform metadata. Null/blank keys and non-string values are
 * dropped before storage.
 */
+ (instancetype)levelPlayBidWithNetworkName:(NSString *)networkName
                                    revenue:(double)revenue
                                  precision:(NSString *)precision
                                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
    NS_SWIFT_NAME(levelPlay(networkName:revenue:precision:extras:));

/**
 * Creates a LevelPlay bid candidate with no extras.
 */
+ (instancetype)levelPlayBidWithNetworkName:(NSString *)networkName
                                    revenue:(double)revenue
                                  precision:(NSString *)precision
    NS_SWIFT_NAME(levelPlay(networkName:revenue:precision:));

/**
 * Creates a PubMatic bid candidate.
 *
 * @param price PubMatic OpenWrap USD eCPM / CPM value from POBBid.price.
 * SDK fallback divides this value by 1,000 for per-impression comparison.
 * @param partnerName Partner name reported by the source SDK, when available.
 * @param extras Optional platform metadata. Null/blank keys and non-string values are
 * dropped before storage.
 */
+ (instancetype)pubMaticBidWithPrice:(double)price
                         partnerName:(nullable NSString *)partnerName
                              extras:(nullable NSDictionary<NSString *, NSString *> *)extras
    NS_SWIFT_NAME(pubMatic(price:partnerName:extras:));

/**
 * Creates a PubMatic bid candidate with no partner name or extras.
 */
+ (instancetype)pubMaticBidWithPrice:(double)price
    NS_SWIFT_NAME(pubMatic(price:));

/**
 * Creates a bid candidate from any mediation platform not covered by a dedicated factory.
 *
 * The bid's platform is CLXArbiterPlatform.custom. The originating mediator is
 * carried separately in platformName.
 *
 * @param platformName Originating mediator, e.g. "CUSTOM_MEDIATOR".
 * @param networkName Winning demand source within the platform. Pass "" if absent.
 * @param revenuePerImpressionUSD Platform-reported revenue for this single impression,
 * in USD. This is not a CPM.
 * @param precision Revenue precision reported by the platform.
 * @param extras Optional platform metadata. Null/blank keys and non-string values are
 * dropped before storage.
 */
+ (instancetype)customBidWithPlatformName:(NSString *)platformName
                              networkName:(NSString *)networkName
                  revenuePerImpressionUSD:(double)revenuePerImpressionUSD
                                precision:(CLXArbiterPrecision *)precision
                                    extras:(nullable NSDictionary<NSString *, NSString *> *)extras
    NS_SWIFT_NAME(custom(platformName:networkName:revenuePerImpressionUSD:precision:extras:));

/**
 * Creates a custom bid candidate with no extras.
 */
+ (instancetype)customBidWithPlatformName:(NSString *)platformName
                              networkName:(NSString *)networkName
                  revenuePerImpressionUSD:(double)revenuePerImpressionUSD
                                precision:(CLXArbiterPrecision *)precision
    NS_SWIFT_NAME(custom(platformName:networkName:revenuePerImpressionUSD:precision:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
