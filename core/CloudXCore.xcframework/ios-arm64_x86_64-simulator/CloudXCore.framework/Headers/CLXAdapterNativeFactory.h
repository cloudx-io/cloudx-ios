/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNative;
@protocol CLXAdapterNativeDelegate;

@protocol CLXAdapterNativeFactory <NSObject>

- (nullable id<CLXAdapterNative>)createWithAdId:(NSString *)adId
                                          bidId:(NSString *)bidId
                                            adm:(NSString *)adm
                                         extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(nullable NSString *)adUnitName
                               bidExpirationMs:(NSInteger)bidExpirationMs
                           localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                                       delegate:(id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
