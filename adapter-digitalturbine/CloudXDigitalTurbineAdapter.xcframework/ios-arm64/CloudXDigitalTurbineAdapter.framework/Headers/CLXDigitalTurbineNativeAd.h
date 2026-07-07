/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXNativeAd.h>
#import <CloudXCore/CLXAdapterLogger.h>

// Forward-declare the protocol so external consumers don't need the
// adapter-internal protocol header. The full definition is in
// CLXDigitalTurbineNativeAdapting.h, which .m files import directly.
@protocol CLXDigitalTurbineNativeAdapting;

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete `CLXNativeAd` wrapping a DigitalTurbine (Fyber) native assets
 * handle.
 *
 * Registers native ad views via `registerViewForInteraction:` in
 * `prepareForInteractionClickableViews:withContainer:`. Holds the SDK object
 * behind `CLXDigitalTurbineNativeAdapting` so it can be unit-tested with a
 * fake.
 */
@interface CLXDigitalTurbineNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<CLXDigitalTurbineNativeAdapting> nativeAdAssets;

- (instancetype)initWithAssets:(id<CLXDigitalTurbineNativeAdapting>)assets
          localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
