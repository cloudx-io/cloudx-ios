/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAuctionBidManager.h
 * @brief Auction bid state manager
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
 * Tracks bid states and metadata for auction lifecycle
 */
@interface CLXAuctionBidManager : NSObject

/**
 * Shared bid-state instance. Bids are registered at bid-source time and read
 * back by the publisher classes when they build the impression event's
 * bidOutcomes set.
 */
+ (instancetype)shared;

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
 * Builds the impression event's bidOutcomes entries for an auction.
 * @param auctionId The auction identifier
 * @param winningBidId The bid that served
 * @return One entry per tracked bid with a sealed token: the winner is served,
 *         bids that failed to load are failedLoad, the rest are loadedNotShown.
 */
- (NSArray<NSDictionary<NSString *, NSString *> *> *)bidOutcomesForAuction:(NSString *)auctionId
                                                              winningBidId:(NSString *)winningBidId;

/**
 * Clears all data for a specific auction
 * @param auctionId The auction identifier
 */
- (void)clearAuction:(NSString *)auctionId;

@end

NS_ASSUME_NONNULL_END
