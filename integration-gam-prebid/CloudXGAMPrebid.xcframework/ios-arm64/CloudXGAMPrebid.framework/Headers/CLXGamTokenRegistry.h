//
//  CLXGamTokenRegistry.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import "CLXGamAdFormat.h"

NS_ASSUME_NONNULL_BEGIN

/** Immutable record of a single registered CloudX bid awaiting a GAM prebid token consume. */
@interface CLXGamRegistration : NSObject
@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, strong, readonly) id owner;
@property (nonatomic, copy, readonly) NSString *placement;
@property (nonatomic, assign, readonly) CLXGamAdFormat format;
@property (nonatomic, assign, readonly) double revenue;
/** Optional static slot name scoping format pairing; nil for the single-instance default. */
@property (nonatomic, copy, readonly, nullable) NSString *slot;
/** CloudX auction payload for the bid, carried through to telemetry; nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *auctionTelemetryPayload;
/** CloudX bid payload for the bid, carried through to telemetry; nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *bidTelemetryPayload;
@end

/** Cancels a scheduled TTL timer. */
typedef void (^CLXGamCancellable)(void);

/** Schedules `action` after `delaySeconds`; returns a cancel block. */
typedef CLXGamCancellable _Nonnull (^CLXGamScheduler)(NSTimeInterval delaySeconds,
                                                      dispatch_block_t action);

/**
 * Single-use token registry mapping minted tokens to CloudX bid registrations.
 *
 * Behavior mirrors the Android canon: each register mints a unique token; consume
 * returns a registration exactly once; re-registering the same owner evicts the
 * prior token; release removes by owner; a TTL timer fires `onExpired` for tokens
 * that are still registered when the timer elapses.
 */
@interface CLXGamTokenRegistry : NSObject

/** Default TTL: 30 minutes. */
@property (class, nonatomic, readonly) NSTimeInterval defaultTTLSeconds;

/** The production scheduler: dispatch_after on the main queue, cancellable. */
+ (CLXGamScheduler)mainQueueScheduler;

/** Invoked when a still-registered token's TTL elapses. */
@property (nonatomic, copy, nullable) void (^onExpired)(CLXGamRegistration *registration);

- (instancetype)init;
- (instancetype)initWithTTLSeconds:(NSTimeInterval)ttlSeconds
                         scheduler:(nullable CLXGamScheduler)scheduler NS_DESIGNATED_INITIALIZER;

/** Mints and registers a token for the bid with no slot; returns the token. */
- (NSString *)registerOwner:(id)owner
                  placement:(NSString *)placement
                     format:(CLXGamAdFormat)format
                    revenue:(double)revenue;

/** Mints and registers a token for the bid under `slot`; returns the token. */
- (NSString *)registerOwner:(id)owner
                  placement:(NSString *)placement
                     format:(CLXGamAdFormat)format
                    revenue:(double)revenue
                       slot:(nullable NSString *)slot;

/** Mints and registers a token carrying the ad's telemetry join payloads; returns the token. */
- (NSString *)registerOwner:(id)owner
                  placement:(NSString *)placement
                     format:(CLXGamAdFormat)format
                    revenue:(double)revenue
                       slot:(nullable NSString *)slot
    auctionTelemetryPayload:(nullable NSString *)auctionTelemetryPayload
        bidTelemetryPayload:(nullable NSString *)bidTelemetryPayload;

/** Consumes a token regardless of its format, returning its registration once (nil thereafter). */
- (nullable CLXGamRegistration *)consumeToken:(NSString *)token;

/**
 * Finds the registration for `token` without consuming it, so a dispatch can be validated
 * (owner class, ad readiness) before `consumeRegistration:` commits it. A format mismatch
 * resolves to nil; the registration and its TTL timer stay untouched either way, so a
 * dispatch that fails validation is still settled by a later notify or its TTL instead of
 * being orphaned eventless. Passing nil accepts any format.
 */
- (nullable CLXGamRegistration *)peekToken:(NSString *)token
                           expectedFormats:(nullable NSArray<NSNumber *> *)expectedFormats;

/**
 * Finds the most recently registered ad for `format` (and `slot` when the custom event's
 * static parameter names one) without consuming it. GAM's mediation parameters cannot carry
 * per-request data, so pairing is by format/slot: the publisher contract of
 * load-CloudX-then-immediately-load-GAM keeps at most one pending registration per key.
 */
- (nullable CLXGamRegistration *)peekLatestForFormat:(CLXGamAdFormat)format
                                                slot:(nullable NSString *)slot;

/**
 * Consumes a registration previously returned by `peekToken:expectedFormats:` or
 * `peekLatestForFormat:slot:`. Returns nil when it is no longer pending — consumed by a
 * concurrent dispatch, released, or expired between the peek and this call — in which case
 * the dispatch must fail. Identity-checked under the same lock as the removal.
 */
- (nullable CLXGamRegistration *)consumeRegistration:(CLXGamRegistration *)registration;

/** Removes and returns the registration held by `owner`, if any. */
- (nullable CLXGamRegistration *)releaseOwner:(id)owner;

@end

NS_ASSUME_NONNULL_END
