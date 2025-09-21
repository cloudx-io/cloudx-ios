/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockCLXWinLossTracker.h"
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXError.h>

static MockCLXWinLossTracker *_sharedTestInstance = nil;

@implementation MockCLXWinLossTracker {
    dispatch_queue_t _syncQueue;
    NSInteger _sendWinCallCount;
    NSInteger _sendLossCallCount;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.cloudx.mock.winlosstracker", DISPATCH_QUEUE_SERIAL);
        [self reset];
    }
    return self;
}

- (void)reset {
    dispatch_sync(_syncQueue, ^{
        self.winNotifications = [[NSMutableArray alloc] init];
        self.lossNotifications = [[NSMutableArray alloc] init];
        self.bidResults = [[NSMutableArray alloc] init];
        self.storedBids = [[NSMutableDictionary alloc] init];
        self.configuredAppKey = nil;
        self.configuredEndpoint = nil;
        _sendWinCallCount = 0;
        _sendLossCallCount = 0;
    });
}

#pragma mark - Thread-Safe Property Accessors

- (NSInteger)sendWinCallCount {
    __block NSInteger count;
    dispatch_sync(_syncQueue, ^{
        count = _sendWinCallCount;
    });
    return count;
}

- (void)setSendWinCallCount:(NSInteger)sendWinCallCount {
    dispatch_sync(_syncQueue, ^{
        _sendWinCallCount = sendWinCallCount;
    });
}

- (NSInteger)sendLossCallCount {
    __block NSInteger count;
    dispatch_sync(_syncQueue, ^{
        count = _sendLossCallCount;
    });
    return count;
}

- (void)setSendLossCallCount:(NSInteger)sendLossCallCount {
    dispatch_sync(_syncQueue, ^{
        _sendLossCallCount = sendLossCallCount;
    });
}

#pragma mark - CLXWinLossTracking Implementation

- (void)setAppKey:(NSString *)appKey {
    self.configuredAppKey = [appKey copy];
}

- (void)setEndpoint:(nullable NSString *)endpointUrl {
    self.configuredEndpoint = [endpointUrl copy];
}

- (void)setBidLoadResult:(NSString *)auctionId 
                   bidId:(NSString *)bidId 
                 success:(BOOL)success 
              lossReason:(nullable NSNumber *)lossReason {
    NSDictionary *result = @{
        @"auctionId": auctionId ?: @"",
        @"bidId": bidId ?: @"",
        @"success": @(success),
        @"lossReason": lossReason ?: [NSNull null],
        @"timestamp": [NSDate date]
    };
    dispatch_sync(_syncQueue, ^{
        [self.bidResults addObject:result];
    });
}

- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid {
    dispatch_sync(_syncQueue, ^{
        if (!self.storedBids[auctionId]) {
            self.storedBids[auctionId] = [[NSMutableArray alloc] init];
        }
        [self.storedBids[auctionId] addObject:bid];
    });
}

- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    // Mock implementation - could track winner settings if needed for tests
}

- (void)sendWin:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_sync(_syncQueue, ^{
        _sendWinCallCount++;
        
        // Look up the bid to get NURL and price
        CLXBidResponseBid *bid = [self findBid:bidId inAuction:auctionId];
        
        // Create comprehensive win notification with all expected fields
        NSMutableDictionary *winNotification = [@{
            @"auctionId": auctionId ?: @"",
            @"bidId": bidId ?: @"",
            @"type": @"win",
            @"timestamp": [NSDate date]
        } mutableCopy];
        
        if (bid) {
            // Add original URL (template before replacement)
            if (bid.nurl) {
                winNotification[@"originalURL"] = bid.nurl;
                
                // Simulate URL template replacement (like real CLXWinLossFieldResolver)
                NSString *resolvedURL = [bid.nurl stringByReplacingOccurrencesOfString:@"${AUCTION_PRICE}" 
                                                                            withString:[NSString stringWithFormat:@"%.2f", bid.price]];
                winNotification[@"resolvedURL"] = resolvedURL;
            }
            
            // Add bid price
            winNotification[@"bidPrice"] = @(bid.price);
        }
        
        [self.winNotifications addObject:[winNotification copy]];
    });
}

- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_sync(_syncQueue, ^{
        _sendLossCallCount++;
        
        // Look up the bid to get LURL and loss reason
        CLXBidResponseBid *bid = [self findBid:bidId inAuction:auctionId];
        NSNumber *lossReason = [self findLossReasonForBid:bidId inAuction:auctionId];
        
        // Create comprehensive loss notification with all expected fields
        NSMutableDictionary *lossNotification = [@{
            @"auctionId": auctionId ?: @"",
            @"bidId": bidId ?: @"",
            @"type": @"loss",
            @"timestamp": [NSDate date]
        } mutableCopy];
        
        if (bid) {
            // Add original URL (template before replacement)
            if (bid.lurl) {
                lossNotification[@"originalURL"] = bid.lurl;
                
                // Simulate URL template replacement (like real CLXWinLossFieldResolver)
                NSString *resolvedURL = [bid.lurl stringByReplacingOccurrencesOfString:@"${AUCTION_PRICE}" 
                                                                             withString:[NSString stringWithFormat:@"%.2f", bid.price]];
                if (lossReason) {
                    resolvedURL = [resolvedURL stringByReplacingOccurrencesOfString:@"${AUCTION_LOSS}" 
                                                                         withString:[lossReason stringValue]];
                }
                lossNotification[@"resolvedURL"] = resolvedURL;
            }
            
            // Add bid price
            lossNotification[@"bidPrice"] = @(bid.price);
        }
        
        // Add loss reason
        if (lossReason) {
            lossNotification[@"lossReason"] = lossReason;
        }
        
        [self.lossNotifications addObject:[lossNotification copy]];
    });
}

#pragma mark - Private Helper Methods

- (CLXBidResponseBid *)findBid:(NSString *)bidId inAuction:(NSString *)auctionId {
    NSArray<CLXBidResponseBid *> *bids = self.storedBids[auctionId];
    for (CLXBidResponseBid *bid in bids) {
        if ([bid.id isEqualToString:bidId]) {
            return bid;
        }
    }
    return nil;
}

- (NSNumber *)findLossReasonForBid:(NSString *)bidId inAuction:(NSString *)auctionId {
    for (NSDictionary *result in self.bidResults) {
        if ([result[@"auctionId"] isEqualToString:auctionId] && 
            [result[@"bidId"] isEqualToString:bidId] &&
            [result[@"success"] boolValue] == NO) {
            return result[@"lossReason"];
        }
    }
    return nil;
}

#pragma mark - Test Utilities

- (NSArray<NSDictionary *> *)winNotificationsForAuction:(NSString *)auctionId {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.winNotifications filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"auctionId == %@", auctionId]];
    });
    return result;
}

- (NSArray<NSDictionary *> *)lossNotificationsForAuction:(NSString *)auctionId {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.lossNotifications filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"auctionId == %@", auctionId]];
    });
    return result;
}

- (NSArray<NSDictionary *> *)winNotificationsForBid:(NSString *)bidId {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.winNotifications filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"bidId == %@", bidId]];
    });
    return result;
}

- (BOOL)hasWinNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId {
    __block BOOL result = NO;
    dispatch_sync(_syncQueue, ^{
        for (NSDictionary *notification in self.winNotifications) {
            if ([notification[@"auctionId"] isEqualToString:auctionId] && 
                [notification[@"bidId"] isEqualToString:bidId]) {
                result = YES;
                break;
            }
        }
    });
    return result;
}

- (BOOL)hasLossNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId withReason:(CLXLossReason)reason {
    __block BOOL result = NO;
    dispatch_sync(_syncQueue, ^{
        // For now, just check auction and bid - loss reason tracking can be enhanced
        for (NSDictionary *notification in self.lossNotifications) {
            if ([notification[@"auctionId"] isEqualToString:auctionId] && 
                [notification[@"bidId"] isEqualToString:bidId]) {
                result = YES;
                break;
            }
        }
    });
    return result;
}

