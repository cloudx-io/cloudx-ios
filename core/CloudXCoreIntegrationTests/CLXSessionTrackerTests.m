/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 *
 * CLXSessionTrackerTests (Integration)
 *
 * Lives in the integration test target because the production code
 * dispatches to a background queue via dispatch_async and accesses
 * CLXSystemInformation singleton, which causes flaky failures under
 * parallel unit test execution.
 *
 * Uses the mock's onSendCalled callback to fulfill expectations
 * deterministically instead of dispatch_after timing.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXSessionTracker.h>
#import <CloudXCore/CLXSDKConfig.h>
#import "../CloudXCoreTests/Mocks/MockCLXSessionNetworkService.h"

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

#pragma mark - Helpers

- (CLXSDKConfigResponse *)configWithSessionID:(nullable NSString *)sessionID
                                    accountID:(nullable NSString *)accountID
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

- (void)sendInitEventAndWaitWithConfig:(CLXSDKConfigResponse *)config {
    XCTestExpectation *expectation = [self expectationWithDescription:@"mock received send"];
    _mockNetworkService.onSendCalled = ^{
        [expectation fulfill];
    };

    [_subject sendInitEventWithAppKey:kTestAppKey config:config];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Init Event Sending

- (void)testSendInitEvent_ShouldCallNetworkService {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqual(_mockNetworkService.sendCallCount, 1, @"Should send one event");
}

- (void)testSendInitEvent_ShouldPassAppKeyToNetworkService {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqualObjects(_mockNetworkService.lastAppKey, kTestAppKey, @"Should pass app key");
}

#pragma mark - Payload Fields

- (void)testSendInitEvent_PayloadContainsSessionID {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sessionId"], kTestSessionID);
}

- (void)testSendInitEvent_PayloadContainsAccountID {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"accountId"], kTestAccountID);
}

- (void)testSendInitEvent_PayloadContainsEventTypeInit {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"eventType"], @"init");
}

- (void)testSendInitEvent_PayloadContainsDeviceOSiOS {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"deviceOS"], @"iOS");
}

- (void)testSendInitEvent_PayloadContainsAllRequiredFields {
    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

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
    CLXSDKConfigResponse *config = [self defaultConfig];
    config.deviceConfig = nil;

    [self sendInitEventAndWaitWithConfig:config];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"test"], @0,
                          @"Test flag should be 0 when no deviceConfig");
}

- (void)testSendInitEvent_TestFlagFromDeviceConfig {
    CLXSDKConfigDeviceConfig *deviceConfig = [[CLXSDKConfigDeviceConfig alloc] init];
    deviceConfig.test = 1;
    CLXSDKConfigResponse *config = [self configWithSessionID:kTestSessionID
                                                   accountID:kTestAccountID
                                                deviceConfig:deviceConfig];

    [self sendInitEventAndWaitWithConfig:config];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"test"], @1,
                          @"Test flag should match deviceConfig.test");
}

#pragma mark - Nil / Empty Fields

- (void)testSendInitEvent_NilSessionID_ShouldSendEmptyString {
    CLXSDKConfigResponse *config = [self configWithSessionID:nil accountID:kTestAccountID deviceConfig:nil];

    [self sendInitEventAndWaitWithConfig:config];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sessionId"], @"");
}

- (void)testSendInitEvent_NilAccountID_ShouldSendEmptyString {
    CLXSDKConfigResponse *config = [self configWithSessionID:kTestSessionID accountID:nil deviceConfig:nil];

    [self sendInitEventAndWaitWithConfig:config];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"accountId"], @"");
}

#pragma mark - Network Failure

- (void)testSendInitEvent_NetworkFailure_ShouldNotCrash {
    _mockNetworkService.shouldSucceed = NO;

    [self sendInitEventAndWaitWithConfig:[self defaultConfig]];

    XCTAssertEqual(_mockNetworkService.sendCallCount, 1, @"Should still attempt to send");
}

@end
