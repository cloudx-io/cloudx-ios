//
//  CLXBidderLoadOutcome.h
//  CloudXCore
//
//  Created by CloudX iOS Team
//  Copyright (c) 2026 CloudX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A single recorded load or render failure for a bidder: one entry of the
 * wire's `load.bidderOutcomes[].failures[]` array (CXD-3409 / CXD-3410).
 *
 * Facts only. Age, latency, and the real CloudX error code, no classification
 * (no `isFastFail`, no thresholds) -- the server owns the verdict on what a run
 * of failures with these codes means.
 */
@interface CLXBidderLoadFailure : NSObject

/// Milliseconds between when this failure occurred and when the enclosing bid
/// request was constructed, derived at serialization time from a stored
/// monotonic mark (`CACurrentMediaTime()`) -- never an absolute or epoch
/// timestamp, since a wall-clock change or NTP sync would corrupt it. Added in
/// schema_version 2 so the server can evaluate its own rolling window
/// statelessly instead of double-counting these cumulative counters on every
/// subsequent bid request.
@property (nonatomic, assign, readonly) NSInteger ageMs;

/// `"load"` or `"render"`. New in schema_version 3: the spec scopes cool-off
/// to load and render failures and excludes init, so the stage has to travel
/// on the wire for the server to apply per-stage rules.
@property (nonatomic, copy, readonly) NSString *stage;

/// Load or show latency in integer milliseconds, from the monotonic clock.
@property (nonatomic, assign, readonly) NSInteger latencyMs;

/// The CloudX integer error code (see CLXErrorCode) the adapter failed with,
/// passed through opaquely -- this class never classifies it.
@property (nonatomic, assign, readonly) NSInteger errorCode;

/// The effective ad-load timeout the SDK actually enforced for this attempt
/// (the value actually given to `CLXAdapterLoader`, including any default
/// fallback) -- present only when `stage` is `"load"`; nil on `"render"`
/// entries, since no load timeout governs a render failure. New in
/// schema_version 3.
@property (nonatomic, copy, readonly, nullable) NSNumber *timeoutMs;

/// Wire format string (banner/mrec/interstitial/rewarded/native/app_open),
/// the same identifier `buildLoadBlock`'s `format` field uses. New in
/// schema_version 3, for clustering analysis in shadow mode.
@property (nonatomic, copy, readonly) NSString *format;

- (instancetype)initWithAgeMs:(NSInteger)ageMs
                         stage:(NSString *)stage
                     latencyMs:(NSInteger)latencyMs
                     errorCode:(NSInteger)errorCode
                     timeoutMs:(nullable NSNumber *)timeoutMs
                        format:(NSString *)format NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * Per-bidder session load outcome: one entry of the wire's
 * `load.bidderOutcomes[]` array (CXD-3409 / CXD-3410).
 *
 * Immutable snapshot returned by `CLXSessionMetricsTracker` -- not itself the
 * mutable store. schema_version 3 changed the reset semantics from
 * schema_version 2: a successful load no longer deletes the bidder's store
 * entry. Instead it sets `lastSuccessAgeMs` and clears `loadFailures`,
 * `renderFailures`, and `failures` -- so a healthy bidder still produces an
 * instance of this class (zero counters, EMPTY `failures`, non-nil
 * `lastSuccessAgeMs`). One instance exists per bidder attempted this session,
 * healthy or not; see `CLXSessionMetricsTracker` for the exact reset contract.
 *
 * `failures` is capped at the 10 most recent entries (newest first) ACROSS
 * BOTH STAGES combined, so `loadFailures` / `renderFailures` MAY EXCEED the
 * count of their matching-stage entries in `failures` once a session's
 * failure run exceeds the cap -- that excess is how the server learns the
 * reported sample is truncated. schema_version 2 dropped the redundant
 * `loadAttempts` field that shipped in schema_version 1: under the reset rule
 * it was provably always equal to `loadFailures`, so it was pure redundancy
 * that could only diverge.
 */
@interface CLXBidderLoadOutcome : NSObject

/// Wire name of the bidder (`CLXSDKConfigBidder mappedNetworkNameForName:`),
/// never a display name.
@property (nonatomic, copy, readonly) NSString *bidder;

/// Milliseconds since this bidder's most recent successful load this
/// session, computed at serialization time from a stored monotonic mark. Nil
/// when the bidder has not yet succeeded at all this session. New in
/// schema_version 3.
@property (nonatomic, copy, readonly, nullable) NSNumber *lastSuccessAgeMs;

/// True cumulative load-stage failures recorded since `lastSuccessAgeMs` (or
/// since session start when that is nil). MAY EXCEED the number of
/// load-stage entries in `failures` when the 10-entry combined cap has been
/// hit.
@property (nonatomic, assign, readonly) NSInteger loadFailures;

/// True cumulative render-stage failures over the same span, same cap
/// caveat. New in schema_version 3.
@property (nonatomic, assign, readonly) NSInteger renderFailures;

/// Up to the 10 most recent failures across both stages combined, newest
/// first.
@property (nonatomic, copy, readonly) NSArray<CLXBidderLoadFailure *> *failures;

- (instancetype)initWithBidder:(NSString *)bidder
               lastSuccessAgeMs:(nullable NSNumber *)lastSuccessAgeMs
                   loadFailures:(NSInteger)loadFailures
                 renderFailures:(NSInteger)renderFailures
                       failures:(NSArray<CLXBidderLoadFailure *> *)failures NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
