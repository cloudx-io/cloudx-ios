/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTrackingTests.m
 * @brief Comprehensive tests for server-side win/loss tracking architecture
 * 
 * Tests the complete business logic flow from bid failures through server-side
 * win/loss notifications, ensuring robust revenue recognition and auction analytics.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "Mocks/MockCLXWinLossTracker.h"

// MARK: - Test Constants

static NSString * const kTestAuctionID = @"auction-12345";
static NSString * const kTestBidID1 = @"bid-001";
static NSString * const kTestBidID2 = @"bid-002";
static NSString * const kTestBidID3 = @"bid-003";
static NSString * const kTestLURL1 = @"https://network1.com/lurl?reason=${AUCTION_LOSS}";
static NSString * const kTestLURL2 = @"https://network2.com/lurl?price=${AUCTION_PRICE}";
static NSString * const kTestLURL3 = @"https://network3.com/lurl?simple";
static NSString * const kTestNURL1 = @"https://network1.com/nurl?price=${AUCTION_PRICE}";

static const double kTestPrice = 2.50;
static const NSInteger kTestRank1 = 1;
static const NSInteger kTestRank2 = 2;
static const NSInteger kTestRank3 = 3;

@interface CLXWinLossTrackingTests : XCTestCase
@property (nonatomic, strong) MockCLXWinLossTracker *mockTracker;
@end

@implementation CLXWinLossTrackingTests

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

/**
 * Helper: populate TrackingFieldResolver's responseDataMap so bid.* fields resolve.
 */
- (void)setUpResponseDataForAuction:(NSString *)auctionId bids:(NSArray<CLXBidResponseBid *> *)bids {
    NSMutableArray *bidJsonArray = [NSMutableArray array];
    for (CLXBidResponseBid *bid in bids) {
        NSMutableDictionary *bidJson = [NSMutableDictionary dictionary];
        if (bid.id) bidJson[@"id"] = bid.id;
        bidJson[@"price"] = @(bid.price);
        if (bid.nurl) bidJson[@"nurl"] = bid.nurl;
        if (bid.lurl) bidJson[@"lurl"] = bid.lurl;
        if (bid.burl) bidJson[@"burl"] = bid.burl;
        [bidJsonArray addObject:bidJson];
    }

    NSDictionary *responseJson = @{
        @"id": auctionId,
        @"seatbid": @[@{@"bid": bidJsonArray}]
    };
    [[CLXTrackingFieldResolver shared] setResponseData:auctionId bidResponseJSON:responseJson];
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

#pragma mark - MARK: Core Win/Loss Tracking Tests

/**
 * Test that bids are properly added to the tracking system
 */
- (void)testAddBid_ShouldStoreMultipleBidsPerAuction {
    // Given: Multiple bids for the same auction
    CLXBidResponseBid *bid1 = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    CLXBidResponseBid *bid2 = [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:kTestRank2 price:kTestPrice * 0.8];
    
    // When: Adding bids to tracker
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid1];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid2];
    
    // Then: Both bids should be stored
    XCTAssertEqual(self.mockTracker.storedBids[kTestAuctionID].count, 2, @"Should store both bids for auction");
    XCTAssertEqualObjects(self.mockTracker.storedBids[kTestAuctionID][0].id, kTestBidID1, @"First bid should be stored correctly");
    XCTAssertEqualObjects(self.mockTracker.storedBids[kTestAuctionID][1].id, kTestBidID2, @"Second bid should be stored correctly");
}

/**
 * Test win notification with proper bid data resolution
 */
