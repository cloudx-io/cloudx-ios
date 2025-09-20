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
        NSDictionary *winNotification = @{
            @"auctionId": auctionId ?: @"",
            @"bidId": bidId ?: @"",
            @"timestamp": [NSDate date],
            @"type": @"win"
        };
        [self.winNotifications addObject:winNotification];
    });
}

- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_sync(_syncQueue, ^{
        _sendLossCallCount++;
        // Find the bid to extract its LURL
        CLXBidResponseBid *matchingBid = nil;
        NSArray<CLXBidResponseBid *> *auctionBids = self.storedBids[auctionId];
        for (CLXBidResponseBid *bid in auctionBids) {
            if ([bid.id isEqualToString:bidId]) {
                matchingBid = bid;
                break;
            }
        }
        
        // Get loss reason from bid results
        CLXLossReason lossReason = CLXLossReasonTechnicalError;
        for (NSDictionary *result in self.bidResults) {
            if ([result[@"auctionId"] isEqualToString:auctionId] && 
                [result[@"bidId"] isEqualToString:bidId] &&
                result[@"lossReason"] != [NSNull null]) {
                lossReason = [result[@"lossReason"] integerValue];
                break;
            }
        }
        
        NSDictionary *lossNotification = @{
            @"auctionId": auctionId ?: @"",
            @"bidId": bidId ?: @"",
            @"resolvedURL": matchingBid.lurl ?: @"", // Extract LURL from bid
            @"lossReason": @(lossReason),
            @"timestamp": [NSDate date],
            @"type": @"loss"
        };
        [self.lossNotifications addObject:lossNotification];
    });
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

@end
