/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTrackingIntegrationTests.m
 * @brief Integration tests for server-side win/loss tracking architecture
 *
 * These tests were extracted from CLXWinLossTrackingTests.m because they use
 * asynchronous patterns (waitForExpectationsWithTimeout, dispatch_group_async,
 * dispatch_group_wait) that make them integration tests rather than unit tests.
 * The corresponding unit tests remain in CLXWinLossTrackingTests.m.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "Mocks/MockCLXWinLossTracker.h"

// MARK: - Test Constants

static NSString * const kTestAuctionID = @"auction-12345";
static NSString * const kTestBidID1 = @"bid-001";
static NSString * const kTestBidID2 = @"bid-002";
static NSString * const kTestBidID3 = @"bid-003";
static NSString * const kTestPlacementID = @"test-placement";
static NSString * const kTestUserID = @"test-user";
static NSString * const kTestPublisherID = @"test-publisher";

static NSString * const kTestLURL1 = @"https://network1.com/lurl?reason=${AUCTION_LOSS}";
static NSString * const kTestLURL2 = @"https://network2.com/lurl?price=${AUCTION_PRICE}";
static NSString * const kTestLURL3 = @"https://network3.com/lurl?simple";
static NSString * const kTestNURL1 = @"https://network1.com/nurl?price=${AUCTION_PRICE}";

static const double kTestPrice = 2.50;
static const NSInteger kTestRank1 = 1;
static const NSInteger kTestRank2 = 2;
static const NSInteger kTestRank3 = 3;

// Expose private methods for testing
@interface CLXBidAdSource (Testing)
- (void)tryNextBidInWaterfall:(NSArray<CLXBidResponseBid *> *)sortedBids
                     bidIndex:(NSInteger)bidIndex
                    auctionID:(nullable NSString *)auctionID
                   bidRequest:(NSDictionary *)bidRequest
                correlationId:(NSString *)correlationId
               failureReasons:(NSMutableArray<NSString *> *)failureReasons
                   completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion;
@end

@interface CLXWinLossTrackingIntegrationTests : XCTestCase
@property (nonatomic, strong) MockCLXWinLossTracker *mockTracker;
@end

@implementation CLXWinLossTrackingIntegrationTests

#pragma mark - Test Setup

- (void)setUp {
    [super setUp];
    self.mockTracker = [[MockCLXWinLossTracker alloc] init];
    [CLXWinLossTracker setSharedInstanceForTesting:self.mockTracker];
    
    // Configure with payload mapping (simulating server config)
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"url": @"sdk.[bid.nurl|bid.lurl]",
        @"auctionId": @"auctionId",
        @"bidId": @"bidId",
        @"lossReason": @"sdk.lossReasonCode",
        @"price": @"bid.price"
    };
    [[CLXWinLossTracker shared] setConfig:config];

    // Set endpoint and app key - required for trackWinLoss to be called
    [[CLXWinLossTracker shared] setEndpoint:@"https://test.com/winloss"];
    [[CLXWinLossTracker shared] setAppKey:@"test-app-key"];
}

- (void)tearDown {
    [CLXWinLossTracker resetSharedInstance];
    [super tearDown];
}

#pragma mark - Helper Methods

- (CLXBidResponseBid *)createBidWithId:(NSString *)bidId 
                                  lurl:(nullable NSString *)lurl 
                                  nurl:(nullable NSString *)nurl
                                  rank:(NSInteger)rank
                                 price:(double)price {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = bidId;
    bid.lurl = lurl;
    bid.nurl = nurl;
    bid.price = price;
    
    // Set up rank in ext structure
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = rank;
    
    return bid;
}

- (CLXBidAdSource *)createTestBidAdSourceWithCreateBlock:(id _Nullable (^)(NSString *, NSString *, NSString *, NSDictionary<NSString *, NSString *> *, NSString * _Nullable, BOOL, NSString *, NSError * _Nullable * _Nullable))createBlock {
    return [[CLXBidAdSource alloc] 
        initWithUserID:kTestUserID
        adUnitId:kTestPlacementID
        dealID:nil
        hasCloseButton:NO
        publisherID:kTestPublisherID
        adType:1
        bidTokenSources:@{}
        nativeAdRequirements:nil
        bidRequestTimeout:5.0
        reportingService:nil
        createBidAd:createBlock];
}

#pragma mark - MARK: Waterfall Bid Failure Tests

