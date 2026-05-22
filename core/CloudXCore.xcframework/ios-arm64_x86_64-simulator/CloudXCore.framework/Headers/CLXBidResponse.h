/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BidResponse.h
 * @brief Bid response models for auction responses
 */

#import <Foundation/Foundation.h>

@class CLXBidResponseCloudXRender;

NS_ASSUME_NONNULL_BEGIN

/**
 * OpenRTB bid markup media type values carried in `seatbid[].bid[].mtype`.
 */
typedef NS_ENUM(NSInteger, CLXOpenRTBMarkupType) {
    /** Banner display markup. */
    CLXOpenRTBMarkupTypeBanner = 1,
    /** Video markup. */
    CLXOpenRTBMarkupTypeVideo = 2,
    /** Audio markup. */
    CLXOpenRTBMarkupTypeAudio = 3,
    /** Native markup. */
    CLXOpenRTBMarkupTypeNative = 4,
};

// MARK: - SKAdNetwork Fidelity
@interface CLXBidResponseSKAdFidelity : NSObject
@property (nonatomic, assign) NSInteger fidelity;
@property (nonatomic, copy, nullable) NSString *nonce;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, copy) NSString *timestamp;
@end

// MARK: - SKAdNetwork
@interface CLXBidResponseSKAd : NSObject
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *network;
@property (nonatomic, copy, nullable) NSString *sourceidentifier;
@property (nonatomic, copy, nullable) NSString *campaign;
@property (nonatomic, copy) NSString *itunesitem;
@property (nonatomic, copy, nullable) NSString *productpageid;
@property (nonatomic, strong) NSArray<CLXBidResponseSKAdFidelity *> *fidelities;
@property (nonatomic, copy, nullable) NSString *nonce;
@property (nonatomic, copy) NSString *sourceapp;
@property (nonatomic, copy, nullable) NSString *timestamp;
@property (nonatomic, copy, nullable) NSString *signature;
@end

// MARK: - CloudX Meta
@interface CLXBidResponseCloudXMeta : NSObject
@property (nonatomic, copy) NSString *adaptercode;
@end

// MARK: - CloudX Participants Extension
@interface CLXBidResponseCloudXParticipants : NSObject
@property (nonatomic, assign) NSInteger round;
@property (nonatomic, copy) NSString *bidder;
@property (nonatomic, copy) NSString *lineItemId;
@property (nonatomic, assign) NSInteger bidFloor;
@property (nonatomic, copy) NSString *bid;
@property (nonatomic, assign) NSInteger responseTimeMillis;
@property (nonatomic, assign) NSInteger rank;

- (NSDictionary *)toDictionary;
@end

// MARK: - CloudX Auction Extension
@interface CLXBidResponseCloudXAuction : NSObject
@property (nonatomic, strong, nullable) NSArray<CLXBidResponseCloudXParticipants *> *participants;

- (NSArray<NSDictionary *> *)toDictionary;
@end

// MARK: - CloudX Extension
@interface CLXBidResponseCloudX : NSObject
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, assign) double revenue;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *adapterExtras;
@property (nonatomic, assign) NSInteger test;
@property (nonatomic, copy, nullable) NSString *adaptercode;
@property (nonatomic, copy, nullable) NSString *auctionTelemetryPayload;
@property (nonatomic, copy, nullable) NSString *bidTelemetryPayload;
@property (nonatomic, copy, nullable) NSString *arbiterAuctionPayload;
@property (nonatomic, copy, nullable) NSString *arbiterBidPayload;
@property (nonatomic, strong, nullable) CLXBidResponseCloudXRender *render;

- (NSDictionary *)toDictionary;
@end

// MARK: - Prebid Extension
@interface CLXBidResponsePrebid : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseCloudXMeta *meta;
@property (nonatomic, copy, nullable) NSString *type;
@end

// MARK: - Bid Extension
@interface CLXBidResponseExt : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseSKAd *skadn;
@property (nonatomic, assign) double origbidcpm;
@property (nonatomic, copy, nullable) NSString *origbidcur;
/// Creative type hint from the DSP. The embedded renderer recognizes "html"
/// as a single canonical value covering both plain-HTML and MRAID-using
/// creatives — the MRAID JavaScript runtime is injected for every renderer-
/// routed banner unconditionally, so the renderer never needs a per-bid hint
/// to wire the bridge. Other declared values ("vast", "video", "native",
/// historical "mraid", etc.) are rejected at routing time by the I2 guard in
/// CLXBidAdSource. Missing crtype is allowed and treated as the implicit
/// "html" default. Surfaced as an opaque string for telemetry; this DTO
/// does not interpret it.
@property (nonatomic, copy, nullable) NSString *crtype;
@property (nonatomic, strong, nullable) CLXBidResponseCloudX *cloudx;
@property (nonatomic, strong, nullable) CLXBidResponsePrebid *prebid;
@end

