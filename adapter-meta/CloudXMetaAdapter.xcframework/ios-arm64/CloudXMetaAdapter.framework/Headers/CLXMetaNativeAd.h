/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXNativeAd.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNativeDelegate;

@interface CLXMetaNativeAd : CLXNativeAd <FBMediaViewDelegate>

@property (nonatomic, strong, nullable) FBNativeAd *fbNativeAd;
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithFBNativeAd:(FBNativeAd *)fbNativeAd
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
