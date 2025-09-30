/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXBaseDao.h"
#import "CLXDatabaseProtocol.h"
#import "CLXError.h"
#import "CLXLogger.h"

@interface CLXBaseDao ()

@property (nonatomic, weak) id<CLXDatabaseProtocol> database;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) dispatch_queue_t operationQueue;

// SQL statement cache
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *sqlCache;

@end

@implementation CLXBaseDao

#pragma mark - Initialization

- (instancetype)initWithDatabase:(id<CLXDatabaseProtocol>)database {
    if (self = [super init]) {
        _database = database;
        _logger = [[CLXLogger alloc] initWithCategory:NSStringFromClass([self class])];
        _operationQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.cloudx.dao.%@", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL);
        _sqlCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Abstract Methods (Must be overridden)

- (NSString *)tableName {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"tableName must be implemented by subclasses"
                                 userInfo:nil];
}

- (NSArray<NSString *> *)columnNames {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"columnNames must be implemented by subclasses"
                                 userInfo:nil];
}

- (NSString *)primaryKeyColumn {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"primaryKeyColumn must be implemented by subclasses"
                                 userInfo:nil];
}

- (NSArray *)sqlValuesFromEntity:(id)entity {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"sqlValuesFromEntity: must be implemented by subclasses"
                                 userInfo:nil];
}

- (id)entityFromSQLRow:(NSDictionary *)row {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"entityFromSQLRow: must be implemented by subclasses"
                                 userInfo:nil];
}

#pragma mark - CLXBaseDao Protocol Implementation

- (BOOL)insert:(id)entity {
    if (![self validateEntity:entity error:nil]) {
        [self.logger error:@"Entity validation failed for insert"];
        return NO;
    }
    
    NSString *sql = [self insertSQL];
    NSArray *values = nil;
    if ([entity respondsToSelector:@selector(sqlInsertValues)]) {
        values = [entity performSelector:@selector(sqlInsertValues)];
    } else {
        [self.logger error:@"Entity does not implement sqlInsertValues method"];
        return NO;
    }
    
    BOOL success = [self.database executeSQL:sql withParameters:values];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Successfully inserted entity into %@", self.tableName]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to insert entity into %@", self.tableName]];
    }
    
    return success;
}

- (BOOL)insertBatch:(NSArray *)entities {
    if (!entities || entities.count == 0) {
        return YES; // Empty batch is considered successful
    }
    
    // Validate all entities first
    for (id entity in entities) {
        if (![self validateEntity:entity error:nil]) {
            [self.logger error:@"Entity validation failed in batch insert"];
            return NO;
        }
    }
    
    __block BOOL success = YES;
    
    [self.database executeInTransaction:^{
        NSString *sql = [self insertSQL];
        
        for (id entity in entities) {
            NSArray *values = [self sqlValuesFromEntity:entity];
            if (![self.database executeSQL:sql withParameters:values]) {
                [self.logger error:@"Failed to insert entity in batch"];
                success = NO;
                break;
            }
        }
    }];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Successfully inserted %lu entities into %@", 
                     (unsigned long)entities.count, self.tableName]];
    }
    
    return success;
}

- (nullable id)findById:(NSString *)entityId {
    if (!entityId) {
        return nil;
    }
    
    NSString *sql = [self selectByIdSQL];
    NSArray *results = [self.database executeQuery:sql withParameters:@[entityId]];
    
    if (results.count > 0) {
        return [self entityFromSQLRow:results[0]];
    }
    
    return nil;
}

- (NSArray *)findAll {
    NSString *sql = [self selectAllSQL];
    NSArray *results = [self.database executeQuery:sql];
    
    NSMutableArray *entities = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        id entity = [self entityFromSQLRow:row];
        if (entity) {
            [entities addObject:entity];
        }
    }
    
    return [entities copy];
}

