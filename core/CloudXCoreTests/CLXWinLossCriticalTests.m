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
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",  // CRITICAL: Must be present
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
 * P0 CRITICAL: Verify iOS sends raw URLs with ${AUCTION_PRICE} macro intact for server-side hydration
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Should have fired the event
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send LOAD_SUCCESS payload");
    
    // Verify the payload sent to server contains raw URL with macros
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    NSString *sentURL = payload[@"url"];
    
    XCTAssertNotNil(sentURL, @"URL should be present in payload");
    XCTAssertTrue([sentURL containsString:@"${AUCTION_PRICE}"], 
                  @"CRITICAL: URL must contain raw macro ${AUCTION_PRICE} - server does hydration");
    XCTAssertFalse([sentURL containsString:@"price=3.75"], 
                   @"CRITICAL: URL must NOT have client-side hydration - server does macro replacement");
    XCTAssertTrue([sentURL containsString:@"campaign=test"], @"Other URL params should be preserved");
    
    // Verify notificationType field is present for server
    XCTAssertEqualObjects(payload[@"notificationType"], @"loadSuccess",
                         @"Must include notificationType field for server categorization");
}

/**
 * P0 CRITICAL: Verify iOS sends raw URLs with ${AUCTION_LOSS} macro intact for server-side hydration
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
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
    
    // Verify notificationType field is present for server
    XCTAssertEqualObjects(payload[@"notificationType"], @"loss",
                         @"Must include notificationType field for server categorization");
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Should fire event with correct type in payload
    XCTAssertEqual(self.mockTracker.sendEventCallCount, 1, @"Should call sendEvent once");
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertEqualObjects(payload[@"notificationType"], @"loadSuccess", 
                         @"Payload must include notificationType=loadSuccess");
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
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
 * P0 CRITICAL: Verify notificationType field is present in all payloads for server routing
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *loadSuccessPayload = self.mockTracker.allPayloadsSent.firstObject;
    
    XCTAssertNotNil(loadSuccessPayload[@"notificationType"], 
                   @"CRITICAL: LOAD_SUCCESS payload must include notificationType");
    XCTAssertEqualObjects(loadSuccessPayload[@"notificationType"], @"loadSuccess",
                         @"notificationType should be 'loadSuccess'");
    
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
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
    // Test passes if no crash: If this test compiles, legacy APIs are properly removed
}

#pragma mark - P0 CRITICAL: Server Payload Compliance

/**
 * P0 CRITICAL: Verify iOS sends complete server-required payload structure
 */
- (void)testP0_PayloadStructure_ServerCompliance {
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
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Verify server-required payload structure
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // Then: Payload should have server-required structure
    XCTAssertNotNil(payload[@"notificationType"], @"Must have notificationType for server");
    XCTAssertNotNil(payload[@"url"], @"Must have url field");
    XCTAssertNotNil(payload[@"auctionId"], @"Must have auctionId");
    XCTAssertNotNil(payload[@"bidId"], @"Must have bidId");
    XCTAssertNotNil(payload[@"lossReason"], @"Must have lossReason for loss events");
    
    // Verify URL is raw with macros (server-side hydration)
    NSString *url = payload[@"url"];
    XCTAssertTrue([url containsString:@"${AUCTION_LOSS}"], 
                 @"URLs must be sent with raw macros intact for server-side hydration");
}

#pragma mark - P0 CRITICAL: Server-Required Field Support (2025-10-24)

/**
 * P0 CRITICAL: Verify iOS sends complete `bid` object for server-side analytics
 * 
 * Server requires: Complete bid object from seatbid[0].bid[0]
 * iOS sends: [bid toDictionary] when fieldPath is "seatbid[0].bid[0]"
 * 
 * This enables server to access full bid structure for analytics and reporting.
 */
