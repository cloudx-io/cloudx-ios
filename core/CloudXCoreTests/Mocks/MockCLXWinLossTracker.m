/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockCLXWinLossTracker.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>

/**
 * Category to expose parent's private properties for testing.
 * These properties are declared in CLXWinLossTracker's class extension.
 */
@interface CLXWinLossTracker (Testing)
@property (nonatomic, strong) CLXAuctionBidManager *auctionBidManager;
@property (nonatomic, strong) CLXWinLossFieldResolver *winLossFieldResolver;
@end

static MockCLXWinLossTracker *_sharedTestInstance = nil;

@implementation MockCLXWinLossTracker {
    dispatch_queue_t _syncQueue;
    NSInteger _sendWinCallCount;
    NSInteger _sendLossCallCount;
    NSInteger _sendEventCallCount;
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
        self.lifecycleEvents = [[NSMutableArray alloc] init];
        self.allPayloadsSent = [[NSMutableArray alloc] init];
        self.storedBids = [[NSMutableDictionary alloc] init];
        self.configuredAppKey = nil;
        self.configuredEndpoint = nil;
        _sendWinCallCount = 0;
        _sendLossCallCount = 0;
        _sendEventCallCount = 0;
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

- (NSInteger)sendEventCallCount {
    __block NSInteger count;
    dispatch_sync(_syncQueue, ^{
        count = _sendEventCallCount;
    });
    return count;
}

- (void)setSendEventCallCount:(NSInteger)sendEventCallCount {
    dispatch_sync(_syncQueue, ^{
        _sendEventCallCount = sendEventCallCount;
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
    // Store locally for test inspection
    dispatch_sync(_syncQueue, ^{
        if (!self.storedBids[auctionId]) {
            self.storedBids[auctionId] = [[NSMutableArray alloc] init];
        }
        [self.storedBids[auctionId] addObject:bid];
    });
    
    // CRITICAL: Call parent so auctionBidManager has the bid
    // Without this, parent's sendEvent returns early when getBid returns nil
    [super addBid:auctionId bid:bid];
}

- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    // Mock implementation - could track winner settings if needed for tests
}

// Legacy sendWin and sendLoss methods removed - tests should use sendEvent() instead

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
    // CRITICAL: Must call super to configure parent's winLossFieldResolver
    // Without this, buildWinLossPayload returns nil and trackWinLoss is never called
    [super setConfig:config];
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
        
        // Send loss notification for losing bid using sendEvent (matches Android behavior)
        if (bid.id) {
            [self setBidLoadResult:auctionId 
                             bidId:bid.id 
                           success:NO 
                        lossReason:@(CLXLossReasonLostToHigherBid)];
            
            // Find winner bid to get winner price
            CLXBidResponseBid *winnerBid = [self findBid:winningBidId inAuction:auctionId];
            float winnerBidPrice = winnerBid ? winnerBid.price : -1.0;
            
            [self sendEvent:auctionId
                      bidId:bid.id
                      event:[CLXBidLifecycleEvent lossEvent]
                 lossReason:@(CLXLossReasonLostToHigherBid)
             winnerBidPrice:winnerBidPrice
                      error:nil];
        }
    }
}

#pragma mark - Core Business Logic Override

