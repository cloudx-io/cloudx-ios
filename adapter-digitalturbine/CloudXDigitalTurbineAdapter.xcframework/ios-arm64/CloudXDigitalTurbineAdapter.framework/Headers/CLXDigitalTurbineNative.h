/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXDigitalTurbineNative : CLXAdapterNative

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                            spotID:(nullable NSString *)spotID
                        adUnitName:(nullable NSString *)adUnitName
                           isMuted:(nullable NSNumber *)isMuted
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
