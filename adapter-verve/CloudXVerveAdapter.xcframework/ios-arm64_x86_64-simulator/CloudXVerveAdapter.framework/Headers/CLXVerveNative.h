/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <HyBid/HyBid.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveNative : CLXAdapterNative <HyBidNativeAdLoaderDelegate, HyBidNativeAdFetchDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                   bidExpirationMs:(NSInteger)bidExpirationMs
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
