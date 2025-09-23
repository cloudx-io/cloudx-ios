/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXEventAM.h>

@interface CLXMetricsIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXMetricsTrackerImpl *metricsTracker;
@property (nonatomic, strong) CLXSQLiteDatabase *testDatabase;
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, copy) NSString *testDatabasePath;
@end

@implementation CLXMetricsIntegrationTests

- (void)setUp {
    [super setUp];
    
    // COMPLETE TEST ISOLATION: Unique database per test run
    NSString *uniqueDBName = [NSString stringWithFormat:@"test_metrics_integration_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:uniqueDBName];
    
    // ENSURE CLEAN STATE: Initialize DAO and verify empty database
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    
    // AGGRESSIVE CLEANUP: Drop and recreate table to ensure complete isolation
    [self.testDatabase executeSQL:@"DROP TABLE IF EXISTS metrics_event_table"];
    
    // Force table recreation
    CLXMetricsEventDao *freshDao = [[CLXMetricsEventDao alloc] initWithDatabase:self.testDatabase];
    self.dao = freshDao;
    
    self.metricsTracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.testDatabase];
    
    // Set up basic data
    [self.metricsTracker setBasicDataWithSessionId:@"test-session-123"
                                         accountId:@"test-account-456"
                                       basePayload:@"test-base-payload"];
}

- (void)tearDown {
    @try {
        [self.metricsTracker stop];
    } @catch (NSException *exception) {
        NSLog(@"Exception during metrics tracker stop: %@", exception);
    }
    
    // COMPLETE CLEANUP: Delete all metrics from database
    @try {
        if (self.dao) {
            NSArray<CLXMetricsEvent *> *allEvents = [self.dao getAll];
            for (CLXMetricsEvent *event in allEvents) {
                [self.dao deleteById:event.eventId];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception during metrics cleanup: %@", exception);
    }
    
    // Clean up test database
    if (self.testDatabasePath) {
        [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    }
    
    self.metricsTracker = nil;
    self.testDatabase = nil;
    self.dao = nil;
    self.testDatabasePath = nil;
    [super tearDown];
}

- (void)testEndToEndMethodCallTracking {
    // Given - start the metrics tracker with impression URL
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    config.metricsConfig = metricsConfig;
    config.impressionTrackerURL = @"https://test-impression.example.com/t"; // Test impression URL usage
    
    [self.metricsTracker startWithConfig:config];
    
    // When - track multiple method calls
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner]; // Same method again
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - verify metrics are persisted correctly
    CLXMetricsEvent *bannerEvent = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertNotNil(bannerEvent);
    XCTAssertEqualObjects(bannerEvent.metricName, CLXMetricsTypeMethodCreateBanner);
    XCTAssertEqual(bannerEvent.counter, 2); // Should be aggregated
    XCTAssertEqual(bannerEvent.totalLatency, 0); // Method calls don't have latency
    XCTAssertEqualObjects(bannerEvent.sessionId, @"test-session-123");
    
    CLXMetricsEvent *interstitialEvent = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateInterstitial];
    XCTAssertNotNil(interstitialEvent);
    XCTAssertEqualObjects(interstitialEvent.metricName, CLXMetricsTypeMethodCreateInterstitial);
    XCTAssertEqual(interstitialEvent.counter, 1);
}

- (void)testEndToEndNetworkCallTracking {
    // Given - start the metrics tracker with impression URL for network calls
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.networkCallsEnabled = @YES;
    metricsConfig.networkCallsBidReqEnabled = @YES;
    metricsConfig.networkCallsInitSdkReqEnabled = @YES; // Also enable SDK init network calls
    config.metricsConfig = metricsConfig;
    config.impressionTrackerURL = @"https://test-network.example.com/track"; // Test impression URL for network metrics
    
    [self.metricsTracker startWithConfig:config];
    
    // When - track multiple network calls with latency
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:300]; // Same network call again
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkSdkInit latency:150];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - verify metrics are persisted and aggregated correctly
    CLXMetricsEvent *bidEvent = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertNotNil(bidEvent);
    XCTAssertEqualObjects(bidEvent.metricName, CLXMetricsTypeNetworkBidRequest);
    XCTAssertEqual(bidEvent.counter, 2); // Should be aggregated
    XCTAssertEqual(bidEvent.totalLatency, 550); // 250 + 300
    XCTAssertEqualObjects(bidEvent.sessionId, @"test-session-123");
    
    CLXMetricsEvent *initEvent = [self.dao getAllByMetric:CLXMetricsTypeNetworkSdkInit];
    XCTAssertNotNil(initEvent);
    XCTAssertEqual(initEvent.counter, 1);
    XCTAssertEqual(initEvent.totalLatency, 150);
}

