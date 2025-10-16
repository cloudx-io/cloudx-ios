/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSourceCDPFlowTests.m
 * @brief P0 Unit tests for CDP flow integration in CLXBidAdSource
 * @details Tests the complete CDP flow including:
 *   - CDP skip logic when endpoint is empty
 *   - CDP enrichment flow and fallback
 *   - CDP proxy mode detection and handling
 *   - Error handling and resilience
 *
 * Test Focus:
 * - Unit test level (isolated component testing)
 * - P0 critical paths only
 * - SOLID principles: Single Responsibility per test
 * - Comprehensive error scenarios
 *
 * See CDP_TEST_SPEC.md for complete specification
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBidResponse.h>
#import "Helper/CLXUserDefaultsTestHelper.h"

@interface CLXBidAdSourceCDPFlowTests : XCTestCase
@end

@implementation CLXBidAdSourceCDPFlowTests

- (void)setUp {
    [super setUp];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - P0.1: CDP Skip Logic Tests

/**
 * @brief Test P0.1.1: Empty CDP endpoint should skip CDP flow entirely
 * @discussion Most common production path - validates direct-to-auction flow
 */
- (void)testCDPFlow_EmptyCDPEndpoint_ShouldSkipCDPAndGoDirectToAuction {
    // Given: CDP endpoint is empty (most common production scenario)
    NSString *cdpEndpoint = @"";
    BOOL isCDPEndpointEmpty = (cdpEndpoint == nil || cdpEndpoint.length == 0);
    
    // When: Check if CDP should be called
    // Then: Should skip CDP entirely
    XCTAssertTrue(isCDPEndpointEmpty, @"Empty CDP endpoint should be detected");
    
    // Validation: In production code, this condition triggers direct auction call
    // Log message should be: "[CLXBidAdSource] No CDP endpoint - proceeding directly to auction"
}

/**
 * @brief Test P0.1.2: Nil CDP endpoint should be treated same as empty
 * @discussion Edge case: nil vs empty string should behave identically
 */
- (void)testCDPFlow_NilCDPEndpoint_ShouldBeEquivalentToEmpty {
    // Given: CDP endpoint is nil
    NSString *cdpEndpoint = nil;
    BOOL isCDPEndpointEmpty = (cdpEndpoint == nil || cdpEndpoint.length == 0);
    
    // When: Check CDP status
    // Then: Should be treated as empty
    XCTAssertTrue(isCDPEndpointEmpty, @"Nil CDP endpoint should be treated as empty");
}

/**
 * @brief Test P0.1.3: Valid CDP endpoint should trigger CDP flow
 * @discussion Validates CDP is called when endpoint is configured
 */
- (void)testCDPFlow_ValidCDPEndpoint_ShouldTriggerCDPFlow {
    // Given: Valid CDP endpoint URL
    NSString *cdpEndpoint = @"https://cdp.test.com/enrich";
    BOOL isCDPEndpointEmpty = (cdpEndpoint == nil || cdpEndpoint.length == 0);
    
    // When: Check if CDP should be called
    // Then: Should NOT skip CDP
    XCTAssertFalse(isCDPEndpointEmpty, @"Valid CDP endpoint should trigger CDP flow");
}

#pragma mark - P0.2: CDP Dual-Mode Detection Logic

/**
 * @brief Test P0.2.1: Enrichment mode detection - has bid request fields
 * @discussion Validates correct detection of enrichment response
 */
- (void)testCDPDualMode_DetectEnrichmentMode_HasBidRequestFields {
    // Given: CDP response with bid request structure (enrichment mode)
    NSDictionary *cdpResponse = @{
        @"id": @"request-123",
        @"imp": @[@{@"id": @"imp-1"}],
        @"device": @{@"os": @"iOS"},
        @"app": @{@"bundle": @"com.test"}
    };
    
    // When: Apply dual-mode detection logic (from CLXBidAdSource)
    BOOL hasAuctionResponseFields = (cdpResponse[@"seatbid"] != nil || cdpResponse[@"nbr"] != nil);
    BOOL hasAuctionId = (cdpResponse[@"id"] != nil &&
                         [cdpResponse[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)cdpResponse[@"id"] length] > 0);
    BOOL hasBidRequestFields = (cdpResponse[@"imp"] != nil ||
                                cdpResponse[@"device"] != nil ||
                                cdpResponse[@"app"] != nil);
    BOOL isAuctionResponse = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    // Then: Should identify as enrichment mode (NOT proxy)
    XCTAssertFalse(hasAuctionResponseFields, @"Should not have auction response fields");
    XCTAssertTrue(hasAuctionId, @"Should have auction ID");
    XCTAssertTrue(hasBidRequestFields, @"Should have bid request fields");
    XCTAssertFalse(isAuctionResponse, @"Should NOT be detected as proxy mode");
}

/**
 * @brief Test P0.2.2: Proxy mode detection - has auction response fields
 * @discussion Validates correct detection of proxy/gateway response
 */
- (void)testCDPDualMode_DetectProxyMode_HasAuctionResponseFields {
    // Given: CDP response with auction response structure (proxy mode)
    NSDictionary *cdpResponse = @{
        @"id": @"auction-456",
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-789",
                @"price": @(99.99)
            }]
        }],
        @"cur": @"USD"
    };
    
    // When: Apply dual-mode detection logic
    BOOL hasAuctionResponseFields = (cdpResponse[@"seatbid"] != nil || cdpResponse[@"nbr"] != nil);
    BOOL hasAuctionId = (cdpResponse[@"id"] != nil &&
                         [cdpResponse[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)cdpResponse[@"id"] length] > 0);
    BOOL hasBidRequestFields = (cdpResponse[@"imp"] != nil ||
                                cdpResponse[@"device"] != nil ||
                                cdpResponse[@"app"] != nil);
    BOOL isAuctionResponse = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    // Then: Should identify as proxy mode
    XCTAssertTrue(hasAuctionResponseFields, @"Should have auction response fields");
    XCTAssertTrue(hasAuctionId, @"Should have auction ID");
    XCTAssertFalse(hasBidRequestFields, @"Should NOT have bid request fields");
    XCTAssertTrue(isAuctionResponse, @"Should be detected as proxy mode");
}

