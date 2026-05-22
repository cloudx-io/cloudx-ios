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
 * @brief The real bidder identity (canonical adaptercode) for this bid.
 *
 * Never rewritten to an internal sentinel. Used for factory lookup, reporting,
 * analytics, and win/loss tracking.
 *
 * Resolved from bid.ext.cloudx.adaptercode via the canonical priority chain
 * (ext.cloudx.adaptercode > ext.prebid.meta.adaptercode > adapterExtras).
 * Falls back to "TestVastNetwork" when no adaptercode is available.
 */
@property (nonatomic, copy, readonly) NSString *bidderName;

/**
 * @brief Resolve the route for a given bid.
 *
 * Routing rules:
 *   1. bid.ext.cloudx.render.provider == "cloudx" -> embedded renderer.
 *   2. Otherwise -> external adapter, keyed by the resolved adaptercode.
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

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
