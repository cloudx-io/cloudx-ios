/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBaseDao.h
 * @brief Base DAO implementation with common CRUD operations
 * 
 * Provides thread-safe database operations with prepared statement caching
 * Following SOLID principles with dependency injection support
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXDaoProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXDatabaseProtocol;
@class CLXLogger;

/**
 * Base DAO implementation providing common database operations
 * Abstract base class - should be subclassed for specific entity types
 */
@interface CLXBaseDao : NSObject <CLXBaseDao>

/**
 * Dependencies
 */
@property (nonatomic, weak, readonly) id<CLXDatabaseProtocol> database;
@property (nonatomic, strong, readonly) CLXLogger *logger;
@property (nonatomic, strong, readonly) dispatch_queue_t operationQueue;

/**
 * Table configuration (must be overridden by subclasses)
 */
@property (nonatomic, strong, readonly) NSString *tableName;
@property (nonatomic, strong, readonly) NSArray<NSString *> *columnNames;
@property (nonatomic, strong, readonly) NSString *primaryKeyColumn;

/**
 * Initialization
 */
- (instancetype)initWithDatabase:(id<CLXDatabaseProtocol>)database;

/**
 * Abstract methods (must be implemented by subclasses)
 */
- (NSString *)tableName;
- (NSArray<NSString *> *)columnNames;
- (NSString *)primaryKeyColumn;
- (NSArray *)sqlValuesFromEntity:(id)entity;
- (id)entityFromSQLRow:(NSDictionary *)row;

/**
 * SQL generation utilities
 */
- (NSString *)insertSQL;
- (NSString *)selectByIdSQL;
- (NSString *)selectAllSQL;
- (NSString *)updateSQL;
- (NSString *)deleteByIdSQL;
- (NSString *)deleteAllSQL;
- (NSString *)countSQL;

/**
 * Validation
 */
- (BOOL)validateEntity:(id)entity error:(NSError **)error;
- (NSArray<NSString *> *)validationErrorsForEntity:(id)entity;

/**
 * Utility methods
 */
- (NSString *)generateId;
- (NSTimeInterval)currentTimestamp;

@end

NS_ASSUME_NONNULL_END
