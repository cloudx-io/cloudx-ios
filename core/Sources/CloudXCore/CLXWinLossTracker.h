/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTracker.h
 * @brief Win/Loss tracker interface matching Android WinLossTracker exactly
 * 
 * Main coordinator for win/loss tracking functionality. Manages bid states,
 * builds payloads, and sends notifications to the server.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSDKConfigResponse;
@class CLXBidResponseBid;

/**
 * Protocol defining win/loss tracking interface
 * Matches Android's WinLossTracker interface exactly
 */
@protocol CLXWinLossTracking <NSObject>

/**
 * Sets the app key for authorization
 * @param appKey The application key
 */
- (void)setAppKey:(NSString *)appKey;

/**
 * Sets the server endpoint URL for win/loss notifications
 * @param endpointUrl The endpoint URL (nullable)
 */
- (void)setEndpoint:(nullable NSString *)endpointUrl;

/**
 * Sets the SDK configuration for field resolution
 * @param config The SDK configuration response
 */
- (void)setConfig:(CLXSDKConfigResponse *)config;

/**
 * Attempts to send pending win/loss events from cache
 */
- (void)trySendingPendingWinLossEvents;

/**
 * Adds a bid to auction tracking
 * @param auctionId The auction identifier
 * @param bid The bid to track
 */
- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid;

/**
 * Sets the load result for a specific bid
 * @param auctionId The auction identifier
 * @param bidId The bid identifier
 * @param success Whether the bid loaded successfully
 * @param lossReason The loss reason if unsuccessful (nullable)
 */
- (void)setBidLoadResult:(NSString *)auctionId
                   bidId:(NSString *)bidId
                 success:(BOOL)success
              lossReason:(nullable NSNumber *)lossReason;

/**
 * Sets the winning bid for an auction
 * @param auctionId The auction identifier
 * @param winningBidId The winning bid identifier
 */
- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId;

/**
 * Sends loss notification for a specific bid
 * @param auctionId The auction identifier
 * @param bidId The bid identifier
 */
- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId;

/**
 * Sends win notification for a specific bid
 * @param auctionId The auction identifier
 * @param bidId The bid identifier
 */
- (void)sendWin:(NSString *)auctionId bidId:(NSString *)bidId;

/**
 * Clears all data for a specific auction
 * @param auctionId The auction identifier
 */
- (void)clearAuction:(NSString *)auctionId;

@end

/**
 * Main win/loss tracker implementation
 * Matches Android's WinLossTrackerImpl functionality
 */
@interface CLXWinLossTracker : NSObject <CLXWinLossTracking>

/**
 * Shared singleton instance
 * @return The shared win/loss tracker instance
 */
+ (instancetype)shared;

#pragma mark - Testing Support

/**
 * Override shared instance for testing
 * @param testInstance Mock instance to use in tests
 */
+ (void)setSharedInstanceForTesting:(id<CLXWinLossTracking>)testInstance;

/**
 * Reset shared instance to default implementation
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
