/*
 * CLXTaurusXRewarded+Internal.h
 * CloudXTaurusXAdapter
 */

#if __has_include(<CloudXTaurusXAdapter/CLXTaurusXRewarded.h>)
#import <CloudXTaurusXAdapter/CLXTaurusXRewarded.h>
#else
#import "CLXTaurusXRewarded.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXRewarded (Internal)

/**
 * The initializer the rewarded factory uses. It lives here rather than in the public header so
 * the released initializer, which keeps the close-time reward, stays the published API.
 *
 * @param rewardOnGrant YES forwards the network's earned reward the moment it is granted instead
 *        of holding it until the ad closes, so an ad the user never closes still pays.
 */
- (instancetype)initWithPlacementID:(nullable NSString *)placementID
                             payload:(nullable NSString *)payload
                       rewardOnGrant:(BOOL)rewardOnGrant;

@end

NS_ASSUME_NONNULL_END
