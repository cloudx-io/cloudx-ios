/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXNativeAd.h>

NS_ASSUME_NONNULL_BEGIN

@class HyBidNativeAd;
@protocol CLXAdapterNativeDelegate;

@interface CLXVerveNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) HyBidNativeAd *verveNativeAd;
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithNativeAd:(HyBidNativeAd *)nativeAd;
- (void)stopTracking;

@end

NS_ASSUME_NONNULL_END
