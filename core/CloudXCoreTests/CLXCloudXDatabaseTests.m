/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXDaoProtocols.h>
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
    
    // CRITICAL: Set as shared instance for test isolation
    // This ensures any code using [CLXCloudXDatabase sharedInstance] uses our test database
    [CLXCloudXDatabase setSharedInstanceForTesting:self.database];
    
    XCTAssertTrue([self.database openDatabase], @"Should open database successfully");
}

- (void)tearDown {
    // Reset shared instance BEFORE closing to avoid any race conditions
    [CLXCloudXDatabase setSharedInstanceForTesting:nil];
    
    [self.database closeDatabase];
    self.database = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    [super tearDown];
}

#pragma mark - Database Initialization Tests

- (void)testDatabaseInitialization {
    XCTAssertNotNil(self.database, @"Database should be initialized");
    XCTAssertNotNil(self.database.metricsDao, @"Metrics DAO should be initialized");
    XCTAssertNotNil(self.database.sessionDao, @"Session DAO should be initialized");
    XCTAssertNotNil(self.database.performanceDao, @"Performance DAO should be initialized");
}

- (void)testSchemaCreation {
    XCTAssertTrue([self.database tableExists:@"metrics_event_table"], @"Metrics table should exist");
    XCTAssertTrue([self.database tableExists:@"session_table"], @"Session table should exist");
    XCTAssertTrue([self.database tableExists:@"performance_metrics_table"], @"Performance metrics table should exist");
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

@end