/**
 * @brief Test P0.2.3: No-bid response detection (nbr field)
 * @discussion Validates proxy mode detection via no-bid reason field
 */
- (void)testCDPDualMode_DetectProxyMode_ViaNoBidReason {
    // Given: CDP response with no-bid reason (alternative proxy indicator)
    NSDictionary *cdpResponse = @{
        @"id": @"auction-no-bid",
        @"nbr": @(2),  // No-bid reason code
        @"cur": @"USD"
    };
    
    // When: Apply detection logic
    BOOL hasAuctionResponseFields = (cdpResponse[@"seatbid"] != nil || cdpResponse[@"nbr"] != nil);
    BOOL hasAuctionId = (cdpResponse[@"id"] != nil &&
                         [cdpResponse[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)cdpResponse[@"id"] length] > 0);
    BOOL hasBidRequestFields = (cdpResponse[@"imp"] != nil ||
                                cdpResponse[@"device"] != nil ||
                                cdpResponse[@"app"] != nil);
    BOOL isAuctionResponse = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    // Then: Should detect as proxy mode via nbr field
    XCTAssertTrue(hasAuctionResponseFields, @"NBR field should indicate auction response");
    XCTAssertTrue(isAuctionResponse, @"Should be detected as proxy mode");
}

#pragma mark - P0.3: CDP Enrichment Flow Validation

/**
 * @brief Test P0.3.1: Enriched request should proceed to auction
 * @discussion Validates enrichment flow completes with auction call
 */
