/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXDatabaseSchema.h
 * @brief Database schema definitions matching Android CloudXDb structure
 * 
 * Centralized schema management following DRY principles
 * All table definitions, indexes, and migrations in one place
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Database version management
 */
extern const NSInteger CLXDatabaseCurrentVersion;
extern NSString * const CLXDatabaseName;

/**
 * Table Names (matching Android exactly)
 */
extern NSString * const CLXMetricsEventTableName;
extern NSString * const CLXCachedTrackingEventsTableName;
extern NSString * const CLXSessionTableName;
extern NSString * const CLXPerformanceMetricsTableName;

/**
 * Schema Creation SQL
 * Designed to match Android Room entities exactly
 */
@interface CLXDatabaseSchema : NSObject

/**
 * Metrics Event Table (matches Android MetricsEvent)
 * Fields: id, metricName, counter, totalLatency, sessionId, auctionId
 */
+ (NSString *)createMetricsEventTableSQL;

/**
 * Cached Tracking Events Table (matches Android CachedTrackingEvents)
 * Fields: id, encoded, campaignId, eventValue, eventName, type
 */
+ (NSString *)createCachedTrackingEventsTableSQL;

/**
 * Session Table (replaces Core Data CLXAppSessionModel)
 * Fields: id, sessionId, appKey, startTime, endTime, duration, url
 */
+ (NSString *)createSessionTableSQL;

/**
 * Performance Metrics Table (replaces Core Data CLXPerformanceMetricModel)
 * Fields: id, placementId, sessionId, clickCount, impressionCount, closeCount, 
 *         loadLatency, bidResponseCount, timestamp
 */
+ (NSString *)createPerformanceMetricsTableSQL;

/**
 * Index Creation for Performance Optimization
 */
+ (NSArray<NSString *> *)createIndexesSQL;

/**
 * Migration SQL for version upgrades
 */
+ (NSArray<NSString *> *)migrationSQLFromVersion:(NSInteger)fromVersion 
                                       toVersion:(NSInteger)toVersion;

/**
 * Database maintenance SQL
 */
+ (NSString *)vacuumSQL;
+ (NSString *)analyzeSQL;

@end

NS_ASSUME_NONNULL_END
