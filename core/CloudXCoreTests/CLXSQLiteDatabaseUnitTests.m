/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSQLiteDatabaseUnitTests.m
 * @brief Fast, deterministic unit tests for CLXSQLiteDatabase guard/validation logic
 *
 * These tests cover input validation, edge cases, and safety guards in the SQLite
 * abstraction layer. Each test creates a lightweight temp database that is cleaned
 * up in tearDown -- no async, no network, no timing dependencies.
 *
 * Heavier integration tests (SQL injection, large datasets, transactions, corruption
 * recovery) live in CloudXCoreIntegrationTests/CLXSQLiteDatabaseTests.m.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <unistd.h>

@interface CLXSQLiteDatabase (Testing)
@property (nonatomic, assign, readonly) sqlite3 *database;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;
- (NSString *)databasePath;
@end

@interface CLXSQLiteDatabaseUnitTests : XCTestCase
@property (nonatomic, strong) CLXSQLiteDatabase *database;
@property (nonatomic, strong) NSString *testDatabaseName;
@end

@implementation CLXSQLiteDatabaseUnitTests

- (void)setUp {
    [super setUp];
    self.testDatabaseName = [NSString stringWithFormat:@"unit_test_%d_%@",
                             getpid(), [[NSUUID UUID] UUIDString]];
    self.database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:self.testDatabaseName];
}

- (void)tearDown {
    if (self.database) {
        [self.database closeDatabase];
        NSString *dbPath = [self.database databasePath];
        if (dbPath) {
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
        }
    }
    self.database = nil;
    self.testDatabaseName = nil;
    [super tearDown];
}

#pragma mark - Initialization

- (void)testInitWithDatabaseName_CreatesValidPath {
    NSString *path = [self.database databasePath];
    XCTAssertNotNil(path);
    XCTAssertTrue([path hasSuffix:@".sqlite"], @"Path should end with .sqlite extension");
    XCTAssertTrue([path containsString:self.testDatabaseName], @"Path should contain the database name");
}

- (void)testInitWithDatabaseName_OpensDatabaseHandle {
    XCTAssertNotEqual(self.database.database, (sqlite3 *)NULL, @"Database should be open after initialization");
}

#pragma mark - Nil / Empty SQL Guards

- (void)testExecuteSQL_NilSQL_ReturnsFalse {
    NSString *nilSQL = nil;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertFalse([self.database executeSQL:nilSQL], @"nil SQL should return NO");
    #pragma clang diagnostic pop
}

- (void)testExecuteSQL_EmptySQL_ReturnsFalse {
    XCTAssertFalse([self.database executeSQL:@""], @"Empty SQL should return NO");
}

- (void)testExecuteQuery_NilSQL_ReturnsEmptyArray {
    NSString *nilSQL = nil;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    NSArray *results = [self.database executeQuery:nilSQL];
    #pragma clang diagnostic pop
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0, @"nil SQL query should return empty results");
}

- (void)testExecuteQuery_EmptySQL_ReturnsEmptyArray {
    NSArray *results = [self.database executeQuery:@""];
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0, @"Empty SQL query should return empty results");
}

#pragma mark - Closed Database Guards

- (void)testCloseDatabase_CalledTwice_DoesNotCrash {
    [self.database closeDatabase];
    XCTAssertNoThrow([self.database closeDatabase], @"Double close must be a safe no-op");
}

- (void)testExecuteSQL_OnClosedDatabase_ReturnsFalse {
    [self.database closeDatabase];
    BOOL result = [self.database executeSQL:@"CREATE TABLE test (id INTEGER);"];
    XCTAssertFalse(result, @"Should fail when database is closed");
}

- (void)testExecuteQuery_OnClosedDatabase_ReturnsEmptyArray {
    [self.database closeDatabase];
    NSArray *results = [self.database executeQuery:@"SELECT 1;"];
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0, @"Should return empty result when database is closed");
}

#pragma mark - tableExists Edge Cases

- (void)testTableExists_EmptyString_ReturnsFalse {
    XCTAssertFalse([self.database tableExists:@""], @"Empty string should return false");
}

- (void)testTableExists_Nil_ReturnsFalse {
    BOOL result = NO;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNoThrow(result = [self.database tableExists:nil]);
    #pragma clang diagnostic pop

    XCTAssertFalse(result, @"nil should return false");
}

- (void)testTableExists_NonExistentTable_ReturnsFalse {
    XCTAssertFalse([self.database tableExists:@"nonexistent_table"]);
}

- (void)testTableExists_OnClosedDatabase_ReturnsFalse {
    [self.database closeDatabase];
    XCTAssertFalse([self.database tableExists:@"any_table"],
                   @"tableExists must return NO when the database handle is closed");
}

#pragma mark - Parameter Binding (Guards)

- (void)testExecuteSQL_WithEmptyParameterArray_ReturnsFalse {
    BOOL result = [self.database executeSQL:@"" withParameters:@[]];
    XCTAssertFalse(result, @"Empty SQL with empty params should return NO");
}

- (void)testExecuteSQL_WithNilParameters_ReturnsFalse {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    BOOL result = [self.database executeSQL:@"" withParameters:nil];
    #pragma clang diagnostic pop
    XCTAssertFalse(result, @"Empty SQL with nil params should return NO");
}

- (void)testExecuteSQL_WithParameters_OnClosedDatabase_ReturnsFalse {
    [self.database closeDatabase];
    BOOL result = [self.database executeSQL:@"INSERT INTO t (c) VALUES (?);" withParameters:@[@"v"]];
    XCTAssertFalse(result, @"Should fail when database is closed regardless of parameters");
}

- (void)testExecuteQuery_WithParameters_OnClosedDatabase_ReturnsEmptyArray {
    [self.database closeDatabase];
    NSArray *results = [self.database executeQuery:@"SELECT * FROM t WHERE c = ?;" withParameters:@[@"v"]];
    XCTAssertNotNil(results);
    XCTAssertEqual(results.count, 0, @"Should return empty result when database is closed");
}

#pragma mark - Invalid SQL (Syntax)

- (void)testExecuteSQL_InvalidSyntax_ReturnsFalse {
    BOOL result = [self.database executeSQL:@"NOT VALID SQL AT ALL;"];
    XCTAssertFalse(result, @"Invalid SQL syntax should return NO");
}

- (void)testExecuteSQL_NonExistentTable_ReturnsFalse {
    BOOL result = [self.database executeSQL:@"INSERT INTO ghost_table (x) VALUES (1);"];
    XCTAssertFalse(result, @"Referencing a non-existent table should return NO");
}

@end
