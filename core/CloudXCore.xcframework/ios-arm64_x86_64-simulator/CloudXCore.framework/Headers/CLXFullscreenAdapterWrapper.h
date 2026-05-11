/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXFullscreenAdapterWrapper.h
 * @brief Per-adapter wrapper that takes the CLXAdapterInterstitialDelegate or
 *        CLXAdapterRewardedDelegate role on a 3p fullscreen adapter and emits
 *        per-adapter surfaces from a frozen CLXAdapterLifecycleContext.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterWrapper.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterRewarded.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXAdapterLifecycleContext;
@class CLXAdLifecycleTracker;
@class CLXAdapterWrapperRegistry;
@class CLXRillTrackingService;
@class CLXTelemetryWiringHelper;
@class CLXReward;
@protocol CLXFullscreenAdapterWrapperHost;

/**
 * Per-adapter wrapper for fullscreen (interstitial + rewarded) adapters.
 *
 * Why a single class for both formats: the two delegate protocols
 * (CLXAdapterInterstitialDelegate / CLXAdapterRewardedDelegate) differ only in
 * (a) the adapter parameter type and (b) reward methods unique to rewarded.
 * Every other event has identical semantics. A single class with shared
 * private helpers keeps the cross-surface emission logic DRY; the two
 * factory initializers (interstitial / rewarded) bind the format-specific
 * adapter type so callers can't accidentally pass an interstitial adapter
 * to a rewarded host (or vice-versa).
 *
 * Like the banner wrapper:
 * - Owns the immutable CLXAdapterLifecycleContext and per-adapter
 *   CLXAdLifecycleTracker captured at adapter-attach time.
 * - Emits Rill / BURL renderSuccess + click / billing impression + click count
 *   / session impression from captured state, NEVER from publisher-global
 *   mutable state.
 * - Hands off non-emission tasks to the publisher via the task-oriented
 *   CLXFullscreenAdapterWrapperHost protocol.
 *
 * Lifetime: registered with CLXAdapterWrapperRegistry at attach; released
 * on terminal events (didFailToLoad, didFailToShow, didClose, expired) or
 * when the publisher tears down its slot (destroy, dealloc, deferred
 * destroy consume). Idempotent.
 */
@interface CLXFullscreenAdapterWrapper : NSObject <CLXAdapterWrapper,
                                                    CLXAdapterInterstitialDelegate,
                                                    CLXAdapterRewardedDelegate>

/** The 3p adapter this wrapper is the delegate for. Strong reference. */
@property (nonatomic, strong, readonly) id adapter;

/**
 * Typed accessor for the underlying interstitial adapter. Returns the
 * stored adapter only when the wrapper was constructed via the
 * interstitial factory; nil for rewarded wrappers. Prefer this over
 * casting `adapter` at call sites — the typed accessor is
 * compiler-verified and self-documents the format expectation.
 */
@property (nonatomic, strong, readonly, nullable) CLXAdapterInterstitial *interstitialAdapter;

/**
 * Typed accessor for the underlying rewarded adapter. Returns the
 * stored adapter only when the wrapper was constructed via the
 * rewarded factory; nil for interstitial wrappers.
 */
@property (nonatomic, strong, readonly, nullable) CLXAdapterRewarded *rewardedAdapter;

/** YES if the wrapper was constructed via the rewarded factory. */
@property (nonatomic, assign, readonly) BOOL isRewarded;

/** The per-adapter lifecycle tracker. Lives for the wrapper's full lifetime. */
@property (nonatomic, strong, readonly) CLXAdLifecycleTracker *tracker;

#pragma mark - Factories

/**
 * Build a wrapper bound to a CLXAdapterInterstitial.
 *
 * The wrapper takes the adapter's CLXAdapterInterstitialDelegate role —
 * callers must NOT also set `adapter.delegate = self` on the publisher;
 * `adapter.delegate = wrapper` is the only correct binding.
 *
 * Construction preconditions: the tracker's `context.bidId` and
 * `context.auction.auctionId` must both be non-empty. Empty identifiers
 * indicate a bug in the upstream attach path.
 */
+ (instancetype)wrapperWithInterstitialAdapter:(CLXAdapterInterstitial *)adapter
                                         tracker:(CLXAdLifecycleTracker *)tracker
                                            host:(id<CLXFullscreenAdapterWrapperHost>)host
                                        registry:(nullable CLXAdapterWrapperRegistry *)registry
                                       accountId:(nullable NSString *)accountId
                                     rillService:(nullable CLXRillTrackingService *)rillService
                            telemetryWiringHelper:(nullable CLXTelemetryWiringHelper *)telemetryWiringHelper;

/**
 * Build a wrapper bound to a CLXAdapterRewarded. Same contract as the
 * interstitial factory; additionally handles reward callbacks.
 */
+ (instancetype)wrapperWithRewardedAdapter:(CLXAdapterRewarded *)adapter
                                     tracker:(CLXAdLifecycleTracker *)tracker
                                        host:(id<CLXFullscreenAdapterWrapperHost>)host
                                    registry:(nullable CLXAdapterWrapperRegistry *)registry
                                   accountId:(nullable NSString *)accountId
                                 rillService:(nullable CLXRillTrackingService *)rillService
                        telemetryWiringHelper:(nullable CLXTelemetryWiringHelper *)telemetryWiringHelper;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Lifetime

