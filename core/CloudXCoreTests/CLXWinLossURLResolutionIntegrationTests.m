/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

/**
 * @brief INTEGRATION Tests for URL Resolution - Tests REAL business logic
 * 
 * Principal Engineer Approach:
 * - Tests the actual CLXWinLossFieldResolver with real inputs
 * - No mocking of core business logic
 * - Focused on verifying URL template replacement works correctly
 * - Separate from network/persistence concerns
 */
@interface CLXWinLossURLResolutionIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXWinLossFieldResolver *fieldResolver;
@end

@implementation CLXWinLossURLResolutionIntegrationTests

- (void)setUp {
    [super setUp];
    
    // Create REAL field resolver with test payload mapping
    NSDictionary *testPayloadMapping = @{
        @"resolvedURL": @"sdk.[bid.nurl|bid.lurl]",
        @"type": @"sdk.[win|loss]",
        @"auctionId": @"auctionId",
        @"bidId": @"bidId"
    };
    
    self.fieldResolver = [[CLXWinLossFieldResolver alloc] initWithPayloadMapping:testPayloadMapping];
}

#pragma mark - Win URL Resolution Tests

/**
 * CRITICAL: Test that REAL CLXWinLossFieldResolver correctly resolves WIN URLs
 * This tests the actual business logic, not a simulation
 */
- (void)testWinURLResolution_WithAuctionPriceTemplate_ShouldReplaceCorrectly {
    // Given: A bid with NURL containing price template
    CLXBidResponseBid *winBid = [[CLXBidResponseBid alloc] init];
    winBid.id = @"win-bid-123";
    winBid.nurl = @"https://network.com/win?price=${AUCTION_PRICE}&campaign=test";
    winBid.price = 3.75;
    
    // When: Build win payload using REAL field resolver
    NSDictionary *payload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                             bid:winBid
                                                                      lossReason:nil
                                                                           isWin:YES
                                                                  loadedBidPrice:3.75];
    
    // Then: Verify REAL URL resolution
    XCTAssertNotNil(payload, @"Payload should be generated");
    
    NSString *resolvedURL = payload[@"resolvedURL"];
    XCTAssertNotNil(resolvedURL, @"Resolved URL should be present");
    XCTAssertTrue([resolvedURL containsString:@"price=3.75"], @"AUCTION_PRICE should be replaced with actual price");
    XCTAssertTrue([resolvedURL containsString:@"campaign=test"], @"Non-template parameters should be preserved");
    XCTAssertFalse([resolvedURL containsString:@"${AUCTION_PRICE}"], @"Template should be fully resolved");
    
    // Verify other payload fields
    XCTAssertEqualObjects(payload[@"type"], @"win", @"Type should be win");
    XCTAssertEqualObjects(payload[@"auctionId"], @"test-auction", @"Auction ID should be preserved");
    XCTAssertEqualObjects(payload[@"bidId"], @"win-bid-123", @"Bid ID should be preserved");
}

/**
 * Test WIN URL with multiple price templates
 */
- (void)testWinURLResolution_WithMultiplePriceTemplates_ShouldReplaceAll {
    // Given: A bid with multiple AUCTION_PRICE templates
    CLXBidResponseBid *winBid = [[CLXBidResponseBid alloc] init];
    winBid.id = @"multi-price-bid";
    winBid.nurl = @"https://network.com/win?price=${AUCTION_PRICE}&backup_price=${AUCTION_PRICE}&id=123";
    winBid.price = 2.50;
    
    // When: Build win payload
    NSDictionary *payload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                             bid:winBid
                                                                      lossReason:nil
                                                                           isWin:YES
                                                                  loadedBidPrice:2.50];
    
    // Then: All price templates should be replaced
    NSString *resolvedURL = payload[@"resolvedURL"];
    XCTAssertTrue([resolvedURL containsString:@"price=2.50"], @"First AUCTION_PRICE should be replaced");
    XCTAssertTrue([resolvedURL containsString:@"backup_price=2.50"], @"Second AUCTION_PRICE should be replaced");
    XCTAssertFalse([resolvedURL containsString:@"${AUCTION_PRICE}"], @"No templates should remain");
    XCTAssertTrue([resolvedURL containsString:@"id=123"], @"Non-template parameters should be preserved");
}

#pragma mark - Loss URL Resolution Tests

/**
 * Test REAL CLXWinLossFieldResolver correctly resolves LOSS URLs
 */
- (void)testLossURLResolution_WithAuctionLossTemplate_ShouldReplaceCorrectly {
    // Given: A bid with LURL containing loss template
    CLXBidResponseBid *lossBid = [[CLXBidResponseBid alloc] init];
    lossBid.id = @"loss-bid-456";
    lossBid.lurl = @"https://network.com/loss?reason=${AUCTION_LOSS}&price=${AUCTION_PRICE}";
    lossBid.price = 1.25;
    
    // When: Build loss payload using REAL field resolver
    NSDictionary *payload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test-auction"
                                                                             bid:lossBid
                                                                      lossReason:@(4)  // Lost to higher bid
                                                                           isWin:NO
                                                                  loadedBidPrice:1.25];
    
    // Then: Verify REAL URL resolution
    XCTAssertNotNil(payload, @"Payload should be generated");
    
    NSString *resolvedURL = payload[@"resolvedURL"];
    XCTAssertNotNil(resolvedURL, @"Resolved URL should be present");
    XCTAssertTrue([resolvedURL containsString:@"reason=4"], @"AUCTION_LOSS should be replaced with loss reason");
    XCTAssertTrue([resolvedURL containsString:@"price=1.25"], @"AUCTION_PRICE should be replaced with bid price");
    XCTAssertFalse([resolvedURL containsString:@"${AUCTION_LOSS}"], @"Loss template should be fully resolved");
    XCTAssertFalse([resolvedURL containsString:@"${AUCTION_PRICE}"], @"Price template should be fully resolved");
    
    // Verify other payload fields
    XCTAssertEqualObjects(payload[@"type"], @"loss", @"Type should be loss");
}

#pragma mark - Cross-Platform Consistency Tests

/**
 * ENHANCED: Test iOS price formatting consistency (%.2f vs Android's raw float)
 */
- (void)testURLResolution_PriceFormattingConsistency_ShouldUseFixedDecimalPlaces {
    // Given: Bids with prices that test formatting edge cases
    CLXBidResponseBid *wholeDollarBid = [[CLXBidResponseBid alloc] init];
    wholeDollarBid.id = @"whole-dollar";
    wholeDollarBid.nurl = @"https://test.com/win?price=${AUCTION_PRICE}";
    wholeDollarBid.price = 5.00; // Should format as "5.00" not "5.0" or "5"
    
    CLXBidResponseBid *precisionBid = [[CLXBidResponseBid alloc] init];
    precisionBid.id = @"precision-bid";
    precisionBid.nurl = @"https://test.com/win?price=${AUCTION_PRICE}";
    precisionBid.price = 1.234; // Should format as "1.23" (rounded)
    
    // When: Build payloads
    NSDictionary *wholePayload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test"
                                                                                  bid:wholeDollarBid
                                                                           lossReason:nil
                                                                                isWin:YES
                                                                       loadedBidPrice:5.00];
    
    NSDictionary *precisionPayload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test"
                                                                                      bid:precisionBid
                                                                               lossReason:nil
                                                                                    isWin:YES
                                                                           loadedBidPrice:1.234];
    
    // Then: Verify iOS formatting consistency (%.2f format)
    NSString *wholeURL = wholePayload[@"resolvedURL"];
    XCTAssertTrue([wholeURL containsString:@"price=5.00"], @"Whole dollar amounts should format with .00");
    
    // Use regex to ensure exact format matching
    NSError *regexError = nil;
    NSRegularExpression *singleDecimalRegex = [NSRegularExpression regularExpressionWithPattern:@"price=5\\.0[^0-9]|price=5\\.0$" 
                                                                                        options:0 
                                                                                          error:&regexError];
    NSRegularExpression *integerRegex = [NSRegularExpression regularExpressionWithPattern:@"price=5[^\\.]" 
                                                                                   options:0 
                                                                                     error:&regexError];
    
    XCTAssertEqual([singleDecimalRegex numberOfMatchesInString:wholeURL options:0 range:NSMakeRange(0, wholeURL.length)], 0,
                   @"Should not use single decimal format (5.0)");
    XCTAssertEqual([integerRegex numberOfMatchesInString:wholeURL options:0 range:NSMakeRange(0, wholeURL.length)], 0,
                   @"Should not use integer format (5)");
    
    NSString *precisionURL = precisionPayload[@"resolvedURL"];
    XCTAssertTrue([precisionURL containsString:@"price=1.23"], @"Should round to 2 decimal places");
    XCTAssertFalse([precisionURL containsString:@"price=1.234"], @"Should not preserve extra precision");
    
    NSLog(@"📊 iOS URL Formatting Test - Whole: %@, Precision: %@", wholeURL, precisionURL);
}

/**
 * Test that win URLs don't replace loss templates (and vice versa)
 */
- (void)testURLResolution_TemplateIsolation_ShouldOnlyReplaceRelevantTemplates {
    // Given: URLs with both win and loss templates
    CLXBidResponseBid *winBid = [[CLXBidResponseBid alloc] init];
    winBid.id = @"mixed-template-win";
    winBid.nurl = @"https://test.com/win?price=${AUCTION_PRICE}&loss=${AUCTION_LOSS}";
    winBid.price = 3.50;
    
    CLXBidResponseBid *lossBid = [[CLXBidResponseBid alloc] init];
    lossBid.id = @"mixed-template-loss";
    lossBid.lurl = @"https://test.com/loss?price=${AUCTION_PRICE}&loss=${AUCTION_LOSS}";
    lossBid.price = 2.75;
    
    // When: Build win and loss payloads
    NSDictionary *winPayload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test"
                                                                                bid:winBid
                                                                         lossReason:nil
                                                                              isWin:YES
                                                                     loadedBidPrice:3.50];
    
    NSDictionary *lossPayload = [self.fieldResolver buildWinLossPayloadWithAuctionId:@"test"
                                                                                 bid:lossBid
                                                                          lossReason:@(1)
                                                                               isWin:NO
                                                                      loadedBidPrice:2.75];
    
    // Then: Win URLs should not replace loss templates
    NSString *winURL = winPayload[@"resolvedURL"];
    XCTAssertTrue([winURL containsString:@"price=3.50"], @"Win URL should replace AUCTION_PRICE");
    XCTAssertTrue([winURL containsString:@"loss=${AUCTION_LOSS}"], @"Win URL should NOT replace AUCTION_LOSS");
    
    // And: Loss URLs should replace both templates
    NSString *lossURL = lossPayload[@"resolvedURL"];
    XCTAssertTrue([lossURL containsString:@"price=2.75"], @"Loss URL should replace AUCTION_PRICE");
    XCTAssertTrue([lossURL containsString:@"loss=1"], @"Loss URL should replace AUCTION_LOSS");
}

@end
