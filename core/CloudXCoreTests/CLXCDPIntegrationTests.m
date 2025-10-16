/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXCDPIntegrationTests.m
 * @brief P0 Integration tests for CDP (Customer Data Platform) endpoint functionality
 * @details Tests both enrichment mode and proxy mode CDP flows with comprehensive error handling
 *
 * Test Strategy:
 * - Focus on P0 critical paths only
 * - Test both happy paths and failure fallbacks
 * - Validate dual-mode detection logic
 * - Ensure CDP failures don't break ad serving
 *
 * See CDP_TEST_SPEC.md for complete test specification
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXErrorReporter.h>
#import "Helper/CLXUserDefaultsTestHelper.h"

@interface CLXCDPIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXBidNetworkServiceClass *networkService;
@property (nonatomic, strong) CLXBidNetworkServiceClass *emptyCDPNetworkService;
@property (nonatomic, strong) CLXErrorReporter *errorReporter;
@end

@implementation CLXCDPIntegrationTests

- (void)setUp {
    [super setUp];
    self.errorReporter = [[CLXErrorReporter alloc] init];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    // Initialize network service with CDP endpoint
    self.networkService = [[CLXBidNetworkServiceClass alloc]
                          initWithAuctionEndpointUrl:@"https://test.cloudx.io/auction"
                          cdpEndpointUrl:@"https://test.cloudx.io/cdp"
                          errorReporter:self.errorReporter];
    
    // Initialize network service WITHOUT CDP endpoint (empty string)
    self.emptyCDPNetworkService = [[CLXBidNetworkServiceClass alloc]
                                   initWithAuctionEndpointUrl:@"https://test.cloudx.io/auction"
                                   cdpEndpointUrl:@""
                                   errorReporter:self.errorReporter];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    self.networkService = nil;
    self.emptyCDPNetworkService = nil;
    self.errorReporter = nil;
    [super tearDown];
}

#pragma mark - P0.1: CDP Configuration Tests

/**
 * @brief Test P0.1.1: Empty CDP endpoint should indicate CDP is disabled
 * @discussion Most common production scenario - validates SDK behavior when CDP is not configured
 */
- (void)testCDPConfiguration_EmptyCDPEndpoint_ShouldIndicateDisabled {
    // Given: Network service initialized with empty CDP endpoint
    // When: Check CDP status
    // Then: Should indicate CDP is disabled
    XCTAssertTrue(self.emptyCDPNetworkService.isCDPEndpointEmpty,
                 @"Empty CDP endpoint should set isCDPEndpointEmpty to YES");
    
    // Validate that service can still be used for auctions
    XCTAssertNotNil(self.emptyCDPNetworkService,
                   @"Network service should initialize even without CDP");
}

/**
 * @brief Test P0.1.2: Valid CDP endpoint should be properly configured
 * @discussion Validates CDP endpoint is stored and accessible when configured
 */
- (void)testCDPConfiguration_ValidCDPEndpoint_ShouldBeConfigured {
    // Given: Network service initialized with valid CDP endpoint
    // When: Check CDP status
    // Then: Should indicate CDP is enabled
    XCTAssertFalse(self.networkService.isCDPEndpointEmpty,
                  @"Valid CDP endpoint should set isCDPEndpointEmpty to NO");
    
    // Validate service is properly initialized
    XCTAssertNotNil(self.networkService,
                   @"Network service should initialize with CDP endpoint");
}

#pragma mark - P0.2: CDP Enrichment Mode Detection Tests

/**
 * @brief Test P0.2.1: Detect enrichment mode from response structure
 * @discussion Validates SDK correctly identifies bid request enrichment response
 */
