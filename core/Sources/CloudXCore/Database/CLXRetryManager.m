/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXRetryManager.h"
#import "CLXLogger.h"
#import "CLXError.h"

#pragma mark - CLXRetryPolicy

@implementation CLXRetryPolicy

+ (instancetype)defaultPolicy {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.maxRetries = 3;
    policy.baseDelay = 1.0; // 1 second
    policy.maxDelay = 30.0; // 30 seconds
    policy.backoffMultiplier = 2.0; // Exponential backoff
    policy.jitterFactor = 0.1; // 10% jitter
    return policy;
}

+ (instancetype)aggressivePolicy {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.maxRetries = 5;
    policy.baseDelay = 0.5; // 500ms
    policy.maxDelay = 15.0; // 15 seconds
    policy.backoffMultiplier = 1.5;
    policy.jitterFactor = 0.2; // 20% jitter
    return policy;
}

+ (instancetype)conservativePolicy {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.maxRetries = 2;
    policy.baseDelay = 2.0; // 2 seconds
    policy.maxDelay = 60.0; // 1 minute
    policy.backoffMultiplier = 3.0;
    policy.jitterFactor = 0.05; // 5% jitter
    return policy;
}

@end

#pragma mark - CLXRetryManager

@interface CLXRetryManager ()

@property (nonatomic, strong) CLXRetryPolicy *policy;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) dispatch_queue_t retryQueue;

// Circuit breaker state
@property (nonatomic, assign) NSInteger consecutiveFailures;
@property (nonatomic, assign) NSTimeInterval lastFailureTime;
@property (nonatomic, assign) BOOL circuitOpen;

@end

@implementation CLXRetryManager

#pragma mark - Initialization

- (instancetype)initWithPolicy:(CLXRetryPolicy *)policy {
    if (self = [super init]) {
        _policy = policy ?: [CLXRetryPolicy defaultPolicy];
        _logger = [[CLXLogger alloc] initWithCategory:@"RetryManager"];
        _retryQueue = dispatch_queue_create("com.cloudx.retry", DISPATCH_QUEUE_SERIAL);
        _consecutiveFailures = 0;
        _lastFailureTime = 0;
        _circuitOpen = NO;
    }
    return self;
}

- (instancetype)init {
    return [self initWithPolicy:[CLXRetryPolicy defaultPolicy]];
}

#pragma mark - Public Methods

- (void)executeOperation:(CLXRetryOperation)operation
              completion:(CLXRetryCompletion)completion {
    [self executeOperation:operation policy:self.policy completion:completion];
}

- (void)executeOperation:(CLXRetryOperation)operation
                  policy:(CLXRetryPolicy *)policy
              completion:(CLXRetryCompletion)completion {
    
    if (!operation || !completion) {
        [self.logger error:@"Invalid operation or completion block"];
        if (completion) {
            completion(NO, [CLXError errorWithCode:CLXErrorCodeInvalidRequest 
                                        description:@"Invalid operation or completion block"], 0);
        }
        return;
    }
    
    dispatch_async(self.retryQueue, ^{
        [self executeOperationInternal:operation 
                                policy:policy 
                               attempt:1 
                            completion:completion];
    });
}

#pragma mark - Private Methods

- (void)executeOperationInternal:(CLXRetryOperation)operation
                          policy:(CLXRetryPolicy *)policy
                         attempt:(NSInteger)attempt
                      completion:(CLXRetryCompletion)completion {
    
    // Check circuit breaker
    if (self.circuitOpen && ![self shouldResetCircuitBreaker]) {
        [self.logger info:@"Circuit breaker is open, failing fast"];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeNetworkError 
                                     description:@"Circuit breaker is open"];
        completion(NO, error, attempt);
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Executing operation attempt %ld/%ld", (long)attempt, (long)policy.maxRetries]];
    
    operation(^(BOOL success, NSError *error) {
        dispatch_async(self.retryQueue, ^{
            if (success) {
                [self handleSuccess];
                [self.logger debug:[NSString stringWithFormat:@"Operation succeeded on attempt %ld", (long)attempt]];
                completion(YES, nil, attempt);
            } else {
                [self handleFailure:error];
                
                if (attempt >= policy.maxRetries || ![self shouldAttemptRetry:error attemptCount:attempt]) {
                    [self.logger error:[NSString stringWithFormat:@"Operation failed after %ld attempts: %@", 
                     (long)attempt, error.localizedDescription]];
                    completion(NO, error, attempt);
                } else {
                    // Schedule retry
                    NSTimeInterval delay = [self calculateDelayForAttempt:attempt withPolicy:policy];
                    [self.logger debug:[NSString stringWithFormat:@"Retrying operation in %.2f seconds (attempt %ld)", 
                     delay, (long)(attempt + 1)]];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), 
                                   self.retryQueue, ^{
                        [self executeOperationInternal:operation 
                                                policy:policy 
                                               attempt:attempt + 1 
                                            completion:completion];
                    });
                }
            }
        });
    });
}

