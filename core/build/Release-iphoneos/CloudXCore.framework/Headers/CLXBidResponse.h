/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BidResponse.h
 * @brief Bid response models for auction responses
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

// MARK: - CloudX Extension
@interface CLXBidResponseCloudX : NSObject
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *adapterExtras;
@end

// MARK: - Prebid Extension
@interface CLXBidResponsePrebid : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseCloudXMeta *meta;
@end

// MARK: - Bid Extension
@interface CLXBidResponseExt : NSObject
@property (nonatomic, strong, nullable) CLXBidResponseSKAd *skadn;
@property (nonatomic, assign) double origbidcpm;
@property (nonatomic, copy, nullable) NSString *origbidcur;
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
@property (nonatomic, assign) int64_t abTestId;
@property (nonatomic, copy, nullable) NSString *abTestGroup;
@property (nonatomic, copy, nullable) NSString *nurl;
@property (nonatomic, copy, nullable) NSString *lurl;
@property (nonatomic, copy, nullable) NSString *iurl;
@property (nonatomic, strong, nullable) NSArray<NSString *> *cat;
@property (nonatomic, copy, nullable) NSString *cid;
@property (nonatomic, copy, nullable) NSString *crid;
@property (nonatomic, copy, nullable) NSString *dealid;
@property (nonatomic, assign) NSInteger w;
@property (nonatomic, assign) NSInteger h;
@end

// MARK: - Seat Bid
@interface CLXBidResponseSeatBid : NSObject
@property (nonatomic, strong) NSArray<CLXBidResponseBid *> *bid;
@property (nonatomic, copy, nullable) NSString *seat;
@end

// MARK: - Response Extension
@interface CLXBidResponseResponseExt : NSObject
// Add any response-level extension fields here
@end

// MARK: - Main Bid Response
@interface CLXBidResponse : NSObject
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *bidid;
@property (nonatomic, strong) NSArray<CLXBidResponseSeatBid *> *seatbid;
@property (nonatomic, copy, nullable) NSString *cur;
@property (nonatomic, strong, nullable) CLXBidResponseResponseExt *ext;

// Helper methods to get bids
- (NSArray<CLXBidResponseBid *> *)allBids;
- (nullable CLXBidResponseBid *)findBidWithID:(NSString *)bidID;

// Helper method to get all bids sorted by rank for waterfall loading (true Android parity)
- (NSArray<CLXBidResponseBid *> *)getAllBidsForWaterfall;

+ (nullable instancetype)parseBidResponseFromDictionary:(NSDictionary *)dictionary;

// Parsing helper methods
+ (nullable CLXBidResponseSeatBid *)parseSeatBidFromDictionary:(NSDictionary *)dictionary;
+ (nullable CLXBidResponseBid *)parseBidFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END 
