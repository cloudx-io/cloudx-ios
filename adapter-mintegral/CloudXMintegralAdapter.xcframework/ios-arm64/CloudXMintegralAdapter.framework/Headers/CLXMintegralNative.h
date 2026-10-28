//
//  CLXMintegralNative.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDK/MTGBidNativeAdManager.h>
#import <MTGSDK/MTGMediaView.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mintegral native adapter — conforms to `CLXAdapterNative`,
 * `MTGBidNativeAdManagerDelegate`, and `MTGMediaViewDelegate` for the underlying
 * Mintegral custom rendering bidding SDK handle.
 *
 * Custom rendered: delivers discrete native assets (title, body, CTA, icon,
 * mediaView, optionsView) via `CLXMintegralNativeAd` to the CloudX native pipeline
 * (standalone native, native-in-banner 320x50, native-in-MREC 300x250).
 *
 * Bidding-only: loads via `loadWithBidToken:` with the auction's bid payload.
 * An empty payload fails fast — there is no waterfall fallback.
 */
@interface CLXMintegralNative : CLXAdapterNative <MTGBidNativeAdManagerDelegate, MTGMediaViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                        adUnitName:(nullable NSString *)adUnitName
                     requiresTitle:(BOOL)requiresTitle
               isCompactBannerSlot:(BOOL)isCompactBannerSlot
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
