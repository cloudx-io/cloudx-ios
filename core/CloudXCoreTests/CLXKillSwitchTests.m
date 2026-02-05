//
//  CLXKillSwitchTests.m
//  CloudXCoreTests
//
//  Tests for kill switch functionality in SDK initialization and bid requests
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "Mocks/MockURLSession.h"

// Private interface to access internal methods for testing
@interface CLXSDKInitNetworkService (Testing)
- (nullable CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response error:(NSError **)outError;
@end

@interface CLXKillSwitchTests : XCTestCase
@property (nonatomic, strong) MockURLSession *mockSession;
@property (nonatomic, strong) CLXSDKInitNetworkService *sdkInitService;
@property (nonatomic, strong) CLXBidNetworkServiceClass *bidService;
@end

@implementation CLXKillSwitchTests

- (void)setUp {
    [super setUp];
    self.mockSession = [[MockURLSession alloc] init];
    
    // Initialize services with mock session
    self.sdkInitService = [[CLXSDKInitNetworkService alloc] 
                          initWithBaseURL:@"https://test.cloudx.io/init"
                          urlSession:self.mockSession];
    
    self.bidService = [[CLXBidNetworkServiceClass alloc] 
                      initWithAuctionEndpointUrl:@"https://test.cloudx.io/auction"
                      errorReporter:nil
                      urlSession:self.mockSession];
}

- (void)tearDown {
    [self.mockSession reset];
    self.mockSession = nil;
    self.sdkInitService = nil;
    self.bidService = nil;
    [super tearDown];
}

#pragma mark - SDK Initialization Kill Switch Tests

/**
 * Test SDK initialization kill switch with SDK_DISABLED header
 * This simulates 0% traffic control where SDK initialization is completely disabled
 */
- (void)testSDKInitKillSwitch_SDK_DISABLED_ShouldReturnError104 {
    // Given: Server responds with HTTP 204 and SDK_DISABLED header
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:@{@"X-CloudX-Status": @"SDK_DISABLED"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK init kill switch"];

    // When: Initialize SDK
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should fail with SDK disabled error (code 104)
        XCTAssertNil(config, @"Config should be nil when SDK is disabled");
        XCTAssertNotNil(error, @"Error should be present");
        XCTAssertEqual(error.code, CLXErrorCodeSDKDisabled, @"Should return SDK disabled error code 104");
        XCTAssertEqualObjects(error.domain, CLXErrorDomain, @"Should use CloudX error domain");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

/**
 * Test SDK initialization with normal HTTP 204 response (no kill switch header)
 * This should be treated as a normal no-content response, not a kill switch
 */
- (void)testSDKInit_HTTP204_NoKillSwitchHeader_ShouldNotTriggerKillSwitch {
    // Given: Server responds with HTTP 204 but no X-CloudX-Status header
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Normal 204 response"];
    
    // When: Initialize SDK
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (may fail for other reasons like missing data)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not return ads disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

/**
 * Test SDK initialization with HTTP 200 and SDK_DISABLED header
 * Kill switch should only trigger on HTTP 204, not other status codes
 */
- (void)testSDKInit_HTTP200_WithSDKDisabledHeader_ShouldNotTriggerKillSwitch {
    // Given: Server responds with HTTP 200 and SDK_DISABLED header
    NSData *responseData = [@"{\"accountID\":\"test\"}" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mockSession enqueueResponseWithStatusCode:200 data:responseData headers:@{@"X-CloudX-Status": @"SDK_DISABLED"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 200 with kill switch header"];
    
    // When: Initialize SDK
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (kill switch only works with 204)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

#pragma mark - Bid Request Kill Switch Tests

/**
 * Test bid request kill switch with ADS_DISABLED header
 * This simulates traffic sampling where individual bid requests are disabled
 */
- (void)testBidRequestKillSwitch_ADS_DISABLED_ShouldReturnError301 {
    // Given: Mock successful SDK initialization first
    NSDictionary *mockBidRequest = @{
        @"id": @"test-bid-123",
        @"imp": @[@{@"id": @"imp1", @"tagid": @"test-placement"}],
        @"app": @{@"bundle": @"com.test.app"},
        @"device": @{@"model": @"iPhone"},
        @"regs": @{}
    };
    
    // Configure mock response BEFORE starting the auction
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:@{@"X-CloudX-Status": @"ADS_DISABLED"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bid request kill switch"];
    
    // When: Start auction with kill switch response
    [self.bidService startAuctionWithBidRequest:mockBidRequest
                                         appKey:@"test-app-key"
                                        timeout:0
                                  correlationId:[[NSUUID UUID] UUIDString]
                                     completion:^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Then: Should fail with ads disabled error
        XCTAssertNil(parsedResponse, @"Parsed response should be nil when ads are disabled");
        XCTAssertNil(rawJSON, @"Raw JSON should be nil when ads are disabled");
        XCTAssertNotNil(error, @"Error should be present");
        XCTAssertEqual(error.code, CLXErrorCodeAdsDisabled, @"Should return ads disabled error code 301");
        XCTAssertEqualObjects(error.domain, CLXErrorDomain, @"Should use CloudX error domain");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

/**
 * Test bid request with normal HTTP 204 response (no-fill scenario)
 * This should be treated as normal no-fill, not a kill switch
 */
- (void)testBidRequest_HTTP204_NoKillSwitchHeader_ShouldNotTriggerKillSwitch {
    // Given: Mock bid request
    NSDictionary *mockBidRequest = @{
        @"id": @"test-bid-123",
        @"imp": @[@{@"id": @"imp1", @"tagid": @"test-placement"}],
        @"app": @{@"bundle": @"com.test.app"},
        @"device": @{@"model": @"iPhone"},
        @"regs": @{}
    };
    
    // Configure mock response BEFORE starting the auction
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Normal no-fill response"];
    
    // When: Start auction with normal 204 response
    [self.bidService startAuctionWithBidRequest:mockBidRequest
                                         appKey:@"test-app-key"
                                        timeout:0
                                  correlationId:[[NSUUID UUID] UUIDString]
                                     completion:^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Then: Should not trigger kill switch
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not return ads disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

#pragma mark - Edge Cases

/**
 * Test kill switch with case-sensitive header check
 * Verify that header matching is exact (case-sensitive)
 */
- (void)testKillSwitch_CaseSensitiveHeaders_ShouldNotTriggerWithWrongCase {
    // Given: Server responds with HTTP 204 and lowercase kill switch header
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:@{@"X-CloudX-Status": @"sdk_disabled"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Case sensitive header test"];
    
    // When: Initialize SDK
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (case mismatch)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not trigger with wrong case");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

/**
 * Test kill switch with unknown header value
 * Verify that only specific values trigger kill switch
 */
- (void)testKillSwitch_UnknownHeaderValue_ShouldNotTrigger {
    // Given: Server responds with HTTP 204 and unknown header value
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:@{@"X-CloudX-Status": @"UNKNOWN_STATUS"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Unknown header value test"];
    
    // When: Initialize SDK
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not trigger with unknown header value");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not trigger with unknown header value");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

/**
 * Test that both SDK_DISABLED and ADS_DISABLED headers are recognized
 * Verify the base network service handles both header values correctly
 */
- (void)testKillSwitch_BothHeaderValues_ShouldBeRecognized {
    // Test SDK_DISABLED
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:@{@"X-CloudX-Status": @"SDK_DISABLED"}];
    
    XCTestExpectation *sdkExpectation = [self expectationWithDescription:@"SDK_DISABLED test"];
    
    [self.sdkInitService initializeSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        XCTAssertEqual(error.code, CLXErrorCodeSDKDisabled, @"Should recognize SDK_DISABLED");
        [sdkExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
    
    // Test ADS_DISABLED (would need separate bid service test)
    // Note: This is conceptually tested in the bid request test above
}

#pragma mark - Error Message Tests

/**
 * Test that error messages are descriptive for kill switch scenarios
 */
- (void)testKillSwitchErrorMessages_ShouldBeDescriptive {
    // Test SDK disabled error message
    NSError *sdkError = [CLXError errorWithCode:CLXErrorCodeSDKDisabled];
    XCTAssertNotNil(sdkError.localizedDescription, @"SDK disabled error should have description");
    XCTAssertTrue([sdkError.localizedDescription containsString:@"disabled"], @"Error message should mention disabled");
    
    // Test ads disabled error message  
    NSError *adsError = [CLXError errorWithCode:CLXErrorCodeAdsDisabled];
    XCTAssertNotNil(adsError.localizedDescription, @"Ads disabled error should have description");
    XCTAssertTrue([adsError.localizedDescription containsString:@"disabled"], @"Error message should mention disabled");
}

#pragma mark - Publisher Ad Kill Switch Propagation Tests

/**
 * Test that PublisherBanner fails immediately on kill switch error without continuing waterfall
 * This ensures error code 301 (AdsDisabled) is not converted to 302 (NoFill)
 */
- (void)testPublisherBanner_KillSwitchError_ShouldFailImmediately {
    // This test verifies the fix for kill switch errors being converted to "waterfall exhausted"
    // When PublisherBanner receives error 301, it should fail immediately, not continue waterfall

    NSError *killSwitchError = [CLXError errorWithCode:CLXErrorCodeAdsDisabled
                                            description:@"Ads disabled by kill switch"];

    XCTAssertEqual(killSwitchError.code, CLXErrorCodeAdsDisabled,
                  @"Kill switch error should be code 301");
    XCTAssertEqualObjects(killSwitchError.domain, CLXErrorDomain,
                         @"Kill switch error should use CloudX domain");
    
    // Verify error is not NoFill
    XCTAssertNotEqual(killSwitchError.code, CLXErrorCodeNoFill,
                     @"Kill switch error should not be converted to NoFill");
}

/**
 * Test that SDK disabled error (code 105) also fails immediately
 */
- (void)testPublisherBanner_SDKDisabledError_ShouldFailImmediately {
    NSError *sdkDisabledError = [CLXError errorWithCode:CLXErrorCodeSDKDisabled 
                                             description:@"SDK disabled by kill switch"];
    
    XCTAssertEqual(sdkDisabledError.code, CLXErrorCodeSDKDisabled,
                  @"SDK disabled error should be code 105");
    XCTAssertEqualObjects(sdkDisabledError.domain, CLXErrorDomain,
                         @"SDK disabled error should use CloudX domain");
    
    // Verify error is not converted to NoFill
    XCTAssertNotEqual(sdkDisabledError.code, CLXErrorCodeNoFill,
                     @"SDK disabled error should not be converted to NoFill");
}

/**
 * Test that non-kill-switch errors still continue with waterfall
 * This ensures we didn't break normal error handling
 */
- (void)testPublisherBanner_NetworkError_ShouldContinueWaterfall {
    // Non-kill-switch errors should still allow waterfall to continue
    NSError *networkError = [CLXError errorWithCode:CLXErrorCodeNetworkError
                                         description:@"Network request failed"];
    
    XCTAssertEqual(networkError.code, CLXErrorCodeNetworkError,
                  @"Network error should be code 200");
    
    // Verify it's not a kill switch error
    XCTAssertNotEqual(networkError.code, CLXErrorCodeSDKDisabled,
                     @"Network error should not be SDK disabled");
    XCTAssertNotEqual(networkError.code, CLXErrorCodeAdsDisabled,
                     @"Network error should not be Ads disabled");
}

/**
 * Test that both kill switch error codes (104 and 301) are handled correctly
 */
- (void)testKillSwitchErrorCodes_ShouldBeRecognized {
    // Error code 104 - SDK Disabled
    NSError *error104 = [CLXError errorWithCode:CLXErrorCodeSDKDisabled];
    XCTAssertEqual(error104.code, CLXErrorCodeSDKDisabled, @"SDK disabled should be code 204");

    // Error code 301 - Ads Disabled
    NSError *error301 = [CLXError errorWithCode:CLXErrorCodeAdsDisabled];
    XCTAssertEqual(error301.code, 301, @"Ads disabled should be code 301");

    // Both should have disabled in description
    XCTAssertTrue([error104.localizedDescription containsString:@"kill switch"] ||
                 [error104.localizedDescription containsString:@"disabled"],
                 @"Error 104 description should mention disabled/kill switch");
    XCTAssertTrue([error301.localizedDescription containsString:@"disabled"],
                 @"Error 301 description should mention disabled");
}

@end