- (BOOL)update:(id)entity {
    if (![self validateEntity:entity error:nil]) {
        [self.logger error:@"Entity validation failed for update"];
        return NO;
    }
    
    NSString *sql = [self updateSQL];
    NSArray *values = [self sqlValuesFromEntity:entity];
    
    BOOL success = [self.database executeSQL:sql withParameters:values];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Successfully updated entity in %@", self.tableName]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to update entity in %@", self.tableName]];
    }
    
    return success;
}

- (BOOL)deleteById:(NSString *)entityId {
    if (!entityId) {
        return NO;
    }
    
    NSString *sql = [self deleteByIdSQL];
    BOOL success = [self.database executeSQL:sql withParameters:@[entityId]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Successfully deleted entity from %@", self.tableName]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete entity from %@", self.tableName]];
    }
    
    return success;
}

- (BOOL)deleteAll {
    NSString *sql = [self deleteAllSQL];
    BOOL success = [self.database executeSQL:sql];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Successfully deleted all entities from %@", self.tableName]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete all entities from %@", self.tableName]];
    }
    
    return success;
}

- (NSInteger)count {
    NSString *sql = [self countSQL];
    NSArray *results = [self.database executeQuery:sql];
    
    if (results.count > 0) {
        return [results[0][@"count"] integerValue];
    }
    
    return 0;
}

#pragma mark - SQL Generation

- (NSString *)insertSQL {
    NSString *cacheKey = @"insert";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *columnList = [self.columnNames componentsJoinedByString:@", "];
    NSMutableArray *placeholders = [NSMutableArray arrayWithCapacity:self.columnNames.count];
    for (NSUInteger i = 0; i < self.columnNames.count; i++) {
        [placeholders addObject:@"?"];
    }
    NSString *placeholderList = [placeholders componentsJoinedByString:@", "];
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
                    self.tableName, columnList, placeholderList];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)selectByIdSQL {
    NSString *cacheKey = @"selectById";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                    self.tableName, self.primaryKeyColumn];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)selectAllSQL {
    NSString *cacheKey = @"selectAll";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY created_at DESC",
                    self.tableName];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)updateSQL {
    NSString *cacheKey = @"update";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSMutableArray *setClause = [NSMutableArray arrayWithCapacity:self.columnNames.count];
    for (NSString *column in self.columnNames) {
        if (![column isEqualToString:self.primaryKeyColumn]) {
            [setClause addObject:[NSString stringWithFormat:@"%@ = ?", column]];
        }
    }
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?",
                    self.tableName, [setClause componentsJoinedByString:@", "], self.primaryKeyColumn];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)deleteByIdSQL {
    NSString *cacheKey = @"deleteById";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                    self.tableName, self.primaryKeyColumn];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)deleteAllSQL {
    NSString *cacheKey = @"deleteAll";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", self.tableName];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

- (NSString *)countSQL {
    NSString *cacheKey = @"count";
    NSString *cachedSQL = self.sqlCache[cacheKey];
    if (cachedSQL) {
        return cachedSQL;
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) as count FROM %@", self.tableName];
    
    self.sqlCache[cacheKey] = sql;
    return sql;
}

#pragma mark - Validation

- (BOOL)validateEntity:(id)entity error:(NSError **)error {
    NSArray<NSString *> *errors = [self validationErrorsForEntity:entity];
    
    if (errors.count > 0) {
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"Validation failed: %@", 
                                    [errors componentsJoinedByString:@", "]];
            *error = [CLXError errorWithCode:CLXErrorCodeInvalidRequest description:errorMessage];
        }
        return NO;
    }
    
    return YES;
}

- (NSArray<NSString *> *)validationErrorsForEntity:(id)entity {
    NSMutableArray *errors = [NSMutableArray array];
    
    if (!entity) {
        [errors addObject:@"Entity cannot be nil"];
    }
    
    // Subclasses should override to add specific validation
    
    return [errors copy];
}

#pragma mark - Utility Methods

- (NSString *)generateId {
    return [[NSUUID UUID] UUIDString];
}

- (NSTimeInterval)currentTimestamp {
    return [[NSDate date] timeIntervalSince1970];
}

@end