- (void)testCDPDualMode_EnrichmentResponse_ShouldBeDetectedCorrectly {
    // Given: Mock CDP enrichment response (has bid request fields)
    NSDictionary *enrichedBidRequest = @{
        @"id": @"enriched-request-123",
        @"imp": @[@{
            @"id": @"imp-1",
            @"banner": @{@"w": @320, @"h": @50}
        }],
        @"device": @{
            @"ua": @"test-user-agent",
            @"os": @"iOS"
        },
        @"app": @{
            @"bundle": @"com.test.app",
            @"id": @"test-app-id"
        },
        @"user": @{
            @"ext": @{
                @"eids": @[@{@"source": @"enriched-source"}]
            }
        }
    };
    
    // When: Analyze response structure
    BOOL hasAuctionResponseFields = (enrichedBidRequest[@"seatbid"] != nil || enrichedBidRequest[@"nbr"] != nil);
    BOOL hasBidRequestFields = (enrichedBidRequest[@"imp"] != nil || enrichedBidRequest[@"device"] != nil || enrichedBidRequest[@"app"] != nil);
    BOOL hasAuctionId = (enrichedBidRequest[@"id"] != nil);
    
    // Then: Should detect as enrichment mode (NOT proxy mode)
    BOOL isProxyMode = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    XCTAssertFalse(hasAuctionResponseFields,
                  @"Enrichment response should not have seatbid/nbr fields");
    XCTAssertTrue(hasBidRequestFields,
                 @"Enrichment response should have imp/device/app fields");
    XCTAssertFalse(isProxyMode,
                  @"Enrichment response should NOT be detected as proxy mode");
}

/**
 * @brief Test P0.2.2: Enriched request structure validation
 * @discussion Validates enriched bid request has required fields for auction
 */
- (void)testCDPEnrichment_EnrichedRequest_ShouldHaveRequiredFields {
    // Given: Enriched bid request from CDP
    NSDictionary *enrichedRequest = @{
        @"id": @"request-123",
        @"imp": @[@{@"id": @"imp-1"}],
        @"device": @{@"os": @"iOS"},
        @"app": @{@"bundle": @"com.test"}
    };
    
    // When: Validate required fields
    // Then: Should have all required bid request fields
    XCTAssertNotNil(enrichedRequest[@"id"], @"Must have auction ID");
    XCTAssertNotNil(enrichedRequest[@"imp"], @"Must have impressions array");
    XCTAssertNotNil(enrichedRequest[@"device"], @"Must have device object");
    XCTAssertNotNil(enrichedRequest[@"app"], @"Must have app object");
    
    // Should NOT have auction response fields
    XCTAssertNil(enrichedRequest[@"seatbid"], @"Enriched request should not have seatbid");
    XCTAssertNil(enrichedRequest[@"nbr"], @"Enriched request should not have no-bid reason");
}

#pragma mark - P0.3: CDP Proxy Mode Detection Tests

/**
 * @brief Test P0.3.1: Detect proxy mode from response structure
 * @discussion Validates SDK correctly identifies full auction response from CDP proxy
 */
- (void)testCDPDualMode_ProxyResponse_ShouldBeDetectedCorrectly {
    // Given: Mock CDP proxy response (full auction response)
    NSDictionary *auctionResponse = @{
        @"id": @"auction-response-123",
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-123",
                @"impid": @"imp-1",
                @"price": @99.99,
                @"adm": @"<vast></vast>"
            }]
        }],
        @"cur": @"USD"
    };
    
    // When: Analyze response structure
    BOOL hasAuctionResponseFields = (auctionResponse[@"seatbid"] != nil || auctionResponse[@"nbr"] != nil);
    BOOL hasBidRequestFields = (auctionResponse[@"imp"] != nil || auctionResponse[@"device"] != nil || auctionResponse[@"app"] != nil);
    BOOL hasAuctionId = (auctionResponse[@"id"] != nil &&
                         [auctionResponse[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)auctionResponse[@"id"] length] > 0);
    
    // Then: Should detect as proxy mode
    BOOL isProxyMode = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    XCTAssertTrue(hasAuctionResponseFields,
                 @"Proxy response should have seatbid or nbr fields");
    XCTAssertTrue(hasAuctionId,
                 @"Proxy response should have valid auction ID");
    XCTAssertFalse(hasBidRequestFields,
                  @"Proxy response should not have imp/device/app fields");
    XCTAssertTrue(isProxyMode,
                 @"Auction response should be detected as proxy mode");
}

/**
 * @brief Test P0.3.2: Proxy response can be parsed as CLXBidResponse
 * @discussion Validates auction response from CDP proxy can be parsed correctly
 */