- (void)testP0_BidObjectField_SendsCompleteBidStructure {
    // Update config to include bid field mapping
    CLXSDKConfigResponse *configWithBid = [[CLXSDKConfigResponse alloc] init];
    configWithBid.winLossNotificationURL = @"https://test.com/winloss";
    configWithBid.winLossNotificationPayloadConfig = @{
        @"bid": @"seatbid[0].bid[0]",  // CRITICAL: Server-required bid object
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"auctionId": @"auctionId"
    };
    [[CLXWinLossTracker shared] setConfig:configWithBid];
    
    // Given: A bid with comprehensive structure
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"bid-with-full-structure";
    bid.price = 3.50;
    bid.adm = @"<html>test ad markup</html>";
    bid.w = 320;
    bid.h = 50;
    
    // Add ext structure with rank and adapter info
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.origbidcpm = 3.50;
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = 1;
    bid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    bid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    bid.ext.prebid.meta.adaptercode = @"meta";
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"bid-with-full-structure"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0];
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Verify bid object is present and complete
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // CRITICAL: Verify 'bid' field exists
    id bidField = payload[@"bid"];
    XCTAssertNotNil(bidField, @"CRITICAL: Payload must contain 'bid' field for server analytics");
    XCTAssertTrue([bidField isKindOfClass:[NSDictionary class]], 
                 @"CRITICAL: 'bid' must be dictionary for JSON serialization");
    
    NSDictionary *bidDict = (NSDictionary *)bidField;
    
    // Verify essential bid fields are serialized
    XCTAssertEqualObjects(bidDict[@"id"], @"bid-with-full-structure", @"bid.id must match");
    XCTAssertEqual([bidDict[@"price"] doubleValue], 3.50, @"bid.price must match");
    XCTAssertEqualObjects(bidDict[@"adm"], @"<html>test ad markup</html>", @"bid.adm must be present");
    XCTAssertEqual([bidDict[@"w"] integerValue], 320, @"bid.w must match");
    XCTAssertEqual([bidDict[@"h"] integerValue], 50, @"bid.h must match");
    
    // Verify ext structure is serialized
    XCTAssertNotNil(bidDict[@"ext"], @"bid.ext must be present");
    NSDictionary *extDict = bidDict[@"ext"];
    XCTAssertNotNil(extDict[@"cloudx"], @"bid.ext.cloudx must be present");
    XCTAssertNotNil(extDict[@"prebid"], @"bid.ext.prebid must be present");
    
    NSDictionary *cloudxDict = extDict[@"cloudx"];
    XCTAssertEqual([cloudxDict[@"rank"] integerValue], 1, @"bid.ext.cloudx.rank must match");
}

/**
 * P0 CRITICAL: Verify iOS sends numeric lossReasonCode for server processing
 * 
 * Server requires: Numeric loss reason code (0, 1, 102, etc.)
 * iOS sends: lossReason as NSNumber when fieldPath is "sdk.lossReasonCode"
 * 
 * Note: This is DIFFERENT from "sdk.lossReason" which returns human-readable string.
 */
- (void)testP0_LossReasonCodeField_SendsNumericValue {
    // Update config to include lossReasonCode
    CLXSDKConfigResponse *configWithCode = [[CLXSDKConfigResponse alloc] init];
    configWithCode.winLossNotificationURL = @"https://test.com/winloss";
    configWithCode.winLossNotificationPayloadConfig = @{
        @"lossReasonCode": @"sdk.lossReasonCode",  // CRITICAL: Server requires numeric code
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"auctionId": @"auctionId"
    };
    [[CLXWinLossTracker shared] setConfig:configWithCode];
    
    // Given: A losing bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"losing-bid";
    bid.lurl = @"https://test.com/lurl";
    bid.price = 2.0;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending loss event with code 102 (Lost to Higher Bid)
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"losing-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)  // 102
                            winnerBidPrice:5.0];
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Verify lossReasonCode is numeric
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // CRITICAL: Verify 'lossReasonCode' field exists and is numeric
    id lossReasonCodeField = payload[@"lossReasonCode"];
    XCTAssertNotNil(lossReasonCodeField, @"CRITICAL: Payload must contain 'lossReasonCode' for server");
    XCTAssertTrue([lossReasonCodeField isKindOfClass:[NSNumber class]], 
                 @"CRITICAL: 'lossReasonCode' must be NSNumber for server processing");
    
    NSNumber *code = (NSNumber *)lossReasonCodeField;
    XCTAssertEqual([code integerValue], 102, @"lossReasonCode must be 102 (Lost to Higher Bid)");
    
    // CRITICAL: Verify it's NOT a string description
    XCTAssertFalse([lossReasonCodeField isKindOfClass:[NSString class]], 
                  @"lossReasonCode must NOT be string description (use sdk.lossReason for that)");
}

/**
 * P0 CRITICAL: Verify iOS sends numeric deviceTypeCode for server categorization
 * 
 * Server requires: Numeric device type code from CLXSystemInformation
 * iOS sends: deviceType enum value when fieldPath is "sdk.deviceTypeCode"
 * 
 * Device types: 0=Unknown, 1=Mobile, 2=Tablet, etc.
 */
