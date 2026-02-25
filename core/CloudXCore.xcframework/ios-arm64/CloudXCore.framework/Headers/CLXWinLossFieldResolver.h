/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossFieldResolver.h
 * @brief Win/Loss field resolver for payload construction
 * 
 * Resolves dynamic fields for win/loss notification payloads using server-driven configuration.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSDKConfigResponse;
@class CLXBidResponseBid;
@class CLXTrackingFieldResolver;
@class CLXBidLifecycleEvent;

/**
 * Resolves fields in win/loss notification payloads
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
 * Builds a win/loss notification payload with dynamic field resolution.
 * Delegates most field paths to CLXTrackingFieldResolver.
 */
- (nullable NSDictionary<NSString *, id> *)buildWinLossPayloadWithAuctionId:(NSString *)auctionId
                                                                        bid:(nullable CLXBidResponseBid *)bid
                                                                 lossReason:(nullable NSNumber *)lossReason
                                                                      event:(CLXBidLifecycleEvent *)event
                                                              loadedBidPrice:(double)loadedBidPrice
                                                                      error:(nullable CLXError *)error;

@end

NS_ASSUME_NONNULL_END
