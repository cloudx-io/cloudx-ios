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
                                                                          isWin:YES
                                                                 loadedBidPrice:2.50];
    
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
                                                                          isWin:YES
                                                                 loadedBidPrice:2.50];
    
    XCTAssertNotNil(result, @"Should return dictionary even with empty mapping");
    XCTAssertEqual(result.count, 0, @"Should return empty dictionary for empty mapping");
}

#pragma mark - Field Resolution Edge Cases

/**
 * Test resolution of SDK-specific fields with edge cases
 */
- (void)testResolveField_SDKFields_EdgeCases {
    [self setMockPayloadMapping:@{
        @"win_field": @"sdk.win",
        @"loss_field": @"sdk.loss",
        @"loss_reason_field": @"sdk.lossReason",
        @"win_loss_field": @"sdk.[win|loss]",
        @"sdk_field": @"sdk.sdk"
    }];
    
    CLXBidResponseBid *testBid = [self createTestBid];
    
    // Test WIN scenario
    NSDictionary *winResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                               bid:testBid
                                                                        lossReason:@(2)
                                                                             isWin:YES
                                                                    loadedBidPrice:2.50];
    
    XCTAssertEqualObjects(winResult[@"win_field"], @"win", @"sdk.win should return 'win' for win events");
    XCTAssertNil(winResult[@"loss_field"], @"sdk.loss should return nil for win events");
    XCTAssertEqualObjects(winResult[@"loss_reason_field"], @(2), @"sdk.lossReason should return loss reason even for wins");
    XCTAssertEqualObjects(winResult[@"win_loss_field"], @"win", @"sdk.[win|loss] should return 'win' for wins");
    XCTAssertEqualObjects(winResult[@"sdk_field"], @"sdk", @"sdk.sdk should always return 'sdk'");
    
    // Test LOSS scenario
    NSDictionary *lossResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                bid:testBid
                                                                         lossReason:@(3)
                                                                              isWin:NO
                                                                     loadedBidPrice:2.50];
    
    XCTAssertNil(lossResult[@"win_field"], @"sdk.win should return nil for loss events");
    XCTAssertEqualObjects(lossResult[@"loss_field"], @"loss", @"sdk.loss should return 'loss' for loss events");
    XCTAssertEqualObjects(lossResult[@"loss_reason_field"], @(3), @"sdk.lossReason should return loss reason for losses");
    XCTAssertEqualObjects(lossResult[@"win_loss_field"], @"loss", @"sdk.[win|loss] should return 'loss' for losses");
    XCTAssertEqualObjects(lossResult[@"sdk_field"], @"sdk", @"sdk.sdk should always return 'sdk'");
}

/**
 * Test URL field resolution with missing or malformed URLs
 */
- (void)testResolveField_URLFields_MissingURLs {
    [self setMockPayloadMapping:@{@"url_field": @"sdk.[bid.nurl|bid.lurl]"}];
    
    // Test with bid that has no URLs
    CLXBidResponseBid *bidWithoutURLs = [[CLXBidResponseBid alloc] init];
    bidWithoutURLs.nurl = nil;
    bidWithoutURLs.lurl = nil;
    
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:bidWithoutURLs
                                                                     lossReason:@(1)
                                                                          isWin:YES
                                                                 loadedBidPrice:2.50];
    
    XCTAssertNotNil(result, @"Should return dictionary when payload mapping is configured");
    XCTAssertEqual(result.count, 0, @"Should return empty dictionary when URL fields resolve to nil");
    
    // Test with empty URLs
    CLXBidResponseBid *bidWithEmptyURLs = [[CLXBidResponseBid alloc] init];
    bidWithEmptyURLs.nurl = @"";
    bidWithEmptyURLs.lurl = @"";
    
    NSDictionary *emptyResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                 bid:bidWithEmptyURLs
                                                                          lossReason:@(1)
                                                                               isWin:YES
                                                                      loadedBidPrice:2.50];
    
    XCTAssertNotNil(emptyResult, @"Should return dictionary when payload mapping is configured");
    XCTAssertEqual(emptyResult.count, 0, @"Should return empty dictionary when URL fields resolve to empty strings");
}

/**
 * Test loss reason edge cases
 */
- (void)testResolveField_LossReason_EdgeCases {
    [self setMockPayloadMapping:@{@"loss_reason": @"sdk.lossReason"}];
    
    CLXBidResponseBid *testBid = [self createTestBid];
    
    // Test with nil loss reason
    NSDictionary *nilReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                     bid:testBid
                                                                              lossReason:nil
                                                                                   isWin:NO
                                                                          loadedBidPrice:2.50];
    
    XCTAssertEqual(nilReasonResult.count, 0, @"Should not include field when loss reason is nil");
    
    // Test with zero loss reason
    NSDictionary *zeroReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                      bid:testBid
                                                                               lossReason:@(0)
                                                                                    isWin:NO
                                                                           loadedBidPrice:2.50];
    
    XCTAssertEqualObjects(zeroReasonResult[@"loss_reason"], @(0), @"Should include zero loss reason");
    
    // Test with negative loss reason
    NSDictionary *negativeReasonResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                           bid:testBid
                                                                                    lossReason:@(-1)
                                                                                         isWin:NO
                                                                                loadedBidPrice:2.50];
    
    XCTAssertEqualObjects(negativeReasonResult[@"loss_reason"], @(-1), @"Should include negative loss reason");
}

#pragma mark - URL Template Processing Tests

/**
 * Test URL template replacement with edge cases
 */
- (void)testURLTemplateReplacement_EdgeCases {
    [self setMockPayloadMapping:@{@"processed_url": @"sdk.[bid.nurl|bid.lurl]"}];
    
    // Test with multiple template placeholders
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.nurl = @"https://win.com/track?price=${AUCTION_PRICE}&loss=${AUCTION_LOSS}&price2=${AUCTION_PRICE}";
    bid.lurl = @"https://loss.com/track?price=${AUCTION_PRICE}&loss=${AUCTION_LOSS}&reason=${AUCTION_LOSS}";
    
    // Test WIN scenario with multiple price placeholders
    NSDictionary *winResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                               bid:bid
                                                                        lossReason:@(5)
                                                                             isWin:YES
                                                                    loadedBidPrice:3.75];
    
    NSString *processedWinURL = winResult[@"processed_url"];
    XCTAssertTrue([processedWinURL containsString:@"price=3.75"], @"Should replace AUCTION_PRICE in win URL");
    XCTAssertTrue([processedWinURL containsString:@"price2=3.75"], @"Should replace multiple AUCTION_PRICE occurrences");
    XCTAssertTrue([processedWinURL containsString:@"loss=${AUCTION_LOSS}"], @"Should not replace AUCTION_LOSS in win URL");
    
    // Test LOSS scenario with loss reason replacement
    NSDictionary *lossResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                bid:bid
                                                                         lossReason:@(7)
                                                                              isWin:NO
                                                                     loadedBidPrice:3.75];
    
    NSString *processedLossURL = lossResult[@"processed_url"];
    XCTAssertTrue([processedLossURL containsString:@"price=3.75"], @"Should replace AUCTION_PRICE in loss URL");
    XCTAssertTrue([processedLossURL containsString:@"loss=7"], @"Should replace AUCTION_LOSS in loss URL");
    XCTAssertTrue([processedLossURL containsString:@"reason=7"], @"Should replace multiple AUCTION_LOSS occurrences");
}

/**
 * Test URL template replacement with special characters
 */
- (void)testURLTemplateReplacement_SpecialCharacters {
    [self setMockPayloadMapping:@{@"processed_url": @"sdk.[bid.nurl|bid.lurl]"}];
    
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.lurl = @"https://test.com/track?price=${AUCTION_PRICE}&loss=${AUCTION_LOSS}&encoded=%24%7BAUCTION_PRICE%7D";
    
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                            bid:bid
                                                                     lossReason:@(2)
                                                                          isWin:NO
                                                                 loadedBidPrice:1.50];
    
    NSString *processedURL = result[@"processed_url"];
    XCTAssertTrue([processedURL containsString:@"price=1.50"], @"Should replace unencoded template");
    XCTAssertTrue([processedURL containsString:@"loss=2"], @"Should replace loss reason");
    XCTAssertTrue([processedURL containsString:@"encoded=%24%7BAUCTION_PRICE%7D"], @"Should not replace URL-encoded templates");
}

#pragma mark - Input Validation Tests

/**
 * Test behavior with nil and invalid inputs
 */
- (void)testBuildPayload_InvalidInputs_ShouldHandleGracefully {
    [self setMockPayloadMapping:@{@"test_field": @"sdk.win"}];
    
    // Test with nil auction ID
    NSDictionary *nilAuctionResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:nil
                                                                                      bid:[self createTestBid]
                                                                               lossReason:@(1)
                                                                                    isWin:YES
                                                                           loadedBidPrice:2.50];
    
    XCTAssertNotNil(nilAuctionResult, @"Should not crash with nil auction ID");
    
    // Test with empty auction ID
    NSDictionary *emptyAuctionResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@""
                                                                                        bid:[self createTestBid]
                                                                                 lossReason:@(1)
                                                                                      isWin:YES
                                                                             loadedBidPrice:2.50];
    
    XCTAssertNotNil(emptyAuctionResult, @"Should not crash with empty auction ID");
    
    // Test with nil bid
    NSDictionary *nilBidResult = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                                   bid:nil
                                                                            lossReason:@(1)
                                                                                 isWin:YES
                                                                        loadedBidPrice:2.50];
    
    XCTAssertNotNil(nilBidResult, @"Should not crash with nil bid");
    XCTAssertEqualObjects(nilBidResult[@"test_field"], @"win", @"Should still resolve non-bid fields with nil bid");
}

#pragma mark - Helper Methods

- (CLXBidResponseBid *)createTestBid {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.nurl = @"https://win.com/track?price=${AUCTION_PRICE}";
    bid.lurl = @"https://loss.com/track?reason=${AUCTION_LOSS}&price=${AUCTION_PRICE}";
    return bid;
}

- (void)testSetConfig_ServerPayloadMapping_ShouldConfigureCorrectly {
    // Create a mock config response with payload mapping (like from server)
    // Using field paths that we know work from other tests
    CLXSDKConfigResponse *mockConfig = [[CLXSDKConfigResponse alloc] init];
    mockConfig.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[win|loss]",
        @"source": @"sdk.sdk",
        @"lossReason": @"sdk.lossReason", 
        @"url": @"sdk.[bid.nurl|bid.lurl]"
    };
    
    // Set the config (this should update the payload mapping)
    [self.fieldResolver setConfig:mockConfig];
    
    // Create test bid
    CLXBidResponseBid *testBid = [[CLXBidResponseBid alloc] init];
    testBid.price = 1.50;
    testBid.nurl = @"https://example.com/win?price=${AUCTION_PRICE}";
    testBid.ext = @{@"prebid": @{@"meta": @{@"adaptercode": @"meta"}}};
    
    // Build payload
    NSDictionary *result = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction-123"
                                                                            bid:testBid
                                                                     lossReason:nil
                                                                          isWin:YES
                                                                 loadedBidPrice:1.50];
    
    // Verify server config was applied
    XCTAssertNotNil(result, @"Should build payload with server config");
    XCTAssertEqual(result.count, 3, @"Should have 3 fields from server config (lossReason is nil for win events)");
    
    // Verify specific field mappings work
    XCTAssertEqualObjects(result[@"notificationType"], @"win", @"Should resolve sdk.[win|loss] to 'win' for win events");
    XCTAssertEqualObjects(result[@"source"], @"sdk", @"Should resolve sdk.sdk to 'sdk'");
    XCTAssertNil(result[@"lossReason"], @"Should resolve sdk.lossReason to nil for win events (no loss reason)");
    XCTAssertEqualObjects(result[@"url"], @"https://example.com/win?price=1.50", @"Should process URL template correctly");
}

#pragma mark - Helper Methods

- (void)setMockPayloadMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    // Clean dependency injection - no KVO hacks needed!
    self.fieldResolver = [[CLXWinLossFieldResolver alloc] initWithPayloadMapping:mapping];
}

@end
