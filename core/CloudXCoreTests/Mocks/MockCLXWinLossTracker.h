/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXWinLossTracker.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidResponseBid;

/**
 * Comprehensive mock for CLXWinLossTracker that captures all business-critical tracking events
 * for robust testing of revenue recognition and bid lifecycle management.
 */
@interface MockCLXWinLossTracker : NSObject <CLXWinLossTracking>

#pragma mark - Win/Loss Event Tracking

// Detailed win notification tracking (thread-safe)
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *winNotifications;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *lossNotifications;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *bidResults;

// Call count tracking for tests (thread-safe accessors via methods)
@property (nonatomic, assign) NSInteger sendWinCallCount;
@property (nonatomic, assign) NSInteger sendLossCallCount;

// Bid data storage (to simulate real tracker behavior)
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<CLXBidResponseBid *> *> *storedBids;

#pragma mark - Configuration Tracking

@property (nonatomic, copy, nullable) NSString *configuredAppKey;
@property (nonatomic, copy, nullable) NSString *configuredEndpoint;

#pragma mark - Test Utilities

// Get win notifications for specific auction/bid
- (NSArray<NSDictionary *> *)winNotificationsForAuction:(NSString *)auctionId;
- (NSArray<NSDictionary *> *)lossNotificationsForAuction:(NSString *)auctionId;
- (NSArray<NSDictionary *> *)winNotificationsForBid:(NSString *)bidId;

// Verify business logic
- (BOOL)hasWinNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId;
- (BOOL)hasLossNotificationForAuction:(NSString *)auctionId bidId:(NSString *)bidId withReason:(CLXLossReason)reason;

// Reset for clean test isolation
- (void)reset;

#pragma mark - Additional Methods for Testing

// Configuration methods
- (void)setConfig:(CLXSDKConfigResponse *)config;
- (void)trySendingPendingWinLossEvents;
- (void)clearAuction:(NSString *)auctionId;

// New shared method for competitive loss notifications
- (void)sendLossNotificationsForLosingBids:(NSString *)auctionId
                             winningBidId:(NSString *)winningBidId
                                  allBids:(NSArray<CLXBidResponseBid *> *)allBids;

#pragma mark - Singleton Override for Testing

+ (instancetype)sharedTestInstance;
+ (void)setSharedTestInstance:(MockCLXWinLossTracker *)testInstance;
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
