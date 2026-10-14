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
 * The reward reaches the publisher at most once, before `didClose`: inside
 * -onAdClosed: by default, or at -onUserEarnedReward: when the session's
 * reward-on-grant switch is on.
 */
@interface CLXMobileFuseRewarded : CLXAdapterRewarded <IMFAdCallbackReceiver>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
