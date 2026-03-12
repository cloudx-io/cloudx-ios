/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXSessionTracker.h>
#import <CloudXCore/CLXSDKConfig.h>
#import "MockCLXSessionNetworkService.h"

static NSString * const kTestAppKey = @"test-app-key-456";
static NSString * const kTestSessionID = @"session-xyz-789";
static NSString * const kTestAccountID = @"CLDX2_dc";

@interface CLXSessionTrackerTests : XCTestCase
@property (nonatomic, strong) MockCLXSessionNetworkService *mockNetworkService;
@property (nonatomic, strong) CLXSessionTracker *subject;
@end

@implementation CLXSessionTrackerTests

- (void)setUp {
    [super setUp];
    _mockNetworkService = [[MockCLXSessionNetworkService alloc] init];
    _subject = [[CLXSessionTracker alloc] initWithNetworkService:_mockNetworkService];
}

- (void)tearDown {
    _subject = nil;
    _mockNetworkService = nil;
    [super tearDown];
}

#pragma mark - Test Helpers

- (CLXSDKConfigResponse *)configWithSessionID:(NSString *)sessionID
                                    accountID:(NSString *)accountID
                                 deviceConfig:(nullable CLXSDKConfigDeviceConfig *)deviceConfig {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.sessionID = sessionID;
    config.accountID = accountID;
    config.sessionEndpointURL = @"https://session.cloudx.io/session";
    config.deviceConfig = deviceConfig;
    return config;
}

- (CLXSDKConfigResponse *)defaultConfig {
    return [self configWithSessionID:kTestSessionID accountID:kTestAccountID deviceConfig:nil];
}

#pragma mark - Init Event Sending

- (void)testSendInitEvent_ShouldCallNetworkService {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    // Wait for async dispatch
    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqual(_mockNetworkService.sendCallCount, 1, @"Should send one event");
}

- (void)testSendInitEvent_ShouldPassAppKeyToNetworkService {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    // Wait for async dispatch
    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastAppKey, kTestAppKey, @"Should pass app key");
}

#pragma mark - Payload Fields

- (void)testSendInitEvent_PayloadContainsSessionID {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sessionId"], kTestSessionID);
}

- (void)testSendInitEvent_PayloadContainsAccountID {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"accountId"], kTestAccountID);
}

- (void)testSendInitEvent_PayloadContainsEventTypeInit {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"eventType"], @"init");
}

- (void)testSendInitEvent_PayloadContainsDeviceOSiOS {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"deviceOS"], @"iOS");
}

- (void)testSendInitEvent_PayloadContainsAllRequiredFields {
    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then: verify all expected keys are present
    NSDictionary *payload = _mockNetworkService.lastPayload;
    XCTAssertNotNil(payload, @"Payload should not be nil");
    NSArray *requiredKeys = @[
        @"sessionId", @"accountId", @"eventType", @"appBundle",
        @"deviceOS", @"deviceCountry", @"deviceName", @"deviceType",
        @"osVersion", @"deviceIFA", @"sdkVersion", @"test"
    ];
    for (NSString *key in requiredKeys) {
        XCTAssertNotNil(payload[key], @"Payload should contain key: %@", key);
    }
}

#pragma mark - Test Flag

- (void)testSendInitEvent_TestFlagZeroWhenNoDeviceConfig {
    // Given: config without deviceConfig
    CLXSDKConfigResponse *config = [self defaultConfig];
    config.deviceConfig = nil;

    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"test"], @0, @"Test flag should be 0 when no deviceConfig");
}

- (void)testSendInitEvent_TestFlagFromDeviceConfig {
    // Given: config with test mode enabled
    CLXSDKConfigDeviceConfig *deviceConfig = [[CLXSDKConfigDeviceConfig alloc] init];
    deviceConfig.test = 1;
    CLXSDKConfigResponse *config = [self configWithSessionID:kTestSessionID
                                                   accountID:kTestAccountID
                                                deviceConfig:deviceConfig];

    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"test"], @1, @"Test flag should match deviceConfig.test");
}

#pragma mark - Nil / Empty Fields

- (void)testSendInitEvent_NilSessionID_ShouldSendEmptyString {
    // Given: config with nil sessionID
    CLXSDKConfigResponse *config = [self configWithSessionID:nil accountID:kTestAccountID deviceConfig:nil];

    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then: should fall back to empty string, not crash
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sessionId"], @"");
}

- (void)testSendInitEvent_NilAccountID_ShouldSendEmptyString {
    // Given: config with nil accountID
    CLXSDKConfigResponse *config = [self configWithSessionID:kTestSessionID accountID:nil deviceConfig:nil];

    // When
    [_subject sendInitEventWithAppKey:kTestAppKey config:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Then
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"accountId"], @"");
}

#pragma mark - Network Failure

- (void)testSendInitEvent_NetworkFailure_ShouldNotCrash {
    // Given: network service will fail
    _mockNetworkService.shouldSucceed = NO;

    // When / Then: should not crash
    [_subject sendInitEventWithAppKey:kTestAppKey config:[self defaultConfig]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertEqual(_mockNetworkService.sendCallCount, 1, @"Should still attempt to send");
}

@end
