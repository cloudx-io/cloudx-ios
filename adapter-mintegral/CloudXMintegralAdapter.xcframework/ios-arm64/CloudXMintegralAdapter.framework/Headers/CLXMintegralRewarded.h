#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>
#import <MTGSDKReward/MTGRewardAdManager.h>
#import <MTGSDK/MTGRewardAdInfo.h>
#import <CloudXCore/CLXAdapterRewarded.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralRewarded - Mintegral Rewarded Ad Implementation
 *
 * Supports both bidding (MTGBidRewardAdManager) and waterfall (MTGRewardAdManager).
 * Both use singleton pattern via [*sharedInstance].
 */
@interface CLXMintegralRewarded : CLXAdapterRewarded <MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                     playVideoMute:(BOOL)playVideoMute;

@end

NS_ASSUME_NONNULL_END