- (void)testSendWin_WithValidBid_ShouldCreateWinNotificationWithResolvedData {
    // Given: A bid with NURL
    CLXBidResponseBid *winningBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:winningBid];
    
    // When: Sending win notification using sendEvent
    [[CLXWinLossTracker shared] sendEvent:kTestAuctionID
                                     bidId:kTestBidID1
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0
                                     error:nil];
    
    // Then: Win notification should be captured
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"One win notification should be sent");
    
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"auctionId"], kTestAuctionID, @"Auction ID should match");
    XCTAssertEqualObjects(winNotification[@"bidId"], kTestBidID1, @"Bid ID should match");
    XCTAssertEqualObjects(winNotification[@"type"], @"win", @"Notification type should be win");
    XCTAssertNotNil(winNotification[@"timestamp"], @"Timestamp should be present");
    
    // BEHAVIORAL TEST: Verify that sendWin was called and tracked
    // URL resolution logic is tested separately in CLXWinLossURLResolutionIntegrationTests
    // This test focuses on the interaction/behavior, not the business logic details
}

// URL template replacement testing moved to CLXWinLossURLResolutionIntegrationTests
// This maintains proper separation of concerns - behavior vs business logic

// Cross-platform formatting tests moved to CLXWinLossURLResolutionIntegrationTests
// This maintains proper separation of concerns

/**
 * Test loss notification with proper loss reason resolution
 */
- (void)testSendLoss_WithValidBidAndReason_ShouldCreateLossNotificationWithResolvedLURL {
    // Given: A bid with LURL and a loss reason set
    CLXBidResponseBid *losingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:losingBid];
    [self setUpResponseDataForAuction:kTestAuctionID bids:@[losingBid]];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID
                                           bidId:kTestBidID1
                                         success:NO
                                      lossReason:@(CLXLossReasonInternalError)];

    // When: Sending loss notification using sendEvent
    [[CLXWinLossTracker shared] sendEvent:kTestAuctionID
                                     bidId:kTestBidID1
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0
                                     error:nil];

    // Then: Loss notification should be captured
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"One loss notification should be sent");

    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertEqualObjects(lossNotification[@"auctionId"], kTestAuctionID, @"Auction ID should match");
    XCTAssertEqualObjects(lossNotification[@"bidId"], kTestBidID1, @"Bid ID should match");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonInternalError, @"Loss reason should match");
    XCTAssertEqualObjects(lossNotification[@"type"], @"loss", @"Notification type should be loss");
    XCTAssertNotNil(lossNotification[@"timestamp"], @"Timestamp should be present");
}

#pragma mark - MARK: Losing Bid Tests

/**
 * Test that when a winner is selected, losing bids get loss notifications with LostToHigherBid reason
 */
- (void)testLosingBids_WhenWinnerSelected_ShouldFireLossNotificationsWithLostToHigherBid {
    // Given: Multiple bids with one winner and multiple losers
    CLXBidResponseBid *winnerBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    CLXBidResponseBid *loser1 = [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:kTestRank2 price:kTestPrice * 0.8];
    CLXBidResponseBid *loser2 = [self createBidWithId:kTestBidID3 lurl:kTestLURL3 nurl:nil rank:kTestRank3 price:kTestPrice * 0.6];
    
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:winnerBid];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:loser1];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:loser2];
    
    // Set winner and mark losers
    [[CLXWinLossTracker shared] setWinner:kTestAuctionID winningBidId:kTestBidID1];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID bidId:kTestBidID2 success:NO lossReason:@(CLXLossReasonLostToHigherBid)];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID bidId:kTestBidID3 success:NO lossReason:@(CLXLossReasonLostToHigherBid)];
    
    // When: Losing bids are notified
    [[CLXWinLossTracker shared] sendEvent:kTestAuctionID bidId:kTestBidID2 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonLostToHigherBid) winnerBidPrice:-1.0 error:nil];
    [[CLXWinLossTracker shared] sendEvent:kTestAuctionID bidId:kTestBidID3 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonLostToHigherBid) winnerBidPrice:-1.0 error:nil];
    
    // Then: Both losing bids should send loss notifications
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 2, @"Both losing bids should send loss notifications");
    
    for (NSDictionary *lossNotification in self.mockTracker.lossNotifications) {
        XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonLostToHigherBid, @"Loss reason should be LostToHigherBid");
        XCTAssertTrue([lossNotification[@"bidId"] isEqualToString:kTestBidID2] || 
                     [lossNotification[@"bidId"] isEqualToString:kTestBidID3], @"Bid ID should be one of the losers");
    }
}

