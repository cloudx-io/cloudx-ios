//
//  CLXMagniteNativeAd.h
//  CloudXMagniteAdapter
//

#import <UIKit/UIKit.h>
#import <MagniteSDK/Magnite.h>

#import <CloudXCore/CLXNativeAd.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstraction over the subset of Magnite's `MGNINativeAdDetails` the adapter consumes.
 *
 * `MGNINativeAdDetails` ships as a concrete SDK class whose `mediaView`,
 * `videoAspectRatio`, and `isVideo` accessors are read-only and populated
 * internally by the SDK, so they cannot be stubbed on a real instance in a unit
 * test. Depending on this protocol (which `MGNINativeAdDetails` satisfies via
 * the category below) lets the adapter be exercised with a deterministic test
 * double while keeping the dependency inverted on the abstraction rather than
 * the concrete SDK type.
 */
@protocol CLXMagniteNativeAdapting <NSObject>

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *description;
@property (nonatomic, copy, nullable) NSString *callToAction;
@property (nonatomic, copy, nullable) NSString *clickToInstall;
@property (nonatomic, copy, nullable) NSNumber *rating;
@property (nonatomic, copy, nullable) NSString *imageUrl;
@property (nonatomic, copy, nullable) NSString *secondaryImageUrl;
@property (nonatomic, copy, nullable) UIImage *imageBitmap;
@property (nonatomic, copy, nullable) UIImage *secondaryImageBitmap;
@property (nonatomic, copy, readonly, nullable) UIImage *policyImage;
@property (nonatomic, copy, readonly, nullable) NSString *eulaUrl;
@property (nonatomic, readonly, nullable) UIView *mediaView;
@property (nonatomic, readonly) CGFloat videoAspectRatio;
@property (nonatomic, readonly) BOOL isVideo;
@property (nonatomic, assign) BOOL videoMuted;

- (void)registerViewForImpression:(UIView *)view andViewsForClick:(NSArray<UIView *> *)clickableViews;
- (void)unregisterViews;

@end

/// `MGNINativeAdDetails` already implements every member of
/// `CLXMagniteNativeAdapting`, so this category only declares the conformance —
/// letting the adapter hold the SDK object behind the protocol without a
/// wrapper.
///
/// The compiler verifies only that `MGNINativeAdDetails` responds to each
/// selector, not that property attributes or return types match. A future
/// `MagniteSDK` bump that changes one of these signatures compiles silently
/// here and can surface as a runtime crash at the call site. Re-validate this
/// protocol against `MGNINativeAdDetails` on every `MagniteSDK` upgrade (see
/// the `DEBUG`-only runtime check in `CLXMagniteNative.m`).
@interface MGNINativeAdDetails (CLXMagniteNativeAdapting) <CLXMagniteNativeAdapting>
@end

/**
 * Concrete `CLXNativeAd` wrapping a Magnite native ad details handle.
 *
 * Registers the rendered container and clickable views for impression/click
 * tracking via `registerViewForImpression:andViewsForClick:` in
 * `prepareForInteractionClickableViews:withContainer:`. Holds the SDK object
 * behind `CLXMagniteNativeAdapting` so it can be unit-tested with a fake.
 */
@interface CLXMagniteNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<CLXMagniteNativeAdapting> magniteNativeAdDetails;

- (instancetype)initWithNativeAdDetails:(id<CLXMagniteNativeAdapting>)nativeAdDetails
                   localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                                 logger:(id<CLXAdapterLogger>)logger;

/// Stops Magnite's impression/click tracking. Called when the native ad is
/// replaced or destroyed.
- (void)stopTracking;

@end

NS_ASSUME_NONNULL_END
