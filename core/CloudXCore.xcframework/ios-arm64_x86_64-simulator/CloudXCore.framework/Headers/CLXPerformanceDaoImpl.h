/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPerformanceDaoImpl.h
 * @brief Performance DAO implementation for ad unit-level metrics
 * 
 * Provides SQLite persistence for performance tracking with aggregation capabilities
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseDao.h>
#import <CloudXCore/CLXDaoProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXPerformanceMetric;

/**
 * Performance DAO implementation
 * Handles performance_metrics_table operations with aggregation and reporting
 */
@interface CLXPerformanceDaoImpl : CLXBaseDao <CLXPerformanceDao>

@end

NS_ASSUME_NONNULL_END
