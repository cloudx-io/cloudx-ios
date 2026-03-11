#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialAdManager.h>
#import <CloudXCore/CLXAdapterInterstitial.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralInterstitial - Mintegral Interstitial Ad Implementation
 *
 * Uses the NEW Interstitial API as recommended by Mintegral.
 * Supports both bidding (MTGNewInterstitialBidAdManager) and waterfall (MTGNewInterstitialAdManager).
 */
@interface CLXMintegralInterstitial : NSObject <MTGNewInterstitialBidAdDelegate, MTGNewInterstitialAdDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                     playVideoMute:(BOOL)playVideoMute
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