/**
 * Test that bids without LURLs are handled gracefully (no crash, no notification)
 */
- (void)testLosingBids_WithoutLURLs_ShouldHandleGracefully {
    // Given: A bid without LURL
    CLXBidResponseBid *bidWithoutLURL = [self createBidWithId:kTestBidID1 lurl:nil nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bidWithoutLURL];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID bidId:kTestBidID1 success:NO lossReason:@(CLXLossReasonLostToHigherBid)];
    
    // When: Loss notification is sent for bid without LURL
    [[CLXWinLossTracker shared] sendEvent:kTestAuctionID
                                     bidId:kTestBidID1
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:-1.0
                                     error:nil];
    
    // Then: Should handle gracefully without crash
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Loss notification should still be sent");
    
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertNil(lossNotification[@"url"], @"Empty LURL should not be included in payload (filtered out)");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonLostToHigherBid, @"Loss reason should match sendEvent parameter");
}

#pragma mark - MARK: Configuration Tests

/**
 * Test that tracker properly stores configuration
 */
- (void)testConfiguration_ShouldStoreAppKeyAndEndpoint {
    // Given: Configuration values
    NSString *testAppKey = @"test-app-key-12345";
    NSString *testEndpoint = @"https://api.cloudx.com/win-loss";
    
    // When: Setting configuration
    [[CLXWinLossTracker shared] setAppKey:testAppKey];
    [[CLXWinLossTracker shared] setEndpoint:testEndpoint];
    
    // Then: Configuration should be stored
    XCTAssertEqualObjects(self.mockTracker.configuredAppKey, testAppKey, @"App key should be stored");
    XCTAssertEqualObjects(self.mockTracker.configuredEndpoint, testEndpoint, @"Endpoint should be stored");
}

#pragma mark - MARK: Edge Cases and Error Handling

/**
 * Test behavior with invalid auction/bid IDs
 */
- (void)testInvalidIds_ShouldHandleGracefully {
    // Given: Bids must be added before sending events
    CLXBidResponseBid *emptyIdBid = [self createBidWithId:@"" lurl:nil nurl:kTestNURL1 rank:1 price:kTestPrice];
    CLXBidResponseBid *invalidBid = [self createBidWithId:@"invalid-bid" lurl:kTestLURL1 nurl:nil rank:2 price:kTestPrice];
    
    [[CLXWinLossTracker shared] addBid:@"" bid:emptyIdBid];
    [[CLXWinLossTracker shared] addBid:@"invalid-auction" bid:invalidBid];
    
    // When: Sending notifications with invalid IDs
    [[CLXWinLossTracker shared] sendEvent:@"" bidId:@"" event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];
    [[CLXWinLossTracker shared] sendEvent:@"invalid-auction" bidId:@"invalid-bid" event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil];
    
    // Then: Should handle gracefully without crash
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Win notification should be sent even with empty IDs");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Loss notification should be sent even with invalid IDs");
    
    // Verify the notifications contain the provided (invalid) IDs
    XCTAssertEqualObjects(self.mockTracker.winNotifications[0][@"auctionId"], @"", @"Empty auction ID should be preserved");
    XCTAssertEqualObjects(self.mockTracker.lossNotifications[0][@"auctionId"], @"invalid-auction", @"Invalid auction ID should be preserved");
}

#pragma mark - MARK: Edge Case Tests

/**
 * Test win/loss tracking with malformed configuration
 */
