/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSessionDaoImpl.h
 * @brief Session DAO implementation replacing Core Data session management
 * 
 * Provides SQLite persistence for session tracking with lifecycle management
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseDao.h>
#import <CloudXCore/CLXDaoProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSession;

/**
 * Session DAO implementation
 * Handles session_table operations replacing Core Data CLXAppSessionModel
 */
@interface CLXSessionDaoImpl : CLXBaseDao <CLXSessionDao>

@end

NS_ASSUME_NONNULL_END
