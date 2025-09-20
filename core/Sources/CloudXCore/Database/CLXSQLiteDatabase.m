/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXSQLiteDatabase.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXSQLiteDatabase ()
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, copy) NSString *databaseName;
@property (nonatomic, strong, readwrite) CLXLogger *logger;
@property (nonatomic, strong, readwrite) dispatch_queue_t databaseQueue;

// Private methods that run on the database queue
- (BOOL)_openDatabase;
- (BOOL)_executeSQL:(NSString *)sql withParameters:(nullable NSArray *)parameters;
- (NSArray<NSDictionary *> *)_executeQuery:(NSString *)sql withParameters:(nullable NSArray *)parameters;
- (void)_executeInTransaction:(void (^)(void))block;
- (id)_dispatchSyncIfNeeded:(id (^)(void))block;
@end

@implementation CLXSQLiteDatabase

- (instancetype)initWithDatabaseName:(NSString *)databaseName {
    self = [super init];
    if (self) {
        _databaseName = [databaseName copy];
        _logger = [[CLXLogger alloc] initWithCategory:@"SQLiteDatabase"];
        _databaseQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.cloudx.database.%@", databaseName] UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // Set a queue-specific key so we can detect if we're already on this queue
        dispatch_queue_set_specific(_databaseQueue, (__bridge const void *)_databaseQueue, (__bridge void *)_databaseQueue, NULL);
        
        [self openDatabase];
    }
    return self;
}

- (void)dealloc {
    [self closeDatabase];
}

#pragma mark - Database Lifecycle

- (BOOL)openDatabase {
    NSNumber *result = [self _dispatchSyncIfNeeded:^id {
        return @([self _openDatabase]);
    }];
    return result.boolValue;
}

- (BOOL)_openDatabase {
    NSString *path = [self databasePath];
    
    int result = sqlite3_open([path UTF8String], &self->_database);
    if (result != SQLITE_OK) {
        [self.logger error:[NSString stringWithFormat:@"Failed to open database at %@: %s", path, sqlite3_errmsg(self->_database)]];
        return NO;
    }
    
    // Enable foreign key constraints
    [self _executeSQL:@"PRAGMA foreign_keys = ON;" withParameters:@[]];
    
    [self.logger debug:[NSString stringWithFormat:@"Database opened successfully at %@", path]];
    return YES;
}

- (void)closeDatabase {
    [self _dispatchSyncIfNeeded:^id {
        if (self->_database) {
            sqlite3_close(self->_database);
            self->_database = NULL;
            [self.logger debug:@"Database closed"];
        }
        return nil;
    }];
}

#pragma mark - SQL Execution

- (BOOL)executeSQL:(NSString *)sql {
    if (!sql) {
        return NO;
    }
    return [self executeSQL:sql withParameters:@[]];
}

- (BOOL)executeSQL:(NSString *)sql withParameters:(NSArray *)parameters {
    NSNumber *result = [self _dispatchSyncIfNeeded:^id {
        return @([self _executeSQL:sql withParameters:parameters]);
    }];
    return result.boolValue;
}

- (BOOL)_executeSQL:(NSString *)sql withParameters:(nullable NSArray *)parameters {
    if (![self _validateDatabaseState] || ![self _validateSQL:sql]) {
        return NO;
    }
    
    sqlite3_stmt *statement;
    int result = sqlite3_prepare_v2(self->_database, [sql UTF8String], -1, &statement, NULL);
    
    if (result != SQLITE_OK) {
        [self.logger error:[NSString stringWithFormat:@"Failed to prepare statement: %s", sqlite3_errmsg(self->_database)]];
        return NO;
    }
    
    [self _bindParameters:parameters toStatement:statement];
    
    result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    if (result == SQLITE_DONE || result == SQLITE_ROW) {
        return YES;
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to execute statement: %s", sqlite3_errmsg(self->_database)]];
        return NO;
    }
}

#pragma mark - Query Execution

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql {
    if (!sql) {
        return @[];
    }
    return [self executeQuery:sql withParameters:@[]];
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql withParameters:(NSArray *)parameters {
    return [self _dispatchSyncIfNeeded:^id {
        return [self _executeQuery:sql withParameters:parameters];
    }];
}

- (NSArray<NSDictionary *> *)_executeQuery:(NSString *)sql withParameters:(nullable NSArray *)parameters {
    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
    
    if (![self _validateDatabaseState] || ![self _validateSQL:sql]) {
        return [results copy];
    }
    
    sqlite3_stmt *statement;
    int result = sqlite3_prepare_v2(self->_database, [sql UTF8String], -1, &statement, NULL);
    
    if (result != SQLITE_OK) {
        [self.logger error:[NSString stringWithFormat:@"Failed to prepare query: %s", sqlite3_errmsg(self->_database)]];
        return [results copy];
    }
    
    [self _bindParameters:parameters toStatement:statement];
    
    int columnCount = sqlite3_column_count(statement);
    
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSMutableDictionary *row = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < columnCount; i++) {
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];
            id value = [self _valueFromStatement:statement atColumn:i];
            row[columnName] = value;
        }
        
        [results addObject:[row copy]];
    }
    
    sqlite3_finalize(statement);
    return [results copy];
}

