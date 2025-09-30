/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXPerformanceDaoImpl.h"
#import "CLXPerformanceMetric.h"
#import "CLXDatabaseProtocol.h"
#import "CLXError.h"
#import "CLXLogger.h"

@implementation CLXPerformanceDaoImpl

#pragma mark - CLXBaseDao Overrides

- (NSString *)tableName {
    return [CLXPerformanceMetric sqlTableName];
}

- (NSArray<NSString *> *)columnNames {
    return [CLXPerformanceMetric sqlColumnNames];
}

- (NSString *)primaryKeyColumn {
    return @"id";
}

- (NSArray *)sqlValuesFromEntity:(CLXPerformanceMetric *)entity {
    return [entity sqlInsertValues];
}

- (CLXPerformanceMetric *)entityFromSQLRow:(NSDictionary *)row {
    NSString *placementId = row[@"placementId"];
    NSString *sessionId = row[@"sessionId"];
    
    if (!placementId || !sessionId) {
        return nil;
    }
    
    CLXPerformanceMetric *metric = [[CLXPerformanceMetric alloc] initWithPlacementId:placementId sessionId:sessionId];
    [metric updateFromSQLRow:row];
    return metric;
}

#pragma mark - CLXPerformanceDao Protocol Implementation

- (BOOL)insertPerformanceMetric:(CLXPerformanceMetric *)metric {
    return [self insert:metric];
}

- (BOOL)insertPerformanceMetricBatch:(NSArray<CLXPerformanceMetric *> *)metrics {
    return [self insertBatch:metrics];
}

- (NSArray<CLXPerformanceMetric *> *)findPerformanceMetricsByPlacementId:(NSString *)placementId {
    NSString *sql = @"SELECT * FROM performance_metrics_table WHERE placementId = ? ORDER BY timestamp DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    NSMutableArray *metrics = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXPerformanceMetric *metric = [self entityFromSQLRow:row];
        if (metric) {
            [metrics addObject:metric];
        }
    }
    
    return [metrics copy];
}

- (NSArray<CLXPerformanceMetric *> *)findPerformanceMetricsBySessionId:(NSString *)sessionId {
    NSString *sql = @"SELECT * FROM performance_metrics_table WHERE sessionId = ? ORDER BY timestamp DESC";
    NSArray *results = [self.database executeQuery:sql withParameters:@[sessionId]];
    
    NSMutableArray *metrics = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        CLXPerformanceMetric *metric = [self entityFromSQLRow:row];
        if (metric) {
            [metrics addObject:metric];
        }
    }
    
    return [metrics copy];
}

- (nullable CLXPerformanceMetric *)findPerformanceMetricByPlacementId:(NSString *)placementId sessionId:(NSString *)sessionId {
    NSString *sql = @"SELECT * FROM performance_metrics_table WHERE placementId = ? AND sessionId = ? LIMIT 1";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId, sessionId]];
    
    if (results.count > 0) {
        return [self entityFromSQLRow:results[0]];
    }
    
    return nil;
}

- (CLXPerformanceMetric *)findOrCreatePerformanceMetricForPlacementId:(NSString *)placementId sessionId:(NSString *)sessionId {
    // First try to find existing metric
    CLXPerformanceMetric *existingMetric = [self findPerformanceMetricByPlacementId:placementId sessionId:sessionId];
    if (existingMetric) {
        return existingMetric;
    }
    
    // Create new metric if not found
    CLXPerformanceMetric *newMetric = [[CLXPerformanceMetric alloc] initWithPlacementId:placementId sessionId:sessionId];
    
    if ([self insertPerformanceMetric:newMetric]) {
        return newMetric;
    }
    
    // If insertion failed, try to find again (race condition protection)
    CLXPerformanceMetric *raceCheckMetric = [self findPerformanceMetricByPlacementId:placementId sessionId:sessionId];
    if (raceCheckMetric) {
        return raceCheckMetric;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to create performance metric for placement %@ session %@", placementId, sessionId]];
    return newMetric; // Return the created instance even if insertion failed
}

#pragma mark - Aggregation Operations

- (NSInteger)getTotalClicksForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT SUM(clickCount) as total FROM performance_metrics_table WHERE placementId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        id total = results[0][@"total"];
        if (total && ![total isKindOfClass:[NSNull class]]) {
            return [total integerValue];
        }
    }
    
    return 0;
}