- (void)testMixedMethodAndNetworkCallTracking {
    // Given - start the metrics tracker with all metrics enabled
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    metricsConfig.networkCallsEnabled = @YES;
    metricsConfig.networkCallsBidReqEnabled = @YES;
    metricsConfig.networkCallsInitSdkReqEnabled = @YES;
    metricsConfig.networkCallsGeoReqEnabled = @YES;
    config.metricsConfig = metricsConfig;
    
    [self.metricsTracker startWithConfig:config];
    
    // When - track mix of method and network calls
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkSdkInit latency:200];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:300];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkGeoApi latency:100];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - verify all metrics are tracked correctly
    NSArray<CLXMetricsEvent *> *allEvents = [self.dao getAll];
    XCTAssertEqual(allEvents.count, 5);
    
    // Verify we have both method and network events
    BOOL hasMethodEvent = NO;
    BOOL hasNetworkEvent = NO;
    
    for (CLXMetricsEvent *event in allEvents) {
        if ([CLXMetricsType isMethodCallType:event.metricName]) {
            hasMethodEvent = YES;
            XCTAssertEqual(event.totalLatency, 0); // Method calls have no latency
        } else if ([CLXMetricsType isNetworkCallType:event.metricName]) {
            hasNetworkEvent = YES;
            XCTAssertGreaterThan(event.totalLatency, 0); // Network calls have latency
        }
    }
    
    XCTAssertTrue(hasMethodEvent);
    XCTAssertTrue(hasNetworkEvent);
}

- (void)testConfigurationBasedFiltering {
    // Given - start with only method calls enabled
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    metricsConfig.networkCallsEnabled = @NO; // Disabled
    config.metricsConfig = metricsConfig;
    
    [self.metricsTracker startWithConfig:config];
    
    // When - track both method and network calls
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - only method calls should be persisted
    NSArray<CLXMetricsEvent *> *allEvents = [self.dao getAll];
    XCTAssertEqual(allEvents.count, 1);
    
    CLXMetricsEvent *event = allEvents.firstObject;
    XCTAssertEqualObjects(event.metricName, CLXMetricsTypeMethodCreateBanner);
}

- (void)testSpecificNetworkCallFiltering {
    // Given - enable network calls but disable specific types
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.networkCallsEnabled = @YES;
    metricsConfig.networkCallsBidReqEnabled = @YES;
    metricsConfig.networkCallsGeoReqEnabled = @NO; // Disabled
    config.metricsConfig = metricsConfig;
    
    [self.metricsTracker startWithConfig:config];
    
    // When - track different network call types
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:250];
    [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkGeoApi latency:150];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - only enabled network calls should be persisted
    NSArray<CLXMetricsEvent *> *allEvents = [self.dao getAll];
    XCTAssertEqual(allEvents.count, 1);
    
    CLXMetricsEvent *event = allEvents.firstObject;
    XCTAssertEqualObjects(event.metricName, CLXMetricsTypeNetworkBidRequest);
}

- (void)testSessionDataPersistence {
    // Given
    [self.metricsTracker setBasicDataWithSessionId:@"session-abc"
                                         accountId:@"account-xyz"
                                       basePayload:@"payload-123"];
    
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    config.metricsConfig = metricsConfig;
    
    [self.metricsTracker startWithConfig:config];
    
    // When
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateRewarded];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - verify session data is included
    CLXMetricsEvent *event = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateRewarded];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.sessionId, @"session-abc");
    // Note: accountId and basePayload are used in payload generation, not stored directly in the event
}

