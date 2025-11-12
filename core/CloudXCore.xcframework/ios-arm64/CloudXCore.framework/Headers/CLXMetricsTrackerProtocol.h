/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTrackerProtocol.h
 * @brief Metrics tracker protocol matching Android's MetricsTracker interface exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMetricsConfig;
@class CLXSDKConfig;

/**
 * Metrics tracker protocol
 * Matches Android's internal interface MetricsTracker exactly
 */
@protocol CLXMetricsTrackerProtocol <NSObject>

/**
 * Start the metrics tracker with configuration
 * Matches Android's fun start(config: Config)
 */
- (void)startWithConfig:(CLXSDKConfig *)config;

/**
 * Set basic data for metrics tracking
 * Matches Android's fun setBasicData(sessionId: String, accountId: String, basePayload: String)
 */
- (void)setBasicDataWithSessionId:(NSString *)sessionId 
                        accountId:(NSString *)accountId 
                      basePayload:(NSString *)basePayload;

/**
 * Track a method call
 * Matches Android's fun trackMethodCall(type: MetricsType.Method)
 */
- (void)trackMethodCall:(NSString *)methodType;

/**
 * Track a network call with latency
 * Matches Android's fun trackNetworkCall(type: MetricsType.Network, latency: Long)
 */
- (void)trackNetworkCall:(NSString *)networkType latency:(NSInteger)latencyMs;

/**
 * Try sending pending metrics
 * Matches Android's fun trySendingPendingMetrics()
 */
- (void)trySendingPendingMetrics;

/**
 * Stop the metrics tracker
 * Matches Android's fun stop()
 */
- (void)stop;

// Debug methods (only available in debug builds)
#ifdef DEBUG
/**
 * Print comprehensive debug information about metrics system
 */
- (void)debugPrintStatus;

/**
 * Validate metrics system integrity
 * @return Array of validation issues found (empty if all good)
 */
- (NSArray<NSString *> *)validateSystem;

/**
 * Flush all pending async operations (testing only)
 * This method blocks until all pending trackMethodCall operations complete
 */
- (void)flushPendingOperations;
#endif

@end

NS_ASSUME_NONNULL_END
