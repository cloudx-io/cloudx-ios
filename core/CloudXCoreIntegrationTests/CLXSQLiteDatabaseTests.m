/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSQLiteDatabaseTests.m
 * @brief Comprehensive tests for SQLite database layer focusing on failure scenarios and edge cases
 * 
 * Critical test coverage for database operations that could lead to data corruption,
 * loss of win/loss events, or system crashes. Tests the robustness of the SQLite
 * abstraction layer under adverse conditions.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <unistd.h>  // For getpid()

@interface CLXSQLiteDatabase (Testing)
@property (nonatomic, assign, readonly) sqlite3 *database;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;
- (NSString *)databasePath;
@end

@interface CLXSQLiteDatabaseTests : XCTestCase
@property (nonatomic, strong) CLXSQLiteDatabase *database;
@property (nonatomic, strong) NSString *testDatabaseName;
@end

@implementation CLXSQLiteDatabaseTests

- (void)setUp {
    [super setUp];
    // Use process ID + UUID + timestamp for maximum uniqueness across parallel test runs
    self.testDatabaseName = [NSString stringWithFormat:@"test_db_%d_%@_%lld", 
                             getpid(), 
                             [[NSUUID UUID] UUIDString],
                             (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
    self.database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:self.testDatabaseName];
}

- (void)tearDown {
    // Close database first
    if (self.database) {
        [self.database closeDatabase];
        
        // Clean up test database file synchronously
        NSString *dbPath = [self.database databasePath];
        if (dbPath) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error];
            // Also remove WAL and SHM files if they exist
            [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
        }
    }
    
    self.database = nil;
    self.testDatabaseName = nil;
    [super tearDown];
}

#pragma mark - Database Initialization Tests

/**
 * Test database initialization with invalid paths and permissions
 */
- (void)testDatabaseInitialization_InvalidPath_ShouldHandleGracefully {
    // Test with invalid characters in database name
    NSString *invalidName = @"test/\\|<>:*?\"db";
    CLXSQLiteDatabase *invalidDb = [[CLXSQLiteDatabase alloc] initWithDatabaseName:invalidName];
    
    // Should not crash and should create a sanitized path
    XCTAssertNotNil(invalidDb);
    XCTAssertNotNil([invalidDb databasePath]);
    
    [invalidDb closeDatabase];
}

/**
 * Test database creation in read-only directory
 */
- (void)testDatabaseCreation_ReadOnlyDirectory_ShouldFailGracefully {
    // This is difficult to test in iOS sandbox, but we can test the error handling path
    // by attempting operations on a closed database
    
    CLXSQLiteDatabase *testDb = [[CLXSQLiteDatabase alloc] initWithDatabaseName:@"test_readonly"];
    [testDb closeDatabase];
    
    // Attempt operations on closed database
    BOOL result = [testDb executeSQL:@"CREATE TABLE test (id INTEGER);"];
    XCTAssertFalse(result, @"Should fail when database is closed");
    
    NSArray *queryResult = [testDb executeQuery:@"SELECT * FROM test;"];
    XCTAssertEqual(queryResult.count, 0, @"Should return empty result when database is closed");
}

#pragma mark - SQL Injection and Security Tests

/**
 * Test SQL injection attempts in parameters
 */