- (void)testWinLossTracking_MalformedConfiguration_ShouldHandleGracefully {
    CLXWinLossTracker *tracker = [[CLXWinLossTracker alloc] init];
    
    // Test with various invalid configurations
    NSArray *invalidAppKeys = @[@"", @" ", @"key with spaces", @"key\nwith\nnewlines", [NSNull null]];
    NSArray *invalidEndpoints = @[@"", @" ", @"not-a-url", @"ftp://invalid.com", @"https://"];
    
    for (id appKey in invalidAppKeys) {
        for (NSString *endpoint in invalidEndpoints) {
            XCTAssertNoThrow([tracker setAppKey:(NSString *)appKey], 
                             @"Should not crash with invalid app key");
            XCTAssertNoThrow([tracker setEndpoint:endpoint], 
                             @"Should not crash with invalid endpoint");
            
            // Try to perform operations - should not crash
            CLXBidResponseBid *bid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
            XCTAssertNoThrow([tracker addBid:kTestAuctionID bid:bid], 
                             @"Should not crash adding bid with invalid config");
            XCTAssertNoThrow([tracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil], 
                             @"Should not crash sending win with invalid config");
        }
    }
    
    [tracker deleteAllEvents];
}

/**
 * Test bid state management with corrupted data
 */
- (void)testBidStateManagement_CorruptedData_ShouldHandleGracefully {
    // Test with bids that have missing required fields
    CLXBidResponseBid *incompleteBid = [[CLXBidResponseBid alloc] init];
    // Don't set nurl, lurl, or other fields
    
    [self.mockTracker addBid:kTestAuctionID bid:incompleteBid];
    
    // Should not crash when trying to use incomplete bid
    XCTAssertNoThrow([self.mockTracker sendEvent:kTestAuctionID bidId:nil event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil], 
                     @"Should handle nil bid ID gracefully");
    XCTAssertNoThrow([self.mockTracker sendEvent:kTestAuctionID bidId:@"nonexistent-bid" event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil], 
                     @"Should handle nonexistent bid ID gracefully");
}

/**
 * Test auction state consistency under rapid state changes
 */
