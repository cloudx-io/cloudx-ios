//
//  CLXMintegralNativeAd.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDK/MTGBidNativeAdManager.h>
#import <MTGSDK/MTGCampaign.h>
#import <MTGSDK/MTGMediaView.h>
#import <MTGSDK/MTGAdChoicesView.h>
#import <CloudXCore/CLXNativeAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete `CLXNativeAd` wrapping Mintegral custom rendering native assets.
 *
 * Custom rendered: exposes discrete native assets (title, body, CTA, icon,
 * mediaView, optionsView) so CloudX can assemble the ad using its standard
 * native templates (standalone native, native-in-banner 320x50, native-in-MREC 300x250).
 *
 * `isSelfRendered` returns NO — CloudX renders the template from assets.
 * `isContainerClickable` returns NO — clicks are handled by Mintegral on the registered views.
 */
@interface CLXMintegralNativeAd : CLXNativeAd

@property (nonatomic, strong, readonly) MTGCampaign *campaign;
@property (nonatomic, strong, readonly, nullable) MTGBidNativeAdManager *adManager;
@property (nonatomic, strong, readonly, nullable) MTGMediaView *mtgMediaView;
@property (nonatomic, strong, readonly, nullable) MTGAdChoicesView *adChoicesView;

- (instancetype)initWithCampaign:(MTGCampaign *)campaign
                       adManager:(nullable MTGBidNativeAdManager *)adManager
                       mediaView:(nullable MTGMediaView *)mediaView
                     optionsView:(nullable MTGAdChoicesView *)optionsView
            localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)unregisterView;

@end

NS_ASSUME_NONNULL_END