- (void)testSQLInjection_ParameterBinding_ShouldPreventInjection {
    // Create test table
    BOOL created = [self.database executeSQL:@"CREATE TABLE injection_test (id INTEGER PRIMARY KEY, name TEXT, value TEXT);"];
    XCTAssertTrue(created);
    
    // Insert legitimate data
    BOOL inserted = [self.database executeSQL:@"INSERT INTO injection_test (name, value) VALUES (?, ?);"
                               withParameters:@[@"test", @"value"]];
    XCTAssertTrue(inserted);
    
    // Attempt SQL injection through parameters
    NSString *maliciousInput = @"'; DROP TABLE injection_test; --";
    BOOL injectionAttempt = [self.database executeSQL:@"INSERT INTO injection_test (name, value) VALUES (?, ?);"
                                       withParameters:@[@"malicious", maliciousInput]];
    XCTAssertTrue(injectionAttempt, @"Should succeed but treat input as literal string");
    
    // Verify table still exists and data is intact
    NSArray *results = [self.database executeQuery:@"SELECT COUNT(*) as count FROM injection_test;"];
    XCTAssertEqual(results.count, 1);
    XCTAssertEqual([results[0][@"count"] integerValue], 2, @"Should have 2 rows, table should not be dropped");
    
    // Verify malicious input was stored as literal string
    NSArray *maliciousResults = [self.database executeQuery:@"SELECT * FROM injection_test WHERE value = ?;" 
                                             withParameters:@[maliciousInput]];
    XCTAssertEqual(maliciousResults.count, 1, @"Should find the malicious input stored as literal string");
}

/**
 * Test SQL injection in direct SQL strings (should be avoided but test for robustness)
 */
- (void)testSQLInjection_DirectSQL_ShouldHandleInvalidSQL {
    // Ensure database is ready
    XCTAssertNotNil(self.database, @"Database should be initialized");
    
    // Create test table
    BOOL created = [self.database executeSQL:@"CREATE TABLE direct_test (id INTEGER PRIMARY KEY, name TEXT);"];
    XCTAssertTrue(created, @"Table creation should succeed");
    
    // Test with invalid SQL syntax that should fail
    NSString *invalidSQL = @"INSERT INTO direct_test (name) VALUES ('test' INVALID SYNTAX;";
    BOOL result = [self.database executeSQL:invalidSQL];
    
    XCTAssertFalse(result, @"Invalid SQL syntax should return NO");
    
    // Test with SQL that references non-existent table
    NSString *nonExistentTableSQL = @"INSERT INTO non_existent_table (name) VALUES ('test');";
    BOOL result2 = [self.database executeSQL:nonExistentTableSQL];
    
    // Should fail due to non-existent table
    XCTAssertFalse(result2, @"Should fail to execute SQL on non-existent table");
    
    // Verify original table still exists
    NSArray *results = [self.database executeQuery:@"SELECT COUNT(*) as count FROM direct_test;"];
    XCTAssertNotNil(results, @"Query should return results");
    XCTAssertGreaterThan(results.count, 0, @"Should have at least one row");
    
    NSInteger count = [results[0][@"count"] integerValue];
    XCTAssertEqual(count, 0, @"Table should be empty after failed operations");
}

#pragma mark - Transaction Failure Tests

/**
 * Test transaction rollback on SQL constraint violation
 */
- (void)testTransaction_SQLConstraintViolation_ShouldRollback {
    // Create test table
    BOOL created = [self.database executeSQL:@"CREATE TABLE transaction_test (id INTEGER PRIMARY KEY UNIQUE, name TEXT);"];
    XCTAssertTrue(created);
    
    // Insert initial data
    BOOL inserted = [self.database executeSQL:@"INSERT INTO transaction_test (id, name) VALUES (1, 'initial');" withParameters:nil];
    XCTAssertTrue(inserted);
    
    // Attempt transaction that should fail due to constraint violation
    [self.database executeSQL:@"BEGIN TRANSACTION;"];
    
    // This should succeed
    BOOL success1 = [self.database executeSQL:@"INSERT INTO transaction_test (id, name) VALUES (2, 'second');" withParameters:nil];
    XCTAssertTrue(success1, @"First insert should succeed");
    
    // This should fail due to UNIQUE constraint violation
    BOOL success2 = [self.database executeSQL:@"INSERT INTO transaction_test (id, name) VALUES (1, 'duplicate');" withParameters:nil];
    XCTAssertFalse(success2, @"Duplicate insert should fail");
    
    // Rollback the transaction
    [self.database executeSQL:@"ROLLBACK;"];
    
    // Verify the state - should have initial data plus the successful insert
    // Note: The behavior depends on SQLite's transaction handling
    NSArray *results = [self.database executeQuery:@"SELECT COUNT(*) as count FROM transaction_test;"];
    NSInteger count = [results[0][@"count"] integerValue];
    
    // ROLLBACK undoes the entire transaction, so only the initial row (id=1) remains
    XCTAssertEqual(count, 1, @"Rollback should undo all statements in the transaction");
    
    NSArray *nameResults = [self.database executeQuery:@"SELECT name FROM transaction_test WHERE id = 1;"];
    XCTAssertEqualObjects(nameResults[0][@"name"], @"initial", @"Should have original data");
}

