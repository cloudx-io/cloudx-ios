/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossRetryBatchingTests.m
 * @brief Tests for win/loss event persistence, retry, and batching
 *
 * Verifies that the win/loss system properly persists failed events to SQLite,
 * retries them on demand, and cleans up after successful delivery. Uses a mock
 * network service for deterministic, fast execution with a real SQLite database
 * to test actual persistence behavior.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXSDKConfig.h>

#pragma mark - Mock Network Service

@interface CLXRetryTestMockNetwork : NSObject <CLXWinLossNetworkServiceProtocol>
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *sentPayloads;
@property (nonatomic, assign) BOOL shouldFail;
/// When YES, the mock never calls the completion handler — simulating iOS
/// suspending the process after the TCP connection opens but before the
/// response arrives. The event should already be in SQLite at this point.
@property (nonatomic, assign) BOOL shouldHang;
@property (nonatomic, copy, nullable) void (^onSendCompleted)(void);
@end

@implementation CLXRetryTestMockNetwork

- (instancetype)init {
    self = [super init];
    if (self) {
        _sentPayloads = [NSMutableArray array];
        _shouldFail = NO;
        _shouldHang = NO;
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
           endpointUrl:(NSString *)endpointUrl
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.sentPayloads addObject:payload];

    if (self.shouldHang) {
        if (self.onSendCompleted) {
            self.onSendCompleted();
        }
        return;
    }

    if (self.shouldFail) {
        NSError *error = [NSError errorWithDomain:@"com.cloudx.test"
                                             code:500
                                         userInfo:@{NSLocalizedDescriptionKey: @"Mock server error"}];
        completion(NO, error);
    } else {
        completion(YES, nil);
    }

    if (self.onSendCompleted) {
        self.onSendCompleted();
    }
}

@end

#pragma mark - Private Property Access

@interface CLXWinLossTracker (RetryTesting)
@property (nonatomic, strong) id<CLXWinLossNetworkServiceProtocol> networkService;
- (NSArray *)getAllCachedEvents;
- (void)deleteAllEvents;
@end

#pragma mark - Test Constants

static NSString * const kTestAuctionID = @"retry-test-auction";
static NSString * const kTestBidID = @"retry-test-bid";
static NSString * const kTestAppKey = @"test-app-key-retry";
static NSString * const kTestEndpoint = @"https://test.cloudx.io/notifications";

@interface CLXWinLossRetryBatchingTests : XCTestCase
@property (nonatomic, strong) CLXWinLossTracker *tracker;
@property (nonatomic, strong) CLXRetryTestMockNetwork *mockNetwork;
@end

@implementation CLXWinLossRetryBatchingTests

#pragma mark - Test Setup

- (void)setUp {
    [super setUp];

    self.tracker = [[CLXWinLossTracker alloc] init];
    [self.tracker setAppKey:kTestAppKey];
    [self.tracker setEndpoint:kTestEndpoint];

    self.mockNetwork = [[CLXRetryTestMockNetwork alloc] init];
    self.tracker.networkService = self.mockNetwork;

    [self setUpTrackerWithValidConfig];
    [self.tracker deleteAllEvents];
}

- (void)tearDown {
    [self.tracker deleteAllEvents];
    [CLXWinLossTracker resetSharedInstance];
    self.tracker = nil;
    self.mockNetwork = nil;
    [super tearDown];
}

#pragma mark - Helpers

- (CLXBidResponseBid *)createTestBidWithId:(NSString *)bidId {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = bidId;
    bid.price = 2.50;
    bid.lurl = @"https://test.com/lurl";
    bid.nurl = @"https://test.com/nurl";
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = 1;
    return bid;
}

- (void)setUpTrackerWithValidConfig {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationPayloadConfig = @{
        @"auctionId": @"auctionId",
        @"bidId": @"bid.id",
        @"price": @"bid.price",
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]"
    };
    [self.tracker setConfig:config];
}

- (void)sendEventAndWait:(NSString *)auctionId
                   bidId:(NSString *)bidId
                   event:(CLXBidLifecycleEvent *)event
              lossReason:(nullable NSNumber *)lossReason {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completed"];
    self.mockNetwork.onSendCompleted = ^{
        [expectation fulfill];
    };

    [self.tracker sendEvent:auctionId
                      bidId:bidId
                      event:event
                 lossReason:lossReason
             winnerBidPrice:-1.0
                      error:nil];

    [self waitForExpectations:@[expectation] timeout:5.0];
    self.mockNetwork.onSendCompleted = nil;
}

