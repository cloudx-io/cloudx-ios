/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXNativeAdapterWrapper.h
 * @brief Per-adapter wrapper that takes the `CLXAdapterNativeDelegate` role
 *        on a 3p native adapter and emits per-adapter surfaces from a frozen
 *        `CLXAdapterLifecycleContext`.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterWrapper.h>
#import <CloudXCore/CLXAdapterNative.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXAdapterLifecycleContext;
@class CLXAdLifecycleTracker;
@class CLXAdapterWrapperRegistry;
@class CLXNativeAd;
@class CLXRillTrackingService;
@class CLXTelemetryWiringHelper;
@protocol CLXNativeAdapterWrapperHost;

/**
 * Per-adapter wrapper for native adapters.
 *
 * Why this exists (cross-surface attribution): the legacy publisher-as-delegate
 * path on `CLXPublisherNative` (`didDisplayNativeAdWithExtraInfo:` /
 * `-didClickNativeAd`, since deleted in favor of this wrapper) read mutable
 * publisher state (`self.lastBidResponse`, `self.rillTrackingService`
 * instance state, `self.publisherPlacement`). When a load on auction A is
 * followed by a load on auction B before A's impression / click callback
 * fires, those reads return B's data.
 *
 * The wrapper takes the adapter's delegate role at attach time, captures an
 * immutable `CLXAdapterLifecycleContext`, and emits per-adapter surfaces
 * from that captured context. Slot rotation cannot affect the wrapper's
 * reads because the wrapper holds its own state.
 *
 * The wrapper does NOT replace `CLXPublisherNative` — the publisher stays
 * the host-app-facing entity (load orchestration, expiration timer, debug
 * overlay, publisher delegate fan-out, and host-side bookkeeping such as
 * `sdk.placement` / `sdk.customData` resolver updates that depend on
 * publisher show-time state).
 *
 * Lifetime: registered with `CLXAdapterWrapperRegistry` at attach time;
 * the registry holds the wrapper independent of the publisher's slot
 * rotations so an in-flight callback that lands after the publisher has
 * cleared its slot still finds a live wrapper.
 */
@interface CLXNativeAdapterWrapper : NSObject <CLXAdapterWrapper, CLXAdapterNativeDelegate>

/** The 3p adapter this wrapper is the delegate for. Strong — wrapper owns the adapter. */
@property (nonatomic, strong, readonly) CLXAdapterNative *adapter;

/** The per-adapter lifecycle tracker. Lives for the wrapper's full lifetime. */
@property (nonatomic, strong, readonly) CLXAdLifecycleTracker *tracker;

/**
 * The native ad delivered by the adapter at load time. Captured on the
 * `didLoadNativeAd:extraInfo:` callback and exposed for parity with the
 * banner wrapper's `bannerView`. Publishers read the loaded native ad off
 * the wrapper rather than re-reading from publisher state at fan-out time.
 */
@property (nonatomic, strong, readonly, nullable) CLXNativeAd *loadedNativeAd;

/**
 * Designated initializer. Captures everything the wrapper needs at attach
 * time; no mutation methods are exposed.
 *
 * Construction preconditions: the tracker's `context.bidId` and
 * `context.auction.auctionId` must both be non-empty. Empty identifiers
 * indicate a bug in the upstream attach path — the wrapper refuses to
 * construct in that case rather than silently emitting mis-attributed
 * telemetry downstream.
 *
 * @param accountId       SDK account identifier captured at attach time.
 *                        Used by the wrapper to pass into stateless Rill
 *                        emission so a late callback attributes against
 *                        the account that owned this auction.
 */
- (instancetype)initWithAdapter:(CLXAdapterNative *)adapter
                         tracker:(CLXAdLifecycleTracker *)tracker
                            host:(id<CLXNativeAdapterWrapperHost>)host
                        registry:(nullable CLXAdapterWrapperRegistry *)registry
                       accountId:(nullable NSString *)accountId
                     rillService:(nullable CLXRillTrackingService *)rillService
            telemetryWiringHelper:(nullable CLXTelemetryWiringHelper *)telemetryWiringHelper
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Releases this wrapper from the registry. Idempotent. Invoked by the
 * publisher during slot teardown (reload, destroy, expire) and by the
 * wrapper itself on terminal events (`didFailToLoadNativeAdWithError:`,
 * `-didCloseNativeAd`).
 */
