/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTrackerImpl.h
 * @brief Metrics tracker implementation matching Android's MetricsTrackerImpl exactly
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>

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
 * For dependency injection and testing (database only)
 */
- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database;

/**
 * For full dependency injection and testing (database + bulk API)
 * Use this initializer to inject a mock bulk API for verifying metrics are sent
 */
- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database
                         bulkApi:(id<CLXEventTrackerBulkApi>)bulkApi;

@end

NS_ASSUME_NONNULL_END
