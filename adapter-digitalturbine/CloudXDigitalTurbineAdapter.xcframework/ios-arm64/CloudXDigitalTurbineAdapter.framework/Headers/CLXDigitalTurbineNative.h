/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXDigitalTurbineNative : CLXAdapterNative

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                            spotID:(nullable NSString *)spotID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                   bidExpirationMs:(NSInteger)bidExpirationMs
                           isMuted:(nullable NSNumber *)isMuted
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
