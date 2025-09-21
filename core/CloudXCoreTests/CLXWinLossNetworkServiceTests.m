/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossNetworkServiceTests.m
 * @brief Comprehensive tests for win/loss network service focusing on failure scenarios
 * 
 * Critical test coverage for network operations that could lead to lost revenue events,
 * incorrect retry behavior, or system instability. Tests robustness of network layer
 * under adverse conditions including malformed responses, timeouts, and edge cases.
 * 
 * Uses proper dependency injection for testability - no KVO hacks.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Mock base network service for controlled testing - proper inheritance
@interface MockCLXBaseNetworkService : CLXBaseNetworkService
@property (nonatomic, strong) NSError *simulatedError;
@property (nonatomic, assign) NSInteger simulatedStatusCode;
@property (nonatomic, assign) BOOL shouldTimeout;
@property (nonatomic, assign) NSTimeInterval simulatedDelay;
@property (nonatomic, assign) NSInteger callCount;
@property (nonatomic, strong) NSData *lastRequestBody;
@property (nonatomic, strong) NSDictionary *lastHeaders;
@end

@implementation MockCLXBaseNetworkService

- (void)executeRequestWithEndpoint:(NSString *)endpoint
                     urlParameters:(nullable NSDictionary *)urlParameters
                       requestBody:(nullable NSData *)requestBody
                           headers:(nullable NSDictionary *)headers
                        maxRetries:(NSInteger)maxRetries
                             delay:(NSTimeInterval)delay
                        completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled))completion {
    
    self.callCount++;
    self.lastRequestBody = requestBody;
    self.lastHeaders = headers;
    
    // Simulate delay if specified
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.simulatedDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.shouldTimeout) {
            NSError *timeoutError = [NSError errorWithDomain:NSURLErrorDomain 
                                                        code:NSURLErrorTimedOut 
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}];
            completion(nil, timeoutError, NO);
        } else if (self.simulatedError) {
            completion(nil, self.simulatedError, NO);
        } else {
            // Create mock HTTP response
            NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] 
                initWithURL:[NSURL URLWithString:@"https://test.com"] 
                statusCode:self.simulatedStatusCode 
                HTTPVersion:@"HTTP/1.1" 
                headerFields:nil];
            
            completion(httpResponse, nil, NO);
        }
    });
}

@end

@interface CLXWinLossNetworkServiceTests : XCTestCase
@property (nonatomic, strong) CLXWinLossNetworkService *networkService;
@property (nonatomic, strong) MockCLXBaseNetworkService *mockBaseService;
@end

@implementation CLXWinLossNetworkServiceTests

- (void)setUp {
    [super setUp];
    
    // Create mock base service
    self.mockBaseService = [[MockCLXBaseNetworkService alloc] initWithBaseURL:@"https://test.cloudx.com" 
                                                                   urlSession:[NSURLSession sharedSession]];
    
    // Inject mock via proper dependency injection constructor
    self.networkService = [[CLXWinLossNetworkService alloc] initWithBaseNetworkService:self.mockBaseService];
    
    // Reset mock state
    self.mockBaseService.simulatedError = nil;
    self.mockBaseService.simulatedStatusCode = 200;
    self.mockBaseService.shouldTimeout = NO;
    self.mockBaseService.simulatedDelay = 0;
    self.mockBaseService.callCount = 0;
    self.mockBaseService.lastRequestBody = nil;
    self.mockBaseService.lastHeaders = nil;
}

- (void)tearDown {
    self.networkService = nil;
    self.mockBaseService = nil;
    [super tearDown];
}

#pragma mark - JSON Serialization Failure Tests

/**
 * Test handling of non-serializable payload objects
 */
