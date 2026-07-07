#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKSplash/MTGSplashAD.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralAppOpen - Mintegral App Open Ad Implementation
 *
 * Backs the CloudX app-open format with Mintegral's Splash ad (`MTGSplashAD`).
 * Supports both bidding (preloadWithBidToken:) and waterfall (preload) flows.
 * App open reuses the interstitial adapter contract, so this subclasses
 * CLXAdapterInterstitial.
 */
@interface CLXMintegralAppOpen : CLXAdapterInterstitial <MTGSplashADDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
