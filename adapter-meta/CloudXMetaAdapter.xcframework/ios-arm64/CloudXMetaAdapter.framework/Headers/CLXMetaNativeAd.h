/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXNativeAd.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNativeDelegate;

@interface CLXMetaNativeAd : CLXNativeAd <FBMediaViewDelegate>

/// Holds either `FBNativeAd` (full native, has media view) or `FBNativeBannerAd` (compact, no media view).
/// Downstream code branches on `isKindOfClass:` at register and options-wiring time.
@property (nonatomic, strong, nullable) FBNativeAdBase *fbNativeAd;
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithFBNativeAd:(FBNativeAdBase *)fbNativeAd
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