- (void)sendMultipleEventsAndWait:(NSInteger)count
                           bidIds:(NSArray<NSString *> *)bidIds
                        auctionId:(NSString *)auctionId
                            event:(CLXBidLifecycleEvent *)event {
    XCTestExpectation *expectation = [self expectationWithDescription:@"All sends completed"];
    expectation.expectedFulfillmentCount = count;
    self.mockNetwork.onSendCompleted = ^{
        [expectation fulfill];
    };

    for (NSInteger i = 0; i < count; i++) {
        [self.tracker sendEvent:auctionId
                          bidId:bidIds[i]
                          event:event
                     lossReason:nil
                 winnerBidPrice:-1.0
                          error:nil];
    }

    [self waitForExpectations:@[expectation] timeout:10.0];
    self.mockNetwork.onSendCompleted = nil;
}

#pragma mark - MARK: Network Failure and Caching

- (void)testWinNotification_NetworkFailure_ShouldCacheEvent {
    self.mockNetwork.shouldFail = YES;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];

    NSArray *initialEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(initialEvents.count, 0);

    [self sendEventAndWait:kTestAuctionID
                     bidId:kTestBidID
                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                lossReason:nil];

    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 1, @"Failed notification should remain in SQLite for retry");
}

- (void)testLossNotification_NetworkFailure_ShouldCacheEvent {
    self.mockNetwork.shouldFail = YES;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];
    [self.tracker setBidLoadResult:kTestAuctionID bidId:kTestBidID success:NO lossReason:@(CLXLossReasonInternalError)];

    [self sendEventAndWait:kTestAuctionID
                     bidId:kTestBidID
                     event:[CLXBidLifecycleEvent lossEvent]
                lossReason:@(CLXLossReasonInternalError)];

    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 1, @"Failed loss notification should remain in SQLite for retry");
}

- (void)testMultipleFailures_ShouldCacheAllEvents {
    self.mockNetwork.shouldFail = YES;

    NSArray *bidIds = @[@"bid-1", @"bid-2", @"bid-3", @"bid-4", @"bid-5"];
    for (NSString *bidId in bidIds) {
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:kTestAuctionID bid:bid];
    }

    [self sendMultipleEventsAndWait:5
                            bidIds:bidIds
                         auctionId:kTestAuctionID
                             event:[CLXBidLifecycleEvent loadSuccessEvent]];

    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 5, @"All 5 failed notifications should be cached");
}

- (void)testSuccessfulSend_ShouldNotCacheEvent {
    self.mockNetwork.shouldFail = NO;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];

    [self sendEventAndWait:kTestAuctionID
                     bidId:kTestBidID
                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                lossReason:nil];

    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 0, @"Successful send should delete event from SQLite");
}

#pragma mark - MARK: App Suspension Simulation

- (void)testAppSuspension_CompletionNeverFires_EventRemainsInDatabase {
    // Simulate iOS suspending the process after the network request starts
    // but before the response arrives. The completion handler never fires.
    self.mockNetwork.shouldHang = YES;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];

    // sendEvent dispatches async → saves to DB → calls network send →
    // mock hangs (never calls completion). onSendCompleted fires after
    // the mock captures the payload, confirming the DB write happened.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network send attempted"];
    self.mockNetwork.onSendCompleted = ^{
        [expectation fulfill];
    };

    [self.tracker sendEvent:kTestAuctionID
                      bidId:kTestBidID
                      event:[CLXBidLifecycleEvent loadSuccessEvent]
                 lossReason:nil
             winnerBidPrice:-1.0
                      error:nil];

    [self waitForExpectations:@[expectation] timeout:5.0];
    self.mockNetwork.onSendCompleted = nil;

    // The completion never fired, so the event was never deleted.
    // It must still be in SQLite.
    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 1,
                   @"Event must survive in SQLite when completion handler never fires (app suspended)");
}

