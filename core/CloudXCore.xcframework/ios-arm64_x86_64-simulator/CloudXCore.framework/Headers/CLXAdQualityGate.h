/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdQualityGate.h
 * @brief Vendor-neutral extension point for inspecting and vetoing loaded ads.
 */

#import <Foundation/Foundation.h>

@class CLXAdQualityRequest;
@class CLXAdQualityVerdict;

NS_ASSUME_NONNULL_BEGIN

/**
 * Vendor-neutral ad-quality gate. A single participant that inspects every
 * loaded ad before the publisher is told it loaded, and may veto ("block") it.
 *
 * Register one gate process-wide with @c +[CloudXCore setAdQualityGate:].
 * Only one gate is consulted per ad; it is not a delegate list. When no gate is
 * registered, ad loading is a zero-overhead passthrough (no allocation, no
 * dispatch).
 *
 * @note Threading contract: @c evaluateAd:completion: may be invoked on any
 * thread. The @c completion handler may be called on any thread; core hops it
 * to the main queue before acting on the verdict. Implementations must be
 * thread-safe and must always invoke @c completion exactly once per call —
 * core enforces at-most-once delivery regardless, but a gate that never
 * answers triggers a fail-open timeout (see @c evaluationTimeout).
 */
@protocol CLXAdQualityGate <NSObject>

/**
 * Inspect the loaded ad and return a verdict.
 *
 * The ad is held back from the publisher until the verdict arrives. Core
 * enforces a timeout (default 3.0s, overridable via @c evaluationTimeout); if
 * the completion is not invoked within the timeout, core fails open (forwards
 * the ad as loaded) and any later block verdict is routed through the
 * revocation path instead.
 *
 * @param request    Immutable, vendor-neutral description of the loaded ad.
 * @param completion  Invoke exactly once with the verdict. May be called on any
 *                    thread. Retained until the verdict is delivered.
 */
- (void)evaluateAd:(CLXAdQualityRequest *)request
         completion:(void (^)(CLXAdQualityVerdict *verdict))completion
    NS_SWIFT_NAME(evaluateAd(_:completion:));

@optional

/**
 * The maximum wall-clock interval core will wait for @c evaluateAd:completion:
 * before failing open. Default 3.0 seconds when unimplemented or non-positive.
 * Exposed as a test seam — inject a short value to keep fail-open deterministic.
 */
- (NSTimeInterval)evaluationTimeout;

/**
 * The ad was displayed to the user. References the same request instance
 * created at load time. Optional; no-op if unimplemented.
 */
- (void)adDidDisplay:(CLXAdQualityRequest *)request NS_SWIFT_NAME(adDidDisplay(_:));

/**
 * The user clicked the ad. References the same request instance created at
 * load time. Optional; no-op if unimplemented.
 */
- (void)adDidClick:(CLXAdQualityRequest *)request NS_SWIFT_NAME(adDidClick(_:));

/**
 * The ad is about to close. References the same request instance created at
 * load time. Optional; no-op if unimplemented.
 */
- (void)adWillClose:(CLXAdQualityRequest *)request NS_SWIFT_NAME(adWillClose(_:));

/**
 * The ad was destroyed (teardown / refresh / slot rotation). References the
 * same request instance created at load time. Core delivers this at most once
 * per request even if multiple internal teardown paths report the same one.
 * Optional; no-op if unimplemented.
 */
- (void)adDidDestroy:(CLXAdQualityRequest *)request NS_SWIFT_NAME(adDidDestroy(_:));

@end

NS_ASSUME_NONNULL_END
