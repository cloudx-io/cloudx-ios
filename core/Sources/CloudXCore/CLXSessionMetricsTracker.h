//
//  CLXSessionMetricsTracker.h
//  CloudXCore
//
//  Created by CloudX iOS Team
//  Copyright (c) 2024 CloudX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSessionMetrics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for session metrics tracking.
 * Enables dependency injection and testing (Interface Segregation Principle).
 */
@protocol CLXSessionMetricsTrackerProtocol <NSObject>

/**
 * Records an impression for session depth tracking.
 *
 * @param placementName The placement identifier
 * @param adType The ad format type
 */
- (void)recordImpressionForPlacement:(NSString *)placementName adType:(NSInteger)adType;

/**
 * Returns current session metrics snapshot.
 */
- (CLXSessionMetrics *)getMetrics;

/**
 * Returns impression count for specific placement in current session.
 */
- (NSInteger)getPlacementDepthForPlacement:(NSString *)placementName;

/**
 * Resets counters for a specific placement.
 */
- (void)resetPlacement:(NSString *)placementName;

/**
 * Resets all session state.
 */
- (void)resetAll;

/**
 * Records SDK initialization timestamp.
 * Called once during CloudXCore.initWithAppKey.
 * Required for time-to-first-ad calculation.
 */
- (void)recordSDKInitialization;

/**
 * Returns time-to-first-ad in milliseconds, or -1 if not yet recorded.
 * Value is only available after first impression in a session.
 */
- (NSInteger)getTimeToFirstAdMs;

/**
 * Sets the callback to be invoked when time-to-first-ad is calculated.
 * The callback is invoked exactly once per session, on the first impression.
 * Thread-safe: callback is invoked on an internal serial queue.
 *
 * @param callback Block that receives the time-to-first-ad value in milliseconds
 */
- (void)setTimeToFirstAdCallback:(void (^)(NSInteger timeToFirstAdMs))callback;

@end

/**
 * Tracks session metrics for impression frequency across global, format, and placement scopes.
 * Metrics reset after 30 minutes of inactivity or an explicit reset call.
 *
 * Thread-safe singleton implementation using serial dispatch queue.
 * Uses monotonic clock (NSProcessInfo.systemUptime) for reliable time tracking.
 *
 * SOLID Principles Applied:
 * - Single Responsibility: Only tracks session metrics, no other concerns
 * - Open/Closed: Extensible through protocol, implementation closed for modification
 * - Liskov Substitution: Conforms to protocol, can be substituted
 * - Interface Segregation: Clean protocol with focused methods
 * - Dependency Inversion: Depends on abstractions (clock provider) not concretions
 *
 * Architecture matches Android SessionMetricsTracker with iOS conventions:
 * - Singleton pattern via +sharedInstance
 * - Serial dispatch queue for thread safety
 * - NSTimeInterval for time tracking
 * - Objective-C naming conventions
 */
@interface CLXSessionMetricsTracker : NSObject <CLXSessionMetricsTrackerProtocol>

/**
 * Shared singleton instance.
 * Thread-safe initialization using dispatch_once.
 */
+ (instancetype)sharedInstance;

/**
 * Records an impression for session depth tracking.
 * Automatically resets session if 30 minutes of inactivity have passed.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @param placementName The placement identifier (must not be nil/empty)
 * @param adType The ad format type (see CLXAdType enum)
 */
- (void)recordImpressionForPlacement:(NSString *)placementName adType:(NSInteger)adType;

/**
 * Returns current session metrics snapshot.
 * Checks for inactivity timeout before returning.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @return Immutable snapshot of current session metrics
 */
- (CLXSessionMetrics *)getMetrics;

/**
 * Returns impression count for specific placement in current session.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @param placementName The placement identifier
 * @return Impression count (0 if placement not tracked)
 */
- (NSInteger)getPlacementDepthForPlacement:(NSString *)placementName;

/**
 * Resets counters for a specific placement.
 * Used when ad view is destroyed (optional - see design notes in implementation plan).
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @param placementName The placement identifier to reset
 */
- (void)resetPlacement:(NSString *)placementName;

/**
 * Resets all session state.
 * Called on SDK initialization or explicit reset.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 */
- (void)resetAll;

#pragma mark - Time-to-First-Ad Tracking

/**
 * Records SDK initialization timestamp.
 * Called once during CloudXCore.initWithAppKey.
 * Required for time-to-first-ad calculation.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 */
- (void)recordSDKInitialization;

/**
 * Returns time-to-first-ad in milliseconds, or -1 if not yet recorded.
 * Value is only available after first impression in a session.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 */
- (NSInteger)getTimeToFirstAdMs;

/**
 * Sets the callback to be invoked when time-to-first-ad is calculated.
 * The callback is invoked exactly once per session, on the first impression.
 * Thread-safe: callback is invoked on an internal serial queue.
 *
 * @param callback Block that receives the time-to-first-ad value in milliseconds
 */
- (void)setTimeToFirstAdCallback:(void (^)(NSInteger timeToFirstAdMs))callback;

#pragma mark - Testing Support

/**
 * Inject custom clock for testing.
 * Enables deterministic testing with controlled time.
 * Default uses NSProcessInfo.systemUptime.
 *
 * @param clockProvider Block that returns current time in seconds
 */
- (void)setClockProviderForTesting:(NSTimeInterval (^)(void))clockProvider;

/**
 * Reset to default clock (NSProcessInfo.systemUptime).
 * Used to cleanup after tests.
 */
- (void)resetClockForTesting;

#pragma mark - Unavailable

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

