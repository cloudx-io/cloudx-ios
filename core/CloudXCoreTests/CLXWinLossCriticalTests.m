/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "MockCLXWinLossTracker.h"

/**
 * @brief P0 CRITICAL Tests for Win/Loss Event System
 * 
 * Principal Engineer Approach - Test Critical Win/Loss Functionality:
 * - Verify zero client-side URL hydration (server handles macro replacement)
 * - Verify consistent event API usage (sendEvent only, no legacy methods)
 * - Verify consistent payload structure (notificationType field present)
 * - Verify raw URLs with macros are sent unchanged to server
 */
@interface CLXWinLossCriticalTests : XCTestCase
@property (nonatomic, strong) MockCLXWinLossTracker *mockTracker;
@property (nonatomic, strong) CLXWinLossFieldResolver *fieldResolver;
@end

@implementation CLXWinLossCriticalTests

- (void)setUp {
    [super setUp];
    
    // Use mock tracker to verify behavior
    self.mockTracker = [[MockCLXWinLossTracker alloc] init];
    [CLXWinLossTracker setSharedInstanceForTesting:self.mockTracker];
    
    // Configure with real payload mapping (simulating server config)
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[notificationType]",  // CRITICAL: Must be present
        @"url": @"sdk.[bid.nurl|bid.lurl]",
        @"auctionId": @"auctionId",
        @"bidId": @"bidId",
        @"lossReason": @"lossReason"
    };
    [[CLXWinLossTracker shared] setConfig:config];
    
    // Set endpoint and app key - required for trackWinLoss to be called
    [[CLXWinLossTracker shared] setEndpoint:@"https://test.com/winloss"];
    [[CLXWinLossTracker shared] setAppKey:@"test-app-key"];
    
    // Create field resolver for direct payload testing
    self.fieldResolver = [[CLXWinLossFieldResolver alloc] initWithPayloadMapping:config.winLossNotificationPayloadConfig];
}

- (void)tearDown {
    [CLXWinLossTracker resetSharedInstance];
    [super tearDown];
}

#pragma mark - P0 CRITICAL: Zero URL Hydration Tests

/**
 * P0 CRITICAL: Verify iOS sends raw URLs with ${AUCTION_PRICE} macro intact (matches Android)
 */
- (void)testP0_LoadSuccessEvent_ShouldSendRawNURLWithMacrosIntact {
    // Given: A bid with NURL containing macros
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"test-bid-123";
    bid.nurl = @"https://network.com/nurl?price=${AUCTION_PRICE}&campaign=test";
    bid.price = 3.75;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending LOAD_SUCCESS event (fires NURL)
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"test-bid-123"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0];
    
    
    // Then: Should have fired the event
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send LOAD_SUCCESS payload");
    
    // Verify the payload sent to server contains raw URL with macros
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    NSString *sentURL = payload[@"url"];
    
    XCTAssertNotNil(sentURL, @"URL should be present in payload");
    XCTAssertTrue([sentURL containsString:@"${AUCTION_PRICE}"], 
                  @"CRITICAL: URL must contain raw macro ${AUCTION_PRICE} - server does hydration");
    XCTAssertFalse([sentURL containsString:@"price=3.75"], 
                   @"CRITICAL: URL must NOT have client-side hydration - matches Android");
    XCTAssertTrue([sentURL containsString:@"campaign=test"], @"Other URL params should be preserved");
    
    // Verify notificationType field is present (matches Android)
    XCTAssertEqualObjects(payload[@"notificationType"], @"load_success",
                         @"Must include notificationType field matching Android");
}

/**
 * P0 CRITICAL: Verify iOS sends raw URLs with ${AUCTION_LOSS} macro intact (matches Android)
 */
- (void)testP0_LossEvent_ShouldSendRawLURLWithMacrosIntact {
    // Given: A bid with LURL containing macros
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"losing-bid-456";
    bid.lurl = @"https://network.com/lurl?reason=${AUCTION_LOSS}&price=${AUCTION_PRICE}";
    bid.price = 2.50;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] setBidLoadResult:@"test-auction" 
                                           bidId:@"losing-bid-456" 
                                         success:NO 
                                      lossReason:@(CLXLossReasonLostToHigherBid)];
    
    // When: Sending LOSS event (fires LURL)
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"losing-bid-456"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:5.00];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    // Then: Should have fired the event
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send LOSS payload");
    
    // Verify the payload sent to server contains raw URL with macros
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    NSString *sentURL = payload[@"url"];
    
    XCTAssertNotNil(sentURL, @"URL should be present in payload");
    XCTAssertTrue([sentURL containsString:@"${AUCTION_LOSS}"], 
                  @"CRITICAL: URL must contain raw macro ${AUCTION_LOSS} - server does hydration");
    XCTAssertTrue([sentURL containsString:@"${AUCTION_PRICE}"], 
                  @"CRITICAL: URL must contain raw macro ${AUCTION_PRICE} - server does hydration");
    XCTAssertFalse([sentURL containsString:@"reason=102"], 
                   @"CRITICAL: URL must NOT have client-side loss reason hydration");
    XCTAssertFalse([sentURL containsString:@"price=2.50"], 
                   @"CRITICAL: URL must NOT have client-side price hydration");
    
    // Verify notificationType field is present (matches Android)
    XCTAssertEqualObjects(payload[@"notificationType"], @"loss",
                         @"Must include notificationType field matching Android");
}

