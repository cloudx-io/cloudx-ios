/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockCLXWinLossTracker.h"
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXError.h>

static MockCLXWinLossTracker *_sharedTestInstance = nil;

@implementation MockCLXWinLossTracker

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    self.winNotifications = [[NSMutableArray alloc] init];
    self.lossNotifications = [[NSMutableArray alloc] init];
    self.bidResults = [[NSMutableArray alloc] init];
    self.storedBids = [[NSMutableDictionary alloc] init];
    self.configuredAppKey = nil;
    self.configuredEndpoint = nil;
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
    [self.bidResults addObject:result];
}

- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid {
    if (!self.storedBids[auctionId]) {
        self.storedBids[auctionId] = [[NSMutableArray alloc] init];
    }
    [self.storedBids[auctionId] addObject:bid];
}

- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    // Mock implementation - could track winner settings if needed for tests
}

- (void)sendWin:(NSString *)auctionId bidId:(NSString *)bidId {
    NSDictionary *winNotification = @{
        @"auctionId": auctionId ?: @"",
        @"bidId": bidId ?: @"",
        @"timestamp": [NSDate date],
        @"type": @"win"
    };
    [self.winNotifications addObject:winNotification];
}

- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId {
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
}

#pragma mark - Test Utilities

- (NSArray<NSDictionary *> *)winNotificationsForAuction:(NSString *)auctionId {
    return [self.winNotifications filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"auctionId == %@", auctionId]];
}

- (NSArray<NSDictionary *> *)lossNotificationsForAuction:(NSString *)auctionId {
    return [self.lossNotifications filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"auctionId == %@", auctionId]];
}

- (NSArray<NSDictionary *> *)winNotificationsForBid:(NSString *)bidId {
    return [self.winNotifications filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"bidId == %@", bidId]];
}

- (BOOL)hasWinNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId {
    for (NSDictionary *notification in self.winNotifications) {
        if ([notification[@"auctionId"] isEqualToString:auctionId] && 
            [notification[@"bidId"] isEqualToString:bidId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasLossNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId withReason:(CLXLossReason)reason {
    // For now, just check auction and bid - loss reason tracking can be enhanced
    for (NSDictionary *notification in self.lossNotifications) {
        if ([notification[@"auctionId"] isEqualToString:auctionId] && 
            [notification[@"bidId"] isEqualToString:bidId]) {
            return YES;
        }
    }
    return NO;
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

@end
