//
//  CLXMintegralNative.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNativeAdvanced/MTGNativeAdvancedAd.h>
#import <MTGSDKNativeAdvanced/MTGNativeAdvancedAdDelegate.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mintegral native adapter — conforms to `CLXAdapterNative` and
 * `MTGNativeAdvancedAdDelegate` for the underlying `MTGNativeAdvancedAd` SDK handle.
 *
 * Self-rendered: `fetchAdView` returns a fully composed UIView. The bridge
 * detects this via `[CLXMintegralNativeAd isSelfRendered] == YES` and uses
 * the view directly instead of assembling a template.
 *
 * Bidding-only: loads via `loadAdWithBidToken:` with the auction's bid payload.
 * An empty payload fails fast — there is no waterfall fallback, so the adapter
 * can never serve demand CloudX didn't auction.
 */
@interface CLXMintegralNative : CLXAdapterNative <MTGNativeAdvancedAdDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                        adUnitName:(nullable NSString *)adUnitName
                            adSize:(CGSize)adSize
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
