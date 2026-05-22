//
//  CLXVungleNativeAd.h
//  CloudXVungleAdapter
//

#import <VungleAdsSDK/VungleAdsSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXNativeAd.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete `CLXNativeAd` wrapping a Vungle `VungleNative` SDK handle.
 *
 * Wires the adapter's registration call (`registerViewForInteractionWithView:
 * mediaView:iconImageView:viewController:clickableViews:`) in
 * `prepareForInteractionClickableViews:withContainer:`.
 */
@interface CLXVungleNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) VungleNative *vungleNative;

- (instancetype)initWithVungleNative:(VungleNative *)vungleNative
                localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
