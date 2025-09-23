/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTrackerImpl.h
 * @brief Metrics tracker implementation matching Android's MetricsTrackerImpl exactly
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMetricsEventDao;
@class CLXSQLiteDatabase;
@class CLXLogger;
@class CLXMetricsConfig;

/**
 * Metrics tracker implementation
 * Matches Android's internal class MetricsTrackerImpl exactly
 */
@interface CLXMetricsTrackerImpl : NSObject <CLXMetricsTrackerProtocol>

- (instancetype)init;

/**
 * For dependency injection and testing
 */
- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database;

@end

NS_ASSUME_NONNULL_END
