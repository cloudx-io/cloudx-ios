/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterWrapper.h
 * @brief Common protocol for per-format adapter wrappers — the immutable
 *        per-callback source of truth for cross-surface attribution.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterLifecycleContext;

/**
 * Identity / lifetime contract for a per-adapter wrapper.
 *
 * The wrapper is the delegate for the partner-SDK adapter. It owns an
 * immutable `CLXAdapterLifecycleContext` captured at adapter-attach time
 * (auction id, bid id, ad network, telemetry payloads, Rill snapshot,
 * frozen bid, ad-unit name, placement). Every observability surface
 * (lifecycle telemetry, BURL, Rill, revenue ILRD, session-depth metrics)
 * emits from the wrapper using identifiers from this context — never
 * from publisher-global mutable state.
 *
 * Lifetime: held by `CLXAdapterWrapperRegistry` for the lifetime of the
 * adapter, not the lifetime of the publisher slot. The wrapper invokes
 * `[registry releaseWrapperForKey:self.registryKey]` on its own terminal
 * events; callers must not rely on weak references to wrappers — slot
 * rotation alone does NOT release them.
 */
@protocol CLXAdapterWrapper <NSObject>

/** Stable identity key used by `CLXAdapterWrapperRegistry`. */
@property (nonatomic, copy, readonly) NSString *registryKey;

/**
 * Immutable context captured at adapter-attach time. All cross-surface
 * emissions read from this — never from publisher-global state.
 */
@property (nonatomic, strong, readonly) CLXAdapterLifecycleContext *context;

@end

NS_ASSUME_NONNULL_END