/**
 * Test that when a bid fails to create an adapter during waterfall selection,
 * a loss notification is sent immediately with TechnicalError reason
 */
- (void)testWaterfallBidFailure_SingleBid_ShouldFireLossNotificationImmediately {
    // Given: A bid that will fail to create an adapter
    CLXBidResponseBid *failingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:failingBid];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return nil; // Simulate adapter creation failure
    }];
    
    // When: Waterfall tries this bid
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:@[failingBid]
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        XCTAssertNil(response, @"Response should be nil for failed bid");
        XCTAssertNotNil(error, @"Error should be present for failed bid");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Then: Loss notification should be sent immediately
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"One loss notification should be sent for failed bid");
    XCTAssertEqual(self.mockTracker.bidResults.count, 1, @"Bid result should be recorded");
    
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertEqualObjects(lossNotification[@"bidId"], kTestBidID1, @"Correct bid ID should be used");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonInternalError, @"Loss reason should be InternalError");
}

/**
 * Test that single bid failure returns specific error code (CLXBidAdSourceErrorAdapterCreationFailed)
 * rather than generic NO_FILL. This allows publishers to see specific error messages.
 */
- (void)testWaterfallBidFailure_SingleBid_ShouldReturnSpecificErrorCode {
    // Given: A single bid that will fail to create an adapter
    CLXBidResponseBid *failingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:failingBid];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return nil; // Simulate adapter creation failure
    }];
    
    // When: Waterfall tries this single bid
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    __block NSError *capturedError = nil;
    [bidAdSource tryNextBidInWaterfall:@[failingBid]
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        capturedError = error;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Then: Error should be CLXBidAdSourceErrorAdapterCreationFailed (not CLXBidAdSourceErrorNoBid)
    XCTAssertNotNil(capturedError, @"Error should be present for failed bid");
    XCTAssertEqual(capturedError.code, CLXBidAdSourceErrorAdapterCreationFailed, 
                   @"Single bid failure should return CLXBidAdSourceErrorAdapterCreationFailed, not generic NO_FILL");
    XCTAssertTrue([capturedError.localizedDescription length] > 0, 
                  @"Error should contain specific failure message");
}

/**
 * Test that multiple bid failures return generic NO_FILL error code (CLXBidAdSourceErrorNoBid)
 */
- (void)testWaterfallBidFailure_MultipleBids_ShouldReturnGenericNoFillErrorCode {
    // Given: Multiple bids that will all fail
    NSArray<CLXBidResponseBid *> *failingBids = @[
        [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice],
        [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:kTestRank2 price:kTestPrice * 0.8]
    ];
    
    for (CLXBidResponseBid *bid in failingBids) {
        [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid];
    }
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return nil; // All bids fail
    }];
    
    // When: Waterfall tries all bids
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    __block NSError *capturedError = nil;
    [bidAdSource tryNextBidInWaterfall:failingBids
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        capturedError = error;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Then: Error should be CLXBidAdSourceErrorNoBid (generic NO_FILL for multiple bids)
    XCTAssertNotNil(capturedError, @"Error should be present when all bids fail");
    XCTAssertEqual(capturedError.code, CLXBidAdSourceErrorNoBid, 
                   @"Multiple bid failures should return CLXBidAdSourceErrorNoBid (generic NO_FILL)");
}

/**
 * Test that when multiple bids fail during waterfall, all send loss notifications
 */
- (void)testWaterfallBidFailure_MultipleBids_ShouldFireAllLossNotifications {
    // Given: Multiple bids that will all fail
    NSArray<CLXBidResponseBid *> *failingBids = @[
        [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice],
        [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:kTestRank2 price:kTestPrice * 0.8],
        [self createBidWithId:kTestBidID3 lurl:kTestLURL3 nurl:nil rank:kTestRank3 price:kTestPrice * 0.6]
    ];
    
    for (CLXBidResponseBid *bid in failingBids) {
        [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid];
    }
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return nil; // All bids fail
    }];
    
    // When: Waterfall tries all bids
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:failingBids
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        XCTAssertNil(response, @"Response should be nil when all bids fail");
        XCTAssertNotNil(error, @"Error should be present when all bids fail");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Then: All bids should have loss notifications
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 3, @"All three bids should send loss notifications");
    XCTAssertEqual(self.mockTracker.bidResults.count, 3, @"All bid results should be recorded");
    
    // Verify each loss notification
    NSSet *expectedBidIds = [NSSet setWithArray:@[kTestBidID1, kTestBidID2, kTestBidID3]];
    NSMutableSet *actualBidIds = [NSMutableSet set];
    
    for (NSDictionary *lossNotification in self.mockTracker.lossNotifications) {
        [actualBidIds addObject:lossNotification[@"bidId"]];
        XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonInternalError, @"All should have InternalError reason");
    }
    
    XCTAssertEqualObjects(actualBidIds, expectedBidIds, @"All expected bid IDs should have loss notifications");
}

