/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBaseNetworkServiceTests.m
 * @brief Unit tests for CLXBaseNetworkService
 *
 * Tests:
 * - HTTP status code handling (2xx, 4xx, 5xx)
 * - Retry triggering on server errors (5xx, 429)
 * - Retry-After header parsing
 * - Kill switch detection via X-CloudX-Status header
 * - Network error handling
 *
 * PRINCIPLES:
 * - Uses MockURLSession for SYNCHRONOUS response delivery (no real network)
 * - XCTestExpectation for async completion handlers
 * - NO arbitrary sleep/delay patterns
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import "Mocks/MockURLSession.h"

#pragma mark - Test Category for Internal Access

@interface CLXBaseNetworkService (Testing)
- (NSTimeInterval)parseRetryAfterHeader:(NSString *)retryAfterHeader;
- (BOOL)isNetworkTimeoutError:(NSError *)error;
@end

#pragma mark - CLXBaseNetworkServiceTests

@interface CLXBaseNetworkServiceTests : XCTestCase
@property (nonatomic, strong) CLXBaseNetworkService *subject;
@property (nonatomic, strong) MockURLSession *mockSession;
@end

@implementation CLXBaseNetworkServiceTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    self.mockSession = [[MockURLSession alloc] init];
    self.subject = [[CLXBaseNetworkService alloc] initWithBaseURL:@"https://test.cloudx.io" urlSession:self.mockSession];
}

- (void)tearDown {
    [self.mockSession reset];
    self.mockSession = nil;
    self.subject = nil;
    [super tearDown];
}

#pragma mark - DRY: Factory Methods

- (NSData *)createJSONData:(NSDictionary *)dict {
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
}

- (NSError *)createNetworkTimeoutError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
}

- (NSError *)createConnectionLostError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];
}

#pragma mark - MARK: Initialization Tests

- (void)testInit_SetsBaseURL {
    XCTAssertEqualObjects(self.subject.baseURL, @"https://test.cloudx.io", @"Should set base URL");
}

- (void)testInit_SetsURLSession {
    XCTAssertEqual(self.subject.urlSession, self.mockSession, @"Should set URL session");
}

- (void)testHeaders_ReturnsContentTypeJSON {
    NSDictionary *headers = [self.subject headers];
    XCTAssertEqualObjects(headers[@"Content-Type"], @"application/json", @"Headers should include JSON content type");
}

#pragma mark - MARK: Success Response Tests (No Retry)

- (void)testRequest_200Success_ReturnsResponse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    NSDictionary *responseDict = @{@"status": @"ok", @"id": @"12345"};
    NSData *responseData = [self createJSONData:responseDict];
    [self.mockSession enqueueResponseWithStatusCode:200 data:responseData headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNotNil(response, @"Should return response");
        XCTAssertNil(error, @"Should not have error");
        XCTAssertFalse(isKillSwitchEnabled, @"Kill switch should not be enabled");
        XCTAssertEqualObjects(response[@"status"], @"ok", @"Should parse JSON response");
        XCTAssertEqualObjects(response[@"id"], @"12345", @"Should parse JSON response");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"Should make exactly 1 request");
}

- (void)testRequest_200Success_DoesNotRetry {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:5
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"200 should NOT trigger retry");
}

- (void)testRequest_201Created_DoesNotRetry {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:201 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:5
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"201 should be success");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"201 should NOT trigger retry");
}

#pragma mark - MARK: Client Error Tests (No Retry)

- (void)testRequest_400ClientError_DoesNotRetry {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:400 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:5
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(response, @"Should not have response for 400");
        XCTAssertNotNil(error, @"Should have error for 400");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"400 should NOT trigger retry");
}

- (void)testRequest_401Unauthorized_DoesNotRetry {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:401 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:5
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNotNil(error, @"Should have error for 401");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"401 should NOT trigger retry");
}

- (void)testRequest_404NotFound_DoesNotRetry {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:404 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:5
                                       delay:1.0
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNotNil(error, @"Should have error for 404");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"404 should NOT trigger retry");
}

#pragma mark - MARK: Server Error Retry Tests

- (void)testRequest_500ServerError_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    // Queue: 500 (retry) -> 200 (success)
    [self.mockSession enqueueResponseWithStatusCode:500 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:200 data:[self createJSONData:@{@"success": @YES}] headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01 // Very short delay for testing
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNotNil(response, @"Should eventually succeed");
        XCTAssertNil(error, @"Should not have error after retry succeeds");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"500 should trigger retry");
}

- (void)testRequest_502BadGateway_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:502 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"Should succeed after retry");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"502 should trigger retry");
}

