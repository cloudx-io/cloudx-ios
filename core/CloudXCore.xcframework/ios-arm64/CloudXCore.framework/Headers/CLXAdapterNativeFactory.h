/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterNativeFactory.h
 * @brief Abstract base class for native adapter factories
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterNative;

/// Abstract base class for native adapter factories.
/// Subclass MUST override @c -createWithAdId:bidId:adm:extras:adUnitName:bidExpirationMs:localExtraParameters:.
/// The wrapper attaches itself as the adapter's delegate after construction.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterNativeFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterNative *)createWithAdId:(NSString *)adId
                                         bidId:(NSString *)bidId
                                           adm:(NSString *)adm
                                        extras:(NSDictionary<NSString *, NSString *> *)extras
                                    adUnitName:(nullable NSString *)adUnitName
                               bidExpirationMs:(NSInteger)bidExpirationMs
                          localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END
