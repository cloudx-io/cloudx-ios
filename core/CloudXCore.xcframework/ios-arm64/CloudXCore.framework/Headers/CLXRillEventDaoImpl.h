/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRillEventDaoImpl.h
 * @brief Rill Event DAO implementation matching Android CachedTrackingEventDao
 * 
 * Provides SQLite persistence for Rill events with retry management and bulk operations
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseDao.h>
#import <CloudXCore/CLXDaoProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXRillEvent;

/**
 * Rill Event DAO implementation
 * Handles cached_tracking_events_table operations matching Android exactly
 */
@interface CLXRillEventDaoImpl : CLXBaseDao <CLXRillEventDao>

@end

NS_ASSUME_NONNULL_END
