/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXCloudXDatabase.h"
#import "CLXDatabaseSchema.h"
#import "CLXDaoProtocols.h"
#import "CLXError.h"
#import "CLXLogger.h"

// DAO Implementations
#import "CLXMetricsEventDaoImpl.h"
#import "CLXRillEventDaoImpl.h"
#import "CLXSessionDaoImpl.h"
#import "CLXPerformanceDaoImpl.h"

@interface CLXCloudXDatabase ()

@property (nonatomic, strong) id<CLXMetricsEventDao> metricsDao;
@property (nonatomic, strong) id<CLXRillEventDao> rillEventDao;
@property (nonatomic, strong) id<CLXSessionDao> sessionDao;
@property (nonatomic, strong) id<CLXPerformanceDao> performanceDao;

@end

// Test instance storage (weak to allow deallocation)
static CLXCloudXDatabase *_testInstance = nil;

@implementation CLXCloudXDatabase

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    // Return test instance if set (for unit testing)
    if (_testInstance) {
        return _testInstance;
    }
    
    // Default production singleton
    static CLXCloudXDatabase *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXCloudXDatabase alloc] initWithDatabaseName:CLXDatabaseName];
    });
    return sharedInstance;
}

+ (void)setSharedInstanceForTesting:(nullable CLXCloudXDatabase *)testInstance {
    _testInstance = testInstance;
}

#pragma mark - Initialization

- (instancetype)initWithDatabaseName:(NSString *)databaseName {
    if (self = [super initWithDatabaseName:databaseName]) {
        [self initializeDAOs];
    }
    return self;
}

- (void)initializeDAOs {
    // Initialize DAO implementations with dependency injection
    self.metricsDao = [[CLXMetricsEventDaoImpl alloc] initWithDatabase:self];
    self.rillEventDao = [[CLXRillEventDaoImpl alloc] initWithDatabase:self];
    self.sessionDao = [[CLXSessionDaoImpl alloc] initWithDatabase:self];
    self.performanceDao = [[CLXPerformanceDaoImpl alloc] initWithDatabase:self];
}

#pragma mark - Database Lifecycle

- (BOOL)openDatabase {
    BOOL success = [super openDatabase];
    if (success) {
        success = [self initializeSchema];
    }
    return success;
}

- (BOOL)isOpen {
    // Check if database is open by trying to execute a simple query
    NSArray *result = [self executeQuery:@"SELECT 1"];
    return result != nil;
}

#pragma mark - Schema Management

- (BOOL)initializeSchema {
    __block BOOL success = YES;
    
    [self executeInTransaction:^{
        // Create all tables
        NSArray *createTableStatements = @[
            [CLXDatabaseSchema createMetricsEventTableSQL],
            [CLXDatabaseSchema createCachedTrackingEventsTableSQL],
            [CLXDatabaseSchema createSessionTableSQL],
            [CLXDatabaseSchema createPerformanceMetricsTableSQL]
        ];
        
        for (NSString *sql in createTableStatements) {
            if (![self executeSQL:sql]) {
                [self.logger error:[NSString stringWithFormat:@"Failed to create table with SQL: %@", sql]];
                success = NO;
                break;
            }
        }
        
        if (success) {
            // Create indexes for performance optimization
            NSArray *indexStatements = [CLXDatabaseSchema createIndexesSQL];
            for (NSString *sql in indexStatements) {
                if (![self executeSQL:sql]) {
                    [self.logger info:[NSString stringWithFormat:@"Failed to create index with SQL: %@", sql]];
                    // Index creation failure is not fatal
                }
            }
        }
        
        if (success) {
            // Set database version
            success = [self setDatabaseVersion:CLXDatabaseCurrentVersion];
        }
    }];
    
    if (success) {
        [self.logger info:@"Database schema initialized successfully"];
    } else {
        [self.logger error:@"Failed to initialize database schema"];
    }
    
    return success;
}

