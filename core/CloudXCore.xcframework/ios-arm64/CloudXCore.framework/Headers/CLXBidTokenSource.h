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

@optional

/**
 * @brief Returns Prebid Server bidder params for impression-level configuration.
 * @discussion Adapters that require per-impression bidder params (e.g., zoneId for Magnite)
 * should implement this method. The returned dictionary is placed at
 * imp.ext.prebid.bidder.<adapterName> in the OpenRTB bid request.
 * @return Bidder params dictionary, or nil if no impression-level params are needed.
 */
- (nullable NSDictionary *)bidderImpressionParams;

@end

NS_ASSUME_NONNULL_END 