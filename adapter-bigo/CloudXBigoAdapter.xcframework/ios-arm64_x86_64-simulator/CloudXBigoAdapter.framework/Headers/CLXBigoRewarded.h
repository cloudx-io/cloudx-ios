#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoRewarded
 * @brief BIGO Ads rewarded video adapter.
 * @discussion Loads the winning bid's encrypted `adm` through `BigoRewardVideoAdLoader` against
 *             the BIGO Slot ID the CloudX backend stamped on the bid, then presents the
 *             resulting `BigoRewardVideoAd`. BIGO reports no reward amount or label, so the
 *             reward callback carries amount 0 and a nil label.
 */
@interface CLXBigoRewarded : CLXAdapterRewarded

/**
 * @brief Creates a rewarded adapter for one winning bid.
 * @param bidPayload The bid's `adm` (the BIGO server-bidding payload); nil when absent.
 * @param slotID The BIGO Slot ID from `adapter_extras.placement_id`.
 * @param adUnitName Publisher ad unit name for log and error context.
 * @param mediationExt Mediation descriptor JSON handed to the BIGO loader; nil to omit.
 * @param logger Adapter logger supplied by CloudXCore.
 * @return An adapter ready for `-loadWithParams:`.
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                            slotID:(NSString *)slotID
                        adUnitName:(nullable NSString *)adUnitName
                      mediationExt:(nullable NSString *)mediationExt
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
