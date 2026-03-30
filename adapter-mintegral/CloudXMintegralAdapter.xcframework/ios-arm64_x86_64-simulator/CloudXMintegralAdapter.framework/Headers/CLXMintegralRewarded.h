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
@interface CLXMintegralRewarded : NSObject <MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate, CLXAdapterRewarded>

@property (nonatomic, strong, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) BOOL isReady;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                     playVideoMute:(BOOL)playVideoMute
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
