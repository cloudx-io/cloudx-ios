/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsEventDaoImpl.h"
#import "CLXMetricsEvent.h"
#import "CLXDatabaseProtocol.h"
#import "CLXError.h"
#import "CLXLogger.h"

@implementation CLXMetricsEventDaoImpl

#pragma mark - CLXBaseDao Overrides

- (NSString *)tableName {
    return [CLXMetricsEvent sqlTableName];
}

- (NSArray<NSString *> *)columnNames {
    return [CLXMetricsEvent sqlColumnNames];
}

- (NSString *)primaryKeyColumn {
    return @"id";
}

- (NSArray *)sqlValuesFromEntity:(CLXMetricsEvent *)entity {
    return [entity sqlInsertValues];
}

- (CLXMetricsEvent *)entityFromSQLRow:(NSDictionary *)row {
    NSString *eventId = row[@"id"];
    NSString *sessionId = row[@"sessionId"] ?: @"";
    NSString *metricName = row[@"metricName"] ?: @"";
    NSString *auctionId = row[@"auctionId"] ?: @"";
    
    if (!eventId) {
        return nil;
    }
    
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:eventId
                                                            sessionId:sessionId
                                                           metricName:metricName
                                                            auctionId:auctionId];
    
    [event updateFromSQLRow:row];
    return event;
}

#pragma mark - CLXMetricsEventDao Protocol Implementation

- (BOOL)insertMetricsEvent:(CLXMetricsEvent *)event {
    return [self insert:event];
}

- (BOOL)insertMetricsEventBatch:(NSArray<CLXMetricsEvent *> *)events {
    return [self insertBatch:events];
}

- (nullable CLXMetricsEvent *)findMetricsEventById:(NSString *)eventId {
    return [self findById:eventId];
}

- (NSArray<CLXMetricsEvent *> *)findMetricsEventsBySessionId:(NSString *)sessionId {
    NSString *sql = @"SELECT * FROM metrics_event_table WHERE sessionId = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[sessionId]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXMetricsEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXMetricsEvent *> *)findMetricsEventsByAuctionId:(NSString *)auctionId {
    NSString *sql = @"SELECT * FROM metrics_event_table WHERE auctionId = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[auctionId]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXMetricsEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXMetricsEvent *> *)findMetricsEventsByMetricName:(NSString *)metricName {
    NSString *sql = @"SELECT * FROM metrics_event_table WHERE metricName = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[metricName]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXMetricsEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXMetricsEvent *> *)findMetricsEventsCreatedAfter:(NSTimeInterval)timestamp {
    NSString *sql = @"SELECT * FROM metrics_event_table WHERE created_at > ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(timestamp)]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXMetricsEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

#pragma mark - Aggregation Operations

- (NSInteger)getTotalCounterForMetric:(NSString *)metricName sessionId:(NSString *)sessionId {
    NSString *sql = @"SELECT SUM(counter) as total FROM metrics_event_table WHERE metricName = ? AND sessionId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[metricName, sessionId]];
    
    if (results.count > 0 && results[0][@"total"]) {
        return [results[0][@"total"] integerValue];
    }
    
    return 0;
}

- (NSInteger)getTotalLatencyForMetric:(NSString *)metricName sessionId:(NSString *)sessionId {
    NSString *sql = @"SELECT SUM(totalLatency) as total FROM metrics_event_table WHERE metricName = ? AND sessionId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[metricName, sessionId]];
    
    if (results.count > 0 && results[0][@"total"]) {
        return [results[0][@"total"] integerValue];
    }
    
    return 0;
}

- (NSDictionary<NSString *, NSNumber *> *)getMetricsSummaryForSession:(NSString *)sessionId {
    NSString *sql = @"SELECT metricName, SUM(counter) as totalCounter, SUM(totalLatency) as totalLatency, COUNT(*) as eventCount FROM metrics_event_table WHERE sessionId = ? GROUP BY metricName";
    NSArray *results = [self.database executeQuery:sql withParameters:@[sessionId]];
    
    NSMutableDictionary *summary = [NSMutableDictionary dictionary];
    
    for (NSDictionary *row in results) {
        NSString *metricName = row[@"metricName"];
        if (metricName) {
            summary[metricName] = @{
                @"totalCounter": row[@"totalCounter"] ?: @0,
                @"totalLatency": row[@"totalLatency"] ?: @0,
                @"eventCount": row[@"eventCount"] ?: @0,
                @"averageLatency": [self calculateAverageLatency:row[@"totalLatency"] counter:row[@"totalCounter"]]
            };
        }
    }
    
    return [summary copy];
}

- (NSNumber *)calculateAverageLatency:(NSNumber *)totalLatency counter:(NSNumber *)counter {
    if (!totalLatency || !counter || [counter integerValue] == 0) {
        return @0;
    }
    
    return @([totalLatency doubleValue] / [counter doubleValue]);
}

#pragma mark - Cleanup Operations

- (BOOL)deleteMetricsEventsOlderThan:(NSTimeInterval)timestamp {
    NSString *sql = @"DELETE FROM metrics_event_table WHERE created_at < ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[@(timestamp)]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted metrics events older than %f", timestamp]];
    } else {
        [self.logger error:@"Failed to delete old metrics events"];
    }
    
    return success;
}

- (BOOL)deleteMetricsEventsBySessionId:(NSString *)sessionId {
    NSString *sql = @"DELETE FROM metrics_event_table WHERE sessionId = ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[sessionId]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted metrics events for session: %@", sessionId]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete metrics events for session: %@", sessionId]];
    }
    
    return success;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrorsForEntity:(CLXMetricsEvent *)entity {
    NSMutableArray *errors = [[super validationErrorsForEntity:entity] mutableCopy];
    
    if (![entity isKindOfClass:[CLXMetricsEvent class]]) {
        [errors addObject:@"Entity must be a CLXMetricsEvent"];
        return [errors copy];
    }
    
    // Add CLXMetricsEvent-specific validation
    NSArray *metricsErrors = [entity validationErrors];
    [errors addObjectsFromArray:metricsErrors];
    
    return [errors copy];
}

@end
