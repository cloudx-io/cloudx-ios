//
//  CLXKillSwitchTests.m
//  CloudXCoreTests
//
//  Tests for kill switch functionality in SDK initialization and bid requests
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access internal methods for testing
@interface CLXSDKInitNetworkService (Testing)
- (CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response;
@end

// Mock data task that can be resumed
@interface MockDataTask : NSObject
@property (nonatomic, assign) BOOL resumed;
- (void)resume;
@end

// Mock URL session for controlled responses
@interface MockURLSession : NSURLSession
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSError *responseError;
@end

@implementation MockURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request 
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] 
                                      initWithURL:request.URL 
                                      statusCode:self.statusCode 
                                      HTTPVersion:@"HTTP/1.1" 
                                      headerFields:self.headers];
    
    // Simulate async behavior
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        completionHandler(self.responseData, httpResponse, self.responseError);
    });
    
    // Return a mock task - cast to satisfy return type
    MockDataTask *mockTask = [[MockDataTask alloc] init];
    return (NSURLSessionDataTask *)mockTask;
}

@end

@implementation MockDataTask
- (void)resume {
    self.resumed = YES;
}
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
                      cdpEndpointUrl:@"https://test.cloudx.io/cdp"
                      errorReporter:nil
                      urlSession:self.mockSession];
}

#pragma mark - SDK Initialization Kill Switch Tests

/**
 * Test SDK initialization kill switch with SDK_DISABLED header
 * This simulates 0% traffic control where SDK initialization is completely disabled
 */
- (void)testSDKInitKillSwitch_SDK_DISABLED_ShouldReturnError105 {
    // Given: Server responds with HTTP 204 and SDK_DISABLED header
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{@"X-CloudX-Status": @"SDK_DISABLED"};
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK init kill switch"];
    
    // When: Initialize SDK
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should fail with SDK disabled error
        XCTAssertNil(config, @"Config should be nil when SDK is disabled");
        XCTAssertNotNil(error, @"Error should be present");
        XCTAssertEqual(error.code, CLXErrorCodeSDKDisabled, @"Should return SDK disabled error code 105");
        XCTAssertEqualObjects(error.domain, CLXErrorDomain, @"Should use CloudX error domain");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test SDK initialization with normal HTTP 204 response (no kill switch header)
 * This should be treated as a normal no-content response, not a kill switch
 */
- (void)testSDKInit_HTTP204_NoKillSwitchHeader_ShouldNotTriggerKillSwitch {
    // Given: Server responds with HTTP 204 but no X-CloudX-Status header
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{}; // No kill switch header
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Normal 204 response"];
    
    // When: Initialize SDK
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (may fail for other reasons like missing data)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not return ads disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test SDK initialization with HTTP 200 and SDK_DISABLED header
 * Kill switch should only trigger on HTTP 204, not other status codes
 */
- (void)testSDKInit_HTTP200_WithSDKDisabledHeader_ShouldNotTriggerKillSwitch {
    // Given: Server responds with HTTP 200 and SDK_DISABLED header
    self.mockSession.statusCode = 200;
    self.mockSession.headers = @{@"X-CloudX-Status": @"SDK_DISABLED"};
    self.mockSession.responseData = [@"{\"accountID\":\"test\"}" dataUsingEncoding:NSUTF8StringEncoding];
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 200 with kill switch header"];
    
    // When: Initialize SDK
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (kill switch only works with 204)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Bid Request Kill Switch Tests

/**
 * Test bid request kill switch with ADS_DISABLED header
 * This simulates traffic sampling where individual bid requests are disabled
 */
- (void)testBidRequestKillSwitch_ADS_DISABLED_ShouldReturnError308 {
    // Given: Mock successful SDK initialization first
    NSDictionary *mockBidRequest = @{
        @"id": @"test-bid-123",
        @"imp": @[@{@"id": @"imp1", @"tagid": @"test-placement"}],
        @"app": @{@"bundle": @"com.test.app"},
        @"device": @{@"model": @"iPhone"},
        @"regs": @{}
    };
    
    // Configure mock response BEFORE starting the auction
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{@"X-CloudX-Status": @"ADS_DISABLED"};
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bid request kill switch"];
    
    // When: Start auction with kill switch response
    [self.bidService startAuctionWithBidRequest:mockBidRequest 
                                         appKey:@"test-app-key" 
                                     completion:^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Then: Should fail with ads disabled error
        XCTAssertNil(parsedResponse, @"Parsed response should be nil when ads are disabled");
        XCTAssertNil(rawJSON, @"Raw JSON should be nil when ads are disabled");
        XCTAssertNotNil(error, @"Error should be present");
        XCTAssertEqual(error.code, CLXErrorCodeAdsDisabled, @"Should return ads disabled error code 308");
        XCTAssertEqualObjects(error.domain, CLXErrorDomain, @"Should use CloudX error domain");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
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
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{}; // No kill switch header
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Normal no-fill response"];
    
    // When: Start auction with normal 204 response
    [self.bidService startAuctionWithBidRequest:mockBidRequest 
                                         appKey:@"test-app-key" 
                                     completion:^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Then: Should not trigger kill switch
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not return SDK disabled error");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not return ads disabled error");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Edge Cases

/**
 * Test kill switch with case-sensitive header check
 * Verify that header matching is exact (case-sensitive)
 */
- (void)testKillSwitch_CaseSensitiveHeaders_ShouldNotTriggerWithWrongCase {
    // Given: Server responds with HTTP 204 and lowercase kill switch header
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{@"X-CloudX-Status": @"sdk_disabled"}; // lowercase
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Case sensitive header test"];
    
    // When: Initialize SDK
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch (case mismatch)
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not trigger with wrong case");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test kill switch with unknown header value
 * Verify that only specific values trigger kill switch
 */
- (void)testKillSwitch_UnknownHeaderValue_ShouldNotTrigger {
    // Given: Server responds with HTTP 204 and unknown header value
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{@"X-CloudX-Status": @"UNKNOWN_STATUS"};
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Unknown header value test"];
    
    // When: Initialize SDK
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // Then: Should not trigger kill switch
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeSDKDisabled, @"Should not trigger with unknown header value");
            XCTAssertNotEqual(error.code, CLXErrorCodeAdsDisabled, @"Should not trigger with unknown header value");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test that both SDK_DISABLED and ADS_DISABLED headers are recognized
 * Verify the base network service handles both header values correctly
 */
- (void)testKillSwitch_BothHeaderValues_ShouldBeRecognized {
    // Test SDK_DISABLED
    self.mockSession.statusCode = 204;
    self.mockSession.headers = @{@"X-CloudX-Status": @"SDK_DISABLED"};
    self.mockSession.responseData = nil;
    self.mockSession.responseError = nil;
    
    XCTestExpectation *sdkExpectation = [self expectationWithDescription:@"SDK_DISABLED test"];
    
    [self.sdkInitService initSDKWithAppKey:@"test-app-key" completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        XCTAssertEqual(error.code, CLXErrorCodeSDKDisabled, @"Should recognize SDK_DISABLED");
        [sdkExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
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
    XCTAssertTrue([sdkError.localizedDescription containsString:@"kill switch"], @"Error message should mention kill switch");
    
    // Test ads disabled error message  
    NSError *adsError = [CLXError errorWithCode:CLXErrorCodeAdsDisabled];
    XCTAssertNotNil(adsError.localizedDescription, @"Ads disabled error should have description");
    XCTAssertTrue([adsError.localizedDescription containsString:@"kill switch"], @"Error message should mention kill switch");
}

@end
