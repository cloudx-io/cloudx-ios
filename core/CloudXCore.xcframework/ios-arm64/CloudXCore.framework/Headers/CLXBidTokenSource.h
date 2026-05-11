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
 * Subclass MUST override @c -getTokenWithCompletion:. Optional impression-level
 * params can be returned via @c -bidderImpressionParams (default nil).
 */
CLX_PUBLIC_ADAPTER
@interface CLXBidTokenSource : NSObject

+ (instancetype)createInstance;

/// Returns bid token from ad network. Subclass MUST override.
- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion;

/// Returns Prebid Server bidder params for impression-level configuration.
/// Default implementation returns nil — override for adapters that need per-impression bidder params
/// (e.g. zoneId for Magnite). The returned dictionary is placed at
/// @c imp.ext.prebid.bidder.<adapterName> in the OpenRTB bid request.
- (nullable NSDictionary *)bidderImpressionParams;

@end

NS_ASSUME_NONNULL_END
