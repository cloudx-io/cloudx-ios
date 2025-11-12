/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSession.h
 * @brief Session model replacing Core Data CLXAppSessionModel
 * 
 * SQLite-compatible session model with comprehensive session tracking
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Session model replacing Core Data CLXAppSessionModel
 * Maps to session_table in SQLite database
 */
@interface CLXSession : CLXBaseEvent

/**
 * Session-specific properties
 */
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval endTime;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong, nullable) NSString *url;

/**
 * Initialization
 */
- (instancetype)initWithSessionId:(NSString *)sessionId appKey:(NSString *)appKey;
- (instancetype)initWithSessionId:(NSString *)sessionId appKey:(NSString *)appKey url:(nullable NSString *)url;

/**
 * Session lifecycle
 */
- (void)startSession;
- (void)endSession;
- (void)updateDuration;
- (BOOL)isActive;

/**
 * Factory methods
 */
+ (instancetype)currentSessionWithAppKey:(NSString *)appKey;
+ (instancetype)sessionWithAppKey:(NSString *)appKey url:(nullable NSString *)url;

/**
 * Database support
 */
+ (NSArray<NSString *> *)sqlColumnNames;
+ (NSString *)sqlTableName;

@end

NS_ASSUME_NONNULL_END
