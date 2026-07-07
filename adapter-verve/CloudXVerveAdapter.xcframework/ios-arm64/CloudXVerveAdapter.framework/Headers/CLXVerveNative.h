/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <HyBid/HyBid.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveNative : CLXAdapterNative <HyBidNativeAdLoaderDelegate, HyBidNativeAdFetchDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