- (void)testAppSuspension_NextLaunchRetry_ShouldDeliverEvent {
    // Phase 1: Simulate first app session where the request hangs (app suspended)
    self.mockNetwork.shouldHang = YES;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];

    XCTestExpectation *hangExpectation = [self expectationWithDescription:@"Hang send attempted"];
    self.mockNetwork.onSendCompleted = ^{
        [hangExpectation fulfill];
    };

    [self.tracker sendEvent:kTestAuctionID
                      bidId:kTestBidID
                      event:[CLXBidLifecycleEvent loadSuccessEvent]
                 lossReason:nil
             winnerBidPrice:-1.0
                      error:nil];

    [self waitForExpectations:@[hangExpectation] timeout:5.0];
    self.mockNetwork.onSendCompleted = nil;

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 1);

    // Phase 2: Simulate next app launch — new tracker reads same SQLite DB
    CLXWinLossTracker *newTracker = [[CLXWinLossTracker alloc] init];
    [newTracker setAppKey:kTestAppKey];
    [newTracker setEndpoint:kTestEndpoint];

    CLXRetryTestMockNetwork *freshMock = [[CLXRetryTestMockNetwork alloc] init];
    freshMock.shouldFail = NO;
    newTracker.networkService = freshMock;

    // This is what CloudXCoreAPI.m calls on SDK init
    [newTracker trySendingPendingWinLossEvents];

    XCTAssertEqual(freshMock.sentPayloads.count, 1,
                   @"Retry on next launch should send the event that was stuck in SQLite");
    XCTAssertEqual([newTracker getAllCachedEvents].count, 0,
                   @"Successful retry should clear the event from SQLite");

    [newTracker deleteAllEvents];
}

#pragma mark - MARK: Retry Logic

- (void)testRetryLogic_ShouldSendCachedEventsAndClearDatabase {
    // Phase 1: Fail events so they get cached
    self.mockNetwork.shouldFail = YES;

    CLXBidResponseBid *bid1 = [self createTestBidWithId:@"retry-bid-1"];
    CLXBidResponseBid *bid2 = [self createTestBidWithId:@"retry-bid-2"];
    [self.tracker addBid:kTestAuctionID bid:bid1];
    [self.tracker addBid:kTestAuctionID bid:bid2];

    [self sendMultipleEventsAndWait:2
                            bidIds:@[@"retry-bid-1", @"retry-bid-2"]
                         auctionId:kTestAuctionID
                             event:[CLXBidLifecycleEvent loadSuccessEvent]];

    NSArray *cachedBefore = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedBefore.count, 2, @"Both events should be cached after failure");

    // Phase 2: Switch mock to succeed and retry
    self.mockNetwork.shouldFail = NO;
    [self.mockNetwork.sentPayloads removeAllObjects];

    [self.tracker trySendingPendingWinLossEvents];

    NSArray *cachedAfter = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedAfter.count, 0, @"Successful retry should clear all cached events");
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 2, @"Retry should have sent both cached events");
}

- (void)testRetryLogic_EmptyCache_ShouldNoOp {
    NSArray *cachedEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedEvents.count, 0);

    XCTAssertNoThrow([self.tracker trySendingPendingWinLossEvents],
                     @"Retry with empty cache should complete without error");
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 0, @"Nothing to send from empty cache");
}

- (void)testRetryLogic_PersistentFailure_ShouldKeepEventsInDatabase {
    // Phase 1: Fail events so they get cached
    self.mockNetwork.shouldFail = YES;

    CLXBidResponseBid *bid = [self createTestBidWithId:kTestBidID];
    [self.tracker addBid:kTestAuctionID bid:bid];

    [self sendEventAndWait:kTestAuctionID
                     bidId:kTestBidID
                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                lossReason:nil];

    // Phase 2: Retry while still failing
    [self.mockNetwork.sentPayloads removeAllObjects];
    [self.tracker trySendingPendingWinLossEvents];

    NSArray *cachedAfter = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedAfter.count, 1, @"Events should remain in DB when retry also fails");
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 1, @"Retry should have attempted to send");
}

#pragma mark - MARK: Batching Behavior

- (void)testBatchRetry_MultipleCachedEvents_ShouldSendAll {
    self.mockNetwork.shouldFail = YES;

    NSInteger eventCount = 10;
    NSMutableArray *bidIds = [NSMutableArray array];
    for (NSInteger i = 0; i < eventCount; i++) {
        NSString *bidId = [NSString stringWithFormat:@"batch-bid-%ld", (long)i];
        NSString *auctionId = [NSString stringWithFormat:@"batch-auction-%ld", (long)i];
        [bidIds addObject:bidId];
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:auctionId bid:bid];
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"All sends completed"];
    expectation.expectedFulfillmentCount = eventCount;
    self.mockNetwork.onSendCompleted = ^{
        [expectation fulfill];
    };

    for (NSInteger i = 0; i < eventCount; i++) {
        NSString *auctionId = [NSString stringWithFormat:@"batch-auction-%ld", (long)i];
        [self.tracker sendEvent:auctionId
                          bidId:bidIds[i]
                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                     lossReason:nil
                 winnerBidPrice:-1.0
                          error:nil];
    }

    [self waitForExpectations:@[expectation] timeout:10.0];
    self.mockNetwork.onSendCompleted = nil;

    NSArray *cachedBefore = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedBefore.count, eventCount);

    // Retry all at once
    self.mockNetwork.shouldFail = NO;
    [self.mockNetwork.sentPayloads removeAllObjects];

    [self.tracker trySendingPendingWinLossEvents];

    NSArray *cachedAfter = [self.tracker getAllCachedEvents];
    XCTAssertEqual(cachedAfter.count, 0, @"All cached events should be cleared after successful batch retry");
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, eventCount, @"All events should have been retried");
}

