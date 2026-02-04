/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXDaoProtocols.h
 * @brief DAO protocol hierarchy following Interface Segregation Principle
 * 
 * Separate protocols for different data access concerns:
 * - CLXBaseDao: Common CRUD operations
 * - CLXMetricsEventDao: Metrics-specific operations
 * - CLXSessionDao: Session management operations
 * - CLXPerformanceDao: Performance metrics operations
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMetricsEvent;
@class CLXSession;
@class CLXPerformanceMetric;

/**
 * Base DAO protocol with common CRUD operations
 * Generic type T represents the model type
 */
@protocol CLXBaseDao <NSObject>

- (BOOL)insert:(id)entity;
- (BOOL)insertBatch:(NSArray *)entities;
- (nullable id)findById:(NSString *)entityId;
- (NSArray *)findAll;
- (BOOL)update:(id)entity;
- (BOOL)deleteById:(NSString *)entityId;
- (BOOL)deleteAll;
- (NSInteger)count;

@end

/**
 * Metrics Event DAO protocol
 * Handles metrics_event_table operations matching Android MetricsEventDao
 */
@protocol CLXMetricsEventDao <CLXBaseDao>

- (BOOL)insertMetricsEvent:(CLXMetricsEvent *)event;
- (BOOL)insertMetricsEventBatch:(NSArray<CLXMetricsEvent *> *)events;
- (nullable CLXMetricsEvent *)findMetricsEventById:(NSString *)eventId;
- (NSArray<CLXMetricsEvent *> *)findMetricsEventsBySessionId:(NSString *)sessionId;
- (NSArray<CLXMetricsEvent *> *)findMetricsEventsByAuctionId:(NSString *)auctionId;
- (NSArray<CLXMetricsEvent *> *)findMetricsEventsByMetricName:(NSString *)metricName;
- (NSArray<CLXMetricsEvent *> *)findMetricsEventsCreatedAfter:(NSTimeInterval)timestamp;

// Aggregation operations
- (NSInteger)getTotalCounterForMetric:(NSString *)metricName sessionId:(NSString *)sessionId;
- (NSInteger)getTotalLatencyForMetric:(NSString *)metricName sessionId:(NSString *)sessionId;
- (NSDictionary<NSString *, NSNumber *> *)getMetricsSummaryForSession:(NSString *)sessionId;

// Cleanup operations
- (BOOL)deleteMetricsEventsOlderThan:(NSTimeInterval)timestamp;
- (BOOL)deleteMetricsEventsBySessionId:(NSString *)sessionId;

@end

/**
 * Session DAO protocol
 * Handles session_table operations replacing Core Data CLXAppSessionModel
 */
@protocol CLXSessionDao <CLXBaseDao>

- (BOOL)insertSession:(CLXSession *)session;
- (nullable CLXSession *)findSessionById:(NSString *)sessionId;
- (nullable CLXSession *)findCurrentSession;
- (NSArray<CLXSession *> *)findSessionsByAppKey:(NSString *)appKey;
- (NSArray<CLXSession *> *)findSessionsInTimeRange:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime;

// Session lifecycle
- (BOOL)updateSessionEndTime:(NSString *)sessionId endTime:(NSTimeInterval)endTime;
- (BOOL)updateSessionDuration:(NSString *)sessionId duration:(NSTimeInterval)duration;
- (BOOL)updateSessionUrl:(NSString *)sessionId url:(NSString *)url;

// Analytics
- (NSInteger)getSessionCountForAppKey:(NSString *)appKey;
- (NSTimeInterval)getAverageSessionDuration;
- (NSArray<CLXSession *> *)findActiveSessions;

// Cleanup operations
- (BOOL)deleteSessionsOlderThan:(NSTimeInterval)timestamp;

@end

/**
 * Performance DAO protocol
 * Handles performance_metrics_table operations replacing Core Data CLXPerformanceMetricModel
 */
@protocol CLXPerformanceDao <CLXBaseDao>

- (BOOL)insertPerformanceMetric:(CLXPerformanceMetric *)metric;
- (BOOL)insertPerformanceMetricBatch:(NSArray<CLXPerformanceMetric *> *)metrics;
- (NSArray<CLXPerformanceMetric *> *)findPerformanceMetricsByAdUnitId:(NSString *)adUnitId;
- (NSArray<CLXPerformanceMetric *> *)findPerformanceMetricsBySessionId:(NSString *)sessionId;
- (nullable CLXPerformanceMetric *)findPerformanceMetricByAdUnitId:(NSString *)adUnitId sessionId:(NSString *)sessionId;
- (CLXPerformanceMetric *)findOrCreatePerformanceMetricForAdUnitId:(NSString *)adUnitId sessionId:(NSString *)sessionId;

// Aggregation operations
- (NSInteger)getTotalClicksForAdUnit:(NSString *)adUnitId;
- (NSInteger)getTotalImpressionsForAdUnit:(NSString *)adUnitId;
- (NSInteger)getTotalClosesForAdUnit:(NSString *)adUnitId;
- (NSTimeInterval)getAverageLoadLatencyForAdUnit:(NSString *)adUnitId;
- (NSInteger)getTotalBidResponsesForAdUnit:(NSString *)adUnitId;

// Performance analytics
- (NSDictionary<NSString *, NSNumber *> *)getPerformanceSummaryForAdUnit:(NSString *)adUnitId;
- (NSDictionary<NSString *, NSNumber *> *)getPerformanceSummaryForSession:(NSString *)sessionId;
- (NSArray<CLXPerformanceMetric *> *)findTopPerformingAdUnits:(NSInteger)limit;

// Cleanup operations
- (BOOL)deletePerformanceMetricsOlderThan:(NSTimeInterval)timestamp;
- (BOOL)deletePerformanceMetricsBySessionId:(NSString *)sessionId;

@end

NS_ASSUME_NONNULL_END
