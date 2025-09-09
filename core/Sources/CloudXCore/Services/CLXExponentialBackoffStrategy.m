/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file ExponentialBackoffStrategy.m
 * @brief Exponential backoff strategy implementation
 */

#import <CloudXCore/CLXExponentialBackoffStrategy.h>
#import <math.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXExponentialBackoffStrategy ()

@property (nonatomic, assign) NSInteger maxAttempts;
@property (nonatomic, assign) NSInteger attempt;
@property (nonatomic, assign) NSTimeInterval initialDelay;
@property (nonatomic, assign) NSTimeInterval maxDelay;

@end

@implementation CLXExponentialBackoffStrategy

- (instancetype)initWithInitialDelay:(NSTimeInterval)initialDelay
                             maxDelay:(NSTimeInterval)maxDelay
                          maxAttempts:(NSInteger)maxAttempts {
    self = [super init];
    if (self) {
        _maxAttempts = maxAttempts;
        _attempt = 0;
        _initialDelay = initialDelay;
        _maxDelay = maxDelay;
    }
    return self;
}

- (instancetype)initWithInitialDelay:(NSTimeInterval)initialDelay
                             maxDelay:(NSTimeInterval)maxDelay {
    return [self initWithInitialDelay:initialDelay
                              maxDelay:maxDelay
                           maxAttempts:NSIntegerMax];
}

- (NSTimeInterval)nextDelayWithError:(NSError **)error {
    if (self.attempt >= self.maxAttempts) {
        if (error) {
            *error = [NSError errorWithDomain:@"ExponentialBackoffStrategy"
                                         code:ExponentialBackoffStrategyErrorMaxAttemptsReached
                                     userInfo:@{NSLocalizedDescriptionKey: @"Maximum attempts reached"}];
        }
        return 0;
    }
    
    // Do first request without delay
    if (self.attempt == 0) {
        self.attempt += 1;
        return 0;
    }
    
    NSTimeInterval delay = MIN(self.initialDelay * pow(2.0, (double)self.attempt), self.maxDelay);
    self.attempt += 1;
    return delay;
}

- (NSTimeInterval)reset {
    self.attempt = 0;
    return 0;
}

@end

NS_ASSUME_NONNULL_END 