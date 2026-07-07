#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialAdManager.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralInterstitial - Mintegral Interstitial Ad Implementation
 *
 * Uses the NEW Interstitial API as recommended by Mintegral.
 * Supports both bidding (MTGNewInterstitialBidAdManager) and waterfall (MTGNewInterstitialAdManager).
 */
@interface CLXMintegralInterstitial : CLXAdapterInterstitial <MTGNewInterstitialBidAdDelegate, MTGNewInterstitialAdDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                     playVideoMute:(BOOL)playVideoMute
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
