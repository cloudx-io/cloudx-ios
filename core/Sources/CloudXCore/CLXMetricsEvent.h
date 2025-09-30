/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsEvent.h
 * @brief Metrics event model matching Android MetricsEvent exactly
 * 
 * Extends CLXBaseEvent with metrics-specific properties
 * Maps to metrics_event_table in SQLite database
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Metrics event model matching Android MetricsEvent structure
 * Fields: id, metricName, counter, totalLatency, sessionId, auctionId
 */
@interface CLXMetricsEvent : CLXBaseEvent

/**
 * Metrics-specific properties (matching Android exactly)
 */
@property (nonatomic, strong) NSString *metricName;
@property (nonatomic, assign) NSInteger counter;
@property (nonatomic, assign) NSInteger totalLatency; // in milliseconds
@property (nonatomic, strong) NSString *auctionId;

/**
 * Initialization
 */
- (instancetype)initWithEventId:(NSString *)eventId
                      sessionId:(NSString *)sessionId
                     metricName:(NSString *)metricName
                      auctionId:(NSString *)auctionId;

- (instancetype)initWithSessionId:(NSString *)sessionId
                       metricName:(NSString *)metricName
                        auctionId:(NSString *)auctionId;

/**
 * Metrics operations
 */
- (void)incrementCounter;
- (void)incrementCounterBy:(NSInteger)amount;
- (void)addLatency:(NSInteger)latencyMs;
- (NSTimeInterval)averageLatency;

/**
 * Factory methods for common metrics
 */
+ (instancetype)impressionMetricWithSessionId:(NSString *)sessionId auctionId:(NSString *)auctionId;
+ (instancetype)clickMetricWithSessionId:(NSString *)sessionId auctionId:(NSString *)auctionId;
+ (instancetype)loadLatencyMetricWithSessionId:(NSString *)sessionId 
                                     auctionId:(NSString *)auctionId 
                                       latency:(NSInteger)latencyMs;

/**
 * Database column names (matching Android table structure)
 */
+ (NSArray<NSString *> *)sqlColumnNames;
+ (NSString *)sqlTableName;

@end

NS_ASSUME_NONNULL_END