/**
 * Releases this wrapper from the registry. Idempotent. Invoked from
 * terminal-event delegate callbacks (didFailToLoad, didFailToShow,
 * didClose, expired) and from the publisher's slot teardown paths
 * (destroy, dealloc, deferred-destroy consume).
 */
- (void)releaseFromRegistry;

/**
 * Re-freeze the wrapper's captured `CLXAd` with the publisher-set placement
 * once the publisher has called `showAdForPlacement:`. Fullscreen formats
 * (interstitial / rewarded) only learn the publisher's placement string at
 * show time — after wrapper construction — so the captured ad built at
 * attach time would otherwise carry a nil `placement` and surface as
 * `Placement: (null)` in click / revenue / close ILRD fan-out.
 *
 * Cross-surface attribution invariant is preserved: the wrapper still
 * captures once and freezes; this method moves the freeze point for the
 * placement field specifically from attach to show. After this call,
 * `capturedAd` is immutable for the rest of the slot's lifetime and every
 * surface (click / revenue / close) emits the same publisher-set placement.
 *
 * No-op when `bidSnapshot` is absent on the lifecycle context (no ad to
 * re-freeze). Repeated calls are last-write-wins: the most recent
 * placement value overwrites any prior one. Supported usage is exactly
 * one call per show; the last-write-wins behavior is the safe shape
 * if a publisher legitimately re-shows with a different placement.
 */
- (void)freezeCapturedAdWithPublisherPlacement:(nullable NSString *)placement;

#pragma mark - Adapter proxies (parity with Android wrapper)

/** Proxy: forward `load` to the underlying adapter. */
- (void)load;

/**
 * Proxy: forward `showFromViewController:` to the underlying adapter.
 * Routes to the format-specific adapter selector so callers don't need to
 * know which adapter type they're driving.
 */
- (void)showFromViewController:(UIViewController *)viewController;

/** Proxy: forward `destroy` to the underlying adapter. */
- (void)destroy;

@end

#pragma mark - Host protocol

/**
 * Tasks the wrapper hands back to the publisher (host). Task-oriented,
 * not state-oriented — the wrapper never reads publisher state directly.
 *
 * Adapter-typed parameters are intentionally absent. Each host call is keyed
 * on the wrapper itself; the publisher does not need access to the concrete
 * adapter (the wrapper owns it). Mirrors the Android wrapper-callback shape.
 *
 * `CLXAd` parameter is constructed once by the wrapper at attach time
 * from the frozen bid snapshot and passed through every host call.
 */
@protocol CLXFullscreenAdapterWrapperHost <NSObject>

/** Adapter slot rotation: this adapter finished loading. */
- (void)fullscreenWrapperDidLoad:(CLXFullscreenAdapterWrapper *)wrapper;

/** Adapter slot rotation: load failed. Wrapper has self-released. */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper didFailToLoadWithError:(nullable NSError *)error;

/**
 * Adapter signaled "shown". Host emits `didDisplayAd:` to publisher delegate.
 *
 * `ad` is nullable: lifecycle signals must always fire regardless of bid
 * snapshot population. When `ad` is nil, the host receives the slot
 * transition and may build its own CLXAd from publisher state.
 */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper didShowWithAd:(nullable CLXAd *)ad;

/** Adapter failed to show. Wrapper has self-released. */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper didFailToShowWithError:(nullable NSError *)error;

/**
 * Adapter closed (user dismissed). Wrapper has self-released.
 *
 * `ad` is nullable for the same reason as `didShowWithAd:` — dismissal
 * must always notify the host so its slot state machine can unlock the
 * next load.
 */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper didCloseWithAd:(nullable CLXAd *)ad;

/** Adapter expired (load-success then time-to-show window passed). Wrapper has self-released. */
- (void)fullscreenWrapperDidExpire:(CLXFullscreenAdapterWrapper *)wrapper;

/**
 * Deliver a click event to the user-facing publisher delegate. Wrapper has
 * already emitted Rill / BURL / click count.
 */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper deliverClickWithAd:(CLXAd *)ad;

/**
 * Deliver a revenue ILRD callback to the revenue delegate. Wrapper has
 * already emitted Rill / BURL / impression / session.
 */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper deliverRevenueWithAd:(CLXAd *)ad;

@optional

/**
 * Rewarded-only: deliver a user-earned-reward callback to the
 * publisher's rewarded delegate. Wrapper passes the amount/label as
 * received from the 3p adapter; the host applies any ad-unit-default
 * merge before forwarding to the publisher delegate.
 */
- (void)fullscreenWrapper:(CLXFullscreenAdapterWrapper *)wrapper
       deliverRewardWithAd:(CLXAd *)ad
                    amount:(NSInteger)amount
                     label:(nullable NSString *)label;

@end

NS_ASSUME_NONNULL_END
