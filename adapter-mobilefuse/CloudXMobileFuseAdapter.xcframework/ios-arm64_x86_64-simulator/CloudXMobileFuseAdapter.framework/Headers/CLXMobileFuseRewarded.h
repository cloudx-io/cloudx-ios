//
//  CLXMobileFuseRewarded.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Rewarded adapter that wraps `MFRewardedAd`.
 *
 * Reward emission is deferred: -onUserEarnedReward: sets an internal flag,
 * and the reward delegate callback fires inside -onAdClosed: so the
 * publisher always sees `userReward` before `didClose`.
 */
@interface CLXMobileFuseRewarded : CLXAdapterRewarded <IMFAdCallbackReceiver>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
