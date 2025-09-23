/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXSQLiteDatabase.h>

// Mock database for testing
@interface MockSQLiteDatabaseForDao : CLXSQLiteDatabase
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *mockResults;
@property (nonatomic, assign) BOOL shouldFailExecute;
@property (nonatomic, assign) BOOL shouldFailQuery;
@property (nonatomic, strong) NSMutableArray<NSString *> *executedQueries;
@property (nonatomic, strong) NSMutableArray<NSArray *> *executedParameters;
@end

@implementation MockSQLiteDatabaseForDao

- (instancetype)init {
    self = [super initWithDatabaseName:@"test_dao_mock.db"];
    if (self) {
        _mockResults = [NSMutableArray array];
        _executedQueries = [NSMutableArray array];
        _executedParameters = [NSMutableArray array];
        _shouldFailExecute = NO;
        _shouldFailQuery = NO;
    }
    return self;
}

- (BOOL)executeSQL:(NSString *)sql withParameters:(NSArray *)parameters {
    [self.executedQueries addObject:sql ?: @""];
    [self.executedParameters addObject:parameters ?: @[]];
    return !self.shouldFailExecute;
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql withParameters:(NSArray *)parameters {
    [self.executedQueries addObject:sql ?: @""];
    [self.executedParameters addObject:parameters ?: @[]];
    
    if (self.shouldFailQuery) {
        return @[];
    }
    
    return [self.mockResults copy];
}

@end

@interface CLXMetricsEventDaoTests : XCTestCase
@property (nonatomic, strong) CLXMetricsEventDao *dao;
@property (nonatomic, strong) MockSQLiteDatabaseForDao *mockDatabase;
@end

@implementation CLXMetricsEventDaoTests

- (void)setUp {
    [super setUp];
    self.mockDatabase = [[MockSQLiteDatabaseForDao alloc] init];
    self.dao = [[CLXMetricsEventDao alloc] initWithDatabase:self.mockDatabase];
}

- (void)tearDown {
    self.dao = nil;
    self.mockDatabase = nil;
    [super tearDown];
}

- (void)testInitialization {
    XCTAssertNotNil(self.dao);
}

- (void)testInsertMetricsEvent {
    // Given
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:@"test-id"
                                                           metricName:@"method_create_banner"
                                                              counter:1
                                                         totalLatency:250
                                                            sessionId:@"session-123"
                                                            auctionId:@"auction-456"];
    
    // When
    BOOL result = [self.dao insert:event];
    
    // Then - focus on business logic, not implementation details
    XCTAssertTrue(result);
    XCTAssertGreaterThanOrEqual(self.mockDatabase.executedQueries.count, 1);
    
    // Verify that an insert query was executed
    BOOL foundInsertQuery = NO;
    for (NSString *query in self.mockDatabase.executedQueries) {
        if ([query containsString:@"INSERT"] || [query containsString:@"REPLACE"]) {
            foundInsertQuery = YES;
            break;
        }
    }
    XCTAssertTrue(foundInsertQuery, @"Should execute an insert/replace query");
}

- (void)testInsertNilEvent {
    // When
    BOOL result = [self.dao insert:nil];
    
    // Then - should handle gracefully and return false
    XCTAssertFalse(result);
}

- (void)testInsertWithDatabaseFailure {
    // Given
    self.mockDatabase.shouldFailExecute = YES;
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:@"test-id"
                                                           metricName:@"method_sdk_init"
                                                              counter:1
                                                         totalLatency:100
                                                            sessionId:@"session-123"
                                                            auctionId:@"auction-456"];
    
    // When
    BOOL result = [self.dao insert:event];
    
    // Then - should handle database failure gracefully and return false
    XCTAssertFalse(result);
}

- (void)testGetAllByMetric {
    // Given
    NSDictionary *mockResult = @{
        @"id": @"test-id",
        @"metricName": @"network_call_bid_req",
        @"counter": @3,
        @"totalLatency": @750,
        @"sessionId": @"session-123",
        @"auctionId": @"auction-456"
    };
    [self.mockDatabase.mockResults addObject:mockResult];
    
    // When
    CLXMetricsEvent *result = [self.dao getAllByMetric:@"network_call_bid_req"];
    
    // Then
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.eventId, @"test-id");
    XCTAssertEqualObjects(result.metricName, @"network_call_bid_req");
    XCTAssertEqual(result.counter, 3);
    XCTAssertEqual(result.totalLatency, 750);
    XCTAssertEqualObjects(result.sessionId, @"session-123");
    XCTAssertEqualObjects(result.auctionId, @"auction-456");
    
    // Verify a SELECT query was executed
    BOOL foundSelectQuery = NO;
    for (NSString *query in self.mockDatabase.executedQueries) {
        if ([query containsString:@"SELECT"]) {
            foundSelectQuery = YES;
            break;
        }
    }
    XCTAssertTrue(foundSelectQuery, @"Should execute a SELECT query");
}

