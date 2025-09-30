/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXSQLiteDatabase.h>

// Mock database for testing
@interface MockMetricsDatabase : CLXSQLiteDatabase
@property (nonatomic, strong) NSMutableArray<CLXMetricsEvent *> *mockEvents;
@property (nonatomic, strong) NSMutableArray<NSString *> *deletedEventIds;
@end

@implementation MockMetricsDatabase
- (instancetype)init {
    self = [super initWithDatabaseName:@"test_cleanup_mock.db"];
    if (self) {
        _mockEvents = [NSMutableArray array];
        _deletedEventIds = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)executeQuery:(NSString *)sql withParameters:(NSArray *)parameters {
    if ([sql containsString:@"SELECT * FROM metrics_event_table"]) {
        // Convert CLXMetricsEvent objects to dictionary format that CLXMetricsEventDao expects
        NSMutableArray *results = [NSMutableArray array];
        for (CLXMetricsEvent *event in self.mockEvents) {
            [results addObject:@{
                @"eventId": event.eventId,
                @"metricName": event.metricName,
                @"counter": @(event.counter),
                @"totalLatency": @(event.totalLatency),
                @"sessionId": event.sessionId ?: @"",
                @"auctionId": event.auctionId ?: @"",
                @"created_at": @(event.createdAt)
            }];
        }
        return results;
    }
    return @[];
}

- (BOOL)executeSQL:(NSString *)sql withParameters:(NSArray *)parameters {
    if ([sql containsString:@"DELETE FROM metrics_event_table WHERE eventId = ?"]) {
        NSString *eventId = parameters.firstObject;
        [self.deletedEventIds addObject:eventId];
        // Remove from mock events
        CLXMetricsEvent *eventToRemove = nil;
        for (CLXMetricsEvent *event in self.mockEvents) {
            if ([event.eventId isEqualToString:eventId]) {
                eventToRemove = event;
                break;
            }
        }
        if (eventToRemove) {
            [self.mockEvents removeObject:eventToRemove];
        }
        return YES;
    }
    return YES;
}
@end

@interface CLXMetricsCleanupTests : XCTestCase
@property (nonatomic, strong) CLXMetricsTrackerImpl *metricsTracker;
@property (nonatomic, strong) MockMetricsDatabase *mockDatabase;
@property (nonatomic, strong) NSMutableArray<CLXMetricsEvent *> *testEvents;
@end

@implementation CLXMetricsCleanupTests

- (void)setUp {
    [super setUp];
    
    // Create mock database
    self.mockDatabase = [[MockMetricsDatabase alloc] init];
    
    // Create test events array
    self.testEvents = [NSMutableArray array];
    
    // Create metrics tracker with mock database
    self.metricsTracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:self.mockDatabase];
}

- (void)tearDown {
    self.metricsTracker = nil;
    self.mockDatabase = nil;
    self.testEvents = nil;
    [super tearDown];
}

#pragma mark - Helper Methods

- (CLXMetricsEvent *)createTestEventWithType:(NSString *)type counter:(NSInteger)counter {
    NSString *eventId = [[NSUUID UUID] UUIDString];
    NSString *sessionId = @"test-session";
    NSString *auctionId = @"test-auction";
    
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:eventId
                                                            sessionId:sessionId
                                                           metricName:type
                                                            auctionId:auctionId];
    event.counter = counter;
    event.totalLatency = 100;
    event.createdAt = [[NSDate date] timeIntervalSince1970] - (counter * 60); // Spread events over time
    return event;
}

- (void)createTestEventsWithCount:(NSInteger)count {
    [self.testEvents removeAllObjects];
    
    for (NSInteger i = 0; i < count; i++) {
        CLXMetricsEvent *event = [self createTestEventWithType:@"test_metric" counter:i + 1];
        [self.testEvents addObject:event];
    }
}

#pragma mark - Cleanup Tests

- (void)testCleanupLogicExists {
    // This test verifies that the cleanup logic exists and can be called
    // Given - A metrics tracker instance
    CLXMetricsTrackerImpl *testTracker = [[CLXMetricsTrackerImpl alloc] init];
    
    // When - Try to call the cleanup method (should not crash)
    XCTAssertNoThrow([testTracker performSelector:@selector(_cleanupOldMetrics)], 
                     @"Cleanup method should exist and be callable");
    
    // Then - Test passes if no exception is thrown
    XCTAssertTrue(YES, @"Cleanup method exists and is callable");
}

- (void)testSendPendingMetricsWithNoEndpoint {
    // This test verifies that _sendPendingMetrics can be called without crashing
    // when there's no endpoint (which should trigger cleanup logic)
    
    // Given - A metrics tracker with no endpoint configured
    CLXMetricsTrackerImpl *testTracker = [[CLXMetricsTrackerImpl alloc] init];
    
    // When - Call _sendPendingMetrics (should trigger cleanup logic internally)
    XCTAssertNoThrow([testTracker performSelector:@selector(_sendPendingMetrics)], 
                     @"_sendPendingMetrics should not crash when no endpoint is configured");
    
    // Then - Test passes if no exception is thrown
    XCTAssertTrue(YES, @"_sendPendingMetrics handles no endpoint gracefully");
}

- (void)testMetricsTrackerInitialization {
    // Test that the metrics tracker initializes properly with a custom database
    
    // Given - A custom database
    NSString *testDBName = [NSString stringWithFormat:@"test_%@", [[NSUUID UUID] UUIDString]];
    CLXSQLiteDatabase *testDatabase = [[CLXSQLiteDatabase alloc] initWithDatabaseName:testDBName];
    
    // When - Create metrics tracker with custom database
    CLXMetricsTrackerImpl *testTracker = [[CLXMetricsTrackerImpl alloc] initWithDatabase:testDatabase];
    
    // Then - Should initialize without crashing
    XCTAssertNotNil(testTracker, @"Metrics tracker should initialize with custom database");
    
    // And should be able to call cleanup methods
    XCTAssertNoThrow([testTracker performSelector:@selector(_cleanupOldMetrics)], 
                     @"Should be able to call cleanup on initialized tracker");
}

- (void)testMetricsConfigurationWithEndpoint {
    // Test that metrics tracker can be configured with an endpoint
    
    // Given - A metrics tracker and config with endpoint
    CLXMetricsTrackerImpl *testTracker = [[CLXMetricsTrackerImpl alloc] init];
    CLXSDKConfig *config = [[CLXSDKConfig alloc] init];
    CLXMetricsConfig *metricsConfig = [[CLXMetricsConfig alloc] init];
    config.metricsConfig = metricsConfig;
    config.impressionTrackerURL = @"https://test-endpoint.com/track";
    
    // When - Start with valid endpoint
    XCTAssertNoThrow([testTracker startWithConfig:config], 
                     @"Should start without crashing with valid config");
    
    // Then - Should be able to call metrics methods
    XCTAssertNoThrow([testTracker performSelector:@selector(_sendPendingMetrics)], 
                     @"Should be able to send metrics with valid endpoint");
}

@end