#pragma mark - Transaction Support

- (void)executeInTransaction:(void (^)(void))block {
    [self _dispatchSyncIfNeeded:^id {
        [self _executeInTransaction:block];
        return nil;
    }];
}

- (void)_executeInTransaction:(void (^)(void))block {
    [self _executeSQL:@"BEGIN TRANSACTION;" withParameters:@[]];
    
    @try {
        block();
        [self _executeSQL:@"COMMIT;" withParameters:@[]];
    } @catch (NSException *exception) {
        [self _executeSQL:@"ROLLBACK;" withParameters:@[]];
        [self.logger error:[NSString stringWithFormat:@"Transaction rolled back due to exception: %@", exception]];
        @throw exception;
    }
}

#pragma mark - Utility Methods

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", self.databaseName]];
}

- (BOOL)tableExists:(NSString *)tableName {
    // Handle nil or empty table name
    if (!tableName || tableName.length == 0) {
        return NO;
    }
    
    // Use case-insensitive comparison by using UPPER() function
    NSArray *results = [self executeQuery:@"SELECT name FROM sqlite_master WHERE type='table' AND UPPER(name)=UPPER(?);" withParameters:@[tableName]];
    return results.count > 0;
}

#pragma mark - Private Helper Methods

/**
 * Generic queue dispatch helper that eliminates redundant dispatch patterns
 * Follows the queue-aware dispatch pattern consistently across all methods
 */
- (id)_dispatchSyncIfNeeded:(id (^)(void))block {
    // Check if we're already on the database queue to avoid deadlock
    if (dispatch_get_specific((__bridge const void *)self.databaseQueue) != NULL) {
        return block();
    }
    
    __block id result = nil;
    dispatch_sync(self.databaseQueue, ^{
        result = block();
    });
    
    return result;
}

/**
 * Centralized parameter binding logic - eliminates 30+ lines of duplication
 */
- (void)_bindParameters:(NSArray *)parameters toStatement:(sqlite3_stmt *)statement {
    if (!parameters) {
        return;
    }
    
    for (NSInteger i = 0; i < parameters.count; i++) {
        [self _bindParameter:parameters[i] atIndex:(int)(i + 1) toStatement:statement];
    }
}

/**
 * Single responsibility: bind one parameter to a statement
 */
- (void)_bindParameter:(id)parameter atIndex:(int)index toStatement:(sqlite3_stmt *)statement {
    if ([parameter isKindOfClass:[NSString class]]) {
        sqlite3_bind_text(statement, index, [parameter UTF8String], -1, SQLITE_TRANSIENT);
    } else if ([parameter isKindOfClass:[NSNumber class]]) {
        NSNumber *number = parameter;
        if (strcmp([number objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(statement, index, [number boolValue] ? 1 : 0);
        } else if (strcmp([number objCType], @encode(int)) == 0 || 
                   strcmp([number objCType], @encode(long)) == 0 ||
                   strcmp([number objCType], @encode(NSInteger)) == 0) {
            sqlite3_bind_int64(statement, index, [number longLongValue]);
        } else {
            sqlite3_bind_double(statement, index, [number doubleValue]);
        }
    } else if ([parameter isKindOfClass:[NSData class]]) {
        NSData *data = parameter;
        // Handle empty NSData properly - SQLite needs a non-NULL pointer even for zero-length blobs
        if (data.length == 0) {
            sqlite3_bind_blob(statement, index, "", 0, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_blob(statement, index, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        }
    } else if ([parameter isKindOfClass:[NSNull class]]) {
        sqlite3_bind_null(statement, index);
    }
}

/**
 * Single responsibility: extract a value from a statement column
 */
- (id)_valueFromStatement:(sqlite3_stmt *)statement atColumn:(int)columnIndex {
    int columnType = sqlite3_column_type(statement, columnIndex);
    
    switch (columnType) {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int64(statement, columnIndex));
        case SQLITE_FLOAT:
            return @(sqlite3_column_double(statement, columnIndex));
        case SQLITE_TEXT: {
            const char *text = (const char *)sqlite3_column_text(statement, columnIndex);
            return text ? [NSString stringWithUTF8String:text] : @"";
        }
        case SQLITE_BLOB: {
            const void *blob = sqlite3_column_blob(statement, columnIndex);
            int blobSize = sqlite3_column_bytes(statement, columnIndex);
            return blob ? [NSData dataWithBytes:blob length:blobSize] : [NSData data];
        }
        case SQLITE_NULL:
        default:
            return [NSNull null];
    }
}

/**
 * Centralized SQL validation
 */
- (BOOL)_validateSQL:(NSString *)sql {
    if (!sql || sql.length == 0) {
        [self.logger error:@"SQL query cannot be nil or empty"];
        return NO;
    }
    return YES;
}

/**
 * Centralized database state validation
 */
- (BOOL)_validateDatabaseState {
    if (!self->_database) {
        [self.logger error:@"Database not initialized"];
        return NO;
    }
    return YES;
}

@end