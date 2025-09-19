/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAuctionBidManager.m
 * @brief Implementation of auction bid state manager matching Android exactly
 */

#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXLogger.h>

/**
 * Internal auction state tracking
 */
@interface CLXAuctionState : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, CLXBidResponseBid *> *bids;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *bidLossReasons;
@property (nonatomic, copy, nullable) NSString *winningBidId;
@property (nonatomic, assign) double winningBidPrice;
@end

@implementation CLXAuctionState

- (instancetype)init {
    self = [super init];
    if (self) {
        _bids = [NSMutableDictionary dictionary];
        _bidLossReasons = [NSMutableDictionary dictionary];
        _winningBidPrice = 0.0;
    }
    return self;
}

@end

@interface CLXAuctionBidManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, CLXAuctionState *> *auctionStates;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAuctionBidManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _auctionStates = [NSMutableDictionary dictionary];
        _logger = [[CLXLogger alloc] initWithCategory:@"AuctionBidManager"];
    }
    return self;
}

- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid {
    if (!auctionId || !bid || !bid.id) {
        [self.logger error:@"❌ [AuctionBidManager] Invalid parameters for addBid"];
        return;
    }
    
    CLXAuctionState *state = [self getOrCreateAuctionState:auctionId];
    state.bids[bid.id] = bid;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [AuctionBidManager] Added bid %@ to auction %@", bid.id, auctionId]];
}

- (void)setBidLoadResult:(NSString *)auctionId
                   bidId:(NSString *)bidId
                 success:(BOOL)success
              lossReason:(nullable NSNumber *)lossReason {
    
    if (!auctionId || !bidId) {
        [self.logger error:@"❌ [AuctionBidManager] Invalid parameters for setBidLoadResult"];
        return;
    }
    
    CLXAuctionState *state = [self getOrCreateAuctionState:auctionId];
    
    if (!success && lossReason) {
        state.bidLossReasons[bidId] = lossReason;
        [self.logger debug:[NSString stringWithFormat:@"📊 [AuctionBidManager] Set bid %@ loss reason: %@", bidId, lossReason]];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [AuctionBidManager] Set bid %@ load result - success: %@", 
                       bidId, success ? @"YES" : @"NO"]];
}

- (void)setBidWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    if (!auctionId || !winningBidId) {
        [self.logger error:@"❌ [AuctionBidManager] Invalid parameters for setBidWinner"];
        return;
    }
    
    CLXAuctionState *state = [self getOrCreateAuctionState:auctionId];
    state.winningBidId = winningBidId;
    
    // Set winning bid price from the bid object
    CLXBidResponseBid *winningBid = state.bids[winningBidId];
    if (winningBid) {
        state.winningBidPrice = winningBid.price;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [AuctionBidManager] Set winner for auction %@: %@ (price: %.2f)", 
                       auctionId, winningBidId, state.winningBidPrice]];
}

- (nullable CLXBidResponseBid *)getBid:(NSString *)auctionId bidId:(NSString *)bidId {
    if (!auctionId || !bidId) {
        return nil;
    }
    
    CLXAuctionState *state = self.auctionStates[auctionId];
    return state ? state.bids[bidId] : nil;
}

- (nullable NSNumber *)getBidLossReason:(NSString *)auctionId bidId:(NSString *)bidId {
    if (!auctionId || !bidId) {
        return nil;
    }
    
    CLXAuctionState *state = self.auctionStates[auctionId];
    return state ? state.bidLossReasons[bidId] : nil;
}

- (double)getLoadedBidPrice:(NSString *)auctionId {
    if (!auctionId) {
        return 0.0;
    }
    
    CLXAuctionState *state = self.auctionStates[auctionId];
    return state ? state.winningBidPrice : 0.0;
}

- (void)clearAuction:(NSString *)auctionId {
    if (!auctionId) {
        return;
    }
    
    [self.auctionStates removeObjectForKey:auctionId];
    [self.logger debug:[NSString stringWithFormat:@"🧹 [AuctionBidManager] Cleared auction data for %@", auctionId]];
}

#pragma mark - Private Methods

- (CLXAuctionState *)getOrCreateAuctionState:(NSString *)auctionId {
    CLXAuctionState *state = self.auctionStates[auctionId];
    if (!state) {
        state = [[CLXAuctionState alloc] init];
        self.auctionStates[auctionId] = state;
        [self.logger debug:[NSString stringWithFormat:@"🔧 [AuctionBidManager] Created new auction state for %@", auctionId]];
    }
    return state;
}

@end
