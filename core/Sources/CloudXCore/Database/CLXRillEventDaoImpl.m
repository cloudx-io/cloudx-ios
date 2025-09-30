/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXRillEventDaoImpl.h"
#import "CLXRillEvent.h"
#import "CLXBaseEvent.h"
#import "CLXDatabaseProtocol.h"
#import "CLXError.h"
#import "CLXLogger.h"

@implementation CLXRillEventDaoImpl

#pragma mark - CLXBaseDao Overrides

- (NSString *)tableName {
    return [CLXRillEvent sqlTableName];
}

- (NSArray<NSString *> *)columnNames {
    return [CLXRillEvent sqlColumnNames];
}

- (NSString *)primaryKeyColumn {
    return @"id";
}

- (NSArray *)sqlValuesFromEntity:(CLXRillEvent *)entity {
    return [entity sqlInsertValues];
}

- (CLXRillEvent *)entityFromSQLRow:(NSDictionary *)row {
    NSString *eventId = row[@"id"];
    NSString *sessionId = row[@"sessionId"] ?: @""; // Handle potential null
    NSString *encoded = row[@"encoded"] ?: @"";
    NSString *campaignId = row[@"campaignId"] ?: @"";
    NSString *eventValue = row[@"eventValue"] ?: @"";
    NSString *eventName = row[@"eventName"] ?: @"";
    NSString *type = row[@"type"] ?: @"";
    
    if (!eventId) {
        return nil;
    }
    
    CLXRillEvent *event = [[CLXRillEvent alloc] initWithEventId:eventId
                                                      sessionId:sessionId
                                                        encoded:encoded
                                                     campaignId:campaignId
                                                     eventValue:eventValue
                                                      eventName:eventName
                                                           type:type];
    
    [event updateFromSQLRow:row];
    return event;
}

#pragma mark - CLXRillEventDao Protocol Implementation

- (BOOL)insertRillEvent:(CLXRillEvent *)event {
    return [self insert:event];
}

- (BOOL)insertRillEventBatch:(NSArray<CLXRillEvent *> *)events {
    return [self insertBatch:events];
}

- (nullable CLXRillEvent *)findRillEventById:(NSString *)eventId {
    return [self findById:eventId];
}

- (NSArray<CLXRillEvent *> *)findRillEventsByCampaignId:(NSString *)campaignId {
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE campaignId = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[campaignId]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXRillEvent *> *)findRillEventsByEventName:(NSString *)eventName {
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE eventName = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[eventName]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXRillEvent *> *)findRillEventsByType:(NSString *)type {
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE type = ? ORDER BY created_at DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[type]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (NSArray<CLXRillEvent *> *)findRillEventsByStatus:(NSString *)status {
    // Convert string status to integer value
    NSInteger statusValue = [self statusValueFromString:status];
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE status = ? ORDER BY created_at DESC";
    NSLog(@"🔍 Executing query: %@ with status value: %ld", sql, (long)statusValue);
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(statusValue)]];
    NSLog(@"🔍 Query returned %lu raw results", (unsigned long)results.count);
    
    for (NSDictionary *row in results) {
        NSLog(@"🔍 Raw row: %@", row);
    }
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        NSLog(@"🔍 entityFromSQLRow returned: %@", event ? @"SUCCESS" : @"NIL");
        if (event) {
            [events addObject:event];
        }
    }
    
    NSLog(@"🔍 Final events array count: %lu", (unsigned long)events.count);
    return [events copy];
}

#pragma mark - Retry Management

- (NSArray<CLXRillEvent *> *)findPendingRillEvents {
    return [self findRillEventsByStatus:@"pending"];
}

- (NSArray<CLXRillEvent *> *)findFailedRillEventsForRetry {
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE status = ? AND retry_count < 3 ORDER BY created_at ASC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(CLXEventStatusFailed)]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (BOOL)updateRillEventStatus:(NSString *)eventId status:(NSString *)status {
    NSString *sql = @"UPDATE cached_tracking_events_table SET status = ?, updated_at = ? WHERE id = ?";
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    return [self.database executeSQL:sql withParameters:@[status, @(now), eventId]];
}

