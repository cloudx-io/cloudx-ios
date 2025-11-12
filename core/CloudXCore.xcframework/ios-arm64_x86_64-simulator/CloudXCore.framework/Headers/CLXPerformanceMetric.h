/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPerformanceMetric.h
 * @brief Performance metric model replacing Core Data CLXPerformanceMetricModel
 * 
 * SQLite-compatible performance tracking with placement-level metrics
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Performance metric model replacing Core Data CLXPerformanceMetricModel
 * Maps to performance_metrics_table in SQLite database
 */
@interface CLXPerformanceMetric : CLXBaseEvent

/**
 * Performance-specific properties
 */
@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, assign) NSInteger clickCount;
@property (nonatomic, assign) NSInteger impressionCount;
@property (nonatomic, assign) NSInteger closeCount;
@property (nonatomic, assign) NSInteger loadLatency; // in milliseconds
@property (nonatomic, assign) NSInteger bidResponseCount;
@property (nonatomic, assign) NSInteger adLoadCount;
@property (nonatomic, assign) double adLoadLatency;
@property (nonatomic, assign) double bidRequestLatency;
@property (nonatomic, assign) NSInteger failToLoadAdCount;
@property (nonatomic, assign) double closeLatency;

/**
 * Initialization
 */
- (instancetype)initWithPlacementId:(NSString *)placementId sessionId:(NSString *)sessionId;

/**
 * Metric operations
 */
- (void)incrementClicks;
- (void)incrementClicksBy:(NSInteger)count;
- (void)incrementImpressions;
- (void)incrementImpressionsBy:(NSInteger)count;
- (void)incrementCloses;
- (void)incrementClosesBy:(NSInteger)count;
- (void)addLoadLatency:(NSInteger)latencyMs;
- (void)incrementBidResponses;
- (void)incrementBidResponsesBy:(NSInteger)count;
- (void)incrementAdLoads;
- (void)incrementAdLoadsBy:(NSInteger)count;
- (void)addAdLoadLatency:(double)latency;
- (void)addBidRequestLatency:(double)latency;
- (void)incrementFailToLoadAds;
- (void)incrementFailToLoadAdsBy:(NSInteger)count;
- (void)addCloseLatency:(double)latency;

/**
 * Analytics
 */
- (NSTimeInterval)averageLoadLatency;
- (double)clickThroughRate;
- (double)closeRate;
- (NSDictionary *)performanceSummary;

/**
 * Factory methods
 */
+ (instancetype)metricForPlacement:(NSString *)placementId sessionId:(NSString *)sessionId;

/**
 * Database support
 */
+ (NSArray<NSString *> *)sqlColumnNames;
+ (NSString *)sqlTableName;

@end

NS_ASSUME_NONNULL_END
