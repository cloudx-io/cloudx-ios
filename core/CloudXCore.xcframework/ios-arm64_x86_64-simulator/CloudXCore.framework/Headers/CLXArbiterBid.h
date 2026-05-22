#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXArbiterPlatform.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;

/**
 * Bid candidate submitted for arbiter.
 *
 * Supported V0 bid inputs expose comparable USD auction values for SDK-side fallback selection.
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
 * Optional platform-specific metadata.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *extras;

/**
 * Creates a CloudX bid candidate from a loaded CloudX ad.
 *
 * Uses CLXAd.revenue as the CloudX comparison value.
 * The SDK does not validate bid authenticity client-side. Production arbiter execution
 * validates CloudX bid data server-side.
 */
+ (instancetype)cloudXBidWithAd:(CLXAd *)ad NS_SWIFT_NAME(cloudX(ad:));

/**
 * Creates a LevelPlay bid candidate.
 *
 * @param networkName LevelPlay's winning ad network name.
 * @param revenue LevelPlay-reported USD auction value.
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
 * @param price USD auction value from the originating ad source.
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

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