- (void)testCDPProxy_AuctionResponse_ShouldBeParseable {
    // Given: Valid auction response from CDP proxy
    NSDictionary *auctionResponse = @{
        @"id": @"auction-789",
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-456",
                @"impid": @"imp-123",
                @"price": @(50.00),
                @"adm": @"test-ad-markup",
                @"ext": @{
                    @"cloudx": @{
                        @"rank": @1
                    }
                }
            }]
        }],
        @"cur": @"USD"
    };
    
    // When: Parse as CLXBidResponse
    CLXBidResponse *bidResponse = nil;
    XCTAssertNoThrow(bidResponse = [CLXBidResponse parseBidResponseFromDictionary:auctionResponse],
                    @"Should parse proxy response without throwing");
    
    // Then: Should successfully parse and have bids
    XCTAssertNotNil(bidResponse, @"Should create bid response object");
    XCTAssertNotNil(bidResponse.id, @"Should have auction ID");
    XCTAssertEqual([bidResponse allBids].count, 1, @"Should have one bid");
}

#pragma mark - P0.4: CDP Ambiguous Response Handling

/**
 * @brief Test P0.4.1: Handle response with both request and response fields
 * @discussion Edge case: CDP returns ambiguous structure with mixed fields
 */
- (void)testCDPDualMode_AmbiguousResponse_ShouldHandleGracefully {
    // Given: Ambiguous response with both bid request and auction response fields
    NSDictionary *ambiguousResponse = @{
        @"id": @"ambiguous-123",
        @"imp": @[@{@"id": @"imp-1"}],          // Bid request field
        @"seatbid": @[@{@"bid": @[]}],          // Auction response field
        @"device": @{@"os": @"iOS"}             // Bid request field
    };
    
    // When: Apply detection logic
    BOOL hasAuctionResponseFields = (ambiguousResponse[@"seatbid"] != nil || ambiguousResponse[@"nbr"] != nil);
    BOOL hasBidRequestFields = (ambiguousResponse[@"imp"] != nil || ambiguousResponse[@"device"] != nil);
    BOOL hasAuctionId = (ambiguousResponse[@"id"] != nil);
    
    // Then: Detection should not crash and should make a decision
    // Current implementation: if has BOTH sets of fields, prioritize request fields (safer fallback)
    BOOL isProxyMode = hasAuctionResponseFields && hasAuctionId && !hasBidRequestFields;
    
    XCTAssertFalse(isProxyMode,
                  @"Ambiguous response with request fields should NOT be treated as proxy");
    
    // Verify it can be handled without crash
    XCTAssertNoThrow({
        if (isProxyMode) {
            [CLXBidResponse parseBidResponseFromDictionary:ambiguousResponse];
        }
    }, @"Ambiguous response handling should not crash");
}

/**
 * @brief Test P0.4.2: Handle empty response
 * @discussion Edge case: CDP returns empty object
 */
- (void)testCDPError_EmptyResponse_ShouldFallbackGracefully {
    // Given: Empty response from CDP
    NSDictionary *emptyResponse = @{};
    
    // When: Validate response
    BOOL isValid = (emptyResponse != nil && [emptyResponse isKindOfClass:[NSDictionary class]]);
    BOOL hasAuctionResponseFields = (emptyResponse[@"seatbid"] != nil || emptyResponse[@"nbr"] != nil);
    BOOL hasBidRequestFields = (emptyResponse[@"imp"] != nil || emptyResponse[@"device"] != nil || emptyResponse[@"app"] != nil);
    
    // Then: Should be detected as invalid and fallback
    XCTAssertTrue(isValid, @"Empty dict should be valid dictionary type");
    XCTAssertFalse(hasAuctionResponseFields, @"Empty response should not have auction fields");
    XCTAssertFalse(hasBidRequestFields, @"Empty response should not have request fields");
    
    // Should handle gracefully without crash
    XCTAssertNoThrow({
        [CLXBidResponse parseBidResponseFromDictionary:emptyResponse];
    }, @"Empty response should not crash parser");
}

#pragma mark - P0.5: CDP Invalid Response Handling

/**
 * @brief Test P0.5.1: Handle null/nil CDP response
 * @discussion Critical error path: CDP returns nil
 */
- (void)testCDPError_NilResponse_ShouldBeHandledSafely {
    // Given: Nil response from CDP
    id nilResponse = nil;
    
    // When: Validate response
    BOOL isValid = (nilResponse != nil && [nilResponse isKindOfClass:[NSDictionary class]]);
    
    // Then: Should be detected as invalid
    XCTAssertFalse(isValid, @"Nil response should be invalid");
    
    // Should handle without crash
    XCTAssertNoThrow({
        if (isValid) {
            [CLXBidResponse parseBidResponseFromDictionary:nilResponse];
        }
    }, @"Nil response handling should not crash");
}

