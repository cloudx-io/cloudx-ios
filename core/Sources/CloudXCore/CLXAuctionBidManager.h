/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAuctionBidManager.h
 * @brief Auction bid state manager matching Android AuctionBidManager
 * 
 * Manages bid states throughout the auction lifecycle for win/loss tracking.
 * Tracks which bids succeeded, failed, and their loss reasons.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidResponseBid;

/**
 * Manages auction bid state tracking
 * Matches Android's AuctionBidManager functionality
 */
@interface CLXAuctionBidManager : NSObject

/**
 * Adds a bid to the auction tracking
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
- (void)setBidWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId;

/**
 * Gets a specific bid from an auction
 * @param auctionId The auction identifier
 * @param bidId The bid identifier
 * @return The bid object, or nil if not found
 */
- (nullable CLXBidResponseBid *)getBid:(NSString *)auctionId bidId:(NSString *)bidId;

/**
 * Gets the loss reason for a specific bid
 * @param auctionId The auction identifier
 * @param bidId The bid identifier
 * @return The loss reason, or nil if not set
 */
- (nullable NSNumber *)getBidLossReason:(NSString *)auctionId bidId:(NSString *)bidId;

/**
 * Gets the winning bid price for an auction
 * @param auctionId The auction identifier
 * @return The winning bid price, or 0.0 if no winner set
 */
- (double)getLoadedBidPrice:(NSString *)auctionId;

/**
 * Clears all data for a specific auction
 * @param auctionId The auction identifier
 */
- (void)clearAuction:(NSString *)auctionId;

@end

NS_ASSUME_NONNULL_END
