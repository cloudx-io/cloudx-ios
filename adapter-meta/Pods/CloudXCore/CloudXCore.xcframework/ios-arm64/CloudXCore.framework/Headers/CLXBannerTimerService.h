/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BannerTimerService.h
 * @brief Banner timer service implementation
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Banner timer service for managing countdown timers
 */
@interface CLXBannerTimerService : NSObject

/**
 * Initialize a new banner timer service
 * @return Initialized banner timer service
 */
- (instancetype)init;

/**
 * Start a countdown timer
 * @param deadline Deadline in seconds
 * @param completion Completion block called when timer reaches deadline
 */
- (void)startCountDownWithDeadline:(NSTimeInterval)deadline
                       completion:(void (^)(void))completion;

/**
 * Stop the timer
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END 