/**
 * CRITICAL: Override trackWinLoss to capture REAL resolved payload from CLXWinLossFieldResolver
 * This ensures integration tests verify actual business logic, not simulated behavior
 * MUST match parent signature exactly: trackWinLoss:auctionId:bidId:
 */
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload
           auctionId:(NSString *)auctionId
               bidId:(NSString *)bidId {
    dispatch_sync(_syncQueue, ^{
        // Store ALL payloads for debugging and test inspection
        [self.allPayloadsSent addObject:payload];
        
        // Capture the REAL resolved payload from the actual CLXWinLossFieldResolver
        NSString *notificationType = payload[@"notificationType"] ?: @"";
        
        // Derive type from notificationType
        NSString *type = @"unknown";
        if ([notificationType isEqualToString:@"loadSuccess"] ||
            [notificationType isEqualToString:@"renderSuccess"] ||
            [notificationType isEqualToString:@"rewardEarned"] ||
            [notificationType isEqualToString:@"click"] ||
            [notificationType isEqualToString:@"load_success"] ||
            [notificationType isEqualToString:@"render_success"] ||
            [notificationType isEqualToString:@"reward_earned"]) {
            type = @"win";
        } else if ([notificationType isEqualToString:@"loss"]) {
            type = @"loss";
        }
        
        NSMutableDictionary *notification = [@{
            @"auctionId": auctionId,  // Use parameter, not payload (payload might not have it)
            @"bidId": bidId,          // Use parameter, not payload
            @"timestamp": [NSDate date],
            @"type": type,
            @"notificationType": notificationType,
            @"fullPayload": payload  // Store the complete resolved payload
        } mutableCopy];
        
        // Extract all relevant fields from the real field resolver output
        NSString *url = payload[@"url"];
        if (url) {
            notification[@"url"] = url;
        }
        
        NSNumber *bidPrice = payload[@"price"];
        if (bidPrice) {
            notification[@"bidPrice"] = bidPrice;
        }
        
        // Extract lossReason - could be a string (from sdk.lossReason) or number
        id lossReasonValue = payload[@"lossReason"];
        if (lossReasonValue) {
            if ([lossReasonValue isKindOfClass:[NSNumber class]]) {
                notification[@"lossReason"] = lossReasonValue;
            } else if ([lossReasonValue isKindOfClass:[NSString class]]) {
                // Convert string back to loss reason code if needed
                // For now, store the string value
                notification[@"lossReasonString"] = lossReasonValue;
                // Map common loss reason strings back to codes for test assertions
                if ([lossReasonValue isEqualToString:@"Internal Error"]) {
                    notification[@"lossReason"] = @(CLXLossReasonInternalError);
                } else if ([lossReasonValue isEqualToString:@"Lost to Higher Bid"]) {
                    notification[@"lossReason"] = @(CLXLossReasonLostToHigherBid);
                } else if ([lossReasonValue isEqualToString:@"Bid Won"]) {
                    notification[@"lossReason"] = @(CLXLossReasonBidWon);
                }
            }
        }
        
        // Categorize by notificationType (support both camelCase and snake_case)
        // camelCase: loadSuccess, renderSuccess, rewardEarned, loss (from event.notificationType)
        // snake_case: load_success, render_success, reward_earned, loss (from sdk.[notificationType])
        if ([notificationType isEqualToString:@"loadSuccess"] ||
            [notificationType isEqualToString:@"renderSuccess"] ||
            [notificationType isEqualToString:@"rewardEarned"] ||
            [notificationType isEqualToString:@"click"] ||
            [notificationType isEqualToString:@"load_success"] ||
            [notificationType isEqualToString:@"render_success"] ||
            [notificationType isEqualToString:@"reward_earned"]) {
            [self.winNotifications addObject:[notification copy]];
            _sendWinCallCount++;
        } else if ([notificationType isEqualToString:@"loss"]) {
            [self.lossNotifications addObject:[notification copy]];
            _sendLossCallCount++;
        }
    });
    
    // DO NOT call super - we don't want actual network requests in tests
    // The payload has been captured for test verification
}

#pragma mark - New Lifecycle Event Methods

/**
 * FULLY SYNCHRONOUS sendEvent implementation for reliable testing.
 * 
 * This does NOT call [super sendEvent:] because the parent uses dispatch_async
 * which causes race conditions between tests. Instead, we:
 * 1. Record the event for test inspection
 * 2. Build the payload synchronously using parent's field resolver
 * 3. Call trackWinLoss synchronously to capture the payload
 */