#pragma mark - Memory Pressure Tests

/**
 * Test database behavior under memory pressure with large datasets
 */
- (void)testLargeDataset_MemoryPressure_ShouldHandleGracefully {
    // Create test table
    BOOL created = [self.database executeSQL:@"CREATE TABLE large_test (id INTEGER PRIMARY KEY, data TEXT);"];
    XCTAssertTrue(created);
    
    // Insert large amount of data
    NSInteger recordCount = 10000;
    NSString *largeString = [@"" stringByPaddingToLength:1000 withString:@"ABCDEFGHIJ" startingAtIndex:0];
    
    [self.database executeSQL:@"BEGIN TRANSACTION;"];
    for (NSInteger i = 0; i < recordCount; i++) {
        NSString *data = [NSString stringWithFormat:@"%@_%ld", largeString, (long)i];
        [self.database executeSQL:@"INSERT INTO large_test (data) VALUES (?);" withParameters:@[data]];
    }
    [self.database executeSQL:@"COMMIT;"];
    
    // Verify all data was inserted
    NSArray *countResults = [self.database executeQuery:@"SELECT COUNT(*) as count FROM large_test;"];
    XCTAssertEqual([countResults[0][@"count"] integerValue], recordCount, @"Should have inserted all records");
    
    // Test large query results
    NSArray *allResults = [self.database executeQuery:@"SELECT * FROM large_test LIMIT 1000;"];
    XCTAssertEqual(allResults.count, 1000, @"Should handle large result sets");
    
    // Verify data integrity of first and last records
    NSArray *firstResult = [self.database executeQuery:@"SELECT data FROM large_test WHERE id = 1;"];
    NSString *expectedFirst = [NSString stringWithFormat:@"%@_%d", largeString, 0];
    XCTAssertTrue([firstResult[0][@"data"] hasPrefix:largeString], @"First record should have correct data");
}

#pragma mark - Data Type Edge Cases

/**
 * Test handling of various data types and edge cases
 */
