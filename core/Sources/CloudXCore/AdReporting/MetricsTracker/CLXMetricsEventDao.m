/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsEventDao.h"
#import "CLXMetricsEvent.h"
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMetricsEventDao ()
@property (nonatomic, strong) CLXSQLiteDatabase *database;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetricsEventDao

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database {
    self = [super init];
    if (self) {
        _database = database;
        _logger = [[CLXLogger alloc] initWithCategory:@"MetricsEventDao"];
        [self createTableIfNeeded];
    }
    return self;
}

- (BOOL)createTableIfNeeded {
    NSString *createTableSQL = @"CREATE TABLE IF NOT EXISTS metrics_event_table ("
                              @"id TEXT PRIMARY KEY, "
                              @"metricName TEXT NOT NULL, "
                              @"counter INTEGER DEFAULT 0, "
                              @"totalLatency INTEGER DEFAULT 0, "
                              @"sessionId TEXT NOT NULL, "
                              @"auctionId TEXT NOT NULL"
                              @");";
    
    BOOL success = [self.database executeSQL:createTableSQL];
    if (success) {
        [self.logger debug:@"Metrics table created successfully"];
    } else {
        [self.logger error:@"Failed to create metrics table"];
    }
    return success;
}

- (BOOL)insert:(CLXMetricsEvent *)event {
    if (!event) {
        [self.logger error:@"Cannot insert nil event"];
        return NO;
    }
    
    NSString *insertSQL = @"INSERT OR REPLACE INTO metrics_event_table "
                         @"(id, metricName, counter, totalLatency, sessionId, auctionId) "
                         @"VALUES (?, ?, ?, ?, ?, ?);";
    
    NSArray *parameters = @[
        event.eventId,
        event.metricName,
        @(event.counter),
        @(event.totalLatency),
        event.sessionId,
        event.auctionId
    ];
    
    BOOL success = [self.database executeSQL:insertSQL withParameters:parameters];
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Inserted metric: %@ (counter: %ld, latency: %ld)", 
                           event.metricName, (long)event.counter, (long)event.totalLatency]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to insert metric: %@", event.metricName]];
    }
    
    return success;
}

- (nullable CLXMetricsEvent *)getAllByMetric:(NSString *)metricName {
    if (!metricName || metricName.length == 0) {
        [self.logger error:@"Cannot query with nil/empty metric name"];
        return nil;
    }
    
    NSString *selectSQL = @"SELECT * FROM metrics_event_table WHERE metricName = ? LIMIT 1;";
    NSArray *parameters = @[metricName];
    
    NSArray<NSDictionary *> *results = [self.database executeQuery:selectSQL withParameters:parameters];
    
    if (results.count > 0) {
        CLXMetricsEvent *event = [CLXMetricsEvent fromDictionary:results.firstObject];
        [self.logger debug:[NSString stringWithFormat:@"Found existing metric: %@ (counter: %ld)", 
                           metricName, (long)event.counter]];
        return event;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"No existing metric found for: %@", metricName]];
    return nil;
}

- (BOOL)deleteById:(NSString *)eventId {
    if (!eventId || eventId.length == 0) {
        [self.logger error:@"Cannot delete with nil/empty event ID"];
        return NO;
    }
    
    NSString *deleteSQL = @"DELETE FROM metrics_event_table WHERE id = ?;";
    NSArray *parameters = @[eventId];
    
    BOOL success = [self.database executeSQL:deleteSQL withParameters:parameters];
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted metric with ID: %@", eventId]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete metric with ID: %@", eventId]];
    }
    
    return success;
}

- (NSArray<CLXMetricsEvent *> *)getAll {
    NSString *selectSQL = @"SELECT * FROM metrics_event_table ORDER BY metricName;";
    
    NSArray<NSDictionary *> *results = [self.database executeQuery:selectSQL];
    NSMutableArray<CLXMetricsEvent *> *events = [NSMutableArray arrayWithCapacity:results.count];
    
    for (NSDictionary *row in results) {
        CLXMetricsEvent *event = [CLXMetricsEvent fromDictionary:row];
        if (event) {
            [events addObject:event];
        } else {
            [self.logger error:[NSString stringWithFormat:@"Failed to create CLXMetricsEvent from row: %@", row]];
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Retrieved %lu metrics events", (unsigned long)events.count]];
    return [events copy];
}

@end