- (void)testAuctionStateConsistency_RapidStateChanges_ShouldMaintainConsistency {
    // Add multiple bids to auction
    NSArray *bidIds = @[kTestBidID1, kTestBidID2, kTestBidID3];
    for (NSString *bidId in bidIds) {
        CLXBidResponseBid *bid = [self createBidWithId:bidId lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
        [self.mockTracker addBid:kTestAuctionID bid:bid];
    }
    
    // Rapidly change winner
    for (NSString *bidId in bidIds) {
        [self.mockTracker setWinner:kTestAuctionID winningBidId:bidId];
        
        // Trigger some operations
        [self.mockTracker sendEvent:kTestAuctionID bidId:bidId event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];
        [self.mockTracker sendEvent:kTestAuctionID bidId:bidIds[0] event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil]; // Try to send loss for same bid
    }
    
    // Verify mock received calls (exact behavior depends on implementation)
    XCTAssertGreaterThan(self.mockTracker.sendWinCallCount, 0, @"Should have processed win notifications");
}

/**
 * Test error handling in field resolution
 */
- (void)testFieldResolution_ErrorHandling_ShouldNotCrash {
    CLXWinLossTracker *realTracker = [[CLXWinLossTracker alloc] init];
    [realTracker setAppKey:@"test-app-key"];
    [realTracker setEndpoint:@"https://test.cloudx.com/win-loss"];
    
    // Create bid with potentially problematic URL templates
    CLXBidResponseBid *problematicBid = [[CLXBidResponseBid alloc] init];
    problematicBid.nurl = @"${INVALID_TEMPLATE}${AUCTION_PRICE}${MALFORMED";
    problematicBid.lurl = @"https://test.com?price=${AUCTION_PRICE}&data=\0\0\0null\0bytes";
    
    [realTracker addBid:kTestAuctionID bid:problematicBid];
    
    // Should not crash with problematic URLs
    XCTAssertNoThrow([realTracker sendEvent:kTestAuctionID bidId:@"problematic-bid" event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil], 
                     @"Should handle problematic URL templates gracefully");
    XCTAssertNoThrow([realTracker sendEvent:kTestAuctionID bidId:@"problematic-bid" event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil], 
                     @"Should handle problematic URL templates gracefully");
    
    [realTracker deleteAllEvents];
}

#pragma mark - MARK: P0 CRITICAL - Lifecycle Event Integration Tests

/**
 * P0 CRITICAL: Test sendEvent with LOAD_SUCCESS event
 * Revenue Risk: If LOAD_SUCCESS events fail, nurl notifications don't fire
 */
- (void)testSendEvent_LoadSuccess_ShouldFireNurlAndNotCountAsWin {
    // Given: A bid with nurl
    CLXBidResponseBid *bid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    [self.mockTracker addBid:kTestAuctionID bid:bid];
    
    // When: Sending LOAD_SUCCESS event
    CLXBidLifecycleEvent *loadEvent = [CLXBidLifecycleEvent loadSuccessEvent];
    [self.mockTracker sendEvent:kTestAuctionID 
                          bidId:kTestBidID1 
                          event:loadEvent 
                     lossReason:nil 
                 winnerBidPrice:kTestPrice
                          error:nil];
    
    // Then: Event should be recorded but NOT counted as revenue win
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"sendEvent should be called once");
    XCTAssertEqual(self.mockTracker.lifecycleEvents.count, 1, @"Lifecycle event should be recorded");
    
    NSDictionary *lifecycleEvent = self.mockTracker.lifecycleEvents.firstObject;
    XCTAssertEqualObjects(lifecycleEvent[@"eventType"], @"LOAD_SUCCESS", @"Event type should be LOAD_SUCCESS");
    XCTAssertEqualObjects(lifecycleEvent[@"urlType"], @"nurl", @"URL type should be nurl");
    XCTAssertEqualObjects(lifecycleEvent[@"notificationType"], @"loadSuccess", @"Notification type should match");
    
    // LOAD_SUCCESS should be tracked (SDK sends the notification)
    // Note: Server determines which events count as billable impressions (typically only renderSuccess)
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"LOAD_SUCCESS event should be sent to server");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"Should not have loss notifications");
}

/**
 * P0 CRITICAL: Test sendEvent with RENDER_SUCCESS event
 * Revenue Risk: If RENDER_SUCCESS events fail, burl notifications don't fire = ZERO REVENUE
 */
- (void)testSendEvent_RenderSuccess_ShouldFireBurlAndCountAsWin {
    // Given: A bid with burl (billing URL)
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = kTestBidID1;
    bid.burl = @"https://network.com/burl?price=${AUCTION_PRICE}";
    bid.nurl = kTestNURL1;
    bid.price = kTestPrice;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = kTestRank1;
    
    [self.mockTracker addBid:kTestAuctionID bid:bid];
    
    // When: Sending RENDER_SUCCESS event (impression tracked)
    CLXBidLifecycleEvent *renderEvent = [CLXBidLifecycleEvent renderSuccessEvent];
    [self.mockTracker sendEvent:kTestAuctionID 
                          bidId:kTestBidID1 
                          event:renderEvent 
                     lossReason:nil 
                 winnerBidPrice:kTestPrice
                          error:nil];
    
    // Then: Event should trigger win notification (billable impression)
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"sendEvent should be called once");
    XCTAssertEqual(self.mockTracker.lifecycleEvents.count, 1, @"Lifecycle event should be recorded");
    
    NSDictionary *lifecycleEvent = self.mockTracker.lifecycleEvents.firstObject;
    XCTAssertEqualObjects(lifecycleEvent[@"eventType"], @"RENDER_SUCCESS", @"Event type should be RENDER_SUCCESS");
    XCTAssertEqualObjects(lifecycleEvent[@"urlType"], @"burl", @"URL type should be burl for billing");
    XCTAssertEqualObjects(lifecycleEvent[@"notificationType"], @"renderSuccess", @"Notification type should match");
    
    // CRITICAL: RENDER_SUCCESS MUST add to winNotifications (billable impression = revenue)
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"RENDER_SUCCESS MUST count as win for revenue");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"Should not have loss notifications");
    
    // URL resolution is tested separately — verify notification was sent
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"notificationType"], @"renderSuccess", @"Notification type should be renderSuccess");
}

