/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsEndToEndTests.m
 * @brief End-to-end integration tests for the complete metrics flow
 * @details Tests full flow from SDK init response parsing through to bulk API call
 *          Uses mock bulk API - NO real network calls
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
#import <CloudXCore/CLXDIContainer.h>
#import "Helper/CLXMockBulkApi.h"

@interface CLXMetricsEndToEndTests : XCTestCase
@property (nonatomic, strong) CLXSQLiteDatabase *testDatabase;
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, strong) CLXMockBulkApi *mockBulkApi;
@property (nonatomic, strong) CLXMetricsTrackerImpl *tracker;
@end

@implementation CLXMetricsEndToEndTests

- (void)setUp {
    [super setUp];
    
    // Create isolated test database
    NSString *uniqueDBName = [NSString stringWithFormat:@"test_e2e_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:uniqueDBName];
    [self.testDatabase executeSQL:@"DROP TABLE IF EXISTS metrics_event_table"];
    
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    self.mockBulkApi = [[CLXMockBulkApi alloc] init];
    
    self.tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                           bulkApi:self.mockBulkApi];
}

- (void)tearDown {
    [self.tracker stop];
    self.tracker = nil;
    self.testDatabase = nil;
    self.dao = nil;
    self.mockBulkApi = nil;
    [super tearDown];
}

#pragma mark - Helper Methods

- (NSDictionary *)createServerResponseWithMetricsEnabled {
    return @{
        @"sendIntervalSeconds": @60,
        @"sdkAPICalls": @{@"enabled": @YES},
        @"networkCalls": @{
            @"enabled": @YES,
            @"bidReq": @{@"enabled": @YES},
            @"initSdkReq": @{@"enabled": @YES},
            @"geoReq": @{@"enabled": @YES}
        }
    };
}

- (NSDictionary *)createServerResponseWithMetricsDisabled {
    return @{
        @"sendIntervalSeconds": @60,
        @"sdkAPICalls": @{@"enabled": @NO},
        @"networkCalls": @{@"enabled": @NO}
    };
}

- (CLXSDKConfig *)createSDKConfigFromServerResponse:(NSDictionary *)metricsResponse {
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    config.metricsConfig = [CLXMetricsConfig fromDictionary:metricsResponse];
    config.impressionTrackerURL = @"https://analytics.cloudx.io/track";
    return config;
}

#pragma mark - End-to-End Flow Tests

- (void)testCompleteFlowWithMetricsEnabled {
    // Simulate complete flow from server response to metrics being sent
    
    // 1. Parse server response
    NSDictionary *serverResponse = [self createServerResponseWithMetricsEnabled];
    CLXSDKConfig *config = [self createSDKConfigFromServerResponse:serverResponse];
    
    // 2. Initialize tracker (simulates SDK init)
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"account-456"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    // 3. Track various metrics (simulates SDK usage)
    [self.tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner]; // Second banner
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:300];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // 4. Verify metrics are stored correctly
    NSArray<CLXMetricsEvent *> *storedEvents = [self.dao getAll];
    XCTAssertEqual(storedEvents.count, 3, @"Should have 3 metric types stored");
    
    CLXMetricsEvent *bannerEvent = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertEqual(bannerEvent.counter, 2, @"Banner should be aggregated to 2");
    
    CLXMetricsEvent *bidEvent = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertEqual(bidEvent.counter, 2, @"Bid requests should be aggregated to 2");
    XCTAssertEqual(bidEvent.totalLatency, 550, @"Latency should be aggregated");
    
    // 5. Send metrics
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // 6. Verify metrics were sent via bulk API
    XCTAssertEqual(self.mockBulkApi.sendCallCount, 1, @"Bulk API should be called once");
    XCTAssertEqual(self.mockBulkApi.sentEvents.count, 3, @"Should send 3 events");
    XCTAssertTrue([self.mockBulkApi.calledEndpoints[0] containsString:@"analytics.cloudx.io"],
                  @"Should use correct endpoint");
    
    // 7. Verify metrics are deleted after successful send
    NSArray<CLXMetricsEvent *> *remainingEvents = [self.dao getAll];
    XCTAssertEqual(remainingEvents.count, 0, @"Metrics should be deleted after send");
}

