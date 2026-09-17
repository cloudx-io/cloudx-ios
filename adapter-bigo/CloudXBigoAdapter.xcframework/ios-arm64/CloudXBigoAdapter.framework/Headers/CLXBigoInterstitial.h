#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoInterstitial
 * @brief BIGO Ads interstitial adapter.
 * @discussion Loads the winning bid's encrypted `adm` through `BigoInterstitialAdLoader` against
 *             the BIGO Slot ID the CloudX backend stamped on the bid, then presents the
 *             resulting `BigoInterstitialAd`.
 */
@interface CLXBigoInterstitial : CLXAdapterInterstitial

/**
 * @brief Creates an interstitial adapter for one winning bid.
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