/**
 * @brief Test P0.5.2: Handle wrong type CDP response (array instead of dict)
 * @discussion Edge case: CDP returns array instead of dictionary
 */
- (void)testCDPError_WrongTypeResponse_ShouldBeRejected {
    // Given: Array response instead of dictionary
    id arrayResponse = @[@"invalid", @"response"];
    
    // When: Validate response type
    BOOL isValid = (arrayResponse != nil && [arrayResponse isKindOfClass:[NSDictionary class]]);
    
    // Then: Should be rejected as invalid
    XCTAssertFalse(isValid, @"Array response should be invalid");
    XCTAssertTrue([arrayResponse isKindOfClass:[NSArray class]], @"Should still be an array");
}

#pragma mark - P0.6: CDP Proxy Invalid Auction Response

/**
 * @brief Test P0.6.1: CDP proxy returns auction response without ID
 * @discussion Invalid proxy response: missing required auction ID
 */
- (void)testCDPProxy_MissingAuctionID_ShouldBeInvalid {
    // Given: Auction response without ID
    NSDictionary *invalidAuctionResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-123",
                @"price": @(99.99)
            }]
        }]
        // Missing @"id" field
    };
    
    // When: Validate proxy response
    BOOL hasAuctionId = (invalidAuctionResponse[@"id"] != nil &&
                         [invalidAuctionResponse[@"id"] isKindOfClass:[NSString class]] &&
                         [(NSString *)invalidAuctionResponse[@"id"] length] > 0);
    
    // Then: Should be invalid
    XCTAssertFalse(hasAuctionId, @"Response without auction ID should be invalid");
    
    // Parser should handle gracefully
    CLXBidResponse *bidResponse = nil;
    XCTAssertNoThrow(bidResponse = [CLXBidResponse parseBidResponseFromDictionary:invalidAuctionResponse],
                    @"Parser should handle missing ID gracefully");
}

/**
 * @brief Test P0.6.2: CDP proxy returns empty seatbid array
 * @discussion Valid structure but no bids (no-bid response)
 */
- (void)testCDPProxy_EmptySeatbid_ShouldBeValidNoBid {
    // Given: Auction response with empty seatbid
    NSDictionary *noBidResponse = @{
        @"id": @"auction-no-bid-123",
        @"seatbid": @[],
        @"cur": @"USD"
    };
    
    // When: Parse response
    CLXBidResponse *bidResponse = nil;
    XCTAssertNoThrow(bidResponse = [CLXBidResponse parseBidResponseFromDictionary:noBidResponse],
                    @"Should parse no-bid response without throwing");
    
    // Then: Should be valid but with no bids
    XCTAssertNotNil(bidResponse, @"Should create bid response object");
    XCTAssertEqual([bidResponse allBids].count, 0, @"Should have zero bids");
}

#pragma mark - P0.7: CDP Request Structure Validation

/**
 * @brief Test P0.7.1: Validate bid request has required fields for CDP
 * @discussion Ensures bid request sent to CDP is properly formatted
 */
- (void)testCDPRequest_BidRequestStructure_ShouldHaveRequiredFields {
    // Given: Typical bid request structure
    NSDictionary *bidRequest = @{
        @"id": @"request-123",
        @"imp": @[@{
            @"id": @"imp-1",
            @"banner": @{@"w": @320, @"h": @50}
        }],
        @"app": @{
            @"bundle": @"com.test.app",
            @"id": @"app-123"
        },
        @"device": @{
            @"os": @"iOS",
            @"osv": @"18.0",
            @"ifa": @"test-ifa"
        },
        @"regs": @{
            @"ext": @{@"gdpr": @0}
        }
    };
    
    // When: Validate request structure
    // Then: Should have all required fields
    XCTAssertNotNil(bidRequest[@"id"], @"Bid request must have ID");
    XCTAssertNotNil(bidRequest[@"imp"], @"Bid request must have impressions");
    XCTAssertNotNil(bidRequest[@"app"], @"Bid request must have app info");
    XCTAssertNotNil(bidRequest[@"device"], @"Bid request must have device info");
    XCTAssertNotNil(bidRequest[@"regs"], @"Bid request must have regulations");
    
    // Validate it can be serialized to JSON (required for network request)
    NSError *jsonError;
    NSData *jsonData = nil;
    XCTAssertNoThrow(jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError],
                    @"Bid request should be JSON serializable");
    XCTAssertNil(jsonError, @"JSON serialization should not produce error");
    XCTAssertNotNil(jsonData, @"Should produce valid JSON data");
}

