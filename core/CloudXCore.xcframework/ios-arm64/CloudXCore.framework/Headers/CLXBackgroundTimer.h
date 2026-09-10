/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BackgroundTimer.h
 * @brief Background timer implementation
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Background timer for scheduling repeating timers
 */
@interface CLXBackgroundTimer : NSObject

/**
 * Event handler block called when timer fires
 */
@property (nonatomic, copy, nullable) void (^eventHandler)(void);

/**
 * Schedule a repeating timer
 * @param timeInterval Time interval in seconds
 * @param queueLabel Label for the dispatch queue
 * @return Initialized background timer
 */
+ (instancetype)scheduleRepeatingTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                            queueLabel:(NSString *)queueLabel;

/**
 * Schedule a one-time timer
 * @param timeInterval Time interval in seconds
 * @param queueLabel Label for the dispatch queue
 * @return Initialized background timer
 */
+ (instancetype)scheduleTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                   queueLabel:(NSString *)queueLabel;

/**
 * Whether the timer is currently running (resumed rather than suspended).
 *
 * CXD-3709: the suspend/resume pair is driven by app-state notifications, so
 * whether the clock is actually ticking is observable behaviour worth being
 * able to read — not just an internal detail. It also lets the telemetry
 * report only real transitions: those notifications fire whether or not a
 * countdown was live.
 */
@property (nonatomic, readonly, getter=isRunning) BOOL running;

/**
 * Resume the timer
 */
- (void)resume;

/**
 * Suspend the timer
 */
- (void)suspend;

@end

NS_ASSUME_NONNULL_END 