- (void)testConcurrentTrackingIntegrity {
    // Given
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    metricsConfig.networkCallsEnabled = @YES;
    metricsConfig.networkCallsBidReqEnabled = @YES;
    metricsConfig.networkCallsInitSdkReqEnabled = @YES;
    metricsConfig.networkCallsGeoReqEnabled = @YES;
    config.metricsConfig = metricsConfig;
    
    [self.metricsTracker startWithConfig:config];
    
    // When - simulate concurrent tracking from multiple threads
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSInteger methodCallCount = 10;
    NSInteger networkCallCount = 5;
    
    for (int i = 0; i < methodCallCount; i++) {
        dispatch_group_async(group, queue, ^{
            [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
        });
    }
    
    for (int i = 0; i < networkCallCount; i++) {
        dispatch_group_async(group, queue, ^{
            [self.metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:100 + i];
        });
    }
    
    // Wait for all operations to complete
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    
    // Additional wait for async database operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    // Then - verify data integrity
    CLXMetricsEvent *methodEvent = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertNotNil(methodEvent);
    XCTAssertEqual(methodEvent.counter, methodCallCount);
    XCTAssertEqual(methodEvent.totalLatency, 0);
    
    CLXMetricsEvent *networkEvent = [self.dao getAllByMetric:CLXMetricsTypeNetworkBidRequest];
    XCTAssertNotNil(networkEvent);
    XCTAssertEqual(networkEvent.counter, networkCallCount);
    // Total latency should be sum of all individual latencies (100+101+102+103+104 = 510)
    XCTAssertEqual(networkEvent.totalLatency, 510);
}

- (void)testMetricsLifecycle {
    // Given
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    metricsConfig.sdkApiCallsEnabled = @YES;
    config.metricsConfig = metricsConfig;
    config.impressionTrackerURL = @"https://lifecycle-test.example.com/t";
    
    // When - start, track, stop, restart cycle
    [self.metricsTracker startWithConfig:config];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Verify first tracking
    CLXMetricsEvent *event1 = [self.dao getAllByMetric:CLXMetricsTypeMethodSdkInit];
    XCTAssertNotNil(event1, @"First event must exist after tracking");
    XCTAssertEqual(event1.counter, 1, @"First event counter must be exactly 1");
    
    // Stop and restart
    [self.metricsTracker stop];
    [self.metricsTracker startWithConfig:config];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit]; // Track again
    
    // Wait for async operations to complete
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - verify aggregation continues correctly
    CLXMetricsEvent *event2 = [self.dao getAllByMetric:CLXMetricsTypeMethodSdkInit];
    XCTAssertNotNil(event2, @"Second event must exist after restart and tracking");
    XCTAssertEqual(event2.counter, 2, @"Second event counter must be exactly 2 (aggregated)"); // Should be aggregated
}

- (void)testImpressionURLFallbackBehavior {
    // Given - Test fallback from impressionTrackerURL to metricsEndpointURL
    CLXSDKConfig *configWithImpression = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig1 = [[CLXMetricsConfig alloc] init];
    metricsConfig1.sdkApiCallsEnabled = @YES;
    configWithImpression.metricsConfig = metricsConfig1;
    configWithImpression.impressionTrackerURL = @"https://impression.example.com/track";
    configWithImpression.metricsEndpointURL = @"https://metrics.example.com/api";
    
    // When - start with impression URL (should prefer impression URL)
    [self.metricsTracker startWithConfig:configWithImpression];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - should work (using impression URL internally)
    CLXMetricsEvent *event1 = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateBanner];
    XCTAssertNotNil(event1, @"Event should be tracked with impression URL");
    XCTAssertEqual(event1.counter, 1);
    
    // Given - Test fallback to metrics URL when impression URL is nil
    [self.metricsTracker stop];
    CLXSDKConfig *configWithMetrics = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig2 = [[CLXMetricsConfig alloc] init];
    metricsConfig2.sdkApiCallsEnabled = @YES;
    configWithMetrics.metricsConfig = metricsConfig2;
    configWithMetrics.impressionTrackerURL = nil; // No impression URL
    configWithMetrics.metricsEndpointURL = @"https://fallback-metrics.example.com/api";
    
    // When - start with only metrics URL
    [self.metricsTracker startWithConfig:configWithMetrics];
    [self.metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    
    // Wait for async operations
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Then - should still work (using metrics URL as fallback)
    CLXMetricsEvent *event2 = [self.dao getAllByMetric:CLXMetricsTypeMethodCreateInterstitial];
    XCTAssertNotNil(event2, @"Event should be tracked with metrics URL fallback");
    XCTAssertEqual(event2.counter, 1);
}

@end
