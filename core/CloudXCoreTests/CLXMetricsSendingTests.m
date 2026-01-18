/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsSendingTests.m
 * @brief Tests verifying metrics are actually sent via bulk API
 * @details Uses mock bulk API with XCTestExpectation for reliable async synchronization
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXEventAM.h>
#import "Helper/CLXMockBulkApi.h"

/**
 * Category to expose private testing method for flushing pending operations.
 */
@interface CLXMetricsTrackerImpl (Testing)
- (void)flushPendingOperations;
@end

@interface CLXMetricsSendingTests : XCTestCase
@property (nonatomic, strong) CLXSQLiteDatabase *testDatabase;
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, strong) CLXMockBulkApi *mockBulkApi;
@property (nonatomic, strong) CLXMetricsTrackerImpl *tracker;
@property (nonatomic, copy) NSString *uniqueDBName;
@end

@implementation CLXMetricsSendingTests

- (void)setUp {
    [super setUp];
    
    // Create isolated test database with UUID to avoid any cross-test contamination
    self.uniqueDBName = [NSString stringWithFormat:@"test_sending_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:self.uniqueDBName];
    
    // Clean state - drop existing table to ensure fresh state
    [self.testDatabase executeSQL:@"DROP TABLE IF EXISTS metrics_event_table"];
    
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    self.mockBulkApi = [[CLXMockBulkApi alloc] init];
    
    // Create tracker with mock bulk API
    self.tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                           bulkApi:self.mockBulkApi];
    [self.tracker setBasicDataWithSessionId:@"test-session-123"
                                  accountId:@"test-account-456"
                                basePayload:@"ios_sdk"];
    
    // Flush to ensure setBasicData completes before tests start
    [self.tracker flushPendingOperations];
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
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sendIntervalSeconds = 1; // Fast interval for testing
    
    CLXMetricsConfigSDKAPICalls *sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    sdkAPICalls.enabled = @YES;
    metricsConfig.sdkAPICalls = sdkAPICalls;
    
    CLXMetricsConfigNetworkCalls *networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    networkCalls.enabled = @YES;
    CLXMetricsConfigNetworkSubConfig *bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    bidReq.enabled = @YES;
    networkCalls.bidReq = bidReq;
    metricsConfig.networkCalls = networkCalls;
    
    sdkConfig.metricsConfig = metricsConfig;
    sdkConfig.impressionTrackerURL = @"https://test.example.com/track";
    
    return sdkConfig;
}

#pragma mark - Sending Tests

- (void)testMetricsAreSentViaBulkApi {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Bulk API should be called"];
    
    __weak typeof(self) weakSelf = self;
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with enabled config
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    
    // When - Track some metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    [self.tracker flushPendingOperations];
    
    // Trigger sending
    [self.tracker trySendingPendingMetrics];
    
    // Wait for async sending to complete
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Then - Bulk API should have been called
    XCTAssertEqual(weakSelf.mockBulkApi.sendCallCount, 1, @"Bulk API should be called once");
    XCTAssertEqual(weakSelf.mockBulkApi.sentEvents.count, 2, @"Should send 2 events");
}

- (void)testCorrectEndpointIsCalled {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Endpoint should be called"];
    
    __weak typeof(self) weakSelf = self;
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with specific endpoint
    CLXSDKConfig *config = [self createEnabledConfig];
    config.impressionTrackerURL = @"https://analytics.cloudx.io/track";
    [self.tracker startWithConfig:config];
    [self.tracker flushPendingOperations];
    
    // When - Track and send
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker flushPendingOperations];
    [self.tracker trySendingPendingMetrics];
    
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Then - Correct endpoint should be called
    XCTAssertEqual(weakSelf.mockBulkApi.calledEndpoints.count, 1, @"Should call one endpoint");
    XCTAssertTrue([weakSelf.mockBulkApi.calledEndpoints[0] containsString:@"analytics.cloudx.io"],
                  @"Should call the configured endpoint");
}

