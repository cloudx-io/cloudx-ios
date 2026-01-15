/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXDaoProtocols.h>
#import <CloudXCore/CLXRillEvent.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXSession.h>
#import <CloudXCore/CLXPerformanceMetric.h>

@interface CLXCloudXDatabaseTests : XCTestCase

@property (nonatomic, strong) CLXCloudXDatabase *database;
@property (nonatomic, strong) NSString *testDatabasePath;

@end

@implementation CLXCloudXDatabaseTests

- (void)setUp {
    [super setUp];
    
    // Create unique test database for each test
    NSString *tempDir = NSTemporaryDirectory();
    NSString *uniqueName = [NSString stringWithFormat:@"test_cloudx_%@_%f.db", 
                           NSStringFromSelector(self.invocation.selector), 
                           [[NSDate date] timeIntervalSince1970]];
    self.testDatabasePath = [tempDir stringByAppendingPathComponent:uniqueName];
    
    // Remove existing test database
    [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    
    self.database = [[CLXCloudXDatabase alloc] initWithDatabaseName:uniqueName];
    XCTAssertTrue([self.database openDatabase], @"Should open database successfully");
}

- (void)tearDown {
    [self.database closeDatabase];
    [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    [super tearDown];
}

#pragma mark - Database Initialization Tests

- (void)testDatabaseInitialization {
    XCTAssertNotNil(self.database, @"Database should be initialized");
    XCTAssertNotNil(self.database.metricsDao, @"Metrics DAO should be initialized");
    XCTAssertNotNil(self.database.rillEventDao, @"Rill event DAO should be initialized");
    XCTAssertNotNil(self.database.sessionDao, @"Session DAO should be initialized");
    XCTAssertNotNil(self.database.performanceDao, @"Performance DAO should be initialized");
}

- (void)testSchemaCreation {
    XCTAssertTrue([self.database tableExists:@"metrics_event_table"], @"Metrics table should exist");
    XCTAssertTrue([self.database tableExists:@"cached_tracking_events_table"], @"Rill events table should exist");
    XCTAssertTrue([self.database tableExists:@"session_table"], @"Session table should exist");
    XCTAssertTrue([self.database tableExists:@"performance_metrics_table"], @"Performance metrics table should exist");
}

#pragma mark - Rill Event DAO Tests

- (void)testRillEventInsertion {
    CLXRillEvent *event = [CLXRillEvent impressionEventWithSessionId:@"test_session" 
                                                          campaignId:@"test_campaign" 
                                                             payload:@"test_payload"];
    
    BOOL success = [self.database.rillEventDao insertRillEvent:event];
    XCTAssertTrue(success, @"Should insert Rill event successfully");
    
    CLXRillEvent *retrieved = [self.database.rillEventDao findRillEventById:event.eventId];
    XCTAssertNotNil(retrieved, @"Should retrieve inserted event");
    XCTAssertEqualObjects(retrieved.campaignId, @"test_campaign", @"Campaign ID should match");
    XCTAssertEqualObjects(retrieved.eventName, @"impression", @"Event name should match");
}

- (void)testRillEventBatchInsertion {
    NSMutableArray *events = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        CLXRillEvent *event = [CLXRillEvent clickEventWithSessionId:@"test_session" 
                                                         campaignId:[NSString stringWithFormat:@"campaign_%d", i]
                                                            payload:@"test_payload"];
        [events addObject:event];
    }
    
    BOOL success = [self.database.rillEventDao insertRillEventBatch:events];
    XCTAssertTrue(success, @"Should insert batch successfully");
    
    NSArray *pending = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pending.count, 10, @"Should have 10 pending events");
}

#pragma mark - Metrics Event DAO Tests

- (void)testMetricsEventInsertion {
    CLXMetricsEvent *event = [CLXMetricsEvent impressionMetricWithSessionId:@"test_session" 
                                                                  auctionId:@"test_auction"];
    
    BOOL success = [self.database.metricsDao insertMetricsEvent:event];
    XCTAssertTrue(success, @"Should insert metrics event successfully");
    
    CLXMetricsEvent *retrieved = [self.database.metricsDao findMetricsEventById:event.eventId];
    XCTAssertNotNil(retrieved, @"Should retrieve inserted event");
    XCTAssertEqualObjects(retrieved.metricName, @"impression", @"Metric name should match");
    XCTAssertEqual(retrieved.counter, 1, @"Counter should be 1");
}

- (void)testMetricsAggregation {
    NSString *sessionId = @"test_session";
    NSString *auctionId = @"test_auction";
    
    // Insert multiple impression metrics
    for (int i = 0; i < 5; i++) {
        CLXMetricsEvent *event = [CLXMetricsEvent impressionMetricWithSessionId:sessionId auctionId:auctionId];
        [self.database.metricsDao insertMetricsEvent:event];
    }
    
    NSInteger totalCounter = [self.database.metricsDao getTotalCounterForMetric:@"impression" sessionId:sessionId];
    XCTAssertEqual(totalCounter, 5, @"Total counter should be 5");
    
    NSDictionary *summary = [self.database.metricsDao getMetricsSummaryForSession:sessionId];
    XCTAssertNotNil(summary[@"impression"], @"Should have impression summary");
}

#pragma mark - Session DAO Tests

