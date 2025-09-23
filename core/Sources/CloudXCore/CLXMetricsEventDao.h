/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsEventDao.h
 * @brief Data Access Object for metrics events - matches Android's MetricsEventDao exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMetricsEvent;
@class CLXSQLiteDatabase;

/**
 * Data Access Object for metrics events
 * Matches Android's @Dao interface MetricsEventDao exactly
 */
@interface CLXMetricsEventDao : NSObject

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database;

/**
 * Insert or replace a metrics event
 * Matches Android's @Insert(onConflict = OnConflictStrategy.REPLACE)
 */
- (BOOL)insert:(CLXMetricsEvent *)event;

/**
 * Get a specific metric by name (for aggregation)
 * Matches Android's @Query("SELECT * FROM metrics_event_table WHERE metricName = :metricName LIMIT 1")
 */
- (nullable CLXMetricsEvent *)getAllByMetric:(NSString *)metricName;

/**
 * Delete a metrics event by ID
 * Matches Android's @Query("DELETE FROM metrics_event_table WHERE id = :id")
 */
- (BOOL)deleteById:(NSString *)eventId;

/**
 * Get all metrics events
 * Matches Android's @Query("SELECT * FROM metrics_event_table")
 */
- (NSArray<CLXMetricsEvent *> *)getAll;

/**
 * Create the metrics table if it doesn't exist
 */
- (BOOL)createTableIfNeeded;

@end

NS_ASSUME_NONNULL_END