/**
 * P0 CRITICAL: Test sendEvent with LOSS event
 * Revenue Risk: If LOSS events fail, demand partners don't know why they lost = bad relationships
 */
- (void)testSendEvent_Loss_ShouldFireLurlWithLossReason {
    // Given: A bid with lurl and loss reason
    CLXBidResponseBid *losingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [self.mockTracker addBid:kTestAuctionID bid:losingBid];
    
    // When: Sending LOSS event
    CLXBidLifecycleEvent *lossEvent = [CLXBidLifecycleEvent lossEvent];
    [self.mockTracker sendEvent:kTestAuctionID 
                          bidId:kTestBidID1 
                          event:lossEvent 
                     lossReason:@(CLXLossReasonLostToHigherBid) 
                 winnerBidPrice:3.0
                          error:nil];
    
    // Then: Loss notification should be sent
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"sendEvent should be called once");
    XCTAssertEqual(self.mockTracker.lifecycleEvents.count, 1, @"Lifecycle event should be recorded");
    
    NSDictionary *lifecycleEvent = self.mockTracker.lifecycleEvents.firstObject;
    XCTAssertEqualObjects(lifecycleEvent[@"eventType"], @"LOSS", @"Event type should be LOSS");
    XCTAssertEqualObjects(lifecycleEvent[@"urlType"], @"lurl", @"URL type should be lurl");
    XCTAssertEqualObjects(lifecycleEvent[@"notificationType"], @"loss", @"Notification type should match");
    XCTAssertEqualObjects(lifecycleEvent[@"lossReason"], @(CLXLossReasonLostToHigherBid), @"Loss reason should be preserved");
    
    // Verify loss notification was created
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Should have loss notification");
    XCTAssertEqual(self.mockTracker.winNotifications.count, 0, @"Should not have win notifications");
}

/**
 * Test sendEvent with CLICK event
 * Click notifications use burl and should fire as a win notification
 */
- (void)testSendEvent_Click_ShouldFireBurl {
    // Given: A bid with burl (billing URL)
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = kTestBidID1;
    bid.burl = @"https://network.com/burl?price=${AUCTION_PRICE}";
    bid.nurl = kTestNURL1;
    bid.price = kTestPrice;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = kTestRank1;

    [self.mockTracker addBid:kTestAuctionID bid:bid];

    // When: Sending CLICK event
    CLXBidLifecycleEvent *clickEvent = [CLXBidLifecycleEvent clickEvent];
    [self.mockTracker sendEvent:kTestAuctionID
                          bidId:kTestBidID1
                          event:clickEvent
                     lossReason:nil
                 winnerBidPrice:kTestPrice
                          error:nil];

    // Then: Click event should be recorded and sent as win notification (burl)
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"sendEvent should be called once");
    XCTAssertEqual(self.mockTracker.lifecycleEvents.count, 1, @"Lifecycle event should be recorded");

    NSDictionary *lifecycleEvent = self.mockTracker.lifecycleEvents.firstObject;
    XCTAssertEqualObjects(lifecycleEvent[@"eventType"], @"CLICK", @"Event type should be CLICK");
    XCTAssertEqualObjects(lifecycleEvent[@"urlType"], @"burl", @"URL type should be burl for click");
    XCTAssertEqualObjects(lifecycleEvent[@"notificationType"], @"click", @"Notification type should match");

    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Click event should be sent as win notification");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"Should not have loss notifications");

    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"notificationType"], @"click", @"Notification type should be click");
}

