//
//  CLXInMobiNativeAd.h
//  CloudXInMobiAdapter
//

#import <UIKit/UIKit.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXNativeAd.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstraction over the subset of InMobi's `IMNative` the adapter consumes.
 *
 * `IMNative` ships as a concrete SDK class whose asset accessors are read-only
 * and which cannot be instantiated with controlled values in a unit test.
 * Depending on this protocol (which `IMNative` satisfies via the category below)
 * lets the adapter be exercised with a deterministic test double and keeps the
 * dependency inverted on the abstraction rather than the concrete SDK type.
 */
@protocol CLXInMobiNativeAdapting <NSObject>

@property (nonatomic, weak, nullable) id<IMNativeDelegate> delegate;
@property (nonatomic, readonly, copy, nullable) NSString *adTitle;
@property (nonatomic, readonly, copy, nullable) NSString *adDescription;
@property (nonatomic, readonly, copy, nullable) NSString *adCtaText;
@property (nonatomic, readonly, copy, nullable) NSString *advertiserName;
@property (nonatomic, readonly, copy, nullable) NSString *creativeId;
@property (nonatomic, readonly, strong, nullable) IMNativeImage *adIcon;
@property (nonatomic, readonly, strong, nullable) UIImageView *adChoice;

- (BOOL)isReady;
- (BOOL)isVideoAd;
- (nullable UIView *)getMediaView;
- (void)registerViewForTracking:(IMNativeViewData *)viewData;

@end

/// `IMNative` already implements every member of `CLXInMobiNativeAdapting`, so
/// this category only declares the conformance — letting the adapter hold the
/// SDK object behind the protocol without a wrapper.
///
/// The compiler verifies only that `IMNative` responds to each selector, not
/// that property attributes or return types match (e.g. `adChoice` being a
/// `UIImageView *`, or `delegate`'s ownership). A future `InMobiSDK` bump that
/// changes one of these signatures compiles silently here and can surface as a
/// runtime crash at the call site (notably `builder.optionsView = imNative.adChoice`).
/// Re-validate this protocol against `IMNative` on every `InMobiSDK` upgrade.
@interface IMNative (CLXInMobiNativeAdapting) <CLXInMobiNativeAdapting>
@end

/**
 * Concrete `CLXNativeAd` wrapping an InMobi native SDK handle.
 *
 * Registers the native ad views via `IMNativeViewDataBuilder` in
 * `prepareForInteractionClickableViews:withContainer:`. Holds the SDK object
 * behind `CLXInMobiNativeAdapting` so it can be unit-tested with a fake.
 */
@interface CLXInMobiNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<CLXInMobiNativeAdapting> imNative;

- (instancetype)initWithIMNative:(id<CLXInMobiNativeAdapting>)imNative
            localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
