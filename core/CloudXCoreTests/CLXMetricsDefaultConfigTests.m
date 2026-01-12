/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsDefaultConfigTests.m
 * @brief Tests for metrics configuration parsing and enabled/disabled behavior
 * @details Verifies that metrics tracking is correctly enabled/disabled based on server config
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import "Helper/CLXMockBulkApi.h"

@interface CLXMetricsDefaultConfigTests : XCTestCase
@property (nonatomic, strong) CLXSQLiteDatabase *testDatabase;
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, strong) CLXMockBulkApi *mockBulkApi;
@end

@implementation CLXMetricsDefaultConfigTests

- (void)setUp {
    [super setUp];
    
    // Create isolated test database
    NSString *uniqueDBName = [NSString stringWithFormat:@"test_config_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:uniqueDBName];
    
    // Clean state
    [self.testDatabase executeSQL:@"DROP TABLE IF EXISTS metrics_event_table"];
    
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    self.mockBulkApi = [[CLXMockBulkApi alloc] init];
}

- (void)tearDown {
    self.testDatabase = nil;
    self.dao = nil;
    self.mockBulkApi = nil;
    [super tearDown];
}

#pragma mark - Config Nil Tests

- (void)testMetricsDisabledWhenConfigIsNil {
    // Given - A metrics tracker with nil config (simulates server not returning metrics config)
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    // Start with nil config
    [tracker startWithConfig:nil];
    
    // When - Track method calls
    [tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [tracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - No metrics should be stored (tracking is disabled)
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"No metrics should be tracked when config is nil");
    
    [tracker stop];
}

- (void)testMetricsDisabledWhenMetricsConfigIsNil {
    // Given - SDK config exists but metricsConfig is nil
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    sdkConfig.metricsConfig = nil; // Explicitly nil
    sdkConfig.impressionTrackerURL = @"https://test.example.com/t";
    
    [tracker startWithConfig:sdkConfig];
    
    // When - Track method calls
    [tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - No metrics should be stored
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"No metrics should be tracked when metricsConfig is nil");
    
    [tracker stop];
}

#pragma mark - Config Enabled Tests

- (void)testMethodCallMetricsTrackedWhenEnabled {
    // Given - SDK config with sdkAPICalls enabled
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    
    CLXMetricsConfigSDKAPICalls *sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    sdkAPICalls.enabled = @YES;
    metricsConfig.sdkAPICalls = sdkAPICalls;
    
    sdkConfig.metricsConfig = metricsConfig;
    sdkConfig.impressionTrackerURL = @"https://test.example.com/t";
    
    [tracker startWithConfig:sdkConfig];
    
    // When - Track method calls
    [tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [tracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - Metrics should be stored
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 2, @"Method call metrics should be tracked when enabled");
    
    [tracker stop];
}

- (void)testMethodCallMetricsNotTrackedWhenDisabled {
    // Given - SDK config with sdkAPICalls disabled
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    
    CLXMetricsConfigSDKAPICalls *sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    sdkAPICalls.enabled = @NO;
    metricsConfig.sdkAPICalls = sdkAPICalls;
    
    sdkConfig.metricsConfig = metricsConfig;
    sdkConfig.impressionTrackerURL = @"https://test.example.com/t";
    
    [tracker startWithConfig:sdkConfig];
    
    // When - Track method calls
    [tracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - No metrics should be stored (sdkAPICalls is disabled)
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Method call metrics should not be tracked when disabled");
    
    [tracker stop];
}

- (void)testNetworkCallMetricsTrackedWhenEnabled {
    // Given - SDK config with networkCalls and bidReq enabled
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    
    CLXMetricsConfigNetworkCalls *networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    networkCalls.enabled = @YES;
    
    CLXMetricsConfigNetworkSubConfig *bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    bidReq.enabled = @YES;
    networkCalls.bidReq = bidReq;
    
    metricsConfig.networkCalls = networkCalls;
    sdkConfig.metricsConfig = metricsConfig;
    sdkConfig.impressionTrackerURL = @"https://test.example.com/t";
    
    [tracker startWithConfig:sdkConfig];
    
    // When - Track network calls
    [tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    [tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:300];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - Metrics should be stored and aggregated
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertNotNil(event, @"Bid request metrics should be tracked");
    XCTAssertEqual(event.counter, 2, @"Counter should be aggregated");
    XCTAssertEqual(event.totalLatency, 550, @"Latency should be aggregated (250 + 300)");
    
    [tracker stop];
}

- (void)testNetworkCallMetricsNotTrackedWhenGlobalDisabled {
    // Given - networkCalls.enabled is NO
    CLXMetricsTrackerImpl *tracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase
                                                                             bulkApi:self.mockBulkApi];
    [tracker setBasicDataWithSessionId:@"test-session"
                             accountId:@"test-account"
                           basePayload:@"test-payload"];
    
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    
    CLXMetricsConfigNetworkCalls *networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    networkCalls.enabled = @NO; // Global disable
    
    CLXMetricsConfigNetworkSubConfig *bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    bidReq.enabled = @YES; // Even if specific type is enabled
    networkCalls.bidReq = bidReq;
    
    metricsConfig.networkCalls = networkCalls;
    sdkConfig.metricsConfig = metricsConfig;
    sdkConfig.impressionTrackerURL = @"https://test.example.com/t";
    
    [tracker startWithConfig:sdkConfig];
    
    // When - Track network calls
    [tracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - No metrics (global disabled trumps specific enabled)
    NSArray<CLXMetricsEvent *> *events = [self.dao getAll];
    XCTAssertEqual(events.count, 0, @"Network metrics should not be tracked when globally disabled");
    
    [tracker stop];
}

#pragma mark - Config Parsing Tests

- (void)testMetricsConfigFromDictionary {
    // Given - A dictionary representing server response
    NSDictionary *configDict = @{
        @"sendIntervalSeconds": @120,
        @"sdkAPICalls": @{@"enabled": @YES},
        @"networkCalls": @{
            @"enabled": @YES,
            @"bidReq": @{@"enabled": @YES},
            @"initSdkReq": @{@"enabled": @NO},
            @"geoReq": @{@"enabled": @YES}
        }
    };
    
    // When - Parse the config
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:configDict];
    
    // Then - Verify parsing
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqual(config.sendIntervalSeconds, 120, @"Send interval should be parsed");
    XCTAssertTrue([config isSdkApiCallsEnabled], @"SDK API calls should be enabled");
    XCTAssertTrue([config isNetworkCallsEnabled], @"Network calls should be enabled");
    XCTAssertTrue([config isBidRequestNetworkCallsEnabled], @"Bid request calls should be enabled");
    XCTAssertFalse([config isSdkInitNetworkCallsEnabled], @"SDK init calls should be disabled");
    XCTAssertTrue([config isGeoNetworkCallsEnabled], @"Geo calls should be enabled");
}

- (void)testMetricsConfigFromEmptyDictionary {
    // Given - An empty dictionary
    NSDictionary *configDict = @{};
    
    // When - Parse the config
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:configDict];
    
    // Then - Config should exist but features disabled
    XCTAssertNotNil(config, @"Config should be created from empty dictionary");
    XCTAssertFalse([config isSdkApiCallsEnabled], @"SDK API calls should be disabled by default");
    XCTAssertFalse([config isNetworkCallsEnabled], @"Network calls should be disabled by default");
}

@end