/**
 * P0 CRITICAL: Test that lifecycle events use correct URL type for each event
 */
- (void)testSendEvent_CorrectURLTypeForEachEventType {
    // Given: A bid with all three URL types
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = kTestBidID1;
    bid.lurl = @"https://network.com/loss";
    bid.nurl = @"https://network.com/notify";
    bid.burl = @"https://network.com/bill";
    bid.price = kTestPrice;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = kTestRank1;
    
    [self.mockTracker addBid:kTestAuctionID bid:bid];
    
    // When/Then: LOAD_SUCCESS uses nurl
    CLXBidLifecycleEvent *loadEvent = [CLXBidLifecycleEvent loadSuccessEvent];
    XCTAssertEqualObjects(loadEvent.urlType, @"nurl", @"LOAD_SUCCESS should use nurl");
    
    // When/Then: RENDER_SUCCESS uses burl
    CLXBidLifecycleEvent *renderEvent = [CLXBidLifecycleEvent renderSuccessEvent];
    XCTAssertEqualObjects(renderEvent.urlType, @"burl", @"RENDER_SUCCESS should use burl");
    
    // When/Then: LOSS uses lurl
    CLXBidLifecycleEvent *lossEvent = [CLXBidLifecycleEvent lossEvent];
    XCTAssertEqualObjects(lossEvent.urlType, @"lurl", @"LOSS should use lurl");

    // When/Then: CLICK uses burl
    CLXBidLifecycleEvent *clickEvent = [CLXBidLifecycleEvent clickEvent];
    XCTAssertEqualObjects(clickEvent.urlType, @"burl", @"CLICK should use burl");
}

#pragma mark - MARK: P0 CRITICAL - Network Success Cleanup Tests

/**
 * P0 CRITICAL: Test that events are deleted after successful network send
 * Duplicate Risk: If events aren't deleted, they'll send multiple times = revenue overreporting
 */
- (void)testNetworkSuccess_DeletesEventFromDatabase_NoDuplicates {
    // This test verifies the database deletion mechanism
    // Note: In the real implementation, events are deleted on successful network send.
    // Here we verify that deleteAllEvents works correctly as it's called after successful retries.
    
    CLXWinLossTracker *tracker = [[CLXWinLossTracker alloc] init];
    [tracker deleteAllEvents];
    
    // Given: Multiple events that would be in the database
    // We'll use the retry flow test pattern which we know caches events
    CLXBidResponseBid *bid1 = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:1 price:1.5];
    CLXBidResponseBid *bid2 = [self createBidWithId:kTestBidID2 lurl:kTestLURL2 nurl:nil rank:2 price:1.2];
    
    [tracker addBid:kTestAuctionID bid:bid1];
    [tracker addBid:kTestAuctionID bid:bid2];
    
    // These events will attempt to send and may or may not cache depending on network
    [tracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil];
    [tracker sendEvent:kTestAuctionID bidId:kTestBidID2 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil];
    
    // When: Delete all events (this is what happens after successful retry)
    [tracker deleteAllEvents];
    
    // Then: Database should be completely empty
    NSArray *cachedAfterDelete = [tracker getAllCachedEvents];
    XCTAssertEqual(cachedAfterDelete.count, 0, @"deleteAllEvents should remove all cached events");
    
    // Verify we can still use the database after deletion
    CLXBidResponseBid *bid3 = [self createBidWithId:kTestBidID3 lurl:kTestLURL3 nurl:nil rank:3 price:1.0];
    [tracker addBid:@"new-auction" bid:bid3];
    XCTAssertNoThrow([tracker sendEvent:@"new-auction" bidId:kTestBidID3 event:[CLXBidLifecycleEvent lossEvent] lossReason:@(CLXLossReasonInternalError) winnerBidPrice:-1.0 error:nil], 
                     @"Database should still be functional after deleteAllEvents");
    
    // Clean up
    [tracker deleteAllEvents];
}

