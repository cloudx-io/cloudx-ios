/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBidTokenSource.h
 * @brief Bid token source protocol
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudXBidTokenSource is a protocol for networks that require bid tokens for bid requests.
 * It mirrors the Swift BidTokenSource protocol and provides access to bid tokens from ad networks.
 */
@protocol CLXBidTokenSource <NSObject>

/**
 * Returns bid token from ad network.
 * @param completion Completion block that returns the token dictionary or error
 */
- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 