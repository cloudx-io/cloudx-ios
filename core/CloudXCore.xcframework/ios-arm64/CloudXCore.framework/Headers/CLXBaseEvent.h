/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBaseEvent.h
 * @brief Base event model following DRY principles and SOLID design
 * 
 * Shared base class for all event types (metrics, Rill, performance)
 * Provides common functionality while allowing specialization
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Event status enumeration
 */
typedef NS_ENUM(NSInteger, CLXEventStatus) {
    CLXEventStatusPending = 0,
    CLXEventStatusProcessing = 1,
    CLXEventStatusCompleted = 2,
    CLXEventStatusFailed = 3,
    CLXEventStatusRetrying = 4
};

/**
 * Base event protocol for common event operations
 */
@protocol CLXEventProtocol <NSObject>

@required
- (NSString *)eventId;
- (NSString *)sessionId;
- (NSTimeInterval)timestamp;
- (CLXEventStatus)status;
- (NSDictionary *)toDictionary;
- (BOOL)isValid;

@optional
- (NSString *)encryptedPayload;
- (void)setEncryptedPayload:(NSString *)payload;

@end

/**
 * Base event model providing common functionality
 * Abstract base class - should not be instantiated directly
 */
@interface CLXBaseEvent : NSObject <CLXEventProtocol, NSCopying, NSSecureCoding>

/**
 * Common properties for all events
 */
@property (nonatomic, strong, readonly) NSString *eventId;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) NSTimeInterval createdAt;
@property (nonatomic, assign) NSTimeInterval updatedAt;
@property (nonatomic, assign) CLXEventStatus status;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) NSTimeInterval lastRetryAt;

/**
 * Initialization
 */
- (instancetype)initWithEventId:(NSString *)eventId sessionId:(NSString *)sessionId;
- (instancetype)initWithSessionId:(NSString *)sessionId; // Auto-generates eventId

/**
 * Validation
 */
- (BOOL)isValid;
- (NSArray<NSString *> *)validationErrors;

/**
 * Serialization
 */
- (NSDictionary *)toDictionary;
- (NSString *)toJSONString;
+ (nullable instancetype)fromDictionary:(NSDictionary *)dictionary;
+ (nullable instancetype)fromJSONString:(NSString *)jsonString;

/**
 * Database operations support
 */
- (NSArray *)sqlInsertValues;
- (void)updateFromSQLRow:(NSDictionary *)row;

/**
 * Retry management
 */
- (void)incrementRetryCount;
- (BOOL)canRetry;
- (NSTimeInterval)nextRetryDelay;

/**
 * Utility methods
 */
- (NSString *)description;
- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end

/**
 * Event factory protocol for creating different event types
 */
@protocol CLXEventFactory <NSObject>

- (CLXBaseEvent *)createEventWithType:(NSString *)type data:(NSDictionary *)data;
- (CLXBaseEvent *)createEventFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
