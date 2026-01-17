/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTrackerImplTests.m
 * @brief Unit tests for CLXMetricsTrackerImpl
 * @details Tests core tracker functionality with mock dependencies
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import "Helper/CLXMockBulkApi.h"

@interface CLXMetricsTrackerImplTests : XCTestCase
@property (nonatomic, strong) CLXMetricsTrackerImpl *tracker;
@property (nonatomic, strong) CLXSQLiteDatabase *testDatabase;
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, strong) CLXMockBulkApi *mockBulkApi;
@end

@implementation CLXMetricsTrackerImplTests

- (void)setUp {
    [super setUp];
    
    // Create isolated test database
    NSString *uniqueDBName = [NSString stringWithFormat:@"test_tracker_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:uniqueDBName];
    [self.testDatabase executeSQL:@"DROP TABLE IF EXISTS metrics_event_table"];
    
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    self.mockBulkApi = [[CLXMockBulkApi alloc] init];
    
    self.tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                           bulkApi:self.mockBulkApi];
    [self.tracker setBasicDataWithSessionId:@"test-session"
                                  accountId:@"test-account"
                                basePayload:@"test-payload"];
}

- (void)tearDown {
    [self.tracker stop];
    self.tracker = nil;
    self.testDatabase = nil;
    self.dao = nil;
    self.mockBulkApi = nil;
    [super tearDown];
}

- (CLXSDKConfig *)createEnabledConfig {
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    
    CLXMetricsConfigSDKAPICalls *sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    sdkAPICalls.enabled = @YES;
    metricsConfig.sdkAPICalls = sdkAPICalls;
    
    CLXMetricsConfigNetworkCalls *networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    networkCalls.enabled = @YES;
    CLXMetricsConfigNetworkSubConfig *bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    bidReq.enabled = @YES;
    networkCalls.bidReq = bidReq;
    metricsConfig.networkCalls = networkCalls;
    
    config.metricsConfig = metricsConfig;
    config.impressionTrackerURL = @"https://test.example.com/track";
    
    return config;
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    XCTAssertNotNil(self.tracker, @"Tracker should be created");
}

- (void)testInitWithDatabaseBulkApi {
    // Verify the injected bulkApi is used
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    XCTAssertGreaterThan(self.mockBulkApi.sendCallCount, 0, @"Injected bulk API should be used");
}

#pragma mark - Type Validation Tests

- (void)testInvalidMethodTypeIsRejected {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    // Track invalid method type
    [self.tracker trackMethodCall:@"invalid_method_type"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Should not store anything for invalid types
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Invalid method types should not be tracked");
}

- (void)testInvalidNetworkTypeIsRejected {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    // Track invalid network type
    [self.tracker trackNetworkCall:@"invalid_network_type" latency:100];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Should not store anything for invalid types
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Invalid network types should not be tracked");
}

- (void)testNilMethodTypeIsHandled {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    // Should not crash with nil
    [self.tracker trackMethodCall:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Nil method types should not be tracked");
}

- (void)testNilNetworkTypeIsHandled {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    // Should not crash with nil
    [self.tracker trackNetworkCall:nil latency:100];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Nil network types should not be tracked");
}

#pragma mark - Latency Handling Tests

- (void)testZeroLatencyIsAccepted {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertNotNil(event, @"Zero latency should be accepted");
    XCTAssertEqual(event.totalLatency, 0, @"Latency should be 0");
}

- (void)testNegativeLatencyIsAccepted {
    // Negative latency might indicate clock issues but should still be tracked
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:-50];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertNotNil(event, @"Negative latency should be accepted");
    XCTAssertEqual(event.totalLatency, -50, @"Latency should be -50");
}

#pragma mark - Lifecycle Tests

- (void)testStopIsIdempotent {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    // Multiple stops should not crash
    [self.tracker stop];
    [self.tracker stop];
    [self.tracker stop];
    
    // Should still be able to restart
    [self.tracker startWithConfig:[self createEnabledConfig]];
    // Test passes if no crash: Multiple stops should not crash
}

- (void)testStartStopCycles {
    CLXSDKConfig *config = [self createEnabledConfig];
    
    // Multiple start/stop cycles
    for (int i = 0; i < 5; i++) {
        [self.tracker startWithConfig:config];
        [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        [self.tracker stop];
    }
    
    // Test passes if no crash: Multiple start/stop cycles should work
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentTracking {
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent tracking completes"];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // Track from multiple threads concurrently
    for (int i = 0; i < 20; i++) {
        dispatch_group_async(group, queue, ^{
            [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
            [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:100];
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    // Test passes if no crash - concurrent tracking should work without corruption
}

#pragma mark - Basic Data Tests

- (void)testSessionIdIsStoredInEvents {
    [self.tracker setBasicDataWithSessionId:@"unique-session-xyz"
                                  accountId:@"test-account"
                                basePayload:@"test-payload"];
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    
    // Allow async operations to complete
    XCTestExpectation *expectation = [self expectationWithDescription:@"Track completes"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertEqualObjects(event.sessionId, @"unique-session-xyz", @"Session ID should be stored");
}

@end
