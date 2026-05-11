/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterInterstitialFactory.h
 * @brief Abstract base class for interstitial adapter factories
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterInterstitial;

/// Abstract base class for interstitial adapter factories.
/// Subclass MUST override @c -createWithAdId:bidId:adm:extras:adUnitName:.
/// The wrapper attaches itself as the adapter's delegate after construction.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterInterstitialFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterInterstitial *)createWithAdId:(NSString *)adId
                                              bidId:(NSString *)bidId
                                                adm:(NSString *)adm
                                             extras:(NSDictionary<NSString *, NSString *> *)extras
                                         adUnitName:(nullable NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END