/**
 * Test that waterfall bid failure includes CLXError in the loss notification payload.
 * Verifies the fix: adapter creation failure now passes CLXError instead of nil.
 */
- (void)testWaterfallBidFailure_SingleBid_ShouldIncludeErrorInLossPayload {
    // Reconfigure with sdk.error mapping so the error field appears in payloads
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"lossReason": @"sdk.lossReasonCode",
        @"error": @"sdk.error"
    };
    [[CLXWinLossTracker shared] setConfig:config];

    CLXBidResponseBid *failingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:failingBid];

    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return nil; // Simulate adapter creation failure
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:@[failingBid]
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Verify the loss notification payload contains the error field
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1);
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    NSDictionary *fullPayload = lossNotification[@"fullPayload"];

    XCTAssertNotNil(fullPayload[@"error"], @"Loss payload must contain sdk.error for adapter creation failures");

    NSDictionary *errorDict = fullPayload[@"error"];
    XCTAssertEqualObjects(errorDict[@"code"], @"ADAPTER_INTERNAL_ERROR",
                         @"Error code must be ADAPTER_INTERNAL_ERROR for adapter creation failures");
    XCTAssertTrue([errorDict[@"message"] length] > 0,
                 @"Error message must contain the diagnostic reason");
}

/**
 * Test that successful bid creation does NOT fire loss notifications prematurely
 */
- (void)testWaterfallBidSuccess_ShouldNotFireLossNotificationYet {
    // Given: A bid that will successfully create an adapter
    CLXBidResponseBid *successfulBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:successfulBid];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network, NSError **outError) {
        return [[NSObject alloc] init]; // Simulate successful adapter creation
    }];
    
    // When: Waterfall tries this bid
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:@[successfulBid]
                              bidIndex:0
                             auctionID:kTestAuctionID
                            bidRequest:@{@"test": @"data"}
                         correlationId:@"test-correlation-id"
                        failureReasons:[NSMutableArray array]
                            completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        XCTAssertNotNil(response, @"Response should be present for successful bid");
        XCTAssertNil(error, @"Error should be nil for successful bid");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Then: No loss notifications should be sent yet
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"No loss notifications should be sent for successful waterfall selection");
    XCTAssertEqual(self.mockTracker.winNotifications.count, 0, @"No win notifications should be sent yet either");
}

#pragma mark - MARK: Concurrent Access Tests

/**
 * Test concurrent access to tracker (basic thread safety)
 */
- (void)testConcurrentAccess_ShouldNotCrash {
    // Given: Multiple bids
    CLXBidResponseBid *bid1 = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    CLXBidResponseBid *bid2 = [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:kTestRank2 price:kTestPrice];
    
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid1];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid2];
    
    // When: Concurrent win/loss notifications
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[CLXWinLossTracker shared] sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[CLXWinLossTracker shared] sendEvent:kTestAuctionID bidId:kTestBidID2 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil];
    });
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent operations"];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Then: Should not crash and both notifications should be sent
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Win notification should be sent");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Loss notification should be sent");
}

/**
 * Test singleton behavior under concurrent access
 */
- (void)testSingletonBehavior_ConcurrentAccess_ShouldMaintainSingleInstance {
    dispatch_group_t group = dispatch_group_create();
    NSMutableSet *instances = [NSMutableSet set];
    NSLock *lock = [[NSLock alloc] init];
    
    // Get shared instance from multiple threads
    for (NSInteger i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CLXWinLossTracker *instance = [CLXWinLossTracker shared];
            
            [lock lock];
            [instances addObject:[NSValue valueWithPointer:(__bridge void *)instance]];
            [lock unlock];
            
            dispatch_group_leave(group);
        });
    }
    
    long waitResult = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    XCTAssertEqual(waitResult, 0, @"All dispatched blocks should complete within timeout");
    
    XCTAssertEqual(instances.count, 1, @"Should maintain single instance across concurrent access");
}

@end
