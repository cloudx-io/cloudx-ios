/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossFieldResolver.h
 * @brief Win/Loss field resolver matching Android WinLossFieldResolver
 * 
 * Resolves dynamic fields for win/loss notification payloads using server-driven configuration.
 * This matches the Android implementation exactly for consistent cross-platform behavior.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSDKConfigResponse;
@class CLXBidResponseBid;
@class CLXTrackingFieldResolver;

/**
 * iOS equivalent of Android's WinLossFieldResolver
 * Builds win/loss notification payloads with dynamic field resolution
 */
@interface CLXWinLossFieldResolver : NSObject

/**
 * Initializes the resolver with a specific payload mapping (for testing)
 * @param payloadMapping The payload mapping dictionary
 * @return Initialized resolver instance
 */
- (instancetype)initWithPayloadMapping:(NSDictionary<NSString *, NSString *> *)payloadMapping;

/**
 * Initializes the resolver with dependencies (for testing with mocks)
 * @param payloadMapping The payload mapping dictionary
 * @param trackingFieldResolver The tracking field resolver dependency
 * @return Initialized resolver instance
 */
- (instancetype)initWithPayloadMapping:(NSDictionary<NSString *, NSString *> *)payloadMapping
                  trackingFieldResolver:(CLXTrackingFieldResolver *)trackingFieldResolver;

/**
 * Sets the SDK configuration containing server-driven field mappings
 * @param config The SDK configuration response
 */
- (void)setConfig:(CLXSDKConfigResponse *)config;

/**
 * Builds a win/loss notification payload with dynamic field resolution
 * Matches Android's buildWinLossPayload method exactly
 * 
 * @param auctionId The auction identifier
 * @param bid The bid object (nullable for some loss scenarios)
 * @param lossReason The loss reason (nullable for win scenarios)
 * @param isWin Whether this is a win (YES) or loss (NO) notification
 * @param loadedBidPrice The price of the winning bid
 * @return Dictionary containing the payload, or nil if no mapping configured
 */
- (nullable NSDictionary<NSString *, id> *)buildWinLossPayloadWithAuctionId:(NSString *)auctionId
                                                                        bid:(nullable CLXBidResponseBid *)bid
                                                                 lossReason:(nullable NSNumber *)lossReason
                                                                      isWin:(BOOL)isWin
                                                              loadedBidPrice:(double)loadedBidPrice;

@end

NS_ASSUME_NONNULL_END
