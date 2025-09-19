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
                   completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion;
@end

@interface CLXWinLossTrackingTests : XCTestCase
@property (nonatomic, strong) MockCLXWinLossTracker *mockTracker;
@end

@implementation CLXWinLossTrackingTests

#pragma mark - Test Setup

- (void)setUp {
    [super setUp];
    self.mockTracker = [[MockCLXWinLossTracker alloc] init];
    [CLXWinLossTracker setSharedInstanceForTesting:self.mockTracker];
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

- (CLXBidAdSource *)createTestBidAdSourceWithCreateBlock:(id (^)(NSString *, NSString *, NSString *, NSDictionary *, NSString *, BOOL, NSString *))createBlock {
    return [[CLXBidAdSource alloc] 
        initWithUserID:kTestUserID
        placementID:kTestPlacementID
        dealID:nil
        hasCloseButton:NO
        publisherID:kTestPublisherID
        adType:1 // Banner
        bidTokenSources:@{}
        nativeAdRequirements:nil
        tmax:@(5000)
        reportingService:nil  // Uses CLXWinLossTracker.shared
        createBidAd:createBlock];
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
    
    // When: Sending win notification
    [[CLXWinLossTracker shared] sendWin:kTestAuctionID bidId:kTestBidID1];
    
    // Then: Win notification should be captured
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"One win notification should be sent");
    
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"auctionId"], kTestAuctionID, @"Auction ID should match");
    XCTAssertEqualObjects(winNotification[@"bidId"], kTestBidID1, @"Bid ID should match");
    XCTAssertEqualObjects(winNotification[@"type"], @"win", @"Notification type should be win");
    XCTAssertNotNil(winNotification[@"timestamp"], @"Timestamp should be present");
}

/**
 * Test loss notification with proper LURL resolution and loss reason
 */
- (void)testSendLoss_WithValidBidAndReason_ShouldCreateLossNotificationWithResolvedLURL {
    // Given: A bid with LURL and a loss reason set
    CLXBidResponseBid *losingBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:nil rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:losingBid];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID 
                                           bidId:kTestBidID1 
                                         success:NO 
                                      lossReason:@(CLXLossReasonTechnicalError)];
    
    // When: Sending loss notification
    [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID1];
    
    // Then: Loss notification should be captured with resolved LURL
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"One loss notification should be sent");
    
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertEqualObjects(lossNotification[@"auctionId"], kTestAuctionID, @"Auction ID should match");
    XCTAssertEqualObjects(lossNotification[@"bidId"], kTestBidID1, @"Bid ID should match");
    XCTAssertEqualObjects(lossNotification[@"resolvedURL"], kTestLURL1, @"LURL should be resolved from bid");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonTechnicalError, @"Loss reason should match");
    XCTAssertEqualObjects(lossNotification[@"type"], @"loss", @"Notification type should be loss");
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
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
        return nil; // Simulate adapter creation failure
    }];
    
    // When: Waterfall tries this bid
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:@[failingBid] 
                              bidIndex:0 
                             auctionID:kTestAuctionID 
                            bidRequest:@{@"test": @"data"} 
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
    XCTAssertEqualObjects(lossNotification[@"resolvedURL"], kTestLURL1, @"LURL should be resolved");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonTechnicalError, @"Loss reason should be TechnicalError");
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
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
        return nil; // All bids fail
    }];
    
    // When: Waterfall tries all bids
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:failingBids 
                              bidIndex:0 
                             auctionID:kTestAuctionID 
                            bidRequest:@{@"test": @"data"} 
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
        XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonTechnicalError, @"All should have TechnicalError reason");
        XCTAssertNotNil(lossNotification[@"resolvedURL"], @"All should have resolved LURLs");
    }
    
    XCTAssertEqualObjects(actualBidIds, expectedBidIds, @"All expected bid IDs should have loss notifications");
}

/**
 * Test that successful bid creation does NOT fire loss notifications prematurely
 */
- (void)testWaterfallBidSuccess_ShouldNotFireLossNotificationYet {
    // Given: A bid that will successfully create an adapter
    CLXBidResponseBid *successfulBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:successfulBid];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithCreateBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
        return [[NSObject alloc] init]; // Simulate successful adapter creation
    }];
    
    // When: Waterfall tries this bid
    XCTestExpectation *expectation = [self expectationWithDescription:@"Waterfall completion"];
    [bidAdSource tryNextBidInWaterfall:@[successfulBid] 
                              bidIndex:0 
                             auctionID:kTestAuctionID 
                            bidRequest:@{@"test": @"data"} 
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

#pragma mark - MARK: Winner Load Failure Tests

/**
 * Test that when a winning bid fails to load after successful waterfall selection,
 * it sends a loss notification with TechnicalError
 */
- (void)testWinnerLoadFailure_ShouldFireLossNotificationWithTechnicalError {
    // Given: A winning bid that will fail to load
    CLXBidResponseBid *winnerBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    
    // Simulate the winner failing to load (this would normally be called by CLXPublisherBanner)
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:winnerBid];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID 
                                           bidId:kTestBidID1 
                                         success:NO 
                                      lossReason:@(CLXLossReasonTechnicalError)];
    
    // When: Winner load fails
    [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID1];
    
    // Then: Loss notification should be sent
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Winner load failure should send loss notification");
    
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertEqualObjects(lossNotification[@"bidId"], kTestBidID1, @"Correct bid ID should be used");
    XCTAssertEqualObjects(lossNotification[@"resolvedURL"], kTestLURL1, @"Winner's LURL should be resolved");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonTechnicalError, @"Loss reason should be TechnicalError");
}

/**
 * Test that when a winner loads successfully, it sends a win notification
 */
- (void)testWinnerLoadSuccess_ShouldFireWinNotification {
    // Given: A winning bid that loads successfully
    CLXBidResponseBid *winnerBid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:winnerBid];
    [[CLXWinLossTracker shared] setBidLoadResult:kTestAuctionID 
                                           bidId:kTestBidID1 
                                         success:YES 
                                      lossReason:nil];
    
    // When: Winner loads successfully
    [[CLXWinLossTracker shared] sendWin:kTestAuctionID bidId:kTestBidID1];
    
    // Then: Win notification should be sent
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Winner load success should send win notification");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"No loss notifications should be sent for successful winner");
    
    NSDictionary *winNotification = self.mockTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"bidId"], kTestBidID1, @"Correct bid ID should be used");
    XCTAssertEqualObjects(winNotification[@"auctionId"], kTestAuctionID, @"Correct auction ID should be used");
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
    [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID2];
    [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID3];
    
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
    [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID1];
    
    // Then: Should handle gracefully without crash
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Loss notification should still be sent");
    
    NSDictionary *lossNotification = self.mockTracker.lossNotifications.firstObject;
    XCTAssertEqualObjects(lossNotification[@"resolvedURL"], @"", @"Empty LURL should be handled gracefully");
    XCTAssertEqual([lossNotification[@"lossReason"] integerValue], CLXLossReasonLostToHigherBid, @"Loss reason should still be correct");
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
    // When: Sending notifications with invalid IDs
    [[CLXWinLossTracker shared] sendWin:@"" bidId:@""];
    [[CLXWinLossTracker shared] sendLoss:@"invalid-auction" bidId:@"invalid-bid"];
    
    // Then: Should handle gracefully without crash
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Win notification should be sent even with empty IDs");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 1, @"Loss notification should be sent even with invalid IDs");
    
    // Verify the notifications contain the provided (invalid) IDs
    XCTAssertEqualObjects(self.mockTracker.winNotifications[0][@"auctionId"], @"", @"Empty auction ID should be preserved");
    XCTAssertEqualObjects(self.mockTracker.lossNotifications[0][@"auctionId"], @"invalid-auction", @"Invalid auction ID should be preserved");
}

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
        [[CLXWinLossTracker shared] sendWin:kTestAuctionID bidId:kTestBidID1];
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[CLXWinLossTracker shared] sendLoss:kTestAuctionID bidId:kTestBidID2];
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
 * Test mock reset functionality for test isolation
 */
- (void)testMockReset_ShouldClearAllData {
    // Given: Some data in the mock
    CLXBidResponseBid *bid = [self createBidWithId:kTestBidID1 lurl:kTestLURL1 nurl:kTestNURL1 rank:kTestRank1 price:kTestPrice];
    [[CLXWinLossTracker shared] addBid:kTestAuctionID bid:bid];
    [[CLXWinLossTracker shared] sendWin:kTestAuctionID bidId:kTestBidID1];
    [[CLXWinLossTracker shared] setAppKey:@"test-key"];
    
    XCTAssertEqual(self.mockTracker.winNotifications.count, 1, @"Should have win notification before reset");
    XCTAssertNotNil(self.mockTracker.configuredAppKey, @"Should have app key before reset");
    
    // When: Resetting the mock
    [self.mockTracker reset];
    
    // Then: All data should be cleared
    XCTAssertEqual(self.mockTracker.winNotifications.count, 0, @"Win notifications should be cleared");
    XCTAssertEqual(self.mockTracker.lossNotifications.count, 0, @"Loss notifications should be cleared");
    XCTAssertEqual(self.mockTracker.bidResults.count, 0, @"Bid results should be cleared");
    XCTAssertEqual(self.mockTracker.storedBids.count, 0, @"Stored bids should be cleared");
    XCTAssertNil(self.mockTracker.configuredAppKey, @"App key should be cleared");
    XCTAssertNil(self.mockTracker.configuredEndpoint, @"Endpoint should be cleared");
}

@end
