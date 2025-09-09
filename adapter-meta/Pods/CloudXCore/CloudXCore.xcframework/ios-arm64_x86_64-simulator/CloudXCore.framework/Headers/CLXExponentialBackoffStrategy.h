/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file ExponentialBackoffStrategy.h
 * @brief Exponential backoff strategy implementation
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error types for exponential backoff strategy
 */
typedef NS_ENUM(NSInteger, ExponentialBackoffStrategyError) {
    ExponentialBackoffStrategyErrorMaxAttemptsReached = 0
};

/**
 * Algorithm to backoff retrying ad.load() when there have been a lot of adLoadFailed events.
 */
@interface CLXExponentialBackoffStrategy : NSObject

/**
 * Initialize a new exponential backoff strategy
 * @param initialDelay Initial delay in seconds
 * @param maxDelay Maximum delay in seconds
 * @param maxAttempts Maximum number of attempts (optional, defaults to max integer)
 * @return Initialized exponential backoff strategy
 */
- (instancetype)initWithInitialDelay:(NSTimeInterval)initialDelay
                             maxDelay:(NSTimeInterval)maxDelay
                          maxAttempts:(NSInteger)maxAttempts;

/**
 * Initialize a new exponential backoff strategy with default max attempts
 * @param initialDelay Initial delay in seconds
 * @param maxDelay Maximum delay in seconds
 * @return Initialized exponential backoff strategy
 */
- (instancetype)initWithInitialDelay:(NSTimeInterval)initialDelay
                             maxDelay:(NSTimeInterval)maxDelay;

/**
 * Get the next delay for the backoff strategy
 * @param error Error pointer to set if max attempts reached
 * @return Next delay in seconds
 */
- (NSTimeInterval)nextDelayWithError:(NSError **)error;

/**
 * Reset the backoff strategy to initial state
 * @return The reset delay (0 for first attempt)
 */
- (NSTimeInterval)reset;

@end

NS_ASSUME_NONNULL_END 