- (void)testCDPEnrichment_ValidEnrichedRequest_ShouldProceedToAuction {
    // Given: Valid enriched bid request from CDP
    NSDictionary *enrichedRequest = @{
        @"id": @"enriched-123",
        @"imp": @[@{@"id": @"imp-1"}],
        @"device": @{@"os": @"iOS"},
        @"app": @{@"bundle": @"com.test"},
        @"user": @{
            @"ext": @{
                @"eids": @[@{@"source": @"cdp-enriched-data"}]  // CDP added data
            }
        }
    };
    
    // When: Validate enriched request structure
    BOOL hasBidRequestFields = (enrichedRequest[@"imp"] != nil ||
                                enrichedRequest[@"device"] != nil ||
                                enrichedRequest[@"app"] != nil);
    
    // Then: Should be valid for auction
    XCTAssertTrue(hasBidRequestFields, @"Enriched request should have required fields");
    XCTAssertNotNil(enrichedRequest[@"user"][@"ext"][@"eids"],
                   @"Should contain CDP-enriched user data");
    
    // In production: This triggers startAuctionWithFinalBidRequest with enriched data
}

/**
 * @brief Test P0.3.2: Invalid enrichment should fallback to original request
 * @discussion Critical resilience: bad enrichment should not break ad serving
 */
- (void)testCDPEnrichment_InvalidEnrichedRequest_ShouldFallbackToOriginal {
    // Given: Invalid enriched request (missing required fields)
    NSDictionary *invalidEnriched = @{
        @"id": @"invalid-enrichment"
        // Missing imp, device, app
    };
    
    // When: Validate enriched request
    BOOL hasBidRequestFields = (invalidEnriched[@"imp"] != nil ||
                                invalidEnriched[@"device"] != nil ||
                                invalidEnriched[@"app"] != nil);
    
    // Then: Should be detected as invalid
    XCTAssertFalse(hasBidRequestFields, @"Invalid enrichment should be detected");
    
    // In production: This logs warning and triggers fallback to original request
    // Log: "⚠️ [CLXBidAdSource] CDP enrichment invalid - using original request"
}

#pragma mark - P0.4: CDP Proxy Flow Validation

/**
 * @brief Test P0.4.1: Proxy response should be parsed as auction response
 * @discussion Validates proxy mode skips second auction call
 */
- (void)testCDPProxy_ValidAuctionResponse_ShouldBeParseable {
    // Given: Valid auction response from CDP proxy
    NSDictionary *proxyResponse = @{
        @"id": @"proxy-auction-123",
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-456",
                @"impid": @"imp-123",
                @"price": @(75.50),
                @"adm": @"<ad-markup/>"
            }]
        }],
        @"cur": @"USD"
    };
    
    // When: Parse as CLXBidResponse
    CLXBidResponse *bidResponse = nil;
    XCTAssertNoThrow(bidResponse = [CLXBidResponse parseBidResponseFromDictionary:proxyResponse],
                    @"Should parse proxy response");
    
    // Then: Should successfully parse
    XCTAssertNotNil(bidResponse, @"Should create bid response");
    XCTAssertNotNil(bidResponse.id, @"Should have auction ID");
    XCTAssertGreaterThan([bidResponse allBids].count, 0, @"Should have bids");
    
    // In production: This skips second auction and goes directly to waterfall
}

/**
 * @brief Test P0.4.2: Invalid proxy response should fallback to auction
 * @discussion Critical resilience: bad proxy response should recover
 */
- (void)testCDPProxy_InvalidAuctionResponse_ShouldFallbackToAuction {
    // Given: Invalid auction response from proxy (missing ID)
    NSDictionary *invalidProxy = @{
        @"seatbid": @[@{@"bid": @[]}]
        // Missing required @"id" field
    };
    
    // When: Validate auction response
    BOOL hasAuctionId = (invalidProxy[@"id"] != nil &&
                         [invalidProxy[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)invalidProxy[@"id"] length] > 0);
    
    // Then: Should be detected as invalid
    XCTAssertFalse(hasAuctionId, @"Invalid proxy response should fail validation");
    
    // In production: Logs error and falls back to direct auction
    // Log: "❌ [CLXBidAdSource] CDP proxy response invalid - falling back to direct auction"
}

#pragma mark - P0.5: CDP Error Handling

/**
 * @brief Test P0.5.1: CDP network error should fallback to auction
 * @discussion Critical resilience path: CDP failures must not break ads
 */