- (void)testRequest_503ServiceUnavailable_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:503 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"Should succeed after retry");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"503 should trigger retry");
}

- (void)testRequest_429RateLimit_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:429 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"Should succeed after retry");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"429 should trigger retry");
}

#pragma mark - MARK: Retry Exhaustion Tests

- (void)testRequest_MaxRetriesExhausted_ReturnsError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    // Queue all 500 errors - will exhaust retries
    [self.mockSession enqueueResponseWithStatusCode:500 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:500 data:nil headers:nil];
    [self.mockSession enqueueResponseWithStatusCode:500 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2 // Initial + 2 retries = 3 total
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(response, @"Should not have response after max retries");
        XCTAssertNotNil(error, @"Should have error after max retries");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 3, @"Should make initial + 2 retries = 3 total");
}

- (void)testRequest_ZeroRetries_NoRetryOnError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:500 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0 // No retries
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNotNil(error, @"Should have error with no retries");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 1, @"Should make only 1 request with 0 retries");
}

#pragma mark - MARK: Network Error Tests

- (void)testRequest_NetworkTimeout_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueError:[self createNetworkTimeoutError]];
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"Should succeed after retry");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"Network timeout should trigger retry");
}

- (void)testRequest_ConnectionLost_Retries {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueError:[self createConnectionLostError]];
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:2
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(error, @"Should succeed after retry");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(self.mockSession.callCount, 2, @"Connection lost should trigger retry");
}

#pragma mark - MARK: Retry-After Header Parsing Tests

- (void)testParseRetryAfterHeader_IntegerSeconds_ParsesCorrectly {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@"10"];
    XCTAssertEqual(delay, 10.0, @"Should parse integer seconds");
}

- (void)testParseRetryAfterHeader_LargeInteger_CapsAt60Seconds {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@"120"];
    XCTAssertEqual(delay, 60.0, @"Should cap at 60 seconds max");
}

- (void)testParseRetryAfterHeader_ZeroValue_ReturnsZero {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@"0"];
    XCTAssertEqual(delay, 0.0, @"Zero should return 0");
}

- (void)testParseRetryAfterHeader_NilValue_ReturnsZero {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:nil];
    XCTAssertEqual(delay, 0.0, @"Nil should return 0");
}

- (void)testParseRetryAfterHeader_EmptyString_ReturnsZero {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@""];
    XCTAssertEqual(delay, 0.0, @"Empty string should return 0");
}

- (void)testParseRetryAfterHeader_InvalidFormat_ReturnsZero {
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@"invalid"];
    XCTAssertEqual(delay, 0.0, @"Invalid format should return 0");
}

- (void)testParseRetryAfterHeader_NegativeValue_ReturnsZero {
    // integerValue of "-5" returns -5, which is not > 0, so should return 0
    NSTimeInterval delay = [self.subject parseRetryAfterHeader:@"-5"];
    XCTAssertEqual(delay, 0.0, @"Negative value should return 0");
}

#pragma mark - MARK: isNetworkTimeoutError Tests

- (void)testIsNetworkTimeoutError_NSURLErrorTimedOut_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertTrue(result, @"NSURLErrorTimedOut should be network timeout");
}

- (void)testIsNetworkTimeoutError_NSURLErrorCannotFindHost_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertTrue(result, @"NSURLErrorCannotFindHost should be network timeout");
}

- (void)testIsNetworkTimeoutError_NSURLErrorCannotConnectToHost_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertTrue(result, @"NSURLErrorCannotConnectToHost should be network timeout");
}

- (void)testIsNetworkTimeoutError_NSURLErrorNetworkConnectionLost_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertTrue(result, @"NSURLErrorNetworkConnectionLost should be network timeout");
}

- (void)testIsNetworkTimeoutError_NSURLErrorNotConnectedToInternet_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertTrue(result, @"NSURLErrorNotConnectedToInternet should be network timeout");
}

- (void)testIsNetworkTimeoutError_NSURLErrorBadURL_ReturnsNO {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertFalse(result, @"NSURLErrorBadURL should NOT be network timeout");
}

- (void)testIsNetworkTimeoutError_OtherDomain_ReturnsNO {
    NSError *error = [NSError errorWithDomain:@"com.other.domain" code:123 userInfo:nil];
    BOOL result = [self.subject isNetworkTimeoutError:error];
    XCTAssertFalse(result, @"Other domain should NOT be network timeout");
}

#pragma mark - MARK: Kill Switch Detection Tests