- (BOOL)incrementRetryCount:(NSString *)eventId {
    NSString *sql = @"UPDATE cached_tracking_events_table SET retry_count = retry_count + 1, last_retry_at = ?, updated_at = ? WHERE id = ?";
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    return [self.database executeSQL:sql withParameters:@[@(now), @(now), eventId]];
}

#pragma mark - Batch Processing

- (NSArray<CLXRillEvent *> *)findRillEventsForBatch:(NSInteger)batchSize {
    // Convert string status to integer value (pending = 0)
    NSInteger statusValue = [self statusValueFromString:@"pending"];
    NSString *sql = @"SELECT * FROM cached_tracking_events_table WHERE status = ? ORDER BY created_at ASC LIMIT ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(statusValue), @(batchSize)]];
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXRillEvent *event = [self entityFromSQLRow:row];
        if (event) {
            [events addObject:event];
        }
    }
    
    return [events copy];
}

- (BOOL)markRillEventsAsProcessed:(NSArray<NSString *> *)eventIds {
    if (eventIds.count == 0) {
        return YES;
    }
    
    __block BOOL success = YES;
    
    [self.database executeInTransaction:^{
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        for (NSString *eventId in eventIds) {
            NSString *sql = @"UPDATE cached_tracking_events_table SET status = 'completed', updated_at = ? WHERE id = ?";
            if (![self.database executeSQL:sql withParameters:@[@(now), eventId]]) {
                [self.logger error:[NSString stringWithFormat:@"Failed to mark event as processed: %@", eventId]];
                success = NO;
                break;
            }
        }
    }];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Marked %lu events as processed", (unsigned long)eventIds.count]];
    }
    
    return success;
}

#pragma mark - Cleanup Operations

- (BOOL)deleteRillEventsOlderThan:(NSTimeInterval)timestamp {
    NSString *sql = @"DELETE FROM cached_tracking_events_table WHERE created_at < ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[@(timestamp)]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted Rill events older than %f", timestamp]];
    } else {
        [self.logger error:@"Failed to delete old Rill events"];
    }
    
    return success;
}

- (BOOL)deleteProcessedRillEvents {
    NSString *sql = @"DELETE FROM cached_tracking_events_table WHERE status = 'completed'";
    BOOL success = [self.database executeSQL:sql];
    
    if (success) {
        [self.logger debug:@"Deleted processed Rill events"];
    } else {
        [self.logger error:@"Failed to delete processed Rill events"];
    }
    
    return success;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrorsForEntity:(CLXRillEvent *)entity {
    NSMutableArray *errors = [[super validationErrorsForEntity:entity] mutableCopy];
    
    if (![entity isKindOfClass:[CLXRillEvent class]]) {
        [errors addObject:@"Entity must be a CLXRillEvent"];
        return [errors copy];
    }
    
    // Add CLXRillEvent-specific validation
    NSArray *rillErrors = [entity validationErrors];
    [errors addObjectsFromArray:rillErrors];
    
    return [errors copy];
}

#pragma mark - Private Helper Methods

- (NSInteger)statusValueFromString:(NSString *)status {
    if ([status isEqualToString:@"pending"]) {
        return CLXEventStatusPending;     // 0
    } else if ([status isEqualToString:@"processing"]) {
        return CLXEventStatusProcessing;  // 1
    } else if ([status isEqualToString:@"completed"]) {
        return CLXEventStatusCompleted;   // 2
    } else if ([status isEqualToString:@"failed"]) {
        return CLXEventStatusFailed;      // 3
    } else if ([status isEqualToString:@"retrying"]) {
        return CLXEventStatusRetrying;    // 4
    }
    return CLXEventStatusPending; // Default to pending
}

@end
