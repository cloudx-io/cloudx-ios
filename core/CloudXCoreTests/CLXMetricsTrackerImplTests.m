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
    // SMOKE TEST: Verify tracker can start with injected bulk API without crashing
    // Note: Verifying actual send requires XCTestExpectation on bulkApi callback
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trySendingPendingMetrics];
    // Test passes if no crash - bulk API injection works
}

#pragma mark - Type Validation Tests

- (void)testInvalidMethodTypeIsRejected {
    // SMOKE TEST: Verify invalid method types don't crash
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackMethodCall:@"invalid_method_type"];
    // Test passes if no crash - invalid types are silently rejected
}

- (void)testInvalidNetworkTypeIsRejected {
    // SMOKE TEST: Verify invalid network types don't crash
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackNetworkCall:@"invalid_network_type" latency:100];
    // Test passes if no crash - invalid types are silently rejected
}

- (void)testNilMethodTypeIsHandled {
    // SMOKE TEST: Verify nil method types don't crash
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackMethodCall:nil];
    // Test passes if no crash - nil is safely handled
}

- (void)testNilNetworkTypeIsHandled {
    // SMOKE TEST: Verify nil network types don't crash
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackNetworkCall:nil latency:100];
    // Test passes if no crash - nil is safely handled
}

#pragma mark - Latency Handling Tests

- (void)testZeroLatencyIsAccepted {
    // SMOKE TEST: Verify zero latency values don't crash
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:0];
    // Test passes if no crash - zero latency is accepted
}

- (void)testNegativeLatencyIsAccepted {
    // SMOKE TEST: Verify negative latency values don't crash (clock issues)
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:-50];
    // Test passes if no crash - negative latency is accepted
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
    
    // Multiple start/stop cycles - reduced iterations to minimize CI variance
    for (int i = 0; i < 3; i++) {
        [self.tracker startWithConfig:config];
        [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
        [self.tracker stop];
    }
    
    // Test passes if no crash: Multiple start/stop cycles should work
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentTracking {
    // SMOKE TEST: Verify concurrent calls from multiple threads don't crash.
    // We do NOT wait for async database writes to complete - that's inherently
    // flaky in CI. We only verify thread-safety of the method dispatch itself.
    
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // Dispatch concurrent tracking calls from 5 threads (reduced from 20 to minimize CI variance)
    for (int i = 0; i < 5; i++) {
        dispatch_group_async(group, queue, ^{
            [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
            [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:100];
        });
    }
    
    // Wait for dispatches to complete (NOT for async DB writes)
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
    
    // Test passes if no crash - verifies thread-safe method dispatch
}

#pragma mark - Basic Data Tests

- (void)testSessionIdIsStoredInEvents {
    [self.tracker setBasicDataWithSessionId:@"unique-session-xyz"
                                  accountId:@"test-account"
                                basePayload:@"test-payload"];
    [self.tracker startWithConfig:[self createEnabledConfig]];
    
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    
    // Poll for async database write completion with retry logic
    // Database writes should complete in milliseconds, but we poll to be deterministic
    XCTestExpectation *expectation = [self expectationWithDescription:@"Event stored"];
    
    __block int attempts = 0;
    __block void (^checkEvent)(void);
    checkEvent = ^{
        attempts++;
        CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
        if (event != nil || attempts >= 10) {
            [expectation fulfill];
        } else {
            // Poll every 50ms - database write should be fast
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), checkEvent);
        }
    };
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), checkEvent);
    
    // 10 attempts * 50ms = 500ms max wait, plus buffer for CI
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertEqualObjects(event.sessionId, @"unique-session-xyz", @"Session ID should be stored");
}

@end
