/*
 * CLXVerveRewarded+Internal.h
 * CloudXVerveAdapter
 */

#if __has_include(<CloudXVerveAdapter/CLXVerveRewarded.h>)
#import <CloudXVerveAdapter/CLXVerveRewarded.h>
#else
#import "CLXVerveRewarded.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveRewarded (Internal)

/**
 * The initializer the rewarded factory uses. It lives here rather than in the public header so
 * the released initializer, which keeps the close-time reward, stays the published API.
 *
 * @param rewardOnGrant YES forwards the network's earned reward the moment it is granted instead
 *        of holding it until the ad closes, so an ad the user never closes still pays.
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger
                     rewardOnGrant:(BOOL)rewardOnGrant;

@end

NS_ASSUME_NONNULL_END
