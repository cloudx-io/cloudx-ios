/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXSessionNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import "MockURLSession.h"

static NSString * const kTestAppKey = @"test-app-key-123";
static NSString * const kTestEndpointURL = @"https://session.cloudx.io/session";

@interface CLXSessionNetworkServiceTests : XCTestCase
@property (nonatomic, strong) MockURLSession *mockURLSession;
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXSessionNetworkService *subject;
@end

@implementation CLXSessionNetworkServiceTests

- (void)setUp {
    [super setUp];
    _mockURLSession = [[MockURLSession alloc] init];
    _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:kTestEndpointURL
                                                             urlSession:_mockURLSession];
    _subject = [[CLXSessionNetworkService alloc] initWithBaseNetworkService:_baseNetworkService];
}

- (void)tearDown {
    _subject = nil;
    _baseNetworkService = nil;
    _mockURLSession = nil;
    [super tearDown];
}

#pragma mark - Test Helpers

- (NSDictionary *)samplePayload {
    return @{
        @"sessionId": @"session-abc",
        @"accountId": @"CLDX2_dc",
        @"eventType": @"init",
        @"appBundle": @"com.test.app",
        @"deviceOS": @"iOS",
        @"deviceCountry": @"US",
        @"deviceName": @"iPhone",
        @"deviceType": @"mobile",
        @"osVersion": @"17.0",
        @"deviceIFA": @"00000000-0000-0000-0000-000000000000",
        @"sdkVersion": @"2.2.0",
        @"test": @0,
    };
}

#pragma mark - Success Tests

- (void)testSend_Success_ShouldCallCompletionWithTrue {
    // Given
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:@{@"status": @"ok"} options:0 error:nil];
    [_mockURLSession enqueueResponseWithStatusCode:200 data:responseData];

    // When
    __block BOOL completionCalled = NO;
    __block BOOL completionSuccess = NO;
    [_subject sendWithAppKey:kTestAppKey
                     payload:[self samplePayload]
                  completion:^(BOOL success, NSError * _Nullable error) {
        completionCalled = YES;
        completionSuccess = success;
    }];

    // Then
    XCTAssertTrue(completionCalled, @"Completion should be called");
    XCTAssertTrue(completionSuccess, @"Should succeed with 200 response");
}

- (void)testSend_ShouldSetBearerAuthorizationHeader {
    // Given
    [_mockURLSession enqueueResponseWithStatusCode:200 data:nil];

    // When
    [_subject sendWithAppKey:kTestAppKey payload:[self samplePayload] completion:nil];

    // Then
    XCTAssertEqual(_mockURLSession.callCount, 1, @"Should make one request");
    NSURLRequest *request = _mockURLSession.lastRequest;
    NSString *authHeader = [request valueForHTTPHeaderField:@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Bearer test-app-key-123", @"Should set Bearer auth with app key");
}

- (void)testSend_ShouldSetContentTypeJSON {
    // Given
    [_mockURLSession enqueueResponseWithStatusCode:200 data:nil];

    // When
    [_subject sendWithAppKey:kTestAppKey payload:[self samplePayload] completion:nil];

    // Then
    NSURLRequest *request = _mockURLSession.lastRequest;
    NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
    XCTAssertEqualObjects(contentType, @"application/json", @"Should set Content-Type to application/json");
}

- (void)testSend_ShouldSerializePayloadAsJSON {
    // Given
    [_mockURLSession enqueueResponseWithStatusCode:200 data:nil];
    NSDictionary *payload = [self samplePayload];

    // When
    [_subject sendWithAppKey:kTestAppKey payload:payload completion:nil];

    // Then
    NSURLRequest *request = _mockURLSession.lastRequest;
    XCTAssertNotNil(request.HTTPBody, @"Request should have a body");

    NSDictionary *sentBody = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    XCTAssertEqualObjects(sentBody[@"sessionId"], @"session-abc");
    XCTAssertEqualObjects(sentBody[@"eventType"], @"init");
    XCTAssertEqualObjects(sentBody[@"deviceOS"], @"iOS");
}

#pragma mark - Error Tests

- (void)testSend_NetworkError_ShouldCallCompletionWithFalse {
    // Given: Enqueue two errors (initial + 1 retry)
    NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain code:-1009 userInfo:nil];
    [_mockURLSession enqueueError:networkError];
    [_mockURLSession enqueueError:networkError];

    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion called"];
    __block BOOL completionSuccess = YES;
    __block NSError *completionError = nil;
    [_subject sendWithAppKey:kTestAppKey
                     payload:[self samplePayload]
                  completion:^(BOOL success, NSError * _Nullable error) {
        completionSuccess = success;
        completionError = error;
        [expectation fulfill];
    }];

    // Then: wait for retry delay + completion
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertFalse(completionSuccess, @"Should fail on network error");
    XCTAssertNotNil(completionError, @"Should pass error to completion");
}

- (void)testSend_NilCompletion_ShouldNotCrash {
    // Given
    [_mockURLSession enqueueResponseWithStatusCode:200 data:nil];

    // When / Then — should not crash
    [_subject sendWithAppKey:kTestAppKey payload:[self samplePayload] completion:nil];
    XCTAssertEqual(_mockURLSession.callCount, 1, @"Should still make the request");
}

#pragma mark - Retry Tests

- (void)testSend_FirstFailThenSucceed_ShouldRetry {
    // Given: First request fails (500), retry succeeds (200)
    [_mockURLSession enqueueResponseWithStatusCode:500 data:nil];
    NSData *successData = [NSJSONSerialization dataWithJSONObject:@{@"status": @"ok"} options:0 error:nil];
    [_mockURLSession enqueueResponseWithStatusCode:200 data:successData];

    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"retry completion"];
    __block BOOL completionSuccess = NO;
    [_subject sendWithAppKey:kTestAppKey
                     payload:[self samplePayload]
                  completion:^(BOOL success, NSError * _Nullable error) {
        completionSuccess = success;
        [expectation fulfill];
    }];

    // Then: wait for retry delay + completion
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqual(_mockURLSession.callCount, 2, @"Should retry once after failure");
    XCTAssertTrue(completionSuccess, @"Should succeed on retry");
}

@end
