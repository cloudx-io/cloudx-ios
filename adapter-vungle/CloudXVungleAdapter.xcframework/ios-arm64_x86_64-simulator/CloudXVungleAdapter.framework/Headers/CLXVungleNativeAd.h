//
//  CLXVungleNativeAd.h
//  CloudXVungleAdapter
//

#import <UIKit/UIKit.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXNativeAd.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstraction over the subset of `VungleNative` the adapter consumes.
 *
 * The Vungle SDK ships `VungleNative` as a concrete class whose asset
 * accessors are read-only, so it cannot be instantiated with controlled values
 * in a unit test. Depending on this protocol (which `VungleNative` satisfies via
 * the category below) lets the adapter be exercised with a deterministic test
 * double and keeps the dependency inverted on an abstraction rather than the
 * concrete SDK type.
 */
@protocol CLXVungleNativeAdapting <NSObject>

/// Mirrors `VungleNative`'s own delegate — the SDK -> adapter callback ref, where
/// `VungleNative` controls the actual storage, so this annotation is descriptive.
/// This is NOT the data-pipeline delegate: callback fidelity is guaranteed by the
/// *strong* adapter -> core delegate (`CLXAdapterNative.delegate`, "strong to keep
/// the callback chain alive through the ad lifecycle") plus the core wrapper
/// retaining the adapter. This SDK-facing back-ref stays `weak` so a missed
/// `-destroy` cannot strand an adapter <-> SDK retain cycle.
@property (nonatomic, weak, nullable) id<VungleNativeDelegate> delegate;
@property (nonatomic, readonly, copy, nullable) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *bodyText;
@property (nonatomic, readonly, copy, nullable) NSString *callToAction;
@property (nonatomic, readonly, copy, nullable) NSString *sponsoredText;
@property (nonatomic, readonly, strong, nullable) UIImage *iconImage;
@property (nonatomic, readonly) double adStarRating;

- (BOOL)hasVideoContent;
- (BOOL)canPlayAd;
- (CGFloat)getMediaAspectRatio;
- (void)registerViewForInteractionWithView:(UIView *)view
                                 mediaView:(MediaView *)mediaView
                             iconImageView:(nullable UIImageView *)iconImageView
                            viewController:(nullable UIViewController *)viewController
                            clickableViews:(nullable NSArray<UIView *> *)clickableViews;
- (void)performCTA;
- (void)unregisterView;

@end

/// `VungleNative` already implements every member of `CLXVungleNativeAdapting`;
/// this category only declares the conformance so the adapter can hold the SDK
/// object behind the protocol.
@interface VungleNative (CLXVungleNativeAdapting) <CLXVungleNativeAdapting>
@end

/**
 * Concrete `CLXNativeAd` wrapping a Vungle native SDK handle.
 *
 * Wires the adapter's registration call (`registerViewForInteractionWithView:
 * mediaView:iconImageView:viewController:clickableViews:`) in
 * `prepareForInteractionClickableViews:withContainer:`. Holds the SDK object
 * behind `CLXVungleNativeAdapting` so it can be unit-tested with a fake.
 */
@interface CLXVungleNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<CLXVungleNativeAdapting> vungleNative;

- (instancetype)initWithVungleNative:(id<CLXVungleNativeAdapting>)vungleNative;

@end

NS_ASSUME_NONNULL_END
