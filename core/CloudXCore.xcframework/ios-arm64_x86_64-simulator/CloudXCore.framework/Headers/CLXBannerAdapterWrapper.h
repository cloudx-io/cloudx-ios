/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerAdapterWrapper.h
 * @brief Per-adapter wrapper that takes the `CLXAdapterBannerDelegate` role on
 *        a 3p banner adapter and emits per-adapter surfaces from a frozen
 *        `CLXAdapterLifecycleContext`.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterWrapper.h>
#import <CloudXCore/CLXAdapterBanner.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXAdapterLifecycleContext;
@class CLXAdLifecycleTracker;
@class CLXAdapterWrapperRegistry;
@class CLXRillTrackingService;
@class CLXTelemetryWiringHelper;
@protocol CLXBannerAdapterWrapperHost;

/**
 * Per-adapter wrapper for banner / MREC adapters.
 *
 * Why this exists (cross-surface attribution): the legacy publisher-as-delegate
 * path reads mutable publisher state (`self.lastBidResponse`,
 * `self.rillTrackingService` instance state, `self.adUnitName`,
 * `self.publisherPlacement`) inside `impressionBanner:` / `clickBanner:`.
 * When the publisher rotates auction A -> B between adapter-attach and a late
 * callback, those reads return B's data and the firing adapter's surfaces get
 * mis-attributed.
 *
 * The wrapper takes the adapter's delegate role at attach time, captures an
 * immutable `CLXAdapterLifecycleContext` (auction id, bid id, frozen bid,
 * ad-unit name, placement, ad type), and emits per-adapter surfaces from
 * that captured context. Slot rotation cannot affect the wrapper's reads
 * because the wrapper holds its own state.
 *
 * The wrapper does NOT replace `CLXPublisherBanner` — the publisher stays the
 * host-app-facing entity (slot management, refresh timers, debug overlay,
 * publisher delegate fan-out). The wrapper hands off non-emission tasks to
 * the publisher via the task-oriented `CLXBannerAdapterWrapperHost` protocol.
 *
 * Lifetime: registered with `CLXAdapterWrapperRegistry` at attach time; held
 * strongly by the registry until either the wrapper invokes
 * `releaseFromRegistry` itself (terminal callback) or the publisher invokes
 * it during slot teardown (refresh, destroy). The registry holds the
 * wrapper independent of the publisher's lifetime so an in-flight callback
 * landing after the publisher is deallocated still finds a live wrapper.
 */
@interface CLXBannerAdapterWrapper : NSObject <CLXAdapterWrapper, CLXAdapterBannerDelegate>

/** The 3p adapter this wrapper is the delegate for. Strong — wrapper owns the adapter. */
@property (nonatomic, strong, readonly) CLXAdapterBanner *adapter;

/** The per-adapter lifecycle tracker. Lives for the wrapper's full lifetime. */
@property (nonatomic, strong, readonly) CLXAdLifecycleTracker *tracker;

/**
 * The banner view delivered by the adapter at load time. Hoisted onto the
 * wrapper (parity with Android `BannerAdapterWrapper.adView`) so publishers
 * read the banner view from the wrapper rather than calling back into the
 * concrete adapter.
 */
@property (nonatomic, strong, readonly, nullable) UIView *bannerView;

/**
 * Designated initializer. The wrapper captures everything it needs at
 * construction time; no mutation methods are exposed. The host is held
 * weakly to avoid a retain cycle through the publisher.
 *
 * Construction preconditions: the tracker's `context.bidId` and
 * `context.auction.auctionId` must both be non-empty. Empty identifiers
 * indicate a bug in the upstream attach path — the wrapper refuses to
 * construct in that case rather than silently emitting mis-attributed
 * telemetry downstream.
 *
 * @param adapter         The 3p adapter to wrap. Strong reference.
 * @param tracker         The per-adapter lifecycle tracker (holds the
 *                        immutable context this wrapper reads from).
 * @param host            The publisher (held weakly) that performs
 *                        non-emission tasks (slot rotation, host-facing
 *                        delegate fan-out, debug overlay).
 * @param registry        The wrapper registry that owns the wrapper's
 *                        lifetime. Held weakly — the registry holds the
 *                        wrapper strongly, the wrapper holds the registry
 *                        weakly to avoid a cycle.
 * @param accountId       SDK account identifier captured at attach time.
 *                        Used by the wrapper to pass into stateless Rill
 *                        emission so a late callback attributes against the
 *                        account that owned this auction even if the SDK has
 *                        rotated configs.
 * @param rillService     Rill tracking service used for stateless impression /
 *                        click emission (the legacy stateful methods are NOT
 *                        used from the wrapper path).
 * @param telemetryWiringHelper For per-auction telemetry context bookkeeping
 *                              (e.g., click count increment).
 */