- (void)releaseFromRegistry;

#pragma mark - Adapter proxies (parity with Android wrapper)

/** Proxy: forward `load` to the underlying adapter. */
- (void)load;

/** Proxy: forward `destroy` to the underlying adapter. */
- (void)destroy;

@end

#pragma mark - Host protocol

/**
 * Tasks the wrapper hands back to the publisher (host). Task-oriented (not
 * state-oriented) — the wrapper never reads publisher state directly.
 *
 * For non-cross-surface events (didLoad / didFail), the host is expected to
 * forward to the existing legacy publisher methods so the publisher's
 * load-success / load-failure work (waterfall LURLs, latency metrics,
 * publisher delegate fan-out) runs once. For cross-surface events
 * (didDisplay / didClick / didClose) the wrapper has already emitted the
 * tracker / Rill / win-loss surfaces, so the host method is the delegate
 * fan-out only — it must NOT re-enter the legacy publisher method to avoid
 * double emission.
 *
 * Adapter-typed parameters are intentionally absent from cross-surface host
 * calls — the publisher does not need access to the concrete adapter (the
 * wrapper owns it). Load callbacks keep the adapter parameter so the legacy
 * publisher path can dispatch on the adapter pointer (waterfall id, etc.).
 */
@protocol CLXNativeAdapterWrapperHost <NSObject>

/**
 * Adapter loaded. Host typically forwards to the legacy
 * didLoadNativeAd:extraInfo: which performs publisher-side load-success
 * bookkeeping + delegate fan-out. The `nativeAd` parameter is the same
 * instance the wrapper captured on `loadedNativeAd`.
 */
- (void)nativeWrapper:(CLXNativeAdapterWrapper *)wrapper
        didLoadWithNativeAd:(CLXNativeAd *)nativeAd
              extraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;

/** Adapter failed to load. Wrapper has already self-released. */
- (void)nativeWrapper:(CLXNativeAdapterWrapper *)wrapper
   didFailToLoadWithError:(nullable NSError *)error;

/**
 * Adapter displayed (impression). Wrapper has already emitted Rill,
 * trackImpression, render-success, session-impression. The host method
 * does the publisher-side `sdk.placement` / `sdk.customData` resolver
 * bookkeeping (publisher state is the source of truth at show time)
 * plus publisher delegate fan-out (didDisplayAd: + didPayRevenueForAd:).
 *
 * The `auctionId` parameter is intentionally absent — the publisher reads
 * it off `wrapper.tracker.context.auction.auctionId` so resolver keys
 * always match the captured auction even if publisher state has rotated.
 */
- (void)nativeWrapper:(CLXNativeAdapterWrapper *)wrapper
      didDisplayWithExtraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;

/**
 * Deliver the impression-time revenue ILRD callback to the publisher. Split
 * from `didDisplay…` so the publisher's bookkeeping (resolver updates,
 * placement/customData re-emission to event telemetry) happens deterministically
 * before revenue fan-out, and so a host that wants to suppress revenue
 * (e.g., debug overlay only) can no-op this call without affecting display.
 */
- (void)nativeWrapper:(CLXNativeAdapterWrapper *)wrapper
        deliverRevenueWithAd:(CLXAd *)ad;

/** Click: wrapper has emitted Rill / trackClick / win-loss. Host does didClickAd: delegate fan-out. */
- (void)nativeWrapper:(CLXNativeAdapterWrapper *)wrapper deliverClickWithAd:(CLXAd *)ad;

@optional

/**
 * AdChoices opt-out close. Wrapper has emitted trackClose:UserDismiss
 * and self-released. Host does didCloseAd: delegate fan-out.
 */
- (void)nativeWrapperDidCloseByUserAction:(CLXNativeAdapterWrapper *)wrapper;

@end

NS_ASSUME_NONNULL_END
