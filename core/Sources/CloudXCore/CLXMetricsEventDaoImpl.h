/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsEventDaoImpl.h
 * @brief Metrics Event DAO implementation matching Android MetricsEventDao
 * 
 * Provides SQLite persistence for metrics events with aggregation and reporting capabilities
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseDao.h>
#import <CloudXCore/CLXDaoProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMetricsEvent;

/**
 * Metrics Event DAO implementation
 * Handles metrics_event_table operations matching Android exactly
 */
@interface CLXMetricsEventDaoImpl : CLXBaseDao <CLXMetricsEventDao>

@end

NS_ASSUME_NONNULL_END