- (void)testKillSwitch_204WithADS_DISABLED_DetectsKillSwitch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    NSDictionary *headers = @{@"X-CloudX-Status": @"ADS_DISABLED"};
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:headers];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertTrue(isKillSwitchEnabled, @"Should detect ADS_DISABLED kill switch");
        XCTAssertNil(error, @"204 is success - no error");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testKillSwitch_204WithSDK_DISABLED_DetectsKillSwitch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    NSDictionary *headers = @{@"X-CloudX-Status": @"SDK_DISABLED"};
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:headers];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertTrue(isKillSwitchEnabled, @"Should detect SDK_DISABLED kill switch");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testKillSwitch_204WithoutHeader_NoKillSwitch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertFalse(isKillSwitchEnabled, @"204 without header should NOT be kill switch");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testKillSwitch_200WithHeader_NoKillSwitch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    // Kill switch only applies to 204 responses
    NSDictionary *headers = @{@"X-CloudX-Status": @"ADS_DISABLED"};
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:headers];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertFalse(isKillSwitchEnabled, @"200 response should NOT trigger kill switch");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testKillSwitch_204WithOtherStatus_NoKillSwitch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    NSDictionary *headers = @{@"X-CloudX-Status": @"SOME_OTHER_STATUS"};
    [self.mockSession enqueueResponseWithStatusCode:204 data:nil headers:headers];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertFalse(isKillSwitchEnabled, @"204 with other status should NOT be kill switch");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

#pragma mark - MARK: URL Construction Tests

- (void)testRequest_ConstructsCorrectURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/v1/endpoint"
                               urlParameters:@{@"key": @"value", @"foo": @"bar"}
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    NSURLRequest *lastRequest = self.mockSession.lastRequest;
    XCTAssertNotNil(lastRequest, @"Should capture request");
    
    NSString *urlString = lastRequest.URL.absoluteString;
    XCTAssertTrue([urlString containsString:@"test.cloudx.io"], @"URL should contain base URL");
    XCTAssertTrue([urlString containsString:@"/api/v1/endpoint"], @"URL should contain endpoint");
    XCTAssertTrue([urlString containsString:@"key=value"], @"URL should contain query params");
    XCTAssertTrue([urlString containsString:@"foo=bar"], @"URL should contain query params");
}

- (void)testRequest_POSTWithBody_SetsHTTPMethod {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    NSData *body = [self createJSONData:@{@"test": @"data"}];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:body
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    NSURLRequest *lastRequest = self.mockSession.lastRequest;
    XCTAssertEqualObjects(lastRequest.HTTPMethod, @"POST", @"Request with body should be POST");
    XCTAssertNotNil(lastRequest.HTTPBody, @"Should have body");
}

- (void)testRequest_GETWithoutBody_SetsHTTPMethod {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil // No body
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    NSURLRequest *lastRequest = self.mockSession.lastRequest;
    XCTAssertEqualObjects(lastRequest.HTTPMethod, @"GET", @"Request without body should be GET");
}

- (void)testRequest_CustomHeaders_AreIncluded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    NSDictionary *customHeaders = @{@"X-Custom-Header": @"custom-value", @"Authorization": @"Bearer token123"};
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:customHeaders
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    NSURLRequest *lastRequest = self.mockSession.lastRequest;
    XCTAssertEqualObjects(lastRequest.allHTTPHeaderFields[@"X-Custom-Header"], @"custom-value", @"Should include custom headers");
    XCTAssertEqualObjects(lastRequest.allHTTPHeaderFields[@"Authorization"], @"Bearer token123", @"Should include custom headers");
    XCTAssertEqualObjects(lastRequest.allHTTPHeaderFields[@"Content-Type"], @"application/json", @"Should include default headers");
}

#pragma mark - MARK: JSON Parsing Tests

- (void)testRequest_InvalidJSON_ReturnsParsingError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    NSData *invalidJSON = [@"not valid json {{{" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mockSession enqueueResponseWithStatusCode:200 data:invalidJSON headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(response, @"Should not have response for invalid JSON");
        XCTAssertNotNil(error, @"Should have JSON parsing error");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testRequest_EmptyResponse_ReturnsNilWithNoError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request completes"];
    
    [self.mockSession enqueueResponseWithStatusCode:200 data:nil headers:nil];
    
    [self.subject executeRequestWithEndpoint:@"/api/test"
                               urlParameters:nil
                                 requestBody:nil
                                     headers:nil
                                  maxRetries:0
                                       delay:0.01
                                  completion:^(id response, NSError *error, BOOL isKillSwitchEnabled) {
        XCTAssertNil(response, @"Empty response should be nil");
        XCTAssertNil(error, @"Empty 200 response should not be error");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