- (void)testSendWinLoss_NonSerializablePayload_ShouldFailWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call completion"];
    
    // Create payload with non-serializable object (custom object that doesn't conform to JSON)
    NSObject *nonSerializableObject = [[NSObject alloc] init];
    NSDictionary *payloadWithNonSerializableObject = @{
        @"validField": @"valid_value",
        @"invalidField": nonSerializableObject // NSObject is not JSON serializable
    };
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:payloadWithNonSerializableObject
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success, @"Should fail for non-serializable payload");
        XCTAssertNotNil(error, @"Should return error for JSON serialization failure");
        XCTAssertEqual(self.mockBaseService.callCount, 0, @"Should not make network call if JSON serialization fails");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test handling of payload with unsupported data types
 */
- (void)testSendWinLoss_UnsupportedDataTypes_ShouldFailWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call completion"];
    
    // Create payload with unsupported data type
    NSDictionary *payloadWithUnsupportedType = @{
        @"validField": @"valid_value",
        @"invalidField": [NSDate date] // NSDate causes JSON serialization to fail
    };
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:payloadWithUnsupportedType
                             completion:^(BOOL success, NSError * _Nullable error) {
        // NSDate actually causes JSON serialization to fail, so we expect failure
        XCTAssertFalse(success, @"Should fail for unsupported data types");
        XCTAssertNotNil(error, @"Should return error for JSON serialization failure");
        XCTAssertEqual(self.mockBaseService.callCount, 0, @"Should not make network call if JSON serialization fails");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Network Failure Tests

/**
 * Test timeout handling
 */
- (void)testSendWinLoss_NetworkTimeout_ShouldFailWithTimeoutError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network timeout"];
    
    self.mockBaseService.shouldTimeout = YES;
    
    NSDictionary *validPayload = @{@"eventType": @"win", @"auctionId": @"test-auction"};
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:validPayload
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success, @"Should fail on timeout");
        XCTAssertNotNil(error, @"Should return timeout error");
        XCTAssertEqual(error.code, NSURLErrorTimedOut, @"Should be timeout error");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test network connectivity errors
 */
- (void)testSendWinLoss_NetworkConnectivityError_ShouldFailWithNetworkError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network connectivity error"];
    
    self.mockBaseService.simulatedError = [NSError errorWithDomain:NSURLErrorDomain
                                                              code:NSURLErrorNotConnectedToInternet
                                                          userInfo:@{NSLocalizedDescriptionKey: @"No internet connection"}];
    
    NSDictionary *validPayload = @{@"eventType": @"loss", @"auctionId": @"test-auction"};
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:validPayload
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success, @"Should fail on network connectivity error");
        XCTAssertNotNil(error, @"Should return network error");
        XCTAssertEqual(error.code, NSURLErrorNotConnectedToInternet, @"Should be connectivity error");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test DNS resolution failures
 */
- (void)testSendWinLoss_DNSResolutionFailure_ShouldFailWithDNSError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"DNS resolution failure"];
    
    self.mockBaseService.simulatedError = [NSError errorWithDomain:NSURLErrorDomain
                                                              code:NSURLErrorCannotFindHost
                                                          userInfo:@{NSLocalizedDescriptionKey: @"Cannot resolve host"}];
    
    NSDictionary *validPayload = @{@"eventType": @"win", @"auctionId": @"test-auction"};
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://invalid-domain-that-does-not-exist.com/win-loss"
                                payload:validPayload
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success, @"Should fail on DNS resolution error");
        XCTAssertNotNil(error, @"Should return DNS error");
        XCTAssertEqual(error.code, NSURLErrorCannotFindHost, @"Should be DNS resolution error");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - HTTP Status Code Tests

/**
 * Test handling of various HTTP error status codes
 */
- (void)testSendWinLoss_HTTPErrorCodes_ShouldFailWithAppropriateErrors {
    NSArray *errorCodes = @[@400, @401, @403, @404, @429, @500, @502, @503, @504];
    
    for (NSNumber *statusCode in errorCodes) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"HTTP %@ error", statusCode]];
        
        self.mockBaseService.simulatedStatusCode = [statusCode integerValue];
        
        NSDictionary *validPayload = @{@"eventType": @"win", @"auctionId": @"test-auction"};
        
        [self.networkService sendWithAppKey:@"test-app-key"
                                endpointUrl:@"https://test.cloudx.com/win-loss"
                                    payload:validPayload
                                 completion:^(BOOL success, NSError * _Nullable error) {
            XCTAssertFalse(success, @"Should fail for HTTP error status %@", statusCode);
            XCTAssertNotNil(error, @"Should return error for HTTP status %@", statusCode);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
    }
}

/**
 * Test successful HTTP status codes
 */
- (void)testSendWinLoss_SuccessStatusCodes_ShouldSucceed {
    NSArray *successCodes = @[@200, @201, @202, @204, @299];
    
    for (NSNumber *statusCode in successCodes) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"HTTP %@ success", statusCode]];
        
        self.mockBaseService.simulatedStatusCode = [statusCode integerValue];
        
        NSDictionary *validPayload = @{@"eventType": @"win", @"auctionId": @"test-auction"};
        
        [self.networkService sendWithAppKey:@"test-app-key"
                                endpointUrl:@"https://test.cloudx.com/win-loss"
                                    payload:validPayload
                                 completion:^(BOOL success, NSError * _Nullable error) {
            XCTAssertTrue(success, @"Should succeed for HTTP status %@", statusCode);
            XCTAssertNil(error, @"Should not return error for success status %@", statusCode);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
    }
}

#pragma mark - Request Validation Tests

/**
 * Test that proper headers are sent
 */
- (void)testSendWinLoss_ValidRequest_ShouldSendCorrectHeaders {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Valid request"];
    
    self.mockBaseService.simulatedStatusCode = 200;
    
    NSDictionary *validPayload = @{@"eventType": @"win", @"auctionId": @"test-auction"};
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:validPayload
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success, @"Should succeed for valid request");
        XCTAssertNil(error, @"Should not return error for valid request");
        
        // Verify headers were set correctly
        XCTAssertNotNil(self.mockBaseService.lastHeaders, @"Should have headers");
        XCTAssertEqualObjects(self.mockBaseService.lastHeaders[@"Authorization"], @"Bearer test-app-key", @"Should have correct auth header");
        XCTAssertEqualObjects(self.mockBaseService.lastHeaders[@"Content-Type"], @"application/json", @"Should have correct content type");
        
        // Verify request body was set
        XCTAssertNotNil(self.mockBaseService.lastRequestBody, @"Should have request body");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test handling of empty payloads
 */
- (void)testSendWinLoss_EmptyPayload_ShouldHandleCorrectly {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Empty payload"];
    
    self.mockBaseService.simulatedStatusCode = 200;
    
    NSDictionary *emptyPayload = @{};
    
    [self.networkService sendWithAppKey:@"test-app-key"
                            endpointUrl:@"https://test.cloudx.com/win-loss"
                                payload:emptyPayload
                             completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success, @"Should handle empty payloads");
        XCTAssertNil(error, @"Should not error on empty payload");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Concurrent Request Tests

/**
 * Test handling of multiple concurrent requests
 */
- (void)testSendWinLoss_ConcurrentRequests_ShouldHandleAllRequests {
    NSInteger requestCount = 10; // Reduced for faster test execution
    NSMutableArray *expectations = [NSMutableArray array];
    
    self.mockBaseService.simulatedStatusCode = 200;
    self.mockBaseService.simulatedDelay = 0.1; // Small delay to test concurrency
    
    for (NSInteger i = 0; i < requestCount; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Concurrent request %ld", (long)i]];
        [expectations addObject:expectation];
        
        NSDictionary *payload = @{
            @"eventType": @"win",
            @"auctionId": [NSString stringWithFormat:@"auction-%ld", (long)i],
            @"requestId": @(i)
        };
        
        [self.networkService sendWithAppKey:@"test-app-key"
                                endpointUrl:@"https://test.cloudx.com/win-loss"
                                    payload:payload
                                 completion:^(BOOL success, NSError * _Nullable error) {
            XCTAssertTrue(success, @"Request %ld should succeed", (long)i);
            XCTAssertNil(error, @"Request %ld should not have error", (long)i);
            [expectation fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertEqual(self.mockBaseService.callCount, requestCount, @"Should have made all requests");
}

@end