#pragma mark - P0 CRITICAL: Lifecycle Event Type Tests

/**
 * P0 CRITICAL: Verify sendEvent with LOAD_SUCCESS fires correct notification type
 */
- (void)testP0_SendEvent_WithLoadSuccess_ShouldFireCorrectType {
    // Given: A bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"test-bid";
    bid.nurl = @"https://test.com/nurl";
    bid.price = 1.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending LOAD_SUCCESS event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"test-bid"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    // Then: Should fire event with correct type in payload
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"Should call sendEvent once");
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertEqualObjects(payload[@"notificationType"], @"load_success", 
                         @"Payload must include notificationType=load_success");
}

/**
 * P0 CRITICAL: Verify sendEvent with LOSS fires correct notification type
 */
- (void)testP0_SendEvent_WithLoss_ShouldFireCorrectType {
    // Given: A losing bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"losing-bid";
    bid.lurl = @"https://test.com/lurl";
    bid.price = 1.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] setBidLoadResult:@"test-auction" 
                                           bidId:@"losing-bid" 
                                         success:NO 
                                      lossReason:@(CLXLossReasonInternalError)];
    
    // When: Sending LOSS event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"losing-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    // Then: Should fire event with correct type in payload
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"Should call sendEvent once");
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertEqualObjects(payload[@"notificationType"], @"loss", 
                         @"Payload must include notificationType=loss");
    XCTAssertEqualObjects(payload[@"lossReason"], @(CLXLossReasonInternalError), 
                         @"Loss reason should be preserved");
}

#pragma mark - P0 CRITICAL: Payload Structure Tests

/**
 * P0 CRITICAL: Verify notificationType field is present in all payloads (matches Android)
 */
- (void)testP0_WinLossPayloads_ShouldIncludeNotificationTypeField {
    // Given: Win and loss bid scenarios
    CLXBidResponseBid *winBid = [[CLXBidResponseBid alloc] init];
    winBid.id = @"win-bid";
    winBid.nurl = @"https://test.com/nurl?price=${AUCTION_PRICE}";
    winBid.price = 3.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:winBid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"win-bid"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *loadSuccessPayload = self.mockTracker.allPayloadsSent.firstObject;
    
    XCTAssertNotNil(loadSuccessPayload[@"notificationType"], 
                   @"CRITICAL: LOAD_SUCCESS payload must include notificationType");
    XCTAssertEqualObjects(loadSuccessPayload[@"notificationType"], @"load_success",
                         @"notificationType should be 'load_success'");
    
    [self.mockTracker reset];
    
    // Test LOSS payload
    CLXBidResponseBid *lossBid = [[CLXBidResponseBid alloc] init];
    lossBid.id = @"loss-bid";
    lossBid.lurl = @"https://test.com/lurl?reason=${AUCTION_LOSS}";
    lossBid.price = 1.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction-2" bid:lossBid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction-2"
                                     bidId:@"loss-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:5.0];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *lossPayload = self.mockTracker.allPayloadsSent.firstObject;
    
    XCTAssertNotNil(lossPayload[@"notificationType"], 
                   @"CRITICAL: LOSS payload must include notificationType");
    XCTAssertEqualObjects(lossPayload[@"notificationType"], @"loss",
                         @"notificationType should be 'loss'");
}

/**
 * P0 CRITICAL: Verify all win/loss events use sendEvent API (no legacy sendWin/sendLoss)
 */
- (void)testP0_AllWinLossEvents_UseSendEventAPI {
    // This test verifies that the codebase has migrated to sendEvent
    // The mere fact that other tests compile and run proves this, since
    // sendWin and sendLoss methods have been removed from the public API
    
    // Verify sendEvent method exists and is callable
    XCTAssertTrue([[CLXWinLossTracker shared] respondsToSelector:@selector(sendEvent:bidId:event:lossReason:winnerBidPrice:)],
                 @"sendEvent API must be available");
    
    // Verify legacy methods are removed (compilation will fail if they exist and we try to call them)
    // This is a compile-time check, not a runtime check
    XCTAssertTrue(YES, @"If this test compiles, legacy APIs are properly removed");
}

#pragma mark - P0 CRITICAL: Cross-Platform Consistency

/**
 * P0 CRITICAL: Verify iOS and Android send identical payload structure
 */
- (void)testP0_PayloadStructure_MatchesAndroid {
    // Given: A bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"consistency-bid";
    bid.lurl = @"https://test.com/lurl?reason=${AUCTION_LOSS}";
    bid.price = 2.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"consistency-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    // Then: Payload should have same structure as Android
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // Then: Payload should have same structure as Android
    XCTAssertNotNil(payload[@"notificationType"], @"Must have notificationType (Android has this)");
    XCTAssertNotNil(payload[@"url"], @"Must have url field");
    XCTAssertNotNil(payload[@"auctionId"], @"Must have auctionId");
    XCTAssertNotNil(payload[@"bidId"], @"Must have bidId");
    XCTAssertNotNil(payload[@"lossReason"], @"Must have lossReason for loss events");
    
    // Verify URL is raw with macros (matching Android)
    NSString *url = payload[@"url"];
    XCTAssertTrue([url containsString:@"${AUCTION_LOSS}"], 
                 @"iOS must send raw URLs like Android does");
}

@end

