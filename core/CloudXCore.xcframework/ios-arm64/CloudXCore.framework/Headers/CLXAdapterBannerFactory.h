/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterBannerFactory.h
 * @brief Abstract base class for banner adapter factories
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterBanner;

/// Abstract base class for banner adapter factories.
/// Subclass MUST override @c -createWithType:adId:bidId:adm:hasClosedButton:extras:adUnitName:.
/// The wrapper attaches itself as the adapter's delegate after construction.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterBannerFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterBanner *)createWithType:(CLXBannerType)type
                                          adId:(NSString *)adId
                                         bidId:(NSString *)bidId
                                           adm:(NSString *)adm
                               hasClosedButton:(BOOL)hasClosedButton
                                        extras:(NSDictionary<NSString *, NSString *> *)extras
                                    adUnitName:(nullable NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END
