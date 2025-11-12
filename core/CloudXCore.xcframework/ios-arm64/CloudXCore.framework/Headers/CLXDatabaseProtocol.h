/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXDatabaseProtocol.h
 * @brief Database abstraction protocol following Dependency Inversion Principle
 * 
 * Enables:
 * - Easy testing with mock implementations
 * - Future database migrations (SQLite -> Core Data -> Other)
 * - Dependency injection throughout the system
 * - SOLID compliance with interface segregation
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXDatabaseProtocol <NSObject>

/**
 * Database lifecycle management
 */
- (BOOL)openDatabase;
- (void)closeDatabase;
- (BOOL)isOpen;

/**
 * Schema management
 */
- (BOOL)initializeSchema;
- (BOOL)migrateFromVersion:(NSInteger)fromVersion toVersion:(NSInteger)toVersion;
- (NSInteger)getDatabaseVersion;
- (BOOL)setDatabaseVersion:(NSInteger)version;

/**
 * Basic SQL execution
 */
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
- (BOOL)executeInTransactionWithResult:(BOOL (^)(void))block;

/**
 * Bulk operations for performance
 */
- (BOOL)executeBulkInsert:(NSString *)tableName 
                  columns:(NSArray<NSString *> *)columns 
                   values:(NSArray<NSArray *> *)valueArrays;

/**
 * Utility methods
 */
- (NSString *)databasePath;
- (BOOL)tableExists:(NSString *)tableName;
- (void)vacuum;
- (void)analyze;

@end

/**
 * Database factory protocol for dependency injection
 */
@protocol CLXDatabaseFactory <NSObject>

- (id<CLXDatabaseProtocol>)createDatabase;
- (id<CLXDatabaseProtocol>)createDatabaseWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
