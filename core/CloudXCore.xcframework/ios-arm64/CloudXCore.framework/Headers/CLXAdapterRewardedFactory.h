/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterRewardedFactory.h
 * @brief Abstract base class for rewarded adapter factories
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterRewarded;

/// Abstract base class for rewarded adapter factories.
/// Subclass MUST override the create method.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterRewardedFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterRewarded *)createWithAdId:(NSString *)adId
                                          bidId:(NSString *)bidId
                                            adm:(NSString *)adm
                                         extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(nullable NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END
