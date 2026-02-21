/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossFieldResolverTests.m
 * @brief Comprehensive tests for win/loss field resolver focusing on edge cases and failures
 * 
 * Critical test coverage for field resolution that could lead to malformed win/loss
 * notifications, incorrect revenue tracking, or system crashes. Tests robustness
 * of field resolution and URL template processing under adverse conditions.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXWinLossFieldResolverTests : XCTestCase
@property (nonatomic, strong) CLXWinLossFieldResolver *fieldResolver;
@end

@implementation CLXWinLossFieldResolverTests

- (void)setUp {
    [super setUp];
    // Initialize with nil mapping - tests will set specific mappings as needed
    self.fieldResolver = [[CLXWinLossFieldResolver alloc] init];
}

- (void)tearDown {
    self.fieldResolver = nil;
    [super tearDown];
}

#pragma mark - Configuration Tests

/**
 * Test behavior when no payload mapping is configured
 */
- (void)testBuildPayload_NoMappingConfigured_ShouldReturnNil {
    // Don't set any configuration
    CLXBidResponseBid *testBid = [self createTestBid];
    
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:testBid
                                                                     lossReason:@(1)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];
    
    XCTAssertNil(result, @"Should return nil when no payload mapping is configured");
}

/**
 * Test behavior with empty payload mapping
 */
- (void)testBuildPayload_EmptyMapping_ShouldReturnEmptyDictionary {
    // Set empty configuration
    [self setMockPayloadMapping:@{}];
    
    CLXBidResponseBid *testBid = [self createTestBid];
    
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:testBid
                                                                     lossReason:@(1)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];
    
    XCTAssertNotNil(result, @"Should return dictionary even with empty mapping");
    XCTAssertEqual(result.count, 0, @"Should return empty dictionary for empty mapping");
}

#pragma mark - Field Resolution: Hardcoded Cases

/**
 * Test sdk.sdk always returns "sdk"
 */
- (void)testResolveField_SdkSdk_AlwaysReturnsSdk {
    [self setMockPayloadMapping:@{@"sdk_field": @"sdk.sdk"}];
    CLXBidResponseBid *testBid = [self createTestBid];

    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:testBid
                                                                     lossReason:@(0)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];

    XCTAssertEqualObjects(result[@"sdk_field"], @"sdk", @"sdk.sdk should always return 'sdk'");
}

/**
 * Test sdk.lossReasonCode returns numeric loss reason
 */
- (void)testResolveField_LossReasonCode_ReturnsNumericValue {
    [self setMockPayloadMapping:@{@"loss_reason_code_field": @"sdk.lossReasonCode"}];
    CLXBidResponseBid *testBid = [self createTestBid];

    NSDictionary *winResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                               bid:testBid
                                                                        lossReason:@(0)
                                                                             event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                    loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertEqualObjects(winResult[@"loss_reason_code_field"], @(0), @"Should return 0 for BidWon");

    NSDictionary *lossResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                bid:testBid
                                                                         lossReason:@(102)
                                                                              event:[CLXBidLifecycleEvent lossEvent]
                                                                     loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertEqualObjects(lossResult[@"loss_reason_code_field"], @(102), @"Should return 102 for LostToHigherBid");
}

#pragma mark - Field Resolution: payloadKey-based Cases

/**
 * Test notificationType payloadKey returns event.notificationType
 */
- (void)testResolveField_NotificationType_ReturnsEventNotificationType {
    [self setMockPayloadMapping:@{@"notificationType": @"notification"}];
    CLXBidResponseBid *testBid = [self createTestBid];

    NSDictionary *loadResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                bid:testBid
                                                                         lossReason:@(0)
                                                                              event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                     loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertEqualObjects(loadResult[@"notificationType"], @"loadSuccess", @"Should return event notificationType for loadSuccess");

    NSDictionary *lossResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                bid:testBid
                                                                         lossReason:@(102)
                                                                              event:[CLXBidLifecycleEvent lossEvent]
                                                                     loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertEqualObjects(lossResult[@"notificationType"], @"loss", @"Should return event notificationType for loss");

    NSDictionary *rewardResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                  bid:testBid
                                                                           lossReason:nil
                                                                                event:[CLXBidLifecycleEvent rewardEvent]
                                                                       loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertEqualObjects(rewardResult[@"notificationType"], @"rewardEarned", @"Should return event notificationType for reward");
}

/**
 * Test bid payloadKey returns bid dictionary
 */
- (void)testResolveField_BidPayloadKey_ReturnsBidDictionary {
    [self setMockPayloadMapping:@{@"bid": @"seatbid[0].bid[0]"}];
    CLXBidResponseBid *testBid = [self createTestBid];

    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:testBid
                                                                     lossReason:@(0)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertNotNil(result[@"bid"], @"Should return bid dictionary for payloadKey 'bid'");
    XCTAssertTrue([result[@"bid"] isKindOfClass:[NSDictionary class]], @"bid should be a dictionary");
}

/**
 * Test bid payloadKey with nil bid returns no bid field
 */
- (void)testResolveField_BidPayloadKey_NilBid_ReturnsNil {
    [self setMockPayloadMapping:@{@"bid": @"seatbid[0].bid[0]"}];

    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:nil
                                                                     lossReason:@(1)
                                                                          event:[CLXBidLifecycleEvent lossEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];
    XCTAssertNil(result[@"bid"], @"Should return nil for bid when bid object is nil");
}

#pragma mark - Delegation to TrackingFieldResolver

/**
 * Test that unrecognized field paths delegate to CLXTrackingFieldResolver
 * (without auction data set up, TrackingFieldResolver returns nil)
 */