- (NSInteger)getTotalImpressionsForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT SUM(impressionCount) as total FROM performance_metrics_table WHERE placementId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        id total = results[0][@"total"];
        if (total && ![total isKindOfClass:[NSNull class]]) {
            return [total integerValue];
        }
    }
    
    return 0;
}

- (NSInteger)getTotalClosesForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT SUM(closeCount) as total FROM performance_metrics_table WHERE placementId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        id total = results[0][@"total"];
        if (total && ![total isKindOfClass:[NSNull class]]) {
            return [total integerValue];
        }
    }
    
    return 0;
}

- (NSTimeInterval)getAverageLoadLatencyForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT AVG(CASE WHEN bidResponseCount > 0 THEN CAST(loadLatency AS REAL) / bidResponseCount ELSE 0 END) as average FROM performance_metrics_table WHERE placementId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        id average = results[0][@"average"];
        if (average && ![average isKindOfClass:[NSNull class]]) {
            return [average doubleValue];
        }
    }
    
    return 0;
}

- (NSInteger)getTotalBidResponsesForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT SUM(bidResponseCount) as total FROM performance_metrics_table WHERE placementId = ?";
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        id total = results[0][@"total"];
        if (total && ![total isKindOfClass:[NSNull class]]) {
            return [total integerValue];
        }
    }
    
    return 0;
}

#pragma mark - Performance Analytics

- (NSDictionary<NSString *, NSNumber *> *)getPerformanceSummaryForPlacement:(NSString *)placementId {
    NSString *sql = @"SELECT "
                    @"SUM(clickCount) as totalClicks, "
                    @"SUM(impressionCount) as totalImpressions, "
                    @"SUM(closeCount) as totalCloses, "
                    @"SUM(loadLatency) as totalLatency, "
                    @"SUM(bidResponseCount) as totalBidResponses, "
                    @"COUNT(*) as recordCount "
                    @"FROM performance_metrics_table WHERE placementId = ?";
    
    NSArray *results = [self.database executeQuery:sql withParameters:@[placementId]];
    
    if (results.count > 0) {
        NSDictionary *row = results[0];
        NSInteger totalClicks = [row[@"totalClicks"] integerValue];
        NSInteger totalImpressions = [row[@"totalImpressions"] integerValue];
        NSInteger totalCloses = [row[@"totalCloses"] integerValue];
        NSInteger totalLatency = [row[@"totalLatency"] integerValue];
        NSInteger totalBidResponses = [row[@"totalBidResponses"] integerValue];
        
        double ctr = totalImpressions > 0 ? (double)totalClicks / totalImpressions : 0.0;
        double closeRate = totalImpressions > 0 ? (double)totalCloses / totalImpressions : 0.0;
        double avgLatency = totalBidResponses > 0 ? (double)totalLatency / totalBidResponses : 0.0;
        
        return @{
            @"totalClicks": @(totalClicks),
            @"totalImpressions": @(totalImpressions),
            @"totalCloses": @(totalCloses),
            @"totalBidResponses": @(totalBidResponses),
            @"clickThroughRate": @(ctr),
            @"closeRate": @(closeRate),
            @"averageLoadLatency": @(avgLatency),
            @"recordCount": row[@"recordCount"] ?: @0
        };
    }
    
    return @{};
}

