/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTracker+ErrorTracking.h
 * @brief Error tracking extension for CLXMetricsTracker
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXErrorMetricType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error tracking extension for CLXMetricsTracker
 * Adds capability to track and report SDK errors via the existing metrics infrastructure
 */
@interface CLXMetricsTracker (ErrorTracking)

/**
 * Tracks an error event with context information
 * @param errorType The type of error that occurred
 * @param placementID Optional placement ID where the error occurred
 * @param context Optional context dictionary with additional error information
 */
- (void)trackError:(CLXErrorMetricType)errorType
       placementID:(nullable NSString *)placementID
           context:(nullable NSDictionary<NSString *, NSString *> *)context;

/**
 * Tracks an NSException with automatic type classification
 * @param exception The exception that was caught
 * @param placementID Optional placement ID where the exception occurred
 * @param context Optional context dictionary with additional information
 */
- (void)trackException:(NSException *)exception
           placementID:(nullable NSString *)placementID
               context:(nullable NSDictionary<NSString *, NSString *> *)context;

/**
 * Tracks an NSError with automatic type classification
 * @param error The error that occurred
 * @param placementID Optional placement ID where the error occurred
 * @param context Optional context dictionary with additional information
 */
- (void)trackNSError:(NSError *)error
         placementID:(nullable NSString *)placementID
             context:(nullable NSDictionary<NSString *, NSString *> *)context;

@end

NS_ASSUME_NONNULL_END