- (void)testResolveField_UnrecognizedFieldPath_DelegatesToTrackingFieldResolver {
    [self setMockPayloadMapping:@{@"some_field": @"bid.price"}];
    CLXBidResponseBid *testBid = [self createTestBid];

    // Without setting up auction data in TrackingFieldResolver, bid.* fields return nil
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:testBid
                                                                     lossReason:@(0)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:2.50
                                                                          error:nil];

    // Field delegates to TrackingFieldResolver — without auction data, resolves to nil
    XCTAssertNotNil(result, @"Should return dictionary even when delegated fields resolve to nil");
}

/**
 * Test loss reason edge cases
 */
- (void)testResolveField_LossReason_EdgeCases {
    [self setMockPayloadMapping:@{@"loss_reason_code": @"sdk.lossReasonCode"}];
    
    CLXBidResponseBid *testBid = [self createTestBid];
    
    // Test with nil loss reason
    NSDictionary *nilReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                      bid:testBid
                                                                              lossReason:nil
                                                                                   event:[CLXBidLifecycleEvent lossEvent]
                                                                          loadedBidPrice:2.50
                                                                          error:nil];
    
    XCTAssertEqual(nilReasonResult.count, 0, @"Should not include field when loss reason is nil");
    
    // Test with zero loss reason (Bid Won)
    NSDictionary *zeroReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                      bid:testBid
                                                                               lossReason:@(0)
                                                                                    event:[CLXBidLifecycleEvent lossEvent]
                                                                           loadedBidPrice:2.50
                                                                          error:nil];
    
    XCTAssertEqualObjects(zeroReasonResult[@"loss_reason_code"], @(0), @"Should return numeric code 0 for Bid Won");
    
    // Test with invalid negative loss reason (still passes through as numeric)
    NSDictionary *negativeReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                           bid:testBid
                                                                                    lossReason:@(-1)
                                                                                         event:[CLXBidLifecycleEvent lossEvent]
                                                                                loadedBidPrice:2.50
                                                                          error:nil];
    
    XCTAssertEqualObjects(negativeReasonResult[@"loss_reason_code"], @(-1), @"Loss reason code should pass through numeric values as-is");
}

#pragma mark - Input Validation Tests

/**
 * Test behavior with nil and invalid inputs
 */
- (void)testBuildPayload_InvalidInputs_ShouldHandleGracefully {
    [self setMockPayloadMapping:@{@"sdk_field": @"sdk.sdk"}];

    // Test with nil auction ID
    NSDictionary *nilAuctionResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:nil
                                                                                      bid:[self createTestBid]
                                                                               lossReason:@(1)
                                                                                    event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                           loadedBidPrice:2.50
                                                                          error:nil];

    XCTAssertNotNil(nilAuctionResult, @"Should not crash with nil auction ID");

    // Test with empty auction ID
    NSDictionary *emptyAuctionResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@""
                                                                                        bid:[self createTestBid]
                                                                                 lossReason:@(1)
                                                                                      event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                             loadedBidPrice:2.50
                                                                          error:nil];

    XCTAssertNotNil(emptyAuctionResult, @"Should not crash with empty auction ID");

    // Test with nil bid
    NSDictionary *nilBidResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                   bid:nil
                                                                            lossReason:@(1)
                                                                                 event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                        loadedBidPrice:2.50
                                                                          error:nil];

    XCTAssertNotNil(nilBidResult, @"Should not crash with nil bid");
    XCTAssertEqualObjects(nilBidResult[@"sdk_field"], @"sdk", @"Should still resolve non-bid fields with nil bid");
}

- (void)testSetConfig_ServerPayloadMapping_ShouldConfigureCorrectly {
    CLXSDKConfigResponse *mockConfig = [[CLXSDKConfigResponse alloc] init];
    mockConfig.winLossNotificationPayloadConfig = @{
        @"notificationType": @"notification",
        @"source": @"sdk.sdk",
        @"lossReasonCode": @"sdk.lossReasonCode"
    };

    [self.fieldResolver setConfig:mockConfig];

    CLXBidResponseBid *testBid = [[CLXBidResponseBid alloc] init];
    testBid.price = 1.50;

    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction-123"
                                                                            bid:testBid
                                                                     lossReason:@(0)
                                                                          event:[CLXBidLifecycleEvent loadSuccessEvent]
                                                                 loadedBidPrice:1.50
                                                                          error:nil];

    XCTAssertNotNil(result, @"Should build payload with server config");
    XCTAssertEqualObjects(result[@"notificationType"], @"loadSuccess", @"Should return event notificationType via payloadKey check");
    XCTAssertEqualObjects(result[@"source"], @"sdk", @"Should resolve sdk.sdk to 'sdk'");
    XCTAssertEqualObjects(result[@"lossReasonCode"], @(0), @"Should return numeric loss reason code");
}

#pragma mark - Helper Methods

- (CLXBidResponseBid *)createTestBid {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"test-bid-1";
    bid.price = 2.50;
    bid.nurl = @"https://win.com/track?price=${AUCTION_PRICE}";
    bid.lurl = @"https://loss.com/track?reason=${AUCTION_LOSS}&price=${AUCTION_PRICE}";
    bid.rawJSON = @{
        @"id": @"test-bid-1",
        @"price": @(2.50),
        @"nurl": @"https://win.com/track?price=${AUCTION_PRICE}",
        @"lurl": @"https://loss.com/track?reason=${AUCTION_LOSS}&price=${AUCTION_PRICE}"
    };
    return bid;
}

- (void)setMockPayloadMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    self.fieldResolver = [[CLXWinLossFieldResolver alloc] initWithPayloadMapping:mapping];
}

@end