- (void)handleSuccess {
    self.consecutiveFailures = 0;
    self.circuitOpen = NO;
}

- (void)handleFailure:(NSError *)error {
    self.consecutiveFailures++;
    self.lastFailureTime = [[NSDate date] timeIntervalSince1970];
    
    // Open circuit breaker after too many consecutive failures
    if (self.consecutiveFailures >= 5) {
        self.circuitOpen = YES;
        [self.logger info:[NSString stringWithFormat:@"Circuit breaker opened after %ld consecutive failures", 
                     (long)self.consecutiveFailures]];
    }
}

- (BOOL)shouldResetCircuitBreaker {
    if (!self.circuitOpen) {
        return NO;
    }
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastFailure = now - self.lastFailureTime;
    
    // Reset circuit breaker after 60 seconds
    return timeSinceLastFailure > 60.0;
}

#pragma mark - Delay Calculation

- (NSTimeInterval)calculateDelayForAttempt:(NSInteger)attempt {
    return [self calculateDelayForAttempt:attempt withPolicy:self.policy];
}

- (NSTimeInterval)calculateDelayForAttempt:(NSInteger)attempt withPolicy:(CLXRetryPolicy *)policy {
    // Exponential backoff: baseDelay * (backoffMultiplier ^ (attempt - 1))
    NSTimeInterval delay = policy.baseDelay * pow(policy.backoffMultiplier, attempt - 1);
    
    // Cap at max delay
    delay = MIN(delay, policy.maxDelay);
    
    // Add jitter to prevent thundering herd
    if (policy.jitterFactor > 0) {
        double jitterRange = delay * policy.jitterFactor;
        double jitter = (arc4random_uniform(2000) / 1000.0 - 1.0) * jitterRange; // -jitterRange to +jitterRange
        delay += jitter;
    }
    
    // Ensure minimum delay
    delay = MAX(delay, 0.1);
    
    return delay;
}

#pragma mark - Retry Logic

- (BOOL)shouldAttemptRetry:(NSError *)error attemptCount:(NSInteger)attemptCount {
    // Don't retry if circuit breaker is open
    if (self.circuitOpen && ![self shouldResetCircuitBreaker]) {
        return NO;
    }
    
    // Check if error is retryable
    if (![self isRetryableError:error]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isRetryableError:(NSError *)error {
    if (!error) {
        return NO;
    }
    
    // Check CloudX error codes
    if ([error.domain isEqualToString:CLXErrorDomain]) {
        switch (error.code) {
            case CLXErrorCodeNetworkError:
            case CLXErrorCodeNetworkTimeout:
            case CLXErrorCodeServerError:
                return YES;
            case CLXErrorCodeInvalidRequest:
            case CLXErrorCodeInvalidPlacement:
                return NO; // Don't retry client errors
            default:
                return YES; // Retry unknown errors
        }
    }
    
    // Check NSURLError codes
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorTimedOut:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorDNSLookupFailed:
                return YES;
            case NSURLErrorBadURL:
            case NSURLErrorUnsupportedURL:
            case NSURLErrorHTTPTooManyRedirects:
                return NO; // Don't retry client errors
            default:
                return YES;
        }
    }
    
    // Default to retryable for unknown error domains
    return YES;
}

#pragma mark - Utility Methods

- (void)reset {
    dispatch_async(self.retryQueue, ^{
        self.consecutiveFailures = 0;
        self.lastFailureTime = 0;
        self.circuitOpen = NO;
        [self.logger debug:@"Retry manager reset"];
    });
}

- (NSDictionary *)diagnostics {
    return @{
        @"consecutiveFailures": @(self.consecutiveFailures),
        @"lastFailureTime": @(self.lastFailureTime),
        @"circuitOpen": @(self.circuitOpen),
        @"policy": @{
            @"maxRetries": @(self.policy.maxRetries),
            @"baseDelay": @(self.policy.baseDelay),
            @"maxDelay": @(self.policy.maxDelay),
            @"backoffMultiplier": @(self.policy.backoffMultiplier),
            @"jitterFactor": @(self.policy.jitterFactor)
        }
    };
}

@end
