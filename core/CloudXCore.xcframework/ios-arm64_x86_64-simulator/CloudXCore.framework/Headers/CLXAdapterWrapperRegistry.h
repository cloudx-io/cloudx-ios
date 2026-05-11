/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterWrapperRegistry.h
 * @brief Per-publisher active-wrappers set that keeps wrappers alive for the
 *        lifetime of their adapter, decoupled from publisher slot lifetime.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterWrapper;

/**
 * Strong-reference set of in-flight `id<CLXAdapterWrapper>` instances.
 * The object that owns a registry also owns the maximum lifetime of the
 * wrappers inside it: a publisher-scoped registry protects wrappers from slot
 * rotation inside that publisher, while a coordinator-scoped registry would be
 * required to keep wrappers alive after publisher dealloc.
 *
 * Why a registry separate from publisher slots:
 *
 * The publisher rotates between adapter slots (current-loading, on-screen,
 * previous, prefetched, pending-swap-destroy). Slot rotation drops the
 * publisher's slot reference to the wrapper. If that were the only owner,
 * a partner-SDK callback that fires after rotation would land on a freed
 * wrapper — the silent-drop class of attribution bugs the wrapper
 * architecture is designed to close.
 *
 * The registry holds a strong reference until the wrapper invokes
 * `releaseWrapperForKey:` on the registry from one of its own terminal
 * events (e.g., a fullscreen `adClosed` callback, a banner explicit
 * destroy, or an explicit timer-based teardown). Adapter dealloc is the
 * deterministic terminal-state signal — when nothing else references the
 * wrapper, its own dealloc will call `clearAuction:` on the embedded
 * `CLXAdLifecycleTracker` to tear down its observer chain.
 *
 * Ownership contract: this class does not make a registry globally central.
 * Callers must retain the registry at the ownership layer that matches the
 * callback lifetime they need. In the publisher-owned migration path, wrapper
 * lifetimes are decoupled from slot lifetimes, not from the publisher object
 * itself; publisher destroy/dealloc remains responsible for explicit cleanup
 * of any wrappers that never delivered a clean terminal callback.
 *
 * Terminal-state safety net (Phase 2): for adapters that never fire a
 * clean terminal callback (timeout-only paths, partner-SDK quirks),
 * `releaseWrappersForAuctionId:` lets producers (publishers) release
 * every wrapper bound to a given auction in one shot — wired into the
 * same publisher teardown paths that already invoke
 * `[CLXAdapterLifecycleCorrelator clearAuction:]`.
 *
 * Thread safety: a private concurrent queue serves as a reader-writer
 * lock — writes (`registerWrapper:forKey:`, `releaseWrapperForKey:`)
 * `dispatch_barrier_sync` the queue for exclusive access, reads
 * (`wrapperForKey:`, `count`, `containsKey:`, `snapshotAllWrappers`)
 * `dispatch_sync` and execute in parallel. The barrier model preserves
 * synchronous semantics for callers and is more re-entrancy-tolerant
 * than a plain serial queue under callback-driven flows where a
 * wrapper's terminal callback may indirectly call back into a read
 * API.
 */
@interface CLXAdapterWrapperRegistry : NSObject

/** Number of wrappers currently held alive by the registry. */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Register a wrapper under the given identity key. Subsequent calls with
 * the same key replace the previous entry — callers must use a key that
 * is unique per (auctionId × adapter slot) so the registry doesn't
 * accidentally collapse two in-flight adapters into one.
 *
 * Asserts (DEBUG only) that `wrapper` is non-nil and `key` is non-empty.
 * In release builds the call is a no-op rather than a crash so a
 * misbehaving caller can't poison registration state for other callers.
 */
- (void)registerWrapper:(id<CLXAdapterWrapper>)wrapper forKey:(NSString *)key;

/**
 * Release the wrapper registered under `key`. No-op when the key is not
 * registered. After release returns, the registry no longer holds a
 * reference; the wrapper deallocates as soon as the publisher and the
 * partner-SDK adapter have also released their references.
 */
- (void)releaseWrapperForKey:(NSString *)key;

/**
 * Defensive teardown: releases every wrapper whose
 * `context.auction.auctionId` matches `auctionId`. No-op when `auctionId`
 * is empty or no matching wrapper is registered.
 *
 * Producer hook: callers that already invoke
 * `[CLXAdapterLifecycleCorrelator clearAuction:]` (e.g., publisher
 * destroy / explicit auction teardown) should also call this so wrappers
 * for that auction are not leaked. The matching pass runs under the
 * registry's barrier so it is consistent against concurrent
 * registrations and reads.
 *
 * Use case: a partner SDK that times out without firing close/fail or
 * silently drops a callback. Without this safety net the wrapper would
 * sit in the registry until publisher dealloc, which can be much later
 * than the auction's logical end.
 */
- (void)releaseWrappersForAuctionId:(NSString *)auctionId;

/** Lookup. Returns nil if no wrapper is registered under `key`. */
- (nullable id<CLXAdapterWrapper>)wrapperForKey:(NSString *)key;

/** Returns YES if a wrapper is currently registered under `key`. */
- (BOOL)containsKey:(NSString *)key;

/**
 * Snapshot of every wrapper currently registered. Returned array is a
 * point-in-time copy — safe to iterate without holding the registry's
 * internal queue. Mutations after the snapshot do not affect the
 * returned array.
 */
- (NSArray<id<CLXAdapterWrapper>> *)snapshotAllWrappers;

@end

NS_ASSUME_NONNULL_END
