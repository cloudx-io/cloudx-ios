/*
 * CLXUnityAdsRewarded+Internal.h
 * CloudXUnityAdsAdapter
 */

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>
#else
#import "CLXUnityAdsRewarded.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsRewarded (Internal)

/**
 * The initializer the rewarded factory uses. It lives here rather than in the public header so
 * the released initializer, which keeps the close-time reward, stays the published API.
 *
 * @param rewardOnGrant YES forwards the network's earned reward the moment it is granted instead
 *        of holding it until the show completes, so an ad the user never closes still pays.
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                            logger:(id<CLXAdapterLogger>)logger
                     rewardOnGrant:(BOOL)rewardOnGrant;

@end

NS_ASSUME_NONNULL_END
