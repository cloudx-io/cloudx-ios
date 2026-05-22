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

/**
 * Key in `localExtraParameters` whose value is an NSValue wrapping CGSize.
 * When present, indicates the target container size for native-in-banner rendering
 * (e.g., 320x50 compact banner or 300x250 MREC).
 *
 * Populated by CLXNativeBannerBridge before invoking a native factory on the
 * banner/MREC path. Adapters that need size at init time (e.g., Mintegral) must
 * read this value. Adapters that do not may ignore it.
 */
CLX_PUBLIC_ADAPTER FOUNDATION_EXPORT NSString * const CLXNativeContainerTargetSizeKey;

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