// MARK: - Individual Bid
@interface CLXBidResponseBid : NSObject
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *adm;
@property (nonatomic, copy, nullable) NSString *adid;
@property (nonatomic, copy, nullable) NSString *impid;
@property (nonatomic, copy, nullable) NSString *bundle;
@property (nonatomic, copy, nullable) NSString *burl;
@property (nonatomic, strong, nullable) CLXBidResponseExt *ext;
@property (nonatomic, strong, nullable) NSArray<NSString *> *adomain;
@property (nonatomic, assign) double price;
@property (nonatomic, copy, nullable) NSString *nurl;
@property (nonatomic, copy, nullable) NSString *lurl;
@property (nonatomic, copy, nullable) NSString *iurl;
@property (nonatomic, strong, nullable) NSArray<NSString *> *cat;
@property (nonatomic, copy, nullable) NSString *cid;
@property (nonatomic, copy, nullable) NSString *crid;
@property (nonatomic, copy, nullable) NSString *dealid;
@property (nonatomic, assign) NSInteger w;
@property (nonatomic, assign) NSInteger h;
/// OpenRTB media type for this bid. See `CLXOpenRTBMarkupType`.
@property (nonatomic, strong, nullable) NSNumber *mtype;
@property (nonatomic, copy, nullable) NSDictionary *rawJSON;
@end

// MARK: - Seat Bid
@interface CLXBidResponseSeatBid : NSObject
@property (nonatomic, strong) NSArray<CLXBidResponseBid *> *bid;
@property (nonatomic, copy, nullable) NSString *seat;
@end

// MARK: - CloudX Extension
@interface CLXBidResponseAuction : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseCloudXAuction *auction;
@property (nonatomic, copy, nullable) NSString *serverVersion;
@property (nonatomic, copy, nullable) NSString *arbiterAuctionPayload;

- (NSDictionary *)toDictionary;
@end

// MARK: - Non-Bid (per impression within a seat)
@interface CLXBidResponseNonBid : NSObject
@property (nonatomic, copy, nullable) NSString *impId;
@property (nonatomic, assign) NSInteger statusCode;
@end

// MARK: - Seat Non-Bid (per bidder seat)
@interface CLXBidResponseSeatNonBid : NSObject
@property (nonatomic, copy, nullable) NSString *seat;
@property (nonatomic, strong) NSArray<CLXBidResponseNonBid *> *nonBid;
@end

// MARK: - Prebid Response Extension
@interface CLXBidResponsePrebidResponseExt : NSObject
@property (nonatomic, strong, nullable) NSArray<CLXBidResponseSeatNonBid *> *seatNonBid;
@end

// MARK: - Response Extension
@interface CLXBidResponseResponseExt : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseAuction *cloudx;
@property (nonatomic, strong, nullable) CLXBidResponsePrebidResponseExt *prebid;
@end

// MARK: - Main Bid Response
@interface CLXBidResponse : NSObject
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *bidid;
@property (nonatomic, strong) NSArray<CLXBidResponseSeatBid *> *seatbid;
@property (nonatomic, copy, nullable) NSString *cur;
@property (nonatomic, strong, nullable) CLXBidResponseResponseExt *ext;
@property (nonatomic, strong, nullable) NSNumber *nbr;

// Helper methods to get bids
- (NSArray<CLXBidResponseBid *> *)allBids;
- (nullable CLXBidResponseBid *)findBidWithID:(NSString *)bidID;

// Helper method to get all bids sorted by rank for waterfall loading (true Android parity)
- (NSArray<CLXBidResponseBid *> *)getAllBidsForWaterfall;

+ (nullable instancetype)parseBidResponseFromDictionary:(NSDictionary *)dictionary;

// Parsing helper methods
+ (nullable CLXBidResponseSeatBid *)parseSeatBidFromDictionary:(NSDictionary *)dictionary;
+ (nullable CLXBidResponseBid *)parseBidFromDictionary:(NSDictionary *)dictionary;

// Marshaling methods for tracking field resolution
- (NSDictionary *)marshalToJSONDictionary;
+ (NSDictionary *)marshalBidToJSONDictionary:(CLXBidResponseBid *)bid;

/// Resolves the adapter code from a bid ext using the canonical priority chain:
/// ext.cloudx.adaptercode > ext.prebid.meta.adaptercode > adapterExtras bidder/adapter.
/// Returns nil if no adapter code is available from any source.
+ (nullable NSString *)resolveAdapterCodeFromExt:(nullable CLXBidResponseExt *)ext;

/// Builds a human-readable summary of non-bid reasons from the response.
/// Includes top-level NBR and per-seat non-bid details when available.
/// Returns nil if no non-bid information is present.
+ (nullable NSString *)nonBidSummaryFromResponse:(nullable CLXBidResponse *)response;

/// Returns a human-readable label for a non-bid reason status code.
+ (NSString *)labelForNonBidReasonCode:(NSInteger)code;

@end

NS_ASSUME_NONNULL_END