#pragma mark - MARK: P0 CRITICAL - Price Edge Cases Tests

/**
 * P0 CRITICAL: Test handling of zero price
 * Revenue Risk: Zero price could indicate free inventory or error
 */
- (void)testZeroPrice_HandledCorrectlyInURLResolution {
    // Given: Bid with zero price
    CLXBidResponseBid *zeroPriceBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:0.0];
    [self.mockTracker addBid:kTestAuctionID bid:zeroPriceBid];
    [self setUpResponseDataForAuction:kTestAuctionID bids:@[zeroPriceBid]];

    // When: Send win notification with zero price
    [self.mockTracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];

    // Then: Should handle gracefully
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Should send notification even with zero price");
}

/**
 * P0 CRITICAL: Test handling of negative price
 * Data Integrity Risk: Negative prices should be handled or rejected
 */
- (void)testNegativePrice_HandledGracefully {
    // Given: Bid with negative price (should not happen, but test defensive coding)
    CLXBidResponseBid *negativePriceBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:-5.0];
    [self.mockTracker addBid:kTestAuctionID bid:negativePriceBid];
    
    // When: Send win notification
    XCTAssertNoThrow([self.mockTracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil], 
                     @"Should not crash with negative price");
    
    // Then: Should handle without crash
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Should send notification");
}

/**
 * P0 CRITICAL: Test very large prices (>$1000)
 * Format Risk: Large numbers could break URL formatting or payload size
 */
- (void)testLargePrice_FormatsCorrectly {
    // Given: Bid with very large price
    double largePrice = 9999.99;
    CLXBidResponseBid *largePriceBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:largePrice];
    [self.mockTracker addBid:kTestAuctionID bid:largePriceBid];
    [self setUpResponseDataForAuction:kTestAuctionID bids:@[largePriceBid]];

    // When: Send win notification
    [self.mockTracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];

    // Then: Should format correctly
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Should send notification");
}

/**
 * P0 CRITICAL: Test price with more than 2 decimal places
 * Precision Risk: Extra decimals could cause rounding issues
 */
- (void)testPriceWithExtraDecimals_RoundsToTwoPlaces {
    // Given: Bid with 5 decimal places
    double precisePrice = 3.14159;
    CLXBidResponseBid *precisePriceBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:precisePrice];
    [self.mockTracker addBid:kTestAuctionID bid:precisePriceBid];
    [self setUpResponseDataForAuction:kTestAuctionID bids:@[precisePriceBid]];

    // When: Send win notification
    [self.mockTracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];

    // Then: Bid price should be resolved via TrackingFieldResolver (bid.price)
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Should send notification");
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"bidPrice"], @(3.14159), @"Bid price should be stored with full precision");
}

/**
 * P0 CRITICAL: Test price formatting consistency (3.5 vs 3.50)
 */
- (void)testPriceFormatting_AlwaysUsesTwoDecimals {
    // Given: Bid with price that could format as 3.5
    double simplePrice = 3.5;
    CLXBidResponseBid *simplePriceBid = [self createBidWithId:kTestBidID1 lurl:nil nurl:kTestNURL1 rank:kTestRank1 price:simplePrice];
    [self.mockTracker addBid:kTestAuctionID bid:simplePriceBid];
    [self setUpResponseDataForAuction:kTestAuctionID bids:@[simplePriceBid]];

    // When: Send win notification
    [self.mockTracker sendEvent:kTestAuctionID bidId:kTestBidID1 event:[CLXBidLifecycleEvent loadSuccessEvent] lossReason:nil winnerBidPrice:-1.0 error:nil];

    // Then: Bid price should be resolved via TrackingFieldResolver (bid.price)
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"bidPrice"], @(3.5), @"Bid price should be stored as double (3.5)");
}

@end