- (void)testGetAllByMetricNotFound {
    // Given - empty mock results
    
    // When
    CLXMetricsEvent *result = [self.dao getAllByMetric:@"nonexistent_metric"];
    
    // Then
    XCTAssertNil(result);
}

- (void)testGetAllByMetricWithNilMetricName {
    // When
    CLXMetricsEvent *result = [self.dao getAllByMetric:nil];
    
    // Then - should handle nil gracefully
    XCTAssertNil(result);
}

- (void)testGetAllByMetricWithDatabaseFailure {
    // Given
    self.mockDatabase.shouldFailQuery = YES;
    
    // When
    CLXMetricsEvent *result = [self.dao getAllByMetric:@"method_create_banner"];
    
    // Then
    XCTAssertNil(result);
    // Database operations should be executed
}

- (void)testDeleteById {
    // When
    [self.dao deleteById:@"test-event-id"];
    
    // Then
    // Verify a DELETE query was executed
    BOOL foundDeleteQuery = NO;
    for (NSString *query in self.mockDatabase.executedQueries) {
        if ([query containsString:@"DELETE"]) {
            foundDeleteQuery = YES;
            break;
        }
    }
    XCTAssertTrue(foundDeleteQuery, @"Should execute a DELETE query");
}

- (void)testDeleteByIdWithNilId {
    // When
    BOOL result = [self.dao deleteById:nil];
    
    // Then - should handle gracefully
    XCTAssertFalse(result);
}

- (void)testDeleteByIdWithDatabaseFailure {
    // Given
    self.mockDatabase.shouldFailExecute = YES;
    
    // When/Then - should handle database failure gracefully
    XCTAssertNoThrow([self.dao deleteById:@"test-event-id"]);
    // Database operations should be executed
}

- (void)testGetAll {
    // Given
    NSArray *mockResults = @[
        @{
            @"id": @"event-1",
            @"metricName": @"method_create_banner",
            @"counter": @1,
            @"totalLatency": @100,
            @"sessionId": @"session-1",
            @"auctionId": @"auction-1"
        },
        @{
            @"id": @"event-2",
            @"metricName": @"network_call_bid_req",
            @"counter": @2,
            @"totalLatency": @300,
            @"sessionId": @"session-2",
            @"auctionId": @"auction-2"
        }
    ];
    [self.mockDatabase.mockResults addObjectsFromArray:mockResults];
    
    // When
    NSArray<CLXMetricsEvent *> *results = [self.dao getAll];
    
    // Then
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 2);
    
    CLXMetricsEvent *event1 = results[0];
    XCTAssertEqualObjects(event1.eventId, @"event-1");
    XCTAssertEqualObjects(event1.metricName, @"method_create_banner");
    XCTAssertEqual(event1.counter, 1);
    XCTAssertEqual(event1.totalLatency, 100);
    
    CLXMetricsEvent *event2 = results[1];
    XCTAssertEqualObjects(event2.eventId, @"event-2");
    XCTAssertEqualObjects(event2.metricName, @"network_call_bid_req");
    XCTAssertEqual(event2.counter, 2);
    XCTAssertEqual(event2.totalLatency, 300);
    
    // Verify a SELECT query was executed for getAll
    BOOL foundSelectQuery = NO;
    for (NSString *query in self.mockDatabase.executedQueries) {
        if ([query containsString:@"SELECT"]) {
            foundSelectQuery = YES;
            break;
        }
    }
    XCTAssertTrue(foundSelectQuery, @"Should execute a SELECT query");
}

- (void)testGetAllEmpty {
    // Given - empty mock results
    
    // When
    NSArray<CLXMetricsEvent *> *results = [self.dao getAll];
    
    // Then
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0);
    // Database operations should be executed
}

- (void)testGetAllWithDatabaseFailure {
    // Given
    self.mockDatabase.shouldFailQuery = YES;
    
    // When
    NSArray<CLXMetricsEvent *> *results = [self.dao getAll];
    
    // Then
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0);
    // Database operations should be executed
}

@end