- (void)testSessionInsertion {
    CLXSession *session = [CLXSession currentSessionWithAppKey:@"test_app"];
    
    BOOL success = [self.database.sessionDao insertSession:session];
    XCTAssertTrue(success, @"Should insert session successfully");
    
    CLXSession *retrieved = [self.database.sessionDao findSessionById:session.sessionId];
    XCTAssertNotNil(retrieved, @"Should retrieve inserted session");
    XCTAssertEqualObjects(retrieved.appKey, @"test_app", @"App key should match");
    XCTAssertTrue([retrieved isActive], @"Session should be active");
}

- (void)testCurrentSessionRetrieval {
    CLXSession *session1 = [CLXSession currentSessionWithAppKey:@"test_app"];
    CLXSession *session2 = [CLXSession currentSessionWithAppKey:@"test_app"];
    [session2 endSession]; // End this session
    
    [self.database.sessionDao insertSession:session1];
    [self.database.sessionDao insertSession:session2];
    
    CLXSession *current = [self.database.sessionDao findCurrentSession];
    XCTAssertNotNil(current, @"Should find current session");
    XCTAssertEqualObjects(current.sessionId, session1.sessionId, @"Should return active session");
}

#pragma mark - Performance DAO Tests

- (void)testPerformanceMetricInsertion {
    // First create a session that the performance metric can reference
    CLXSession *session = [CLXSession currentSessionWithAppKey:@"test_app"];
    session.sessionId = @"test_session"; // Override to use predictable ID
    BOOL sessionSuccess = [self.database.sessionDao insertSession:session];
    XCTAssertTrue(sessionSuccess, @"Should insert session successfully");
    
    CLXPerformanceMetric *metric = [CLXPerformanceMetric metricForPlacement:@"test_placement" 
                                                                   sessionId:@"test_session"];
    [metric incrementImpressions];
    [metric incrementClicks];
    
    BOOL success = [self.database.performanceDao insertPerformanceMetric:metric];
    XCTAssertTrue(success, @"Should insert performance metric successfully");
    
    NSArray *metrics = [self.database.performanceDao findPerformanceMetricsByPlacementId:@"test_placement"];
    XCTAssertEqual(metrics.count, 1, @"Should have one metric");
    
    CLXPerformanceMetric *retrieved = metrics.firstObject;
    XCTAssertEqual(retrieved.impressionCount, 1, @"Should have 1 impression");
    XCTAssertEqual(retrieved.clickCount, 1, @"Should have 1 click");
}

- (void)testPerformanceAggregation {
    // First create a session that the performance metrics can reference
    CLXSession *session = [CLXSession currentSessionWithAppKey:@"test_app"];
    session.sessionId = @"test_session"; // Override to use predictable ID
    BOOL sessionSuccess = [self.database.sessionDao insertSession:session];
    XCTAssertTrue(sessionSuccess, @"Should insert session successfully");
    
    NSString *placementId = @"test_placement";
    
    // Insert multiple performance metrics
    for (int i = 0; i < 3; i++) {
        CLXPerformanceMetric *metric = [CLXPerformanceMetric metricForPlacement:placementId 
                                                                       sessionId:@"test_session"];
        [metric incrementImpressionsBy:2];
        [metric incrementClicksBy:1];
        [self.database.performanceDao insertPerformanceMetric:metric];
    }
    
    NSInteger totalImpressions = [self.database.performanceDao getTotalImpressionsForPlacement:placementId];
    NSInteger totalClicks = [self.database.performanceDao getTotalClicksForPlacement:placementId];
    
    XCTAssertEqual(totalImpressions, 6, @"Total impressions should be 6");
    XCTAssertEqual(totalClicks, 3, @"Total clicks should be 3");
    
    NSDictionary *summary = [self.database.performanceDao getPerformanceSummaryForPlacement:placementId];
    XCTAssertNotNil(summary, @"Should have performance summary");
    XCTAssertEqual([summary[@"totalImpressions"] integerValue], 6, @"Summary should show 6 impressions");
}

#pragma mark - Transaction Tests

- (void)testTransactionRollback {
    BOOL transactionResult = [self.database executeInTransactionWithResult:^BOOL{
        CLXRillEvent *event = [CLXRillEvent impressionEventWithSessionId:@"test_session" 
                                                              campaignId:@"test_campaign" 
                                                                 payload:@"test_payload"];
        
        BOOL insertSuccess = [self.database.rillEventDao insertRillEvent:event];
        XCTAssertTrue(insertSuccess, @"Insert should succeed within transaction");
        
        // Force transaction failure by returning NO
        return NO;
    }];
    
    XCTAssertFalse(transactionResult, @"Transaction should have failed");
    
    // Verify rollback
    NSArray *events = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(events.count, 0, @"Should have no events after rollback");
}

#pragma mark - Performance Tests

- (void)testBulkInsertPerformance {
    NSMutableArray *events = [NSMutableArray array];
    for (int i = 0; i < 1000; i++) {
        CLXRillEvent *event = [CLXRillEvent impressionEventWithSessionId:@"test_session" 
                                                              campaignId:[NSString stringWithFormat:@"campaign_%d", i]
                                                                 payload:@"test_payload"];
        [events addObject:event];
    }
    
    NSDate *startTime = [NSDate date];
    BOOL success = [self.database.rillEventDao insertRillEventBatch:events];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
    
    XCTAssertTrue(success, @"Bulk insert should succeed");
    XCTAssertLessThan(duration, 30.0, @"Bulk insert should complete within 30 seconds");
    
    NSArray *retrieved = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(retrieved.count, 1000, @"Should retrieve all inserted events");
}

@end