- (void)testCompleteFlowWithMetricsDisabled {
    // Server returns config with metrics disabled
    NSDictionary *serverResponse = [self createServerResponseWithMetricsDisabled];
    CLXSDKConfig *config = [self createSDKConfigFromServerResponse:serverResponse];
    
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"account-456"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    // Try to track metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Nothing should be stored
    NSArray<CLXMetricsEvent *> *storedEvents = [self.dao getAll];
    XCTAssertEqual(storedEvents.count, 0, @"No metrics should be tracked when disabled");
    
    // Try to send
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Bulk API should not be called
    XCTAssertEqual(self.mockBulkApi.sendCallCount, 0, @"Bulk API should not be called when no metrics");
}

- (void)testCompleteFlowWithNoServerConfig {
    // Simulate server not returning any metrics config (nil)
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    config.metricsConfig = nil;
    config.impressionTrackerURL = @"https://analytics.cloudx.io/track";
    
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"account-456"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    // Try to track metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Nothing should be stored (metrics disabled when config is nil)
    NSArray<CLXMetricsEvent *> *storedEvents = [self.dao getAll];
    XCTAssertEqual(storedEvents.count, 0, @"No metrics should be tracked when config is nil");
}

- (void)testRetryAfterNetworkFailure {
    // Setup enabled config
    NSDictionary *serverResponse = [self createServerResponseWithMetricsEnabled];
    CLXSDKConfig *config = [self createSDKConfigFromServerResponse:serverResponse];
    
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"account-456"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    // Track metrics
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // First send fails
    self.mockBulkApi.shouldSucceed = NO;
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Metrics should still exist
    NSArray<CLXMetricsEvent *> *eventsAfterFailure = [self.dao getAll];
    XCTAssertEqual(eventsAfterFailure.count, 1, @"Metrics should be retained after failed send");
    
    // Second send succeeds
    self.mockBulkApi.shouldSucceed = YES;
    [self.mockBulkApi reset];
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Metrics should now be sent and deleted
    XCTAssertEqual(self.mockBulkApi.sendCallCount, 1, @"Should retry successfully");
    NSArray<CLXMetricsEvent *> *eventsAfterSuccess = [self.dao getAll];
    XCTAssertEqual(eventsAfterSuccess.count, 0, @"Metrics should be deleted after successful retry");
}

- (void)testEventPayloadContainsEncryptedData {
    // Verify the encryption is working
    NSDictionary *serverResponse = [self createServerResponseWithMetricsEnabled];
    CLXSDKConfig *config = [self createSDKConfigFromServerResponse:serverResponse];
    
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"test-account-id"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    [self.tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    [self.tracker trySendingPendingMetrics];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Verify event structure
    CLXEventAM *event = self.mockBulkApi.sentEvents.firstObject;
    XCTAssertNotNil(event.impression, @"Should have encrypted impression");
    XCTAssertNotNil(event.campaignId, @"Should have encrypted campaignId");
    XCTAssertGreaterThan(event.impression.length, 0, @"Impression should not be empty");
    XCTAssertGreaterThan(event.campaignId.length, 0, @"CampaignId should not be empty");
}

- (void)testMixedEnabledDisabledMetricTypes {
    // Only SDK API calls enabled, network calls disabled
    NSDictionary *serverResponse = @{
        @"sendIntervalSeconds": @60,
        @"sdkAPICalls": @{@"enabled": @YES},
        @"networkCalls": @{@"enabled": @NO}
    };
    CLXSDKConfig *config = [self createSDKConfigFromServerResponse:serverResponse];
    
    [self.tracker setBasicDataWithSessionId:@"session-123"
                                  accountId:@"account-456"
                                basePayload:@"ios_sdk"];
    [self.tracker startWithConfig:config];
    
    // Track both types
    [self.tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    // Only method call should be stored
    NSArray<CLXMetricsEvent *> *storedEvents = [self.dao getAll];
    XCTAssertEqual(storedEvents.count, 1, @"Only method calls should be tracked");
    
    CLXMetricsEvent *event = storedEvents.firstObject;
    XCTAssertEqualObjects(event.metricName, CLXMetricsTypeMethodCreateBanner, @"Should be banner metric");
}

@end
