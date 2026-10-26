/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdQualityRequest.h
 * @brief Immutable carrier describing a loaded ad for ad-quality evaluation.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Block installed by core on every ad-quality request. The gate invokes it to
 * revoke (dismiss) an already-surfaced ad after the verdict — e.g. when a block
 * verdict arrives after a fail-open timeout, or when a post-impression signal
 * invalidates the ad.
 *
 * Idempotent: subsequent calls (and any call after teardown / slot rotation) are
 * a safe no-op. Safe to call from any thread; the dismissal itself is hopped to
 * the main queue by core.
 *
 * @param reason Free-form reason for the revocation, or nil. Copied.
 */
typedef void (^CLXAdQualityRevokeHandler)(NSString * _Nullable reason);

@class CLXAdQualityVerdict;

/**
 * Immutable, vendor-neutral description of a loaded ad, handed to the
 * ad-quality gate for inspection before the publisher is told the ad loaded.
 *
 * Every identifier on this request is sourced from the wrapper's frozen
 * @c CLXAdapterLifecycleContext (captured at adapter-attach time) — never from
 * publisher-mutable state — so a late gate callback attributes to the original
 * auction even after the publisher has rotated to a new one. The @c adUnitId is
 * stable per ad instance (set at creation, not rotated per auction) and is the
 * one field not on the frozen context.
 *
 * The @c adObject is the most concrete loaded ad object reachable at the
 * load-success seam: for banner / MREC the publisher-facing container view
 * that hosts the rendered ad (the inner adapter-loaded view is not reliably
 * reachable at this seam); for fullscreen the adapter instance; for native the
 * native ad object. A gate that needs the partner SDK's own ad object finds it
 * from @c adapter.
 */
CLX_PUBLIC
@interface CLXAdQualityRequest : NSObject

/** The most concrete loaded ad object available at the load-success seam. */
@property (nonatomic, strong, readonly) NSObject *adObject;

/** The CloudX adapter instance that produced the ad (e.g. a CLXAdapterAdView subclass). */
@property (nonatomic, strong, readonly) NSObject *adapter;

/** The ad format captured at adapter-attach time. */
@property (nonatomic, assign, readonly) CLXAdType adFormat;

/** The publisher's ad unit id (stable per ad instance). nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitId;

/** The ad-unit name captured on the frozen context. nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/** The publisher placement captured on the frozen context. nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *placement;

/**
 * The ad network's own identifier for the inventory this bid filled — the id the
 * network keys its placement / ad unit by, resolved from the bid. Distinct from
 * @c placement (the publisher's own label) and from @c adUnitId (CloudX's id):
 * an ad-quality engine reporting per-network inventory needs this one. nil when
 * the bid carried no network identifier.
 */
@property (nonatomic, copy, readonly, nullable) NSString *networkPlacement;

/** The ad network code resolved at attach time (e.g. "meta", "vungle"). nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *adNetwork;

/** The bid identifier captured at attach time. nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *bidId;

/** The SSP-issued bid-response auction id captured at attach time. nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *auctionId;

/** The bid price captured at attach time. 0.0 when unavailable. */
@property (nonatomic, assign, readonly) double price;

/** The bid's creative id (OpenRTB @c crid). nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *creativeId;

/** The bid's network creative id (OpenRTB @c cid). nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSString *networkCreativeId;

/** The bid's raw JSON payload (OpenRTB @c rawJSON). nil when unavailable. */
@property (nonatomic, copy, readonly, nullable) NSDictionary *bidPayload;

/**
 * Capability handle installed by core. Calling it revokes / dismisses the ad.
 * Idempotent and a safe no-op after teardown / rotation. See the
 * @c CLXAdQualityRevokeHandler typedef.
 */
@property (nonatomic, copy, readonly) CLXAdQualityRevokeHandler revokeHandler;

/**
 * Designated initializer. All identifiers are captured (copied) at construction;
 * the request is never mutated. Pass nil for any identifier unavailable at the
 * call site.
 *
 * @param adObject          The most concrete loaded ad object. Must be non-nil.
 * @param adapter           The CloudX adapter instance. Must be non-nil.
 * @param adFormat          The ad format captured at attach time.
 * @param adUnitId          The publisher's ad unit id, or nil.
 * @param adUnitName        The ad-unit name from the frozen context, or nil.
 * @param placement         The publisher placement from the frozen context, or nil.
 * @param networkPlacement  The ad network's own placement / unit id from the bid, or nil.
 * @param adNetwork         The ad network code from the frozen context, or nil.
 * @param bidId             The bid id from the frozen context, or nil.
 * @param auctionId         The SSP bid-response auction id from the frozen context, or nil.
 * @param price             The bid price from the frozen context.
 * @param creativeId        The bid @c crid, or nil.
 * @param networkCreativeId The bid @c cid, or nil.
 * @param bidPayload        The bid @c rawJSON, or nil.
 * @param revokeHandler     The revocation handle installed by core. Must be non-nil.
 */
- (instancetype)initWithAdObject:(NSObject *)adObject
                          adapter:(NSObject *)adapter
                         adFormat:(CLXAdType)adFormat
                         adUnitId:(nullable NSString *)adUnitId
                       adUnitName:(nullable NSString *)adUnitName
                        placement:(nullable NSString *)placement
                 networkPlacement:(nullable NSString *)networkPlacement
                        adNetwork:(nullable NSString *)adNetwork
                            bidId:(nullable NSString *)bidId
                        auctionId:(nullable NSString *)auctionId
                            price:(double)price
                       creativeId:(nullable NSString *)creativeId
                  networkCreativeId:(nullable NSString *)networkCreativeId
                      bidPayload:(nullable NSDictionary *)bidPayload
                    revokeHandler:(CLXAdQualityRevokeHandler)revokeHandler NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
