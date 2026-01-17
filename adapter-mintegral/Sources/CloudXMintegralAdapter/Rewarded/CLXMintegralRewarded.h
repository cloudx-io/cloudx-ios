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
 * IMPORTANT: Uses MTGBidRewardAdManager as a SINGLETON via [MTGBidRewardAdManager sharedInstance]
 * This matches the AppLovin adapter pattern and Mintegral's recommended usage.
 */
@interface CLXMintegralRewarded : NSObject <MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate, CLXAdapterRewarded>

@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *placementName;
@property (nonatomic, strong, readonly) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) BOOL playVideoMute;
@property (nonatomic, assign, readonly) BOOL isReady;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     placementName:(nullable NSString *)placementName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

