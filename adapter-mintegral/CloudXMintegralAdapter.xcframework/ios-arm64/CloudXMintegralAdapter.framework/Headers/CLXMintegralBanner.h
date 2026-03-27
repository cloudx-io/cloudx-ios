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
@interface CLXMintegralBanner : NSObject <MTGBannerAdViewDelegate, CLXAdapterBanner>

@property (nonatomic, strong, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                   hasClosedButton:(BOOL)hasClosedButton
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