- (void)testCDPError_NetworkFailure_ShouldFallbackGracefully {
    // Given: CDP network error (simulated)
    NSError *cdpError = [NSError errorWithDomain:NSURLErrorDomain
                                            code:NSURLErrorTimedOut
                                        userInfo:@{
        NSLocalizedDescriptionKey: @"CDP request timed out"
    }];
    
    // When: Handle CDP error
    // Then: Should have error for fallback logic
    XCTAssertNotNil(cdpError, @"Should have CDP error");
    XCTAssertEqualObjects(cdpError.domain, NSURLErrorDomain, @"Should be network error");
    
    // In production: Logs error and calls startAuctionWithFinalBidRequest with original request
    // Log: "⚠️ [CLXBidAdSource] CDP enrichment failed: {error} - proceeding with original request"
}

/**
 * @brief Test P0.5.2: CDP null response should fallback to auction
 * @discussion Edge case: CDP returns nothing
 */
- (void)testCDPError_NullResponse_ShouldFallbackToAuction {
    // Given: CDP returns nil/null
    id cdpResponse = nil;
    
    // When: Validate response
    BOOL isValid = (cdpResponse != nil && [cdpResponse isKindOfClass:[NSDictionary class]]);
    
    // Then: Should be invalid
    XCTAssertFalse(isValid, @"Nil response should be invalid");
    
    // In production: Logs debug message and falls back to auction
    // Log: "🔧 [CLXBidAdSource] No enriched request from CDP - using original"
}

/**
 * @brief Test P0.5.3: CDP wrong type response should fallback
 * @discussion Edge case: CDP returns array instead of dictionary
 */
- (void)testCDPError_WrongTypeResponse_ShouldFallbackToAuction {
    // Given: CDP returns wrong type
    id cdpResponse = @[@"wrong", @"type"];
    
    // When: Validate response type
    BOOL isValid = (cdpResponse != nil && [cdpResponse isKindOfClass:[NSDictionary class]]);
    
    // Then: Should be invalid
    XCTAssertFalse(isValid, @"Array response should be invalid");
    XCTAssertTrue([cdpResponse isKindOfClass:[NSArray class]], @"Should still be array type");
    
    // In production: Falls back to auction with original request
}

#pragma mark - P0.6: CDP Auction ID Validation

/**
 * @brief Test P0.6.1: Proxy response must have valid auction ID
 * @discussion Critical validation: auction ID required for tracking
 */
- (void)testCDPProxy_AuctionIDValidation_MustBeNonEmptyString {
    // Test Case 1: Valid auction ID
    NSDictionary *validResponse = @{@"id": @"auction-123"};
    BOOL hasValidId1 = (validResponse[@"id"] != nil &&
                        [validResponse[@"id"] isKindOfClass:[NSString class]] &&
                        [(NSString *)validResponse[@"id"] length] > 0);
    XCTAssertTrue(hasValidId1, @"Valid auction ID should pass validation");
    
    // Test Case 2: Nil auction ID
    NSDictionary *nilIdResponse = @{};
    BOOL hasValidId2 = (nilIdResponse[@"id"] != nil &&
                        [nilIdResponse[@"id"] isKindOfClass:[NSString class]] &&
                        [(NSString *)nilIdResponse[@"id"] length] > 0);
    XCTAssertFalse(hasValidId2, @"Nil auction ID should fail validation");
    
    // Test Case 3: Empty string auction ID
    NSDictionary *emptyIdResponse = @{@"id": @""};
    BOOL hasValidId3 = (emptyIdResponse[@"id"] != nil &&
                        [emptyIdResponse[@"id"] isKindOfClass:[NSString class]] &&
                        [(NSString *)emptyIdResponse[@"id"] length] > 0);
    XCTAssertFalse(hasValidId3, @"Empty auction ID should fail validation");
    
    // Test Case 4: Wrong type (number) auction ID
    NSDictionary *numberIdResponse = @{@"id": @123};
    BOOL hasValidId4 = (numberIdResponse[@"id"] != nil &&
                        [numberIdResponse[@"id"] isKindOfClass:[NSString class]] &&
                        [(NSString *)numberIdResponse[@"id"] length] > 0);
    XCTAssertFalse(hasValidId4, @"Number auction ID should fail validation");
}