- (instancetype)initWithAdapter:(CLXAdapterBanner *)adapter
                         tracker:(CLXAdLifecycleTracker *)tracker
                            host:(id<CLXBannerAdapterWrapperHost>)host
                        registry:(nullable CLXAdapterWrapperRegistry *)registry
                       accountId:(nullable NSString *)accountId
                     rillService:(nullable CLXRillTrackingService *)rillService
            telemetryWiringHelper:(nullable CLXTelemetryWiringHelper *)telemetryWiringHelper
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Releases this wrapper from the registry. Idempotent. The publisher invokes
 * this during slot teardown (refresh, destroy, swap); the wrapper itself
 * invokes this from terminal-event delegate callbacks (`failToLoadBanner:`,
 * `closedByUserActionBanner:`).
 */
- (void)releaseFromRegistry;

#pragma mark - Adapter proxies (parity with Android wrapper)

/** Proxy: forward `load` to the underlying adapter. */
- (void)load;

/** Proxy: forward `showFromViewController:` to the underlying adapter. */
- (void)showFromViewController:(UIViewController *)viewController;

/** Proxy: forward `destroy` to the underlying adapter. */
- (void)destroy;

@end

#pragma mark - Host protocol

/**
 * Tasks the wrapper hands back to the publisher (host). Task-oriented (not
 * state-oriented) — the wrapper never reads publisher state directly. The
 * publisher conforms to this protocol; the wrapper holds it weakly.
 *
 * `CLXAd` parameter is constructed once by the wrapper at attach time from the
 * frozen bid snapshot and passed through every host call. The publisher does
 * not need to (and should not) build its own `CLXAd` instance for these
 * surfaces — the captured one is the attribution-correct one.
 *
 * Adapter-typed parameters are intentionally absent. Each host call is keyed on
 * the wrapper itself; the publisher does not need access to the concrete
 * adapter (the wrapper owns it). Mirrors the Android wrapper-callback shape
 * (host receives the wrapper, not the adapter).
 */
@protocol CLXBannerAdapterWrapperHost <NSObject>

/** Adapter slot rotation: this adapter finished loading. */
- (void)bannerWrapperDidLoad:(CLXBannerAdapterWrapper *)wrapper;

/** Adapter slot rotation: this adapter failed to load. Wrapper has already self-released. */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper didFailToLoadWithError:(nullable NSError *)error;

/** Adapter loaded successfully, then entered a terminal renderer failure state. */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper didFailAfterLoadWithError:(NSError *)error;

/** Adapter signaled "shown" (typically a no-op, here for protocol completeness). */
- (void)bannerWrapperDidShow:(CLXBannerAdapterWrapper *)wrapper;

/** Adapter closed by user action. Wrapper has already self-released. */
- (void)bannerWrapperDidCloseByUserAction:(CLXBannerAdapterWrapper *)wrapper;

/** Adapter expanded (host forwards to the user-facing publisher delegate). */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper didExpandWithAd:(CLXAd *)ad;

/** Adapter collapsed (host forwards to the user-facing publisher delegate). */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper didCollapseWithAd:(CLXAd *)ad;

/**
 * Deliver a click event to the user-facing publisher delegate. The wrapper has
 * already emitted Rill / BURL / click count for the click; this call is the
 * host-side delegate fan-out + click-feedback UI.
 */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper deliverClickWithAd:(CLXAd *)ad;

/**
 * Deliver a revenue ILRD callback to the user-facing revenue delegate. The
 * wrapper has already emitted Rill / BURL / impression / session for the
 * impression; this call is the host-side revenue delegate fan-out.
 */
- (void)bannerWrapper:(CLXBannerAdapterWrapper *)wrapper deliverRevenueWithAd:(CLXAd *)ad;

@end

NS_ASSUME_NONNULL_END
