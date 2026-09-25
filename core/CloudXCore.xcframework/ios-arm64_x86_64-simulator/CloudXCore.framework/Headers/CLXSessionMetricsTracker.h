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
// Private wire-contract type (CXD-3409 / CXD-3410). Forward-declared rather than
// imported: this header is Public and may not include a Private one, and the type
// appears only as a pointer in -getBidderLoadOutcomes' return type.
@class CLXBidderLoadOutcome;

@protocol CLXSessionMetricsTrackerProtocol <NSObject>

/**
 * Records an impression for session depth tracking.
 *
 * @param adUnitName The ad unit identifier
 * @param adType The ad format type
 */
- (void)recordImpressionForAdUnit:(NSString *)adUnitName adType:(NSInteger)adType;

/**
 * Returns current session metrics snapshot.
 */
- (CLXSessionMetrics *)getMetrics;

/**
 * Returns impression count for specific ad unit in current session.
 */
- (NSInteger)getAdUnitDepthForAdUnit:(NSString *)adUnitName;

/**
 * Resets counters for a specific ad unit.
 */
- (void)resetAdUnit:(NSString *)adUnitName;

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

#pragma mark - Bidder load outcomes (CXD-3409 / CXD-3410)

/**
 * Records a failed load attempt for a bidder in the current process's session.
 *
 * Deliberately NOT subject to the 30-minute idle-inactivity reset that the rest
 * of this tracker's state uses (see `-maybeResetForInactivity:`): the only two
 * reset triggers for this counter family are (1) a successful load from the same
 * bidder -- see `-recordBidderLoadSuccessForBidder:` -- and (2) process death (this
 * store is in-memory only and is never written to disk). An idle timeout was
 * never a stated requirement for this field; it was only an incidental property
 * of where the pre-existing `session` block counters happen to live.
 *
 * The true failure count is tracked independently of the retained failure
 * detail array, which is capped at the 10 most recent entries (newest first)
 * ACROSS BOTH LOAD AND RENDER STAGES COMBINED, so a long failing session
 * cannot grow the bid request unboundedly -- see `getBidderLoadOutcomes`. A
 * monotonic mark (`CACurrentMediaTime()`) is stored per failure at record
 * time; `ageMs` is derived from it at snapshot time.
 *
 * @param bidder Wire name of the bidder (`CLXSDKConfigBidder mappedNetworkNameForName:`),
 *               never a display name. No-op if empty.
 * @param errorCode The CloudX integer error code (see CLXErrorCode), passed through
 *                   opaquely. Callers must not report NoFill (302) or AdapterNoFill
 *                   (601) here -- those are excluded upstream.
 * @param latencyMs Load latency in integer milliseconds from the monotonic clock.
 * @param timeoutMs The effective ad-load timeout the SDK actually enforced for
 *                  this attempt (the value actually given to `CLXAdapterLoader`,
 *                  including any default fallback). New in schema_version 3.
 * @param format Wire format string (banner/mrec/interstitial/rewarded/native/
 *               app_open) -- the same identifier `buildLoadBlock`'s `format`
 *               field uses. New in schema_version 3.
 */
- (void)recordBidderLoadFailureForBidder:(NSString *)bidder
                                errorCode:(NSInteger)errorCode
                                latencyMs:(NSInteger)latencyMs
                                timeoutMs:(NSInteger)timeoutMs
                                   format:(NSString *)format;

/**
 * Records a failed render/show attempt for a bidder in the current process's
 * session (CXD-3409 / CXD-3410 schema_version 3). Same counter family and
 * cap as the load-failure counterpart above, but tallied into `renderFailures`
 * and tagged `stage: "render"` rather than `"load"`. Render failures carry no
 * `timeoutMs` -- no load timeout governs a render attempt.
 *
 * @param bidder Wire name of the bidder. No-op if empty.
 * @param errorCode The CloudX integer error code, passed through opaquely.
 *                  Callers must not report NoFill (302) or AdapterNoFill (601).
 * @param latencyMs Show/render latency in integer milliseconds from the
 *                  monotonic clock.
 * @param format Wire format string, same source as the load-failure counterpart.
 */
- (void)recordBidderRenderFailureForBidder:(NSString *)bidder
                                  errorCode:(NSInteger)errorCode
                                  latencyMs:(NSInteger)latencyMs
                                     format:(NSString *)format;

/**
 * Records a successful load for a bidder. schema_version 3 changed this from
 * schema_version 2: the bidder's store entry is no longer deleted. Instead
 * this sets the entry's `lastSuccessAgeMs` mark and clears `loadFailures`,
 * `renderFailures`, and the retained `failures` detail -- so a healthy bidder
 * still produces an explicit recovery record (zero counters, no failures)
 * rather than disappearing. This is one of exactly two reset triggers for
 * this counter family -- see `-recordBidderLoadFailureForBidder:errorCode:latencyMs:timeoutMs:format:`.
 *
 * @param bidder Wire name of the bidder. No-op if empty.
 */
- (void)recordBidderLoadSuccessForBidder:(NSString *)bidder;

/**
 * Returns an immutable snapshot of every bidder attempted (load or render,
 * succeeded or failed) in the current process's session. Empty when nothing
 * was attempted at all -- callers omit the wire field entirely in that case
 * rather than emitting an empty array, matching the `googleWaterfall`
 * precedent. A healthy bidder still yields an entry: `lastSuccessAgeMs`
 * non-nil, `loadFailures` / `renderFailures` zero, `failures` empty.
 *
 * Each outcome's `loadFailures` / `renderFailures` are the true cumulative
 * counts, which MAY EXCEED their matching-stage entry count in `failures`
 * once the 10-entry combined cap has truncated the retained detail -- that is
 * how the server learns the reported sample is truncated. `failures` is
 * ordered newest first across both stages, and each entry's `ageMs` /
 * `lastSuccessAgeMs` is computed at the moment of this call from the
 * monotonic marks stored at record time.
 */
- (NSArray<CLXBidderLoadOutcome *> *)getBidderLoadOutcomes;

@end

/**
 * Tracks session metrics for impression frequency across global, format, and ad unit scopes.
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
 * @param adUnitName The ad unit identifier (must not be nil/empty)
 * @param adType The ad format type (see CLXAdType enum)
 */
- (void)recordImpressionForAdUnit:(NSString *)adUnitName adType:(NSInteger)adType;

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
 * Returns impression count for specific ad unit in current session.
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @param adUnitName The ad unit identifier
 * @return Impression count (0 if ad unit not tracked)
 */
- (NSInteger)getAdUnitDepthForAdUnit:(NSString *)adUnitName;

/**
 * Resets counters for a specific ad unit.
 * Used when ad view is destroyed (optional - see design notes in implementation plan).
 *
 * Thread-safe: Uses serial dispatch queue for synchronization.
 *
 * @param adUnitName The ad unit identifier to reset
 */
- (void)resetAdUnit:(NSString *)adUnitName;

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

/**
 * Clears every bidder's accumulated load-outcome counters.
 *
 * Production code never calls this: the bidder load-outcome store (CXD-3409 /
 * CXD-3410) is deliberately exempt from `-resetAll` and the idle-inactivity
 * reset -- its only two production reset triggers are a bidder's successful
 * load and process death. This method exists solely so tests using the shared
 * singleton don't leak state across cases.
 */
- (void)resetBidderLoadOutcomesForTesting;

#pragma mark - Unavailable

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