- (BOOL)migrateFromVersion:(NSInteger)fromVersion toVersion:(NSInteger)toVersion {
    if (fromVersion == toVersion) {
        return YES;
    }
    
    [self.logger info:[NSString stringWithFormat:@"Migrating database from version %ld to %ld", (long)fromVersion, (long)toVersion]];
    
    __block BOOL success = YES;
    
    [self executeInTransaction:^{
        NSArray *migrationStatements = [CLXDatabaseSchema migrationSQLFromVersion:fromVersion toVersion:toVersion];
        
        for (NSString *sql in migrationStatements) {
            if (![self executeSQL:sql]) {
                [self.logger error:[NSString stringWithFormat:@"Migration failed at SQL: %@", sql]];
                success = NO;
                break;
            }
        }
        
        if (success) {
            success = [self setDatabaseVersion:toVersion];
        }
    }];
    
    if (success) {
        [self.logger info:@"Database migration completed successfully"];
    } else {
        [self.logger error:@"Database migration failed"];
    }
    
    return success;
}

#pragma mark - Transaction Support

- (BOOL)executeInTransactionWithResult:(BOOL (^)(void))block {
    return [super executeInTransactionWithResult:block];
}

#pragma mark - Bulk Operations

- (BOOL)executeBulkInsert:(NSString *)tableName 
                  columns:(NSArray<NSString *> *)columns 
                   values:(NSArray<NSArray *> *)valueArrays {
    
    if (!tableName || columns.count == 0 || valueArrays.count == 0) {
        [self.logger error:@"Invalid parameters for bulk insert"];
        return NO;
    }
    
    // Validate all value arrays have the same length as columns
    for (NSArray *values in valueArrays) {
        if (values.count != columns.count) {
            [self.logger error:@"Value array length mismatch in bulk insert"];
            return NO;
        }
    }
    
    __block BOOL success = YES;
    
    [self executeInTransaction:^{
        // Build the SQL statement
        NSString *columnList = [columns componentsJoinedByString:@", "];
        NSString *placeholders = [@"?" stringByPaddingToLength:columns.count * 2 - 1 
                                                    withString:@", ?" 
                                               startingAtIndex:0];
        
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", 
                        tableName, columnList, placeholders];
        
        // Execute for each value array
        for (NSArray *values in valueArrays) {
            if (![self executeSQL:sql withParameters:values]) {
                [self.logger error:[NSString stringWithFormat:@"Bulk insert failed for values: %@", values]];
                success = NO;
                break;
            }
        }
    }];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Bulk insert completed: %lu rows into %@", 
                     (unsigned long)valueArrays.count, tableName]];
    }
    
    return success;
}

#pragma mark - Database Maintenance

- (void)vacuum {
    dispatch_async(self.databaseQueue, ^{
        NSString *sql = [CLXDatabaseSchema vacuumSQL];
        if ([self executeSQL:sql]) {
            [self.logger info:@"Database vacuum completed"];
        } else {
            [self.logger error:@"Database vacuum failed"];
        }
    });
}

- (void)analyze {
    dispatch_async(self.databaseQueue, ^{
        NSString *sql = [CLXDatabaseSchema analyzeSQL];
        if ([self executeSQL:sql]) {
            [self.logger info:@"Database analyze completed"];
        } else {
            [self.logger error:@"Database analyze failed"];
        }
    });
}

#pragma mark - Version Management

- (NSInteger)getDatabaseVersion {
    NSArray *result = [self executeQuery:@"PRAGMA user_version"];
    if (result.count > 0) {
        return [result[0][@"user_version"] integerValue];
    }
    return 0;
}

- (BOOL)setDatabaseVersion:(NSInteger)version {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %ld", (long)version];
    return [self executeSQL:sql];
}


#pragma mark - DAO Getters

- (id<CLXMetricsEventDao>)metricsDao {
    return _metricsDao;
}

- (id<CLXRillEventDao>)rillEventDao {
    return _rillEventDao;
}

- (id<CLXSessionDao>)sessionDao {
    return _sessionDao;
}

- (id<CLXPerformanceDao>)performanceDao {
    return _performanceDao;
}

@end