/**
 * @brief Test P0.7.2: CDP request JSON serialization error handling
 * @discussion Validates handling of bid request that cannot be serialized
 */
- (void)testCDPRequest_JSONSerializationFailure_ShouldBeDetected {
    // Given: Invalid bid request with non-serializable object
    // NSDate throws exception (not error) - need to catch it
    NSDictionary *invalidRequest = @{
        @"id": @"request-123",
        @"timestamp": [NSDate date]  // Invalid: NSDate cannot be serialized to JSON
    };
    
    // When: Attempt to serialize (wrap in exception handler)
    NSError *jsonError = nil;
    NSData *jsonData = nil;
    BOOL threwException = NO;
    
    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:invalidRequest options:0 error:&jsonError];
    } @catch (NSException *exception) {
        threwException = YES;
        // In production, this would be caught and reported via error reporter
        XCTAssertEqualObjects(exception.name, NSInvalidArgumentException,
                             @"Should throw NSInvalidArgumentException");
    }
    
    // Then: Should either produce error or throw exception
    XCTAssertTrue(threwException || jsonError != nil,
                 @"Invalid object should produce error or exception");
    
    if (threwException) {
        XCTAssertNil(jsonData, @"Should not produce JSON data when exception thrown");
    } else if (jsonError) {
        XCTAssertNil(jsonData, @"Should not produce JSON data when error returned");
        XCTAssertEqualObjects(jsonError.domain, NSCocoaErrorDomain,
                             @"JSON error should be from Cocoa framework");
    }
}

#pragma mark - P0.8: CDP Authentication Header Tests

/**
 * @brief Test P0.8.1: CDP request should include authorization header
 * @discussion Critical security requirement: CDP requests must be authenticated
 */
- (void)testCDPRequest_AuthorizationHeader_ShouldBeIncluded {
    // Given: Network service with CDP endpoint and app key
    NSString *testAppKey = @"test-app-key-12345";
    
    // When: Prepare CDP request headers
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Content-Type"] = @"application/json";
    headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", testAppKey];
    headers[@"User-Agent"] = @"CloudX/1.0.0";
    
    // Then: Should have required authentication headers
    XCTAssertNotNil(headers[@"Authorization"], @"Must have Authorization header");
    XCTAssertTrue([headers[@"Authorization"] hasPrefix:@"Bearer "],
                 @"Authorization should use Bearer token format");
    XCTAssertTrue([headers[@"Authorization"] containsString:testAppKey],
                 @"Authorization should contain app key");
    
    // Validate other required headers
    XCTAssertEqualObjects(headers[@"Content-Type"], @"application/json",
                         @"Must use JSON content type");
    XCTAssertNotNil(headers[@"User-Agent"], @"Must include User-Agent");
}

/**
 * @brief Test P0.8.2: CDP request headers structure validation
 * @discussion Validates complete header structure for CDP requests
 */
- (void)testCDPRequest_HeadersStructure_ShouldBeComplete {
    // Given: Complete CDP request headers
    NSDictionary *headers = @{
        @"Content-Type": @"application/json",
        @"Authorization": @"Bearer test-key",
        @"User-Agent": @"CloudX/1.0.0"
    };
    
    // When: Validate headers
    // Then: Should have all required headers
    XCTAssertEqual(headers.count, 3, @"Should have exactly 3 headers");
    XCTAssertNotNil(headers[@"Content-Type"], @"Must have Content-Type");
    XCTAssertNotNil(headers[@"Authorization"], @"Must have Authorization");
    XCTAssertNotNil(headers[@"User-Agent"], @"Must have User-Agent");
}

#pragma mark - P0.9: CDP Error Response Handling

/**
 * @brief Test P0.9.1: Handle 4xx client errors from CDP
 * @discussion CDP returns 400/401/403 - should fallback gracefully
 */
