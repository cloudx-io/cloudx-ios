//
//  CLXMintegralNativeAd.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNativeAdvanced/MTGNativeAdvancedAd.h>
#import <CloudXCore/CLXNativeAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete `CLXNativeAd` wrapping a Mintegral `MTGNativeAdvancedAd` handle.
 *
 * Self-rendered: `mediaView` exposes the result of `-[MTGNativeAdvancedAd fetchAdView]`,
 * which is a fully composed UIView. Title/body/icon/CTA are not populated because
 * the Mintegral SDK renders them internally.
 *
 * `isSelfRendered` returns YES — this is the signal CLXNativeBannerBridge reads
 * to bypass template assembly and use the returned mediaView directly.
 * `isContainerClickable` is also YES because the composed view handles its own
 * click registration; the two signals happen to align for Mintegral but are
 * independent in general.
 */
@interface CLXMintegralNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) MTGNativeAdvancedAd *mintegralAd;

- (instancetype)initWithMintegralAd:(MTGNativeAdvancedAd *)mintegralAd
               localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
