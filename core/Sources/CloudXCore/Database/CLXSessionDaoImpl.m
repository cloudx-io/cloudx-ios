/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXSessionDaoImpl.h"
#import "CLXSession.h"
#import "CLXDatabaseProtocol.h"
#import "CLXError.h"
#import "CLXLogger.h"

@implementation CLXSessionDaoImpl

#pragma mark - CLXBaseDao Overrides

- (NSString *)tableName {
    return [CLXSession sqlTableName];
}

- (NSArray<NSString *> *)columnNames {
    return [CLXSession sqlColumnNames];
}

- (NSString *)primaryKeyColumn {
    return @"id";
}

- (NSArray *)sqlValuesFromEntity:(CLXSession *)entity {
    return [entity sqlInsertValues];
}

- (CLXSession *)entityFromSQLRow:(NSDictionary *)row {
    NSString *sessionId = row[@"sessionId"];
    NSString *appKey = row[@"appKey"];
    NSString *url = row[@"url"];
    
    if (!sessionId || !appKey) {
        return nil;
    }
    
    CLXSession *session = [[CLXSession alloc] initWithSessionId:sessionId appKey:appKey url:url];
    [session updateFromSQLRow:row];
    return session;
}

#pragma mark - CLXSessionDao Protocol Implementation

- (BOOL)insertSession:(CLXSession *)session {
    return [self insert:session];
}

- (nullable CLXSession *)findSessionById:(NSString *)sessionId {
    NSString *sql = @"SELECT * FROM session_table WHERE sessionId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[sessionId]];
    
    if (results.count > 0) {
        return [self entityFromSQLRow:results[0]];
    }
    
    return nil;
}

- (nullable CLXSession *)findCurrentSession {
    NSString *sql = @"SELECT * FROM session_table WHERE endTime = 0 ORDER BY startTime DESC LIMIT 1";
    NSArray *results = [self.database executeQuery:sql];
    
    if (results.count > 0) {
        return [self entityFromSQLRow:results[0]];
    }
    
    return nil;
}

- (NSArray<CLXSession *> *)findSessionsByAppKey:(NSString *)appKey {
    NSString *sql = @"SELECT * FROM session_table WHERE appKey = ? ORDER BY startTime DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[appKey]];
    
    NSMutableArray *sessions = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXSession *session = [self entityFromSQLRow:row];
        if (session) {
            [sessions addObject:session];
        }
    }
    
    return [sessions copy];
}

- (NSArray<CLXSession *> *)findSessionsInTimeRange:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime {
    NSString *sql = @"SELECT * FROM session_table WHERE startTime >= ? AND startTime <= ? ORDER BY startTime DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(startTime), @(endTime)]];
    
    NSMutableArray *sessions = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXSession *session = [self entityFromSQLRow:row];
        if (session) {
            [sessions addObject:session];
        }
    }
    
    return [sessions copy];
}

#pragma mark - Session Lifecycle

- (BOOL)updateSessionEndTime:(NSString *)sessionId endTime:(NSTimeInterval)endTime {
    NSString *sql = @"UPDATE session_table SET endTime = ?, updated_at = ? WHERE sessionId = ?";
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    return [self.database executeSQL:sql withParameters:@[@(endTime), @(now), sessionId]];
}

- (BOOL)updateSessionDuration:(NSString *)sessionId duration:(NSTimeInterval)duration {
    NSString *sql = @"UPDATE session_table SET duration = ?, updated_at = ? WHERE sessionId = ?";
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    return [self.database executeSQL:sql withParameters:@[@(duration), @(now), sessionId]];
}

- (BOOL)updateSessionUrl:(NSString *)sessionId url:(NSString *)url {
    NSString *sql = @"UPDATE session_table SET url = ?, updated_at = ? WHERE sessionId = ?";
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    return [self.database executeSQL:sql withParameters:@[url, @(now), sessionId]];
}

#pragma mark - Analytics

- (NSInteger)getSessionCountForAppKey:(NSString *)appKey {
    NSString *sql = @"SELECT COUNT(*) as count FROM session_table WHERE appKey = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[appKey]];
    
    if (results.count > 0) {
        return [results[0][@"count"] integerValue];
    }
    
    return 0;
}

- (NSTimeInterval)getAverageSessionDuration {
    NSString *sql = @"SELECT AVG(duration) as average FROM session_table WHERE duration > 0";
    NSArray *results = [self.database executeQuery:sql];
    
    if (results.count > 0 && results[0][@"average"]) {
        return [results[0][@"average"] doubleValue];
    }
    
    return 0;
}

- (NSArray<CLXSession *> *)findActiveSessions {
    NSString *sql = @"SELECT * FROM session_table WHERE endTime = 0 ORDER BY startTime DESC";
    NSArray *results = [self.database executeQuery:sql];
    
    NSMutableArray *sessions = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXSession *session = [self entityFromSQLRow:row];
        if (session) {
            [sessions addObject:session];
        }
    }
    
    return [sessions copy];
}

#pragma mark - Cleanup Operations

- (BOOL)deleteSessionsOlderThan:(NSTimeInterval)timestamp {
    NSString *sql = @"DELETE FROM session_table WHERE created_at < ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[@(timestamp)]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted sessions older than %f", timestamp]];
    } else {
        [self.logger error:@"Failed to delete old sessions"];
    }
    
    return success;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrorsForEntity:(CLXSession *)entity {
    NSMutableArray *errors = [[super validationErrorsForEntity:entity] mutableCopy];
    
    if (![entity isKindOfClass:[CLXSession class]]) {
        [errors addObject:@"Entity must be a CLXSession"];
        return [errors copy];
    }
    
    // Add CLXSession-specific validation
    NSArray *sessionErrors = [entity validationErrors];
    [errors addObjectsFromArray:sessionErrors];
    
    return [errors copy];
}

@end
