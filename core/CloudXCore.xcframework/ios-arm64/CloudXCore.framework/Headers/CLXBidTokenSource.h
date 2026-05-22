/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXBidTokenSource.h
 * @brief Abstract base class for bid token sources
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for networks that require bid tokens for bid requests.
 *
 * Subclass MUST override @c -getTokenWithCompletion:.
 */
CLX_PUBLIC_ADAPTER
@interface CLXBidTokenSource : NSObject

+ (instancetype)createInstance;

/// Returns bid token from ad network. Subclass MUST override.
- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion;

/// @deprecated Bidder params resolved server-side as of v2. Override retained for v1 ABI compatibility but the return value is not placed on the v2 wire. Remove the override when v1 support is dropped.
- (nullable NSDictionary *)bidderImpressionParams
    __attribute__((deprecated("Bidder params resolved server-side as of v2. Override retained for v1 ABI compatibility but the return value is not placed on the v2 wire. Remove the override when v1 support is dropped.")));

@end

NS_ASSUME_NONNULL_END
