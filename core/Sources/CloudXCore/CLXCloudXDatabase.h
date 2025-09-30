/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXCloudXDatabase.h
 * @brief Unified CloudX database matching Android CloudXDb architecture
 * 
 * Single database with multiple specialized tables:
 * - metrics_event_table: Metrics tracking (matches Android MetricsEvent)
 * - cached_tracking_events_table: Rill event tracking (matches Android CachedTrackingEvents)
 * - session_table: App session management
 * - performance_metrics_table: Placement performance tracking
 * 
 * Follows SOLID principles with protocol-based DAO pattern
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXDatabaseProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXMetricsEventDao;
@protocol CLXRillEventDao;
@protocol CLXSessionDao;
@protocol CLXPerformanceDao;

/**
 * Unified CloudX database providing centralized data persistence
 * Matches Android CloudXDb architecture with multiple specialized tables
 */
@interface CLXCloudXDatabase : CLXSQLiteDatabase <CLXDatabaseProtocol>

/**
 * Singleton instance for unified access
 */
+ (instancetype)sharedInstance;

/**
 * DAO instances for different data types
 * Following Dependency Inversion Principle with protocols
 */
@property (nonatomic, strong, readonly) id<CLXMetricsEventDao> metricsDao;
@property (nonatomic, strong, readonly) id<CLXRillEventDao> rillEventDao;
@property (nonatomic, strong, readonly) id<CLXSessionDao> sessionDao;
@property (nonatomic, strong, readonly) id<CLXPerformanceDao> performanceDao;

/**
 * Database initialization and schema management
 */
- (BOOL)initializeSchema;
- (BOOL)migrateFromVersion:(NSInteger)fromVersion toVersion:(NSInteger)toVersion;

/**
 * Bulk operations for performance optimization
 */
- (BOOL)executeBulkInsert:(NSString *)tableName 
                  columns:(NSArray<NSString *> *)columns 
                   values:(NSArray<NSArray *> *)valueArrays;

/**
 * Database maintenance
 */
- (void)vacuum;
- (void)analyze;
- (NSInteger)getDatabaseVersion;
- (BOOL)setDatabaseVersion:(NSInteger)version;

@end

NS_ASSUME_NONNULL_END