- (NSDictionary<NSString *, NSNumber *> *)getPerformanceSummaryForSession:(NSString *)sessionId {
    NSString *sql = @"SELECT "
                    @"placementId, "
                    @"SUM(clickCount) as totalClicks, "
                    @"SUM(impressionCount) as totalImpressions, "
                    @"SUM(closeCount) as totalCloses, "
                    @"SUM(loadLatency) as totalLatency, "
                    @"SUM(bidResponseCount) as totalBidResponses "
                    @"FROM performance_metrics_table WHERE sessionId = ? GROUP BY placementId";
    
    NSArray *results = [self.database executeQuery:sql withParameters:@[sessionId]];
    
    NSMutableDictionary *summary = [NSMutableDictionary dictionary];
    
    for (NSDictionary *row in results) {
        NSString *placementId = row[@"placementId"];
        if (placementId) {
            NSInteger totalClicks = [row[@"totalClicks"] integerValue];
            NSInteger totalImpressions = [row[@"totalImpressions"] integerValue];
            NSInteger totalCloses = [row[@"totalCloses"] integerValue];
            NSInteger totalLatency = [row[@"totalLatency"] integerValue];
            NSInteger totalBidResponses = [row[@"totalBidResponses"] integerValue];
            
            double ctr = totalImpressions > 0 ? (double)totalClicks / totalImpressions : 0.0;
            double closeRate = totalImpressions > 0 ? (double)totalCloses / totalImpressions : 0.0;
            double avgLatency = totalBidResponses > 0 ? (double)totalLatency / totalBidResponses : 0.0;
            
            summary[placementId] = @{
                @"totalClicks": @(totalClicks),
                @"totalImpressions": @(totalImpressions),
                @"totalCloses": @(totalCloses),
                @"totalBidResponses": @(totalBidResponses),
                @"clickThroughRate": @(ctr),
                @"closeRate": @(closeRate),
                @"averageLoadLatency": @(avgLatency)
            };
        }
    }
    
    return [summary copy];
}

- (NSArray<CLXPerformanceMetric *> *)findTopPerformingPlacements:(NSInteger)limit {
    NSString *sql = @"SELECT placementId, "
                    @"SUM(clickCount) as totalClicks, "
                    @"SUM(impressionCount) as totalImpressions, "
                    @"SUM(closeCount) as totalCloses, "
                    @"SUM(loadLatency) as totalLatency, "
                    @"SUM(bidResponseCount) as totalBidResponses, "
                    @"MAX(sessionId) as sessionId, "
                    @"MAX(timestamp) as timestamp "
                    @"FROM performance_metrics_table "
                    @"GROUP BY placementId "
                    @"ORDER BY totalImpressions DESC, totalClicks DESC "
                    @"LIMIT ?";
    
    NSArray *results = [self.database executeQuery:sql withParameters:@[@(limit)]];
    
    NSMutableArray *metrics = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary *row in results) {
        NSString *placementId = row[@"placementId"];
        NSString *sessionId = row[@"sessionId"];
        
        if (placementId && sessionId) {
            CLXPerformanceMetric *metric = [[CLXPerformanceMetric alloc] initWithPlacementId:placementId sessionId:sessionId];
            
            // Set aggregated values
            metric.clickCount = [row[@"totalClicks"] integerValue];
            metric.impressionCount = [row[@"totalImpressions"] integerValue];
            metric.closeCount = [row[@"totalCloses"] integerValue];
            metric.loadLatency = [row[@"totalLatency"] integerValue];
            metric.bidResponseCount = [row[@"totalBidResponses"] integerValue];
            metric.timestamp = [row[@"timestamp"] doubleValue];
            
            [metrics addObject:metric];
        }
    }
    
    return [metrics copy];
}

#pragma mark - Cleanup Operations

- (BOOL)deletePerformanceMetricsOlderThan:(NSTimeInterval)timestamp {
    NSString *sql = @"DELETE FROM performance_metrics_table WHERE created_at < ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[@(timestamp)]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted performance metrics older than %f", timestamp]];
    } else {
        [self.logger error:@"Failed to delete old performance metrics"];
    }
    
    return success;
}

- (BOOL)deletePerformanceMetricsBySessionId:(NSString *)sessionId {
    NSString *sql = @"DELETE FROM performance_metrics_table WHERE sessionId = ?";
    BOOL success = [self.database executeSQL:sql withParameters:@[sessionId]];
    
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted performance metrics for session: %@", sessionId]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete performance metrics for session: %@", sessionId]];
    }
    
    return success;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrorsForEntity:(CLXPerformanceMetric *)entity {
    NSMutableArray *errors = [[super validationErrorsForEntity:entity] mutableCopy];
    
    if (![entity isKindOfClass:[CLXPerformanceMetric class]]) {
        [errors addObject:@"Entity must be a CLXPerformanceMetric"];
        return [errors copy];
    }
    
    // Add CLXPerformanceMetric-specific validation
    NSArray *performanceErrors = [entity validationErrors];
    [errors addObjectsFromArray:performanceErrors];
    
    return [errors copy];
}

@end
