/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class CLXMetricsTrackerImpl;
@class CLXMetricsEventDao;
@class CLXMetricsConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * Debug utility for metrics system troubleshooting
 * Provides detailed information about metrics state, configuration, and performance
 */
@interface CLXMetricsDebugger : NSObject

/**
 * Print comprehensive metrics debug information to console
 * @param metricsTracker The metrics tracker to debug
 */
+ (void)debugMetricsTracker:(CLXMetricsTrackerImpl *)metricsTracker;

/**
 * Print database state information
 * @param dao The metrics DAO to debug
 */
+ (void)debugDatabase:(CLXMetricsEventDao *)dao;

/**
 * Print configuration information
 * @param config The metrics configuration to debug
 */
+ (void)debugConfiguration:(CLXMetricsConfig *)config;

/**
 * Print all tracked metrics with their current values
 * @param dao The metrics DAO to query
 */
+ (void)printAllMetrics:(CLXMetricsEventDao *)dao;

/**
 * Validate metrics system integrity
 * @param metricsTracker The metrics tracker to validate
 * @return Array of validation issues found (empty if all good)
 */
+ (NSArray<NSString *> *)validateMetricsSystem:(CLXMetricsTrackerImpl *)metricsTracker;

/**
 * Generate performance report for metrics system
 * @param dao The metrics DAO to analyze
 * @return Performance analysis string
 */
+ (NSString *)generatePerformanceReport:(CLXMetricsEventDao *)dao;

/**
 * Test metrics encryption with sample data
 * @param accountId Account ID to test with
 * @return Test results string
 */
+ (NSString *)testEncryption:(NSString *)accountId;

/**
 * Enable enhanced debug mode (more verbose logging)
 */
+ (void)enableEnhancedDebugMode;

/**
 * Disable enhanced debug mode
 */
+ (void)disableEnhancedDebugMode;

/**
 * Check if enhanced debug mode is enabled
 */
+ (BOOL)isEnhancedDebugModeEnabled;

@end

NS_ASSUME_NONNULL_END