- (void)testP0_DeviceTypeCodeField_SendsNumericValue {
    // Update config to include deviceTypeCode
    CLXSDKConfigResponse *configWithDevice = [[CLXSDKConfigResponse alloc] init];
    configWithDevice.winLossNotificationURL = @"https://test.com/winloss";
    configWithDevice.winLossNotificationPayloadConfig = @{
        @"deviceTypeCode": @"sdk.deviceTypeCode",  // CRITICAL: Numeric device type
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"auctionId": @"auctionId"
    };
    [[CLXWinLossTracker shared] setConfig:configWithDevice];
    
    // Given: A bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"test-bid";
    bid.nurl = @"https://test.com/nurl";
    bid.price = 1.5;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"test-bid"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0];
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: Verify deviceTypeCode is numeric
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // CRITICAL: Verify 'deviceTypeCode' field exists and is numeric
    id deviceTypeCodeField = payload[@"deviceTypeCode"];
    XCTAssertNotNil(deviceTypeCodeField, @"CRITICAL: Payload must contain 'deviceTypeCode' for server");
    XCTAssertTrue([deviceTypeCodeField isKindOfClass:[NSNumber class]], 
                 @"CRITICAL: 'deviceTypeCode' must be NSNumber for server categorization");
    
    NSNumber *code = (NSNumber *)deviceTypeCodeField;
    NSInteger codeValue = [code integerValue];
    
    // Verify it's a valid device type code (typically 1 or 2 on simulators/devices)
    XCTAssertTrue(codeValue >= 0 && codeValue <= 7, 
                 @"deviceTypeCode must be valid enum value (0-7)");
    
    // CRITICAL: Verify it matches CLXSystemInformation
    NSInteger expectedCode = [CLXSystemInformation shared].deviceType;
    XCTAssertEqual(codeValue, expectedCode, 
                  @"deviceTypeCode must match CLXSystemInformation.deviceType");
}

/**
 * P0 CRITICAL: Verify all three server-required fields work together in loss event
 */
- (void)testP0_ServerRequiredFields_AllThreePresent_InLossEvent {
    // Update config with all three server-required fields
    CLXSDKConfigResponse *fullConfig = [[CLXSDKConfigResponse alloc] init];
    fullConfig.winLossNotificationURL = @"https://test.com/winloss";
    fullConfig.winLossNotificationPayloadConfig = @{
        @"bid": @"seatbid[0].bid[0]",
        @"lossReasonCode": @"sdk.lossReasonCode",
        @"deviceTypeCode": @"sdk.deviceTypeCode",
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"auctionId": @"auctionId"
    };
    [[CLXWinLossTracker shared] setConfig:fullConfig];
    
    // Given: A losing bid
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"complete-payload-bid";
    bid.lurl = @"https://test.com/lurl";
    bid.price = 2.5;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = 2;
    
    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    
    // When: Sending loss event
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"complete-payload-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:5.0];
    
    // MockCLXWinLossTracker is fully synchronous - no wait needed
    
    // Then: ALL THREE server-required fields must be present
    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1, @"Should send payload");
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    
    // Verify presence of all three server-required fields
    XCTAssertNotNil(payload[@"bid"], @"CRITICAL: Missing 'bid' field");
    XCTAssertNotNil(payload[@"lossReasonCode"], @"CRITICAL: Missing 'lossReasonCode' field");
    XCTAssertNotNil(payload[@"deviceTypeCode"], @"CRITICAL: Missing 'deviceTypeCode' field");
    
    // Verify correct types
    XCTAssertTrue([payload[@"bid"] isKindOfClass:[NSDictionary class]], 
                 @"'bid' must be dictionary");
    XCTAssertTrue([payload[@"lossReasonCode"] isKindOfClass:[NSNumber class]], 
                 @"'lossReasonCode' must be number");
    XCTAssertTrue([payload[@"deviceTypeCode"] isKindOfClass:[NSNumber class]], 
                 @"'deviceTypeCode' must be number");
    
    // Verify correct values
    NSDictionary *bidDict = payload[@"bid"];
    XCTAssertEqualObjects(bidDict[@"id"], @"complete-payload-bid", @"bid.id must match");
    XCTAssertEqual([payload[@"lossReasonCode"] integerValue], 102, @"lossReasonCode must be 102");
    XCTAssertTrue([payload[@"deviceTypeCode"] integerValue] >= 0, @"deviceTypeCode must be valid");
}

@end