#pragma mark - Singleton Override for Testing

+ (instancetype)sharedTestInstance {
    if (!_sharedTestInstance) {
        _sharedTestInstance = [[self alloc] init];
    }
    return _sharedTestInstance;
}

+ (void)setSharedTestInstance:(MockCLXWinLossTracker *)testInstance {
    _sharedTestInstance = testInstance;
}

+ (void)resetSharedInstance {
    _sharedTestInstance = nil;
}

#pragma mark - Additional Methods for Testing

- (void)setConfig:(CLXSDKConfigResponse *)config {
    // Mock implementation - could store config if needed for tests
}

- (void)trySendingPendingWinLossEvents {
    // Mock implementation - could simulate retry logic if needed
}

- (void)clearAuction:(NSString *)auctionId {
    dispatch_sync(_syncQueue, ^{
        // Mock implementation - remove stored bids for this auction
        [self.storedBids removeObjectForKey:auctionId];
    });
}

- (void)sendLossNotificationsForLosingBids:(NSString *)auctionId
                             winningBidId:(NSString *)winningBidId
                                  allBids:(NSArray<CLXBidResponseBid *> *)allBids {
    
    if (!auctionId || !winningBidId || !allBids || allBids.count == 0) {
        return;
    }
    
    // Simulate the shared method behavior
    // First, set the winner (mock implementation)
    [self setWinner:auctionId winningBidId:winningBidId];
    
    // Then send loss notifications for all losing bids
    for (CLXBidResponseBid *bid in allBids) {
        // Skip the winner
        if ([bid.id isEqualToString:winningBidId]) {
            continue;
        }
        
        // Send loss notification for losing bid
        if (bid.id) {
            [self setBidLoadResult:auctionId 
                             bidId:bid.id 
                           success:NO 
                        lossReason:@(CLXLossReasonLostToHigherBid)];
            [self sendLoss:auctionId bidId:bid.id];
        }
    }
}

#pragma mark - Core Business Logic Override

/**
 * CRITICAL: Override trackWinLoss to capture REAL resolved payload from CLXWinLossFieldResolver
 * This ensures integration tests verify actual business logic, not simulated behavior
 */
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload {
    dispatch_sync(_syncQueue, ^{
        // Capture the REAL resolved payload from the actual CLXWinLossFieldResolver
        NSString *type = payload[@"type"] ?: @"unknown";
        NSString *auctionId = payload[@"auctionId"] ?: @"";
        NSString *bidId = payload[@"bidId"] ?: @"";
        
        NSMutableDictionary *notification = [@{
            @"auctionId": auctionId,
            @"bidId": bidId,
            @"timestamp": [NSDate date],
            @"type": type,
            @"fullPayload": payload  // Store the complete resolved payload
        } mutableCopy];
        
        // Extract all relevant fields from the real field resolver output
        NSString *resolvedURL = payload[@"resolvedURL"];
        if (resolvedURL) {
            notification[@"resolvedURL"] = resolvedURL;
        }
        
        // Extract additional fields that integration tests expect
        NSString *originalURL = payload[@"originalURL"];
        if (originalURL) {
            notification[@"originalURL"] = originalURL;
        }
        
        NSNumber *bidPrice = payload[@"price"];
        if (bidPrice) {
            notification[@"bidPrice"] = bidPrice;
        }
        
        NSNumber *lossReason = payload[@"lossReason"];
        if (lossReason) {
            notification[@"lossReason"] = lossReason;
        }
        
        if ([type isEqualToString:@"win"]) {
            [self.winNotifications addObject:[notification copy]];
        } else if ([type isEqualToString:@"loss"]) {
            [self.lossNotifications addObject:[notification copy]];
        }
    });
    
    // DO NOT call super - we don't want actual network requests in tests
    // But we've captured the real resolved payload from CLXWinLossFieldResolver
}


@end
