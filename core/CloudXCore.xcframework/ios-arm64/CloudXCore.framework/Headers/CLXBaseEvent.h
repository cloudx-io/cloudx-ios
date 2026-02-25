/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBaseEvent.h
 * @brief Base event model for metrics events
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Base event model providing common functionality
 * Abstract base class - should not be instantiated directly
 */
@interface CLXBaseEvent : NSObject

/**
 * Common properties for all events
 */
@property (nonatomic, strong, readonly) NSString *eventId;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, assign) NSTimeInterval createdAt;

/**
 * Initialization
 */
- (instancetype)initWithEventId:(NSString *)eventId sessionId:(NSString *)sessionId;

@end

NS_ASSUME_NONNULL_END
