/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSQLiteDatabase.h
 * @brief Base SQLite database class for CloudX SDK
 * 
 * Designed for maximum compatibility:
 * - Works with both SPM and CocoaPods
 * - Compatible with Objective-C and Swift host apps
 * - No external dependencies (uses system SQLite)
 * - Thread-safe with serial queue
 * - Extensible for multiple database needs
 */

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Base SQLite database class providing common functionality
 * Can be subclassed or used directly for different data storage needs
 */
@interface CLXSQLiteDatabase : NSObject

@property (nonatomic, strong, readonly) CLXLogger *logger;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

- (instancetype)initWithDatabaseName:(NSString *)databaseName;

/**
 * Database lifecycle
 */
- (BOOL)openDatabase;
- (void)closeDatabase;
- (BOOL)executeSQL:(NSString *)sql;
- (BOOL)executeSQL:(NSString *)sql withParameters:(nullable NSArray *)parameters;

/**
 * Query execution
 */
- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql;
- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql withParameters:(nullable NSArray *)parameters;

/**
 * Transaction support
 */
- (void)executeInTransaction:(void (^)(void))block;

/**
 * Utility methods
 */
- (NSString *)databasePath;
- (BOOL)tableExists:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
