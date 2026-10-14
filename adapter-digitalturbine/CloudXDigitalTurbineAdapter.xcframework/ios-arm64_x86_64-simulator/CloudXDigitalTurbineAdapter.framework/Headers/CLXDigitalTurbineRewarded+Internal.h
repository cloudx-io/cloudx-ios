/*
 * CLXDigitalTurbineRewarded+Internal.h
 * CloudXDigitalTurbineAdapter
 */

#if __has_include(<CloudXDigitalTurbineAdapter/CLXDigitalTurbineRewarded.h>)
#import <CloudXDigitalTurbineAdapter/CLXDigitalTurbineRewarded.h>
#else
#import "CLXDigitalTurbineRewarded.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXDigitalTurbineRewarded (Internal)

/**
 * The initializer the rewarded factory uses. It lives here rather than in the public header so
 * the released initializer, which keeps the close-time reward, stays the published API.
 *
 * @param rewardOnGrant YES forwards the network's earned reward the moment it is granted instead
 *        of holding it until the ad closes, so an ad the user never closes still pays.
 */
- (instancetype)initWithBidPayload:(NSString *)bidPayload
                            spotID:(nullable NSString *)spotID
                        adUnitName:(nullable NSString *)adUnitName
                           isMuted:(nullable NSNumber *)isMuted
                            logger:(id<CLXAdapterLogger>)logger
                     rewardOnGrant:(BOOL)rewardOnGrant;

@end

NS_ASSUME_NONNULL_END
