/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXNativeAd.h>

@class IANativeAdAssets;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNativeDelegate;

@interface CLXDigitalTurbineNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) IANativeAdAssets *nativeAdAssets;
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithAssets:(IANativeAdAssets *)assets
          localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