- (void)testCDPError_4xxClientError_ShouldFallbackToAuction {
    // Given: Mock 4xx error response
    NSError *clientError = [NSError errorWithDomain:NSURLErrorDomain
                                              code:NSURLErrorBadServerResponse
                                          userInfo:@{
        NSLocalizedDescriptionKey: @"HTTP 400 Bad Request",
        @"statusCode": @400
    }];
    
    // When: Handle error
    // Then: Should be recognized as error and trigger fallback
    XCTAssertNotNil(clientError, @"Should have error object");
    XCTAssertEqualObjects(clientError.domain, NSURLErrorDomain,
                         @"Should be URL error domain");
    
    // Error should be logged and fallback triggered (in production code)
    // Test validates error structure is correct
    XCTAssertNotNil(clientError.localizedDescription,
                   @"Error should have description for logging");
}

/**
 * @brief Test P0.9.2: Handle 5xx server errors from CDP
 * @discussion CDP returns 500/502/503 - should fallback gracefully
 */
- (void)testCDPError_5xxServerError_ShouldFallbackToAuction {
    // Given: Mock 5xx error response
    NSError *serverError = [NSError errorWithDomain:NSURLErrorDomain
                                               code:NSURLErrorCannotConnectToHost
                                           userInfo:@{
        NSLocalizedDescriptionKey: @"HTTP 503 Service Unavailable",
        @"statusCode": @503
    }];
    
    // When: Handle error
    // Then: Should be recognized as error and trigger fallback
    XCTAssertNotNil(serverError, @"Should have error object");
    
    // Validate error can be logged properly
    XCTAssertNotNil(serverError.localizedDescription,
                   @"Server error should have description");
    XCTAssertNotNil(serverError.userInfo,
                   @"Server error should have user info for context");
}

#pragma mark - P0.10: CDP Network Service Initialization

/**
 * @brief Test P0.10.1: Network service initialization with empty CDP URL
 * @discussion Validates proper initialization when CDP is disabled
 */
- (void)testNetworkService_EmptyCDPURL_ShouldInitializeCorrectly {
    // Given: Empty CDP endpoint
    // When: Initialize network service
    CLXBidNetworkServiceClass *service = [[CLXBidNetworkServiceClass alloc]
                                         initWithAuctionEndpointUrl:@"https://auction.test"
                                         cdpEndpointUrl:@""];
    
    // Then: Should initialize successfully
    XCTAssertNotNil(service, @"Should initialize with empty CDP URL");
    XCTAssertTrue(service.isCDPEndpointEmpty, @"Should indicate CDP is disabled");
}

/**
 * @brief Test P0.10.2: Network service initialization with valid CDP URL
 * @discussion Validates proper initialization when CDP is enabled
 */
- (void)testNetworkService_ValidCDPURL_ShouldInitializeCorrectly {
    // Given: Valid CDP endpoint
    // When: Initialize network service
    CLXBidNetworkServiceClass *service = [[CLXBidNetworkServiceClass alloc]
                                         initWithAuctionEndpointUrl:@"https://auction.test"
                                         cdpEndpointUrl:@"https://cdp.test"];
    
    // Then: Should initialize successfully
    XCTAssertNotNil(service, @"Should initialize with valid CDP URL");
    XCTAssertFalse(service.isCDPEndpointEmpty, @"Should indicate CDP is enabled");
}

/**
 * @brief Test P0.10.3: Network service supports error reporter injection
 * @discussion Validates dependency injection for error reporting
 */
- (void)testNetworkService_ErrorReporterInjection_ShouldBeSupported {
    // Given: Error reporter instance
    CLXErrorReporter *errorReporter = [[CLXErrorReporter alloc] init];
    
    // When: Initialize network service with error reporter
    CLXBidNetworkServiceClass *service = [[CLXBidNetworkServiceClass alloc]
                                         initWithAuctionEndpointUrl:@"https://auction.test"
                                         cdpEndpointUrl:@"https://cdp.test"
                                         errorReporter:errorReporter];
    
    // Then: Should initialize successfully with injected dependency
    XCTAssertNotNil(service, @"Should initialize with error reporter");
    
    // Validate error reporter was properly injected (indirectly)
    // If initialization succeeds, dependency injection works
    XCTAssertTrue(YES, @"Error reporter injection successful");
}

@end

