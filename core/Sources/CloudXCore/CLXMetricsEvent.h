/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsEvent.h
 * @brief Metrics event model matching Android's MetricsEvent entity exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Metrics event model for SQLite storage
 * Matches Android's @Entity(tableName = "metrics_event_table") MetricsEvent exactly
 */
@interface CLXMetricsEvent : NSObject

@property (nonatomic, copy) NSString *eventId;        // Primary key - UUID or auctionId
@property (nonatomic, copy) NSString *metricName;     // e.g., "method_create_banner", "network_call_bid_req"
@property (nonatomic, assign) NSInteger counter;      // Number of occurrences
@property (nonatomic, assign) NSInteger totalLatency; // Total latency in milliseconds
@property (nonatomic, copy) NSString *sessionId;      // Current session ID
@property (nonatomic, copy) NSString *auctionId;      // Unique auction/event ID

- (instancetype)initWithEventId:(NSString *)eventId
                     metricName:(NSString *)metricName
                        counter:(NSInteger)counter
                   totalLatency:(NSInteger)totalLatency
                      sessionId:(NSString *)sessionId
                      auctionId:(NSString *)auctionId;

/**
 * Create from dictionary (for SQLite result parsing)
 */
+ (instancetype)fromDictionary:(NSDictionary *)dictionary;

/**
 * Convert to dictionary (for SQLite parameter binding)
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