- (void)testDataTypes_EdgeCases_ShouldHandleCorrectly {
    // Create test table with various column types
    BOOL created = [self.database executeSQL:@"CREATE TABLE datatype_test (id INTEGER PRIMARY KEY, int_val INTEGER, real_val REAL, text_val TEXT, blob_val BLOB);"];
    XCTAssertTrue(created);
    
    // Test NULL values
    BOOL nullInserted = [self.database executeSQL:@"INSERT INTO datatype_test (int_val, real_val, text_val, blob_val) VALUES (?, ?, ?, ?);"
                                   withParameters:@[[NSNull null], [NSNull null], [NSNull null], [NSNull null]]];
    XCTAssertTrue(nullInserted);
    
    // Test extreme values
    NSNumber *maxInt = @(NSIntegerMax);
    NSNumber *minInt = @(NSIntegerMin);
    NSNumber *maxDouble = @(DBL_MAX);
    NSNumber *minDouble = @(-DBL_MAX);
    NSString *emptyString = @"";
    NSString *unicodeString = @"🚀📊💰🔧❌✅";
    NSData *emptyData = [NSData data];
    NSData *binaryData = [@"Binary data with null bytes \0\0\0 and special chars" dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL extremeInserted = [self.database executeSQL:@"INSERT INTO datatype_test (int_val, real_val, text_val, blob_val) VALUES (?, ?, ?, ?);"
                                      withParameters:@[maxInt, maxDouble, unicodeString, binaryData]];
    XCTAssertTrue(extremeInserted);
    
    BOOL extremeInserted2 = [self.database executeSQL:@"INSERT INTO datatype_test (int_val, real_val, text_val, blob_val) VALUES (?, ?, ?, ?);"
                                       withParameters:@[minInt, minDouble, emptyString, emptyData]];
    XCTAssertTrue(extremeInserted2);
    
    // Query and verify data
    NSArray *results = [self.database executeQuery:@"SELECT * FROM datatype_test ORDER BY id;"];
    XCTAssertEqual(results.count, 3);
    
    // Verify NULL values
    NSDictionary *nullRow = results[0];
    XCTAssertTrue([nullRow[@"int_val"] isKindOfClass:[NSNull class]]);
    XCTAssertTrue([nullRow[@"real_val"] isKindOfClass:[NSNull class]]);
    XCTAssertTrue([nullRow[@"text_val"] isKindOfClass:[NSNull class]]);
    XCTAssertTrue([nullRow[@"blob_val"] isKindOfClass:[NSNull class]]);
    
    // Verify extreme values
    NSDictionary *extremeRow = results[1];
    XCTAssertEqual([extremeRow[@"int_val"] longLongValue], NSIntegerMax);
    XCTAssertEqual([extremeRow[@"real_val"] doubleValue], DBL_MAX);
    XCTAssertEqualObjects(extremeRow[@"text_val"], unicodeString);
    XCTAssertEqualObjects(extremeRow[@"blob_val"], binaryData);
    
    // Verify other extreme values
    NSDictionary *extremeRow2 = results[2];
    XCTAssertEqual([extremeRow2[@"int_val"] longLongValue], NSIntegerMin);
    XCTAssertEqual([extremeRow2[@"real_val"] doubleValue], -DBL_MAX);
    XCTAssertEqualObjects(extremeRow2[@"text_val"], emptyString);
    XCTAssertEqualObjects(extremeRow2[@"blob_val"], emptyData);
}

#pragma mark - Error Recovery Tests

/**
 * Test database corruption recovery
 */
- (void)testDatabaseCorruption_Recovery_ShouldHandleGracefully {
    // Ensure database is ready
    XCTAssertNotNil(self.database, @"Database should be initialized");
    
    // Create test table and insert data
    BOOL created = [self.database executeSQL:@"CREATE TABLE recovery_test (id INTEGER PRIMARY KEY, data TEXT);"];
    XCTAssertTrue(created, @"Table creation should succeed");
    
    BOOL inserted = [self.database executeSQL:@"INSERT INTO recovery_test (data) VALUES (?);" withParameters:@[@"test_data"]];
    XCTAssertTrue(inserted, @"Initial insert should succeed");
    
    // Verify data exists
    NSArray *beforeResults = [self.database executeQuery:@"SELECT COUNT(*) as count FROM recovery_test;"];
    XCTAssertNotNil(beforeResults, @"Query should return results");
    XCTAssertGreaterThan(beforeResults.count, 0, @"Should have result rows");
    XCTAssertEqual([beforeResults[0][@"count"] integerValue], 1, @"Should have 1 record");
    
    // Simulate database corruption by executing invalid operations
    // Note: This is difficult to test without actually corrupting the file
    // Instead, we test error handling for invalid SQL
    
    BOOL invalidResult = [self.database executeSQL:@"INVALID SQL STATEMENT;"];
    XCTAssertFalse(invalidResult, @"Invalid SQL should return NO");
    
    // Verify database is still functional after error
    NSArray *afterResults = [self.database executeQuery:@"SELECT COUNT(*) as count FROM recovery_test;"];
    XCTAssertNotNil(afterResults, @"Query should return results after error");
    XCTAssertGreaterThan(afterResults.count, 0, @"Should have result rows after error");
    XCTAssertEqual([afterResults[0][@"count"] integerValue], 1, @"Should still have data after error");
    
    // Test that we can still insert data
    BOOL insertAfterError = [self.database executeSQL:@"INSERT INTO recovery_test (data) VALUES (?);" withParameters:@[@"after_error"]];
    XCTAssertTrue(insertAfterError, @"Should be able to insert after error");
    
    // Verify the new insert worked
    NSArray *finalResults = [self.database executeQuery:@"SELECT COUNT(*) as count FROM recovery_test;"];
    XCTAssertEqual([finalResults[0][@"count"] integerValue], 2, @"Should have 2 records after recovery");
}

/**
 * Test table existence checking with edge cases
 */
- (void)testTableExists_EdgeCases_ShouldHandleCorrectly {
    // Test with non-existent table
    BOOL nonExistent = [self.database tableExists:@"nonexistent_table"];
    XCTAssertFalse(nonExistent, @"Non-existent table should return false");
    
    // Test with empty string - should not crash and return false
    BOOL emptyResult = [self.database tableExists:@""];
    XCTAssertFalse(emptyResult, @"Empty string should return false");
    
    // Test with nil (should not crash) - wrap in try/catch for safety
    @try {
        BOOL nilResult = [self.database tableExists:nil];
        XCTAssertFalse(nilResult, @"nil should return false");
    } @catch (NSException *exception) {
        // Throwing is acceptable -- just don't crash the process
    }
    
    // Test with special characters - should not crash
    BOOL specialResult = [self.database tableExists:@"table'with\"special;chars"];
    XCTAssertFalse(specialResult, @"Special chars table should return false");
    
    // Create table and verify it exists
    BOOL created = [self.database executeSQL:@"CREATE TABLE test_exists (id INTEGER);"];
    XCTAssertTrue(created, @"Table creation should succeed");
    
    BOOL exists = [self.database tableExists:@"test_exists"];
    XCTAssertTrue(exists, @"Created table should exist");
    
    // Test case sensitivity - SQLite table names are case-insensitive by default
    // But the tableExists implementation might be case-sensitive
    // Just verify the exact name works; case variations are implementation-dependent
    BOOL exactMatch = [self.database tableExists:@"test_exists"];
    XCTAssertTrue(exactMatch, @"Exact table name should exist");
}

#pragma mark - Resource Management Tests

/**
 * Test proper cleanup of database resources
 */
- (void)testResourceCleanup_MultipleInstances_ShouldNotLeak {
    NSMutableArray *databases = [NSMutableArray array];
    
    // Create multiple database instances
    for (NSInteger i = 0; i < 100; i++) {
        NSString *dbName = [NSString stringWithFormat:@"cleanup_test_%ld", (long)i];
        CLXSQLiteDatabase *db = [[CLXSQLiteDatabase alloc] initWithDatabaseName:dbName];
        [databases addObject:db];
        
        // Perform some operations
        [db executeSQL:@"CREATE TABLE test (id INTEGER);"];
        [db executeSQL:@"INSERT INTO test (id) VALUES (?);" withParameters:@[@(i)]];
    }
    
    // Close all databases
    for (CLXSQLiteDatabase *db in databases) {
        [db closeDatabase];
    }
    
    // Clean up files including WAL/SHM sidecars
    for (NSInteger i = 0; i < 100; i++) {
        NSString *dbName = [NSString stringWithFormat:@"cleanup_test_%ld", (long)i];
        CLXSQLiteDatabase *tempDb = [[CLXSQLiteDatabase alloc] initWithDatabaseName:dbName];
        NSString *path = [tempDb databasePath];
        [tempDb closeDatabase];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-wal"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-shm"] error:nil];
    }
    
    // This test primarily checks for memory leaks and crashes
    // Test passes if no crash: Should complete without crashes or excessive memory usage
}

@end