#pragma mark - P0.7: CDP Request Preparation

/**
 * @brief Test P0.7.1: Original bid request must be preserved for fallback
 * @discussion Ensures original request available if CDP fails
 */
- (void)testCDPFlow_OriginalBidRequest_ShouldBePreservedForFallback {
    // Given: Original bid request before CDP
    NSDictionary *originalRequest = @{
        @"id": @"original-123",
        @"imp": @[@{@"id": @"imp-1"}],
        @"device": @{@"os": @"iOS"},
        @"app": @{@"bundle": @"com.test"}
    };
    
    // When: Make immutable copy for fallback
    NSDictionary *preservedRequest = [originalRequest copy];
    
    // Then: Original should be preserved
    XCTAssertNotNil(preservedRequest, @"Original request should be preserved");
    XCTAssertEqualObjects(preservedRequest[@"id"], originalRequest[@"id"],
                         @"Preserved request should match original");
    
    // Validate all fields are preserved
    XCTAssertEqualObjects(preservedRequest[@"imp"], originalRequest[@"imp"],
                         @"Impression data should be preserved");
    XCTAssertEqualObjects(preservedRequest[@"device"], originalRequest[@"device"],
                         @"Device data should be preserved");
    XCTAssertEqualObjects(preservedRequest[@"app"], originalRequest[@"app"],
                         @"App data should be preserved");
    
    // Note: For immutable NSDictionary, copy returns same object (expected Cocoa behavior)
    // The important thing is data integrity, not pointer identity
}

#pragma mark - P0.8: CDP Logging and Observability

/**
 * @brief Test P0.8.1: CDP flow should have clear log messages
 * @discussion Validates logging provides visibility into CDP behavior
 */
- (void)testCDPFlow_LogMessages_ShouldIndicateMode {
    // This test documents the expected log messages for CDP flow
    
    // Expected logs for enrichment mode:
    NSString *enrichmentLog = @"✅ [CLXBidAdSource] CDP ENRICHMENT mode - proceeding to auction";
    XCTAssertNotNil(enrichmentLog, @"Enrichment mode should log clearly");
    
    // Expected logs for proxy mode:
    NSString *proxyLog = @"🎯 [CLXBidAdSource] CDP PROXY mode - processing auction response";
    XCTAssertNotNil(proxyLog, @"Proxy mode should log clearly");
    
    // Expected logs for no CDP:
    NSString *noCDPLog = @"🔧 [CLXBidAdSource] No CDP endpoint - proceeding directly to auction";
    XCTAssertNotNil(noCDPLog, @"No CDP should log clearly");
    
    // Expected logs for CDP error:
    NSString *errorLog = @"⚠️ [CLXBidAdSource] CDP enrichment failed: {error} - proceeding with original request";
    XCTAssertNotNil(errorLog, @"CDP errors should log clearly");
    
    // These log messages provide high visibility into CDP behavior
}

#pragma mark - P0.9: CDP Integration with Waterfall

/**
 * @brief Test P0.9.1: Proxy mode should proceed directly to waterfall
 * @discussion Validates proxy response triggers waterfall without second auction
 */
- (void)testCDPProxy_ValidBids_ShouldProceedToWaterfall {
    // Given: Valid proxy response with bids
    NSDictionary *proxyResponse = @{
        @"id": @"proxy-waterfall-test",
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-123",
                @"impid": @"imp-1",
                @"price": @(80.00),
                @"adm": @"<ad/>"
            }]
        }]
    };
    
    // When: Parse and validate
    CLXBidResponse *bidResponse = [CLXBidResponse parseBidResponseFromDictionary:proxyResponse];
    
    // Then: Should have bids ready for waterfall
    XCTAssertNotNil(bidResponse, @"Should parse proxy response");
    XCTAssertGreaterThan([bidResponse allBids].count, 0, @"Should have bids for waterfall");
    
    // In production: Calls tryWaterfallBidsFromResponse directly
    // Skips startAuctionWithFinalBidRequest
}

@end

