#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#import <CloudXCore/CLXAdapterBanner.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralBanner - Mintegral Banner Ad Implementation
 *
 * Uses MTGBannerAdView which supports both bidding and waterfall.
 * Includes proper banner configuration: autoRefreshTime, showCloseButton.
 */
@interface CLXMintegralBanner : CLXAdapterBanner <MTGBannerAdViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                   hasClosedButton:(BOOL)hasClosedButton;

@end

NS_ASSUME_NONNULL_END