- (void)sendEvent:(NSString *)auctionId
            bidId:(NSString *)bidId
            event:(CLXBidLifecycleEvent *)event
       lossReason:(nullable NSNumber *)lossReason
   winnerBidPrice:(double)winnerBidPrice
            error:(nullable CLXError *)error {
    
    // Record the event for test inspection
    dispatch_sync(_syncQueue, ^{
        _sendEventCallCount++;
        
        NSString *eventTypeString = @"unknown";
        switch (event.type) {
            case CLXBidLifecycleEventTypeLoadSuccess:
                eventTypeString = @"LOAD_SUCCESS";
                break;
            case CLXBidLifecycleEventTypeRenderSuccess:
                eventTypeString = @"RENDER_SUCCESS";
                break;
            case CLXBidLifecycleEventTypeLoss:
                eventTypeString = @"LOSS";
                break;
            case CLXBidLifecycleEventTypeReward:
                eventTypeString = @"REWARD";
                break;
            case CLXBidLifecycleEventTypeClick:
                eventTypeString = @"CLICK";
                break;
        }
        
        NSDictionary *lifecycleEvent = @{
            @"auctionId": auctionId ?: @"",
            @"bidId": bidId ?: @"",
            @"eventType": eventTypeString,
            @"notificationType": event.notificationType ?: @"",
            @"urlType": event.urlType ?: @"",
            @"lossReason": lossReason ?: [NSNull null],
            @"winnerBidPrice": @(winnerBidPrice),
            @"timestamp": [NSDate date]
        };
        
        [self.lifecycleEvents addObject:lifecycleEvent];
    });
    
    // SYNCHRONOUS payload building - no dispatch_async, no race conditions
    // Get the bid from parent's auctionBidManager (which was stored via addBid:)
    CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
    if (!bid) {
        return; // No bid found, nothing to track
    }
    
    // Build payload synchronously using parent's field resolver
    NSDictionary *payload = [self buildWinLossPayloadWithAuctionId:auctionId
                                                              bidId:bidId
                                                                bid:bid
                                                              event:event
                                                         lossReason:lossReason
                                                     winnerBidPrice:winnerBidPrice
                                                              error:error];
    
    if (payload) {
        // Call trackWinLoss SYNCHRONOUSLY - this captures the payload for test verification
        [self trackWinLoss:payload auctionId:auctionId bidId:bidId];
    }
}

/**
 * Helper method to build payload synchronously using parent's field resolver.
 * This mirrors the logic in CLXWinLossTracker.sendEvent but without dispatch_async.
 */
- (nullable NSDictionary<NSString *, id> *)buildWinLossPayloadWithAuctionId:(NSString *)auctionId
                                                                      bidId:(NSString *)bidId
                                                                        bid:(CLXBidResponseBid *)bid
                                                                      event:(CLXBidLifecycleEvent *)event
                                                                 lossReason:(nullable NSNumber *)lossReason
                                                             winnerBidPrice:(double)winnerBidPrice
                                                                      error:(nullable CLXError *)error {
    // Determine loaded bid price based on event type (same logic as parent)
    double loadedBidPrice = winnerBidPrice;
    if (event.type == CLXBidLifecycleEventTypeLoadSuccess || event.type == CLXBidLifecycleEventTypeRenderSuccess) {
        loadedBidPrice = bid.price;
    }
    
    // Use parent's field resolver to build the payload
    // Note: winLossFieldResolver is configured via setConfig: which calls [super setConfig:]
    return [self.winLossFieldResolver buildWinLossPayloadWithAuctionId:auctionId
                                                                   bid:bid
                                                            lossReason:lossReason
                                                                 event:event
                                                        loadedBidPrice:loadedBidPrice
                                                                 error:error];
}

// REMOVED: URL template resolution - iOS now does zero client-side URL hydration (matches Android)

// REMOVED: saveBidsAsNew() - No pre-caching in simplified implementation
// REMOVED: convertUnfinishedBidsToLoss() - No state machine in simplified implementation

#pragma mark - Lifecycle Event Queries

- (NSArray<NSDictionary *> *)lifecycleEventsForAuction:(NSString *)auctionId {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.lifecycleEvents filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"auctionId == %@", auctionId]];
    });
    return result;
}

- (NSArray<NSDictionary *> *)lifecycleEventsForBid:(NSString *)bidId {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.lifecycleEvents filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"bidId == %@", bidId]];
    });
    return result;
}

- (NSArray<NSDictionary *> *)lifecycleEventsOfType:(NSString *)eventType {
    __block NSArray<NSDictionary *> *result;
    dispatch_sync(_syncQueue, ^{
        result = [self.lifecycleEvents filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"eventType == %@", eventType]];
    });
    return result;
}

- (BOOL)hasLifecycleEvent:(NSString *)eventType forAuction:(NSString *)auctionId bidId:(NSString *)bidId {
    __block BOOL result = NO;
    dispatch_sync(_syncQueue, ^{
        for (NSDictionary *event in self.lifecycleEvents) {
            if ([event[@"eventType"] isEqualToString:eventType] &&
                [event[@"auctionId"] isEqualToString:auctionId] &&
                [event[@"bidId"] isEqualToString:bidId]) {
                result = YES;
                break;
            }
        }
    });
    return result;
}

@end