- (void)testEventPayloadStructure {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Event should be sent"];
    
    __weak typeof(self) weakSelf = self;
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with enabled config
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    
    // When - Track a specific metric
    [self.tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [self.tracker flushPendingOperations];
    [self.tracker trySendingPendingMetrics];
    
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Then - Event should have correct structure
    XCTAssertEqual(weakSelf.mockBulkApi.sentEvents.count, 1, @"Should have one event");
    
    CLXEventAM *event = weakSelf.mockBulkApi.sentEvents.firstObject;
    XCTAssertNotNil(event, @"Event should not be nil");
    XCTAssertNotNil(event.impression, @"Event should have impression");
    XCTAssertNotNil(event.campaignId, @"Event should have campaignId");
    XCTAssertEqualObjects(event.eventName, @"SDK_METRICS", @"Event name should be SDK_METRICS");
    XCTAssertEqualObjects(event.type, @"SDK_METRICS", @"Event type should be SDK_METRICS");
}

- (void)testMetricsDeletedAfterSuccessfulSend {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Send should complete"];
    
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with enabled config
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    self.mockBulkApi.shouldSucceed = YES;
    
    // When - Track metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker flushPendingOperations];
    
    // Verify metrics exist before send
    NSArray<CLXMetricsEvent *> *eventsBefore = [self.dao getAll];
    XCTAssertEqual(eventsBefore.count, 1, @"Should have metrics before send");
    
    // Send
    [self.tracker trySendingPendingMetrics];
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Allow async deletion to complete
    [self.tracker flushPendingOperations];
    
    // Then - Metrics should be deleted after successful send
    NSArray<CLXMetricsEvent *> *eventsAfter = [self.dao getAll];
    XCTAssertEqual(eventsAfter.count, 0, @"Metrics should be deleted after successful send");
}

- (void)testMetricsRetainedAfterFailedSend {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Send should complete"];
    
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with enabled config and failing bulk API
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    self.mockBulkApi.shouldSucceed = NO;
    
    // When - Track metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker flushPendingOperations];
    
    // Verify metrics exist before send
    NSArray<CLXMetricsEvent *> *eventsBefore = [self.dao getAll];
    XCTAssertEqual(eventsBefore.count, 1, @"Should have metrics before send");
    
    // Send (will fail)
    [self.tracker trySendingPendingMetrics];
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Allow async to complete
    [self.tracker flushPendingOperations];
    
    // Then - Metrics should be retained for retry
    NSArray<CLXMetricsEvent *> *eventsAfter = [self.dao getAll];
    XCTAssertEqual(eventsAfter.count, 1, @"Metrics should be retained after failed send");
}

- (void)testNoSendWhenNoMetrics {
    // Given - Tracker with enabled config but no tracked metrics
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    
    // When - Try to send without tracking anything
    [self.tracker trySendingPendingMetrics];
    [self.tracker flushPendingOperations];
    
    // Then - Bulk API should not be called (flushPendingOperations synchronizes internal queue)
    XCTAssertEqual(self.mockBulkApi.sendCallCount, 0, @"Should not call bulk API when no metrics");
}

- (void)testNoSendWhenNoEndpoint {
    // Given - Config without endpoint
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    CLXMetricsConfigSDKAPICalls *sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    sdkAPICalls.enabled = @YES;
    metricsConfig.sdkAPICalls = sdkAPICalls;
    sdkConfig.metricsConfig = metricsConfig;
    // No impressionTrackerURL or metricsEndpointURL
    
    [self.tracker startWithConfig:sdkConfig];
    [self.tracker flushPendingOperations];
    
    // When - Track metrics and try to send
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker flushPendingOperations];
    [self.tracker trySendingPendingMetrics];
    [self.tracker flushPendingOperations];
    
    // Then - Should not send (no endpoint) - flushPendingOperations synchronizes internal queue
    XCTAssertEqual(self.mockBulkApi.sendCallCount, 0, @"Should not send when no endpoint configured");
}

- (void)testMetricsAggregation {
    // Create expectation for async send completion
    XCTestExpectation *sendExpectation = [self expectationWithDescription:@"Send should complete"];
    
    __weak typeof(self) weakSelf = self;
    self.mockBulkApi.onSendCalled = ^{
        [sendExpectation fulfill];
    };
    
    // Given - Tracker with enabled config
    [self.tracker startWithConfig:[self createEnabledConfig]];
    [self.tracker flushPendingOperations];
    
    // When - Track same metric multiple times
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker flushPendingOperations];
    
    [self.tracker trySendingPendingMetrics];
    [self waitForExpectations:@[sendExpectation] timeout:5.0];
    
    // Then - Should send one aggregated event, not three separate events
    XCTAssertEqual(weakSelf.mockBulkApi.sentEvents.count, 1, @"Should aggregate into single event");
}

@end
