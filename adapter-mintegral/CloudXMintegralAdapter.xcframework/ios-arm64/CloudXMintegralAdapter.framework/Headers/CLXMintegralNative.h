//
//  CLXMintegralNative.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNativeAdvanced/MTGNativeAdvancedAd.h>
#import <MTGSDKNativeAdvanced/MTGNativeAdvancedAdDelegate.h>
#import <CloudXCore/CLXAdapterNative.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mintegral native adapter — conforms to `CLXAdapterNative` and
 * `MTGNativeAdvancedAdDelegate` for the underlying `MTGNativeAdvancedAd` SDK handle.
 *
 * Self-rendered: `fetchAdView` returns a fully composed UIView. The bridge
 * detects this via `[CLXMintegralNativeAd isSelfRendered] == YES` and uses
 * the view directly instead of assembling a template.
 *
 * Bidding-only: waterfall is not supported in the native-in-banner pipeline.
 */
@interface CLXMintegralNative : CLXAdapterNative <MTGNativeAdvancedAdDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                            adSize:(CGSize)adSize
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
