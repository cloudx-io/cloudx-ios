/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidRoute.h
 * @brief Value object describing how a bid should be rendered.
 *
 * The routing decision is derived purely from the bid — no external state,
 * no side effects. The bid response is the single source of truth.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidResponseBid;

/**
 * @brief Routing target for a single bid — embedded renderer or external adapter.
 *
 * - CLXBidRouteKindEmbeddedRenderer: CloudX's built-in WebView-based renderer
 *   handles the creative. The bid's `adm` contains the full HTML/MRAID/VAST
 *   markup.
 * - CLXBidRouteKindExternalAdapter: a third-party ad network SDK handles the
 *   creative. The bid's `adm` is typically an opaque token for that SDK.
 */
typedef NS_ENUM(NSInteger, CLXBidRouteKind) {
    CLXBidRouteKindEmbeddedRenderer,
    CLXBidRouteKindExternalAdapter,
};

/**
 * @brief Value object describing how a bid should be rendered.
 *
 * Create via +routeForBid: — the factory inspects the bid's ext fields per
 * the Rendering Engine Bid Response Format spec. Instances are immutable.
 */
@interface CLXBidRoute : NSObject

/**
 * @brief Whether the bid should be rendered by the embedded renderer or an external adapter.
 */
@property (nonatomic, assign, readonly) CLXBidRouteKind kind;

/**
 * @brief The real bidder identity (raw adaptercode) for this bid.
 *
 * Never rewritten to an internal sentinel, and never canonicalized for
 * routing — a `testbidder_native` bid keeps `testbidder_native` here so every
 * reporting surface matches the publisher-facing network derived from the bid
 * ext in CLXAd. The `_native` suffix is stripped only for the embedded-vs-
 * external routing decision and the native-factory lookup (see
 * +canonicalAdapterCodeForRouting:). Used for reporting, analytics, and
 * win/loss tracking.
 *
 * Resolved from bid.ext.cloudx.adaptercode via the canonical priority chain
 * (ext.cloudx.adaptercode > ext.prebid.meta.adaptercode > adapterExtras).
 * Falls back to "TestVastNetwork" when no adaptercode is available.
 */
@property (nonatomic, copy, readonly) NSString *bidderName;

/**
 * @brief The set of first-party adaptercodes that CLXAdapterFactoryResolver
 *        registers the embedded native renderer factory under, and that
 *        CLXBidRoute consults for the embedded-route decision.
 *
 * Contains `testbidder`, `cloudx`, and `cloudXRenderer`. This is the single
 * source of truth shared by three sites so they cannot drift:
 *   - CLXBidRoute's +routeForBid: embedded-route decision
 *   - CLXAdapterFactoryResolver's CLXCoreRendererNativeFactory registration
 *   - CLXAdapterFactoryResolver's +requiresAdapterMetadataForNetwork:
 *
 * `testbidder` routes embedded for ANY mtype (legacy QA behavior). `cloudx`
 * and `cloudXRenderer` route embedded only for native (mtype == 4) bids —
 * see +routeForBid: for the mtype-conditional rule. The `_native` aliases
 * (e.g. `cloudx_native`) canonicalize to their unsuffixed form before this
 * set is consulted (+canonicalAdapterCodeForRouting:).
 *
 * @return An immutable set of adaptercode strings. Holds the same instances
 *         across calls (dispatch_once-initialized).
 */
+ (NSSet<NSString *> *)embeddedRendererAdaptercodes;

/**
 * @brief Resolve the route for a given bid.
 *
 * Routing rules (mtype-conditional):
 *   1. ext.cloudx.render.provider == "cloudx" -> embedded renderer, for ANY
 *      mtype and any adaptercode. (Server-side embedded-renderer signal.)
 *   2. adaptercode (after +canonicalAdapterCodeForRouting: strips a trailing
 *      `_native` suffix) == "testbidder" -> embedded renderer, for ANY mtype.
 *      (Legacy QA test-bidder behavior; the embedded renderer serves these
 *      even when the bid omits ext.cloudx.render.provider.)
 *   3. adaptercode (after canonicalization) is one of `cloudx` /
 *      `cloudXRenderer` AND bid.mtype == 4 (native) -> embedded renderer.
 *      This admits native-in-banner / native-in-MREC demand on these
 *      first-party keys while keeping non-native bids on them external.
 *   4. Otherwise -> external adapter, keyed by the resolved adaptercode.
 *
 * The mtype gate on rule 3 is the CXD-3271 review fix: pre-fix, `cloudx` and
 * `cloudXRenderer` (plus their `_native` aliases) routed embedded for ALL
 * mtypes, which changed routing for fullscreen placements (interstitial /
 * rewarded / app-open) and non-native banners — a production bid with
 * adaptercode `cloudx` carrying a VAST adm and no render.provider previously
 * took the external route and failed clean as no-fill; the widening committed
 * it to the embedded HTML renderer for a fullscreen placement and rendered
 * broken/blank. Restricting the widened keys to native bids restores
 * fullscreen and non-native banner routing to exactly its pre-PR behavior
 * while preserving native-in-banner routing on those keys (the reason the
 * widening existed). The shared key set lives in
 * +embeddedRendererAdaptercodes and is consumed by CLXAdapterFactoryResolver
 * so route decision and factory registration agree by construction.
 *
 * The server owns renderer creative-type selection and emits Android-aligned
 * crtype values. Routing trusts that contract here; CLXBidAdSource's
 * createBidAd block applies a defense-in-depth crtype guard at adapter
 * creation time and falls through to the next bid for unsupported values.
 *
 * Platform divergence on missing crtype is intentional: iOS treats a missing
 * crtype on a CloudX renderer bid as the implicit HTML default and lets the
 * bid through; Android (PR 266) filters at parse time so renderer creation
 * can hard-switch on HTML vs MRAID. The server contract remains the source
 * of truth on both platforms.
 *
 * @param bid The bid to route. Must not be nil.
 * @return A CLXBidRoute whose kind and bidderName reflect the bid's ext fields.
 */
+ (instancetype)routeForBid:(CLXBidResponseBid *)bid;

/**
 * @brief Canonicalizes an adapter code for routing by stripping a trailing
 *        `_native` suffix.
 *
 * The embedded native renderer is registered under the unsuffixed network key
 * (e.g. `testbidder`), so a bid whose `ext.cloudx.adaptercode` carries the
 * `_native` suffix (e.g. `testbidder_native`) must resolve to the same route
 * and native-factory lookup key as its unsuffixed form. This is the single
 * source of truth for the `_native`-strip; route resolution and the
 * native-in-banner factory lookup both funnel through it so the suffix cannot
 * drift between the two.
 *
 * @param adapterCode The raw adapter code from the bid ext. Passes through
 *        unchanged when no `_native` suffix is present.
 * @return The canonical adapter code with any trailing `_native` suffix removed.
 */
+ (NSString *)canonicalAdapterCodeForRouting:(NSString *)adapterCode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