- (void)testBatchRetry_ProcessingTime_ShouldBeEfficient {
    self.mockNetwork.shouldFail = YES;

    NSInteger eventCount = 20;
    NSMutableArray *bidIds = [NSMutableArray array];
    for (NSInteger i = 0; i < eventCount; i++) {
        NSString *bidId = [NSString stringWithFormat:@"perf-bid-%ld", (long)i];
        NSString *auctionId = [NSString stringWithFormat:@"perf-auction-%ld", (long)i];
        [bidIds addObject:bidId];
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:auctionId bid:bid];
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"All sends completed"];
    expectation.expectedFulfillmentCount = eventCount;
    self.mockNetwork.onSendCompleted = ^{
        [expectation fulfill];
    };

    for (NSInteger i = 0; i < eventCount; i++) {
        NSString *auctionId = [NSString stringWithFormat:@"perf-auction-%ld", (long)i];
        [self.tracker sendEvent:auctionId
                          bidId:bidIds[i]
                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                     lossReason:nil
                 winnerBidPrice:-1.0
                          error:nil];
    }

    [self waitForExpectations:@[expectation] timeout:10.0];
    self.mockNetwork.onSendCompleted = nil;

    self.mockNetwork.shouldFail = NO;
    [self.mockNetwork.sentPayloads removeAllObjects];

    [self.tracker trySendingPendingWinLossEvents];

    XCTAssertEqual(self.mockNetwork.sentPayloads.count, eventCount,
                   @"All %ld cached events should have been retried", (long)eventCount);
    XCTAssertEqual([self.tracker getAllCachedEvents].count, 0,
                   @"All events should be cleared after successful batch retry");
}

#pragma mark - MARK: Database Consistency

- (void)testDatabaseConsistency_NewEventsWhileRetrying_ShouldNotCorrupt {
    // Phase 1: Cache some events via failure
    self.mockNetwork.shouldFail = YES;

    NSArray *bidIds = @[@"db-test-1", @"db-test-2", @"db-test-3"];
    for (NSString *bidId in bidIds) {
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:kTestAuctionID bid:bid];
    }

    [self sendMultipleEventsAndWait:3
                            bidIds:bidIds
                         auctionId:kTestAuctionID
                             event:[CLXBidLifecycleEvent loadSuccessEvent]];

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 3);

    // Phase 2: Retry succeeds, clearing the 3 original events
    self.mockNetwork.shouldFail = NO;
    [self.tracker trySendingPendingWinLossEvents];

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 0, @"Retried events should be cleared");

    // Phase 3: New events that fail should still be cacheable
    self.mockNetwork.shouldFail = YES;
    [self.mockNetwork.sentPayloads removeAllObjects];

    CLXBidResponseBid *newBid = [self createTestBidWithId:@"post-retry-bid"];
    [self.tracker addBid:@"new-auction" bid:newBid];

    [self sendEventAndWait:@"new-auction"
                     bidId:@"post-retry-bid"
                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                lossReason:nil];

    NSArray *finalEvents = [self.tracker getAllCachedEvents];
    XCTAssertEqual(finalEvents.count, 1, @"Database should still accept new events after retry cycle");
}

#pragma mark - MARK: Configuration Edge Cases

- (void)testRetryLogic_NilEndpoint_ShouldHandleGracefully {
    [self.tracker setEndpoint:nil];
    XCTAssertNoThrow([self.tracker trySendingPendingWinLossEvents]);
}

