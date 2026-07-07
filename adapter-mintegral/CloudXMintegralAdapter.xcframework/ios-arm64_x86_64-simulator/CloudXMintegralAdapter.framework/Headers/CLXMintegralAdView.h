#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralAdView - Mintegral Banner Ad Implementation
 *
 * Uses MTGBannerAdView which supports both bidding and waterfall.
 * Includes proper banner configuration such as autoRefreshTime.
 */
@interface CLXMintegralAdView : CLXAdapterAdView <MTGBannerAdViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             unitID:(NSString *)unitID
                               size:(CGSize)size
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
