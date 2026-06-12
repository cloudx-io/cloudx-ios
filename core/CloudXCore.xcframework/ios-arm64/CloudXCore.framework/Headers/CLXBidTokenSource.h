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

@end

NS_ASSUME_NONNULL_END