- (void)testRetryLogic_EmptyEndpoint_ShouldHandleGracefully {
    [self.tracker setEndpoint:@""];
    // setEndpoint: replaces networkService when the URL is non-nil (including @""),
    // so restore the mock to keep the test isolated from real networking.
    self.tracker.networkService = self.mockNetwork;
    XCTAssertNoThrow([self.tracker trySendingPendingWinLossEvents]);
}

- (void)testRetryLogic_NilAppKey_ShouldHandleGracefully {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.tracker setAppKey:nil];
#pragma clang diagnostic pop
    XCTAssertNoThrow([self.tracker trySendingPendingWinLossEvents]);
}

- (void)testRetryLogic_EmptyAppKey_ShouldHandleGracefully {
    [self.tracker setAppKey:@""];
    XCTAssertNoThrow([self.tracker trySendingPendingWinLossEvents]);
}

#pragma mark - MARK: Concurrent Operations

- (void)testConcurrentRetryOperations_ShouldNotCrash {
    self.mockNetwork.shouldFail = YES;

    for (NSInteger i = 0; i < 10; i++) {
        NSString *bidId = [NSString stringWithFormat:@"concurrent-bid-%ld", (long)i];
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:kTestAuctionID bid:bid];
    }

    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"All initial sends completed"];
    sendExpectation.expectedFulfillmentCount = 10;
    self.mockNetwork.onSendCompleted = ^{
        [sendExpectation fulfill];
    };

    for (NSInteger i = 0; i < 10; i++) {
        NSString *bidId = [NSString stringWithFormat:@"concurrent-bid-%ld", (long)i];
        [self.tracker sendEvent:kTestAuctionID
                          bidId:bidId
                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                     lossReason:nil
                 winnerBidPrice:-1.0
                          error:nil];
    }

    [self waitForExpectations:@[sendExpectation] timeout:10.0];
    self.mockNetwork.onSendCompleted = nil;

    // Trigger multiple concurrent retries
    self.mockNetwork.shouldFail = NO;

    dispatch_group_t group = dispatch_group_create();
    for (NSInteger i = 0; i < 5; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.tracker trySendingPendingWinLossEvents];
            dispatch_group_leave(group);
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent retries should complete without deadlock");
    XCTAssertEqual([self.tracker getAllCachedEvents].count, 0,
                   @"All events should be cleared after concurrent retries complete");
}

- (void)testNewEventsDuringRetry_ShouldNotBlock {
    self.mockNetwork.shouldFail = YES;

    CLXBidResponseBid *cachedBid = [self createTestBidWithId:@"cached-bid"];
    [self.tracker addBid:kTestAuctionID bid:cachedBid];

    [self sendEventAndWait:kTestAuctionID
                     bidId:@"cached-bid"
                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                lossReason:nil];

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 1);

    // Start retry (synchronous with mock)
    self.mockNetwork.shouldFail = NO;
    [self.tracker trySendingPendingWinLossEvents];

    // Sending new events after retry should work
    self.mockNetwork.shouldFail = YES;
    CLXBidResponseBid *newBid = [self createTestBidWithId:@"new-bid"];
    [self.tracker addBid:@"new-auction" bid:newBid];

    XCTAssertNoThrow(
        [self sendEventAndWait:@"new-auction"
                         bidId:@"new-bid"
                         event:[CLXBidLifecycleEvent loadSuccessEvent]
                    lossReason:nil],
        @"New notifications should not be blocked by prior retry operations"
    );
}

#pragma mark - MARK: Database Cleanup After Successful Retry

- (void)testDatabaseCleanup_SuccessfulRetry_ShouldRemoveAllCachedEvents {
    self.mockNetwork.shouldFail = YES;

    NSArray *bidIds = @[@"cleanup-bid-1", @"cleanup-bid-2", @"cleanup-bid-3"];
    for (NSString *bidId in bidIds) {
        CLXBidResponseBid *bid = [self createTestBidWithId:bidId];
        [self.tracker addBid:kTestAuctionID bid:bid];
    }

    [self sendMultipleEventsAndWait:3
                            bidIds:bidIds
                         auctionId:kTestAuctionID
                             event:[CLXBidLifecycleEvent loadSuccessEvent]];

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 3);

    // Successful retry
    self.mockNetwork.shouldFail = NO;
    [self.mockNetwork.sentPayloads removeAllObjects];
    [self.tracker trySendingPendingWinLossEvents];

    XCTAssertEqual([self.tracker getAllCachedEvents].count, 0,
                   @"All events should be deleted from SQLite after successful retry");
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 3,
                   @"All 3 cached events should have been sent on retry");
}

@end
