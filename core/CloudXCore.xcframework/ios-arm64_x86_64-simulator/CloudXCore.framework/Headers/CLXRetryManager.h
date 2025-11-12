/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRetryManager.h
 * @brief Retry manager with exponential backoff matching Android implementation
 * 
 * Features:
 * - Exponential backoff with jitter
 * - Circuit breaker pattern
 * - Configurable retry policies
 * - Network-aware retry scheduling
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Retry policy configuration
 */
@interface CLXRetryPolicy : NSObject

@property (nonatomic, assign) NSInteger maxRetries;
@property (nonatomic, assign) NSTimeInterval baseDelay;
@property (nonatomic, assign) NSTimeInterval maxDelay;
@property (nonatomic, assign) double backoffMultiplier;
@property (nonatomic, assign) double jitterFactor;

+ (instancetype)defaultPolicy;
+ (instancetype)aggressivePolicy;
+ (instancetype)conservativePolicy;

@end

/**
 * Retry operation block types
 */
typedef void (^CLXRetryOperation)(void (^completion)(BOOL success, NSError *_Nullable error));
typedef void (^CLXRetryCompletion)(BOOL finalSuccess, NSError *_Nullable finalError, NSInteger attemptCount);

/**
 * Retry manager with exponential backoff and circuit breaker
 */
@interface CLXRetryManager : NSObject

@property (nonatomic, strong, readonly) CLXRetryPolicy *policy;
@property (nonatomic, strong, readonly) CLXLogger *logger;

/**
 * Initialization
 */
- (instancetype)initWithPolicy:(CLXRetryPolicy *)policy;

/**
 * Execute operation with retry logic
 */
- (void)executeOperation:(CLXRetryOperation)operation
              completion:(CLXRetryCompletion)completion;

- (void)executeOperation:(CLXRetryOperation)operation
                  policy:(CLXRetryPolicy *)policy
              completion:(CLXRetryCompletion)completion;

/**
 * Calculate next retry delay
 */
- (NSTimeInterval)calculateDelayForAttempt:(NSInteger)attempt;
- (NSTimeInterval)calculateDelayForAttempt:(NSInteger)attempt withPolicy:(CLXRetryPolicy *)policy;

/**
 * Circuit breaker functionality
 */
- (BOOL)shouldAttemptRetry:(NSError *)error attemptCount:(NSInteger)attemptCount;
- (BOOL)isRetryableError:(NSError *)error;

/**
 * Utility methods
 */
- (void)reset;
- (NSDictionary *)diagnostics;

@end

NS_ASSUME_NONNULL_END
