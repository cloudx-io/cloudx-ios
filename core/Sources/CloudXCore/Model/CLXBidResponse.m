/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BidResponse.m
 * @brief Implementation of bid response models for auction responses
 */

#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXLogger.h>

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"BidResponse.m"];
}

// MARK: - SKAdNetwork Fidelity Implementation
@implementation CLXBidResponseSKAdFidelity
@end

// MARK: - SKAdNetwork Implementation
@implementation CLXBidResponseSKAd
@end

// MARK: - CloudX Meta Implementation
@implementation CLXBidResponseCloudXMeta
@end

// MARK: - CloudX Auction Implementation
@implementation CLXBidResponseAuction
- (NSDictionary *)toDictionary {
    NSArray<NSDictionary *> *participants = [self.auction toDictionary] ?: @[];
    NSString *serverVersion = self.serverVersion ?: @"";
    NSDictionary *auction = @{
        @"participants": participants
        };

        NSDictionary *cloudx = @{
            @"auction": auction,
            @"serverVersion": serverVersion
        };

        NSDictionary *root = @{
            @"cloudx": cloudx
        };

        return root;
}

@end


// MARK: - CloudX Extension Implementation
@implementation CLXBidResponseCloudX
@end

@implementation CLXBidResponseCloudXAuction

- (NSArray<NSDictionary *> *)toDictionary {
    if (!self.participants.count) return @[];

        NSMutableArray *dictArray = [NSMutableArray array];
        for (CLXBidResponseCloudXParticipants *participant in self.participants) {
            if ([participant respondsToSelector:@selector(toDictionary)]) {
                id dict = [participant toDictionary];
                if (dict) {
                    [dictArray addObject:dict];
                }
            }
        }
        return [dictArray copy];
}

@end

@implementation CLXBidResponseCloudXParticipants
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        dict[@"round"] = @(self.round);
        if (self.bidder) dict[@"bidder"] = self.bidder;
        if (self.lineItemId) dict[@"lineItemId"] = self.lineItemId;
        dict[@"bidFloor"] = @(self.bidFloor);
        dict[@"bid"] = self.bid;
        dict[@"responseTimeMillis"] = @(self.responseTimeMillis);
        dict[@"rank"] = @(self.rank);
        
        return dict;
}
@end

// MARK: - Prebid Extension Implementation
@implementation CLXBidResponsePrebid
@end

// MARK: - Bid Extension Implementation
@implementation CLXBidResponseExt
@end

// MARK: - Individual Bid Implementation
@implementation CLXBidResponseBid
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.id) dict[@"id"] = self.id;
    if (self.adm) dict[@"adm"] = self.adm;
    if (self.adid) dict[@"adid"] = self.adid;
    if (self.impid) dict[@"impid"] = self.impid;
    if (self.bundle) dict[@"bundle"] = self.bundle;
    if (self.burl) dict[@"burl"] = self.burl;
    if (self.adomain) dict[@"adomain"] = self.adomain;
    if (self.cat) dict[@"cat"] = self.cat;
    if (self.cid) dict[@"cid"] = self.cid;
    if (self.crid) dict[@"crid"] = self.crid;
    if (self.dealid) dict[@"dealid"] = self.dealid;
    if (self.abTestGroup) dict[@"abTestGroup"] = self.abTestGroup;
    if (self.nurl) dict[@"nurl"] = self.nurl;
    if (self.lurl) dict[@"lurl"] = self.lurl;
    if (self.iurl) dict[@"iurl"] = self.iurl;
    
    dict[@"price"] = @(self.price);
    dict[@"abTestId"] = @(self.abTestId);
    dict[@"w"] = @(self.w);
    dict[@"h"] = @(self.h);
    
    if (self.ext) {
        NSMutableDictionary *extDict = [NSMutableDictionary dictionary];
        // Basic values
        extDict[@"origbidcpm"] = @(self.ext.origbidcpm);
        if (self.ext.origbidcur) extDict[@"origbidcur"] = self.ext.origbidcur;
        
        // SKAdNetwork data
        if (self.ext.skadn) {
            NSMutableDictionary *skadDict = [NSMutableDictionary dictionary];
            skadDict[@"version"] = self.ext.skadn.version;
            skadDict[@"network"] = self.ext.skadn.network;
            if (self.ext.skadn.sourceidentifier) skadDict[@"sourceidentifier"] = self.ext.skadn.sourceidentifier;
            if (self.ext.skadn.campaign) skadDict[@"campaign"] = self.ext.skadn.campaign;
            skadDict[@"itunesitem"] = self.ext.skadn.itunesitem;
            if (self.ext.skadn.productpageid) skadDict[@"productpageid"] = self.ext.skadn.productpageid;
            if (self.ext.skadn.fidelities) {
                NSMutableArray *fidArray = [NSMutableArray array];
                for (CLXBidResponseSKAdFidelity *fidelity in self.ext.skadn.fidelities) {
                    if ([fidelity respondsToSelector:@selector(toDictionary)]) {
                        [fidArray addObject:[fidelity performSelector:@selector(toDictionary)]];
                    }
                }
                skadDict[@"fidelities"] = fidArray;
            }
            if (self.ext.skadn.nonce) skadDict[@"nonce"] = self.ext.skadn.nonce;
            skadDict[@"sourceapp"] = self.ext.skadn.sourceapp;
            if (self.ext.skadn.timestamp) skadDict[@"timestamp"] = self.ext.skadn.timestamp;
            if (self.ext.skadn.signature) skadDict[@"signature"] = self.ext.skadn.signature;
            extDict[@"skadn"] = skadDict;
        }
        
        // CloudX data
        if (self.ext.cloudx) {
            NSMutableDictionary *cloudDict = [NSMutableDictionary dictionary];
            cloudDict[@"rank"] = @(self.ext.cloudx.rank);
            cloudDict[@"test"] = @(self.ext.cloudx.test);
            if (self.ext.cloudx.adapterExtras) cloudDict[@"adapterExtras"] = self.ext.cloudx.adapterExtras;
            extDict[@"cloudx"] = cloudDict;
        }
        
        // Prebid data
        if (self.ext.prebid) {
            NSMutableDictionary *prebidDict = [NSMutableDictionary dictionary];
            
            // Add "type" if it exists
            if (self.ext.prebid.type) {
                prebidDict[@"type"] = self.ext.prebid.type;
            }
            
            // Add "meta" if it exists
            if (self.ext.prebid.meta) {
                NSMutableDictionary *metaDict = [NSMutableDictionary dictionary];
                if (self.ext.prebid.meta.adaptercode) {
                    metaDict[@"adaptercode"] = self.ext.prebid.meta.adaptercode;
                }
                prebidDict[@"meta"] = metaDict;
            }
            extDict[@"prebid"] = prebidDict;
        }
        dict[@"ext"] = extDict;
    }

    return dict;
}

- (NSString *)toJSON {
    NSDictionary *dict = [self toDictionary];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        NSLog(@"JSON Serialization error: %@", error);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
@end

// MARK: - Seat Bid Implementation
@implementation CLXBidResponseSeatBid
@end

// MARK: - Response Extension Implementation
@implementation CLXBidResponseResponseExt
@end

// MARK: - Main Bid Response Implementation
@implementation CLXBidResponse

- (NSArray<CLXBidResponseBid *> *)allBids {
    NSMutableArray<CLXBidResponseBid *> *allBids = [NSMutableArray array];
    for (CLXBidResponseSeatBid *seatBid in self.seatbid) {
        [allBids addObjectsFromArray:seatBid.bid];
    }
    return [allBids copy];
}

- (nullable CLXBidResponseBid *)findBidWithID:(NSString *)bidID {
    if (!bidID) {
        return nil;
    }
    
    NSArray<CLXBidResponseBid *> *allBids = [self allBids];
    for (CLXBidResponseBid *bid in allBids) {
        if ([bid.id isEqualToString:bidID]) {
            return bid;
        }
    }
    
    return nil;
}

- (NSArray<CLXBidResponseBid *> *)getAllBidsForWaterfall {
    NSArray<CLXBidResponseBid *> *allBids = [self allBids];
    
    // Sort bids by rank (ascending) for waterfall loading
    NSArray<CLXBidResponseBid *> *sortedBids = [allBids sortedArrayUsingComparator:^NSComparisonResult(CLXBidResponseBid *bid1, CLXBidResponseBid *bid2) {
        NSInteger rank1 = bid1.ext.cloudx.rank;
        NSInteger rank2 = bid2.ext.cloudx.rank;
        
        if (rank1 < rank2) {
            return NSOrderedAscending;
        } else if (rank1 > rank2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    return sortedBids;
}

#pragma mark - Marshaling Methods

- (NSDictionary *)marshalToJSONDictionary {
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    
    // Basic response fields
    if (self.id) {
        responseDict[@"id"] = self.id;
    }
    
    // Marshal seatbid array
    if (self.seatbid && self.seatbid.count > 0) {
        NSMutableArray *seatbidArray = [NSMutableArray array];
        
        for (CLXBidResponseSeatBid *seatbid in self.seatbid) {
            NSMutableDictionary *seatDict = [NSMutableDictionary dictionary];
            seatDict[@"seat"] = seatbid.seat ?: @"";
            
            if (seatbid.bid && seatbid.bid.count > 0) {
                NSMutableArray *bidArray = [NSMutableArray array];
                for (CLXBidResponseBid *bid in seatbid.bid) {
                    [bidArray addObject:[CLXBidResponse marshalBidToJSONDictionary:bid]];
                }
                seatDict[@"bid"] = bidArray;
            }
            
            [seatbidArray addObject:seatDict];
        }
        
        responseDict[@"seatbid"] = seatbidArray;
    }
    
    return [responseDict copy];
}

+ (NSDictionary *)marshalBidToJSONDictionary:(CLXBidResponseBid *)bid {
    if (!bid) {
        return @{};
    }
    
    NSMutableDictionary *bidDict = [NSMutableDictionary dictionary];
    
    // Core bid fields
    [self addStringFieldToDict:bidDict key:@"id" value:bid.id];
    [self addNumericFieldToDict:bidDict key:@"price" value:@(bid.price)];
    [self addStringFieldToDict:bidDict key:@"crid" value:bid.crid];
    [self addStringFieldToDict:bidDict key:@"dealid" value:bid.dealid];
    [self addNumericFieldToDict:bidDict key:@"w" value:@(bid.w)];
    [self addNumericFieldToDict:bidDict key:@"h" value:@(bid.h)];
    [self addStringFieldToDict:bidDict key:@"adm" value:bid.adm];
    [self addStringFieldToDict:bidDict key:@"nurl" value:bid.nurl];
    [self addStringFieldToDict:bidDict key:@"lurl" value:bid.lurl];
    
    // Marshal extension data
    if (bid.ext) {
        bidDict[@"ext"] = [self marshalBidExtToJSONDictionary:bid.ext];
    }
    
    return [bidDict copy];
}

+ (NSDictionary *)marshalBidExtToJSONDictionary:(CLXBidResponseExt *)ext {
    if (!ext) {
        return @{};
    }
    
    NSMutableDictionary *extDict = [NSMutableDictionary dictionary];
    
    // Original bid pricing
    [self addNumericFieldToDict:extDict key:@"origbidcpm" value:@(ext.origbidcpm)];
    [self addStringFieldToDict:extDict key:@"origbidcur" value:ext.origbidcur];
    
    // Prebid extensions
    if (ext.prebid && ext.prebid.meta) {
        NSMutableDictionary *prebidDict = [NSMutableDictionary dictionary];
        NSMutableDictionary *metaDict = [NSMutableDictionary dictionary];
        [self addStringFieldToDict:metaDict key:@"adaptercode" value:ext.prebid.meta.adaptercode];
        prebidDict[@"meta"] = metaDict;
        extDict[@"prebid"] = prebidDict;
    }
    
    // CloudX extensions
    if (ext.cloudx) {
        NSMutableDictionary *cloudxDict = [NSMutableDictionary dictionary];
        [self addNumericFieldToDict:cloudxDict key:@"rank" value:@(ext.cloudx.rank)];
        if (ext.cloudx.adapterExtras) {
            cloudxDict[@"adapterExtras"] = ext.cloudx.adapterExtras;
        }
        extDict[@"cloudx"] = cloudxDict;
    }
    
    return [extDict copy];
}

#pragma mark - Marshaling Utilities

+ (void)addStringFieldToDict:(NSMutableDictionary *)dict key:(NSString *)key value:(nullable NSString *)value {
    if (value && value.length > 0) {
        dict[key] = value;
    }
}

+ (void)addNumericFieldToDict:(NSMutableDictionary *)dict key:(NSString *)key value:(NSNumber *)value {
    if (value) {
        dict[key] = value;
    }
}


+ (CLXBidResponseCloudXParticipants *)parseExtParticipantsFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponseCloudXParticipants *participant = [[CLXBidResponseCloudXParticipants alloc] init];
    
    // Parse basic fields
    id roundValue = dictionary[@"round"];
    participant.round = (roundValue && ![roundValue isKindOfClass:[NSNull class]]) ? [roundValue integerValue] : 0;
    participant.bidder = dictionary[@"bidder"];
    participant.lineItemId = dictionary[@"lineItemId"];
    participant.bid = dictionary[@"bid"];
    id bidFloorValue = dictionary[@"bidFloor"];
    participant.bidFloor = (bidFloorValue && ![bidFloorValue isKindOfClass:[NSNull class]]) ? [bidFloorValue integerValue] : 0;
    id responseTimeMillisValue = dictionary[@"responseTimeMillis"];
    participant.responseTimeMillis = (responseTimeMillisValue && ![responseTimeMillisValue isKindOfClass:[NSNull class]]) ? [responseTimeMillisValue integerValue] : 0;
    id rankValue = dictionary[@"rank"];
    participant.rank = (rankValue && ![rankValue isKindOfClass:[NSNull class]]) ? [rankValue integerValue] : 0;
    
    return participant;
}

+ (CLXBidResponseCloudXAuction *)parseResponseExtAuctionFromDictionary:(NSDictionary *)dictionary {
    CLXBidResponseCloudXAuction *auction = [[CLXBidResponseCloudXAuction alloc] init];
    
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSArray *participantsArray = dictionary[@"participants"];
    if ([participantsArray isKindOfClass:[NSArray class]]) {
        NSMutableArray<CLXBidResponseCloudXParticipants *> *participants = [NSMutableArray array];
        for (NSDictionary *participantDict in participantsArray) {
            CLXBidResponseCloudXParticipants *participant = [CLXBidResponse parseExtParticipantsFromDictionary:participantDict];
            if (participant) {
                [participants addObject:participant];
            }
        }
        auction.participants = [participants copy];
    } else {
        auction.participants = @[];
    }
    return auction;
}


+ (CLXBidResponseResponseExt *)parseResponseExtFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    CLXBidResponseResponseExt *ext = [[CLXBidResponseResponseExt alloc] init];
    
    NSDictionary *cloudxDict = dictionary[@"cloudx"];
    
    NSDictionary *auctionDict = cloudxDict[@"auction"];
    
    if ([auctionDict isKindOfClass:[NSDictionary class]]) {
        CLXBidResponseCloudXAuction *auction = [CLXBidResponse parseResponseExtAuctionFromDictionary:auctionDict];
        if (auction) {
            CLXBidResponseAuction *cloudx = [[CLXBidResponseAuction alloc] init];
            NSString *serverVersion = cloudxDict[@"serverVersion"] ?: @"";
            cloudx.serverVersion = serverVersion;
            cloudx.auction = auction;
            ext.cloudx = cloudx;
        }
    }
    
    return ext;
}

+ (CLXBidResponse *)parseBidResponseFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        [logger error:@"❌ [BidResponse] Invalid dictionary provided for parsing"];
        return nil;
    }
    
    CLXBidResponse *response = [[CLXBidResponse alloc] init];
    
    // Parse basic fields
    response.id = dictionary[@"id"];
    response.bidid = dictionary[@"bidid"];
    response.cur = dictionary[@"cur"];
    
    NSDictionary *extDict = dictionary[@"ext"];
    if ([extDict isKindOfClass:[NSDictionary class]]) {
        CLXBidResponseResponseExt *ext = [CLXBidResponse parseResponseExtFromDictionary:extDict];
        if (ext) {
            response.ext = ext;
        }
    }
    
    // Parse seatbid array using helper function
    NSArray *seatbidArray = dictionary[@"seatbid"];
    if (seatbidArray && [seatbidArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *seatbids = [NSMutableArray array];
        for (NSDictionary *seatbidDict in seatbidArray) {
            CLXBidResponseSeatBid *seatbid = [CLXBidResponse parseSeatBidFromDictionary:seatbidDict];
            if (seatbid) {
                [seatbids addObject:seatbid];
            }
        }
        response.seatbid = [seatbids copy];
    }
    
    [logger info:[NSString stringWithFormat:@"✅ [BidResponse] Successfully parsed bid response with %lu seatbids", (unsigned long)response.seatbid.count]];
    return response;
}

@end

// MARK: - Parsing Functions
@implementation CLXBidResponse (Parsing)

+ (CLXBidResponseSeatBid *)parseSeatBidFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponseSeatBid *seatBid = [[CLXBidResponseSeatBid alloc] init];
    
    // Parse seat
    seatBid.seat = dictionary[@"seat"];
    
    // Parse bid array
    NSArray *bidArray = dictionary[@"bid"];
    if ([bidArray isKindOfClass:[NSArray class]]) {
        NSMutableArray<CLXBidResponseBid *> *bids = [NSMutableArray array];
        for (NSDictionary *bidDict in bidArray) {
            CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
            if (bid) {
                [bids addObject:bid];
            }
        }
        seatBid.bid = [bids copy];
    } else {
        seatBid.bid = @[];
    }
    
    return seatBid;
}

+ (CLXBidResponseBid *)parseBidFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    
    // Parse basic fields
    bid.id = dictionary[@"id"];
    bid.adm = dictionary[@"adm"];
    bid.adid = dictionary[@"adid"];
    bid.impid = dictionary[@"impid"];
    bid.bundle = dictionary[@"bundle"];
    bid.burl = dictionary[@"burl"];
    bid.nurl = dictionary[@"nurl"];
    bid.lurl = dictionary[@"lurl"];
    bid.iurl = dictionary[@"iurl"];
    bid.cid = dictionary[@"cid"];
    bid.crid = dictionary[@"crid"];
    bid.dealid = dictionary[@"dealid"];
    // Safe parsing with NSNull handling
    id priceValue = dictionary[@"price"];
    bid.price = (priceValue && ![priceValue isKindOfClass:[NSNull class]]) ? [priceValue doubleValue] : 0.0;
    
    id wValue = dictionary[@"w"];
    bid.w = (wValue && ![wValue isKindOfClass:[NSNull class]]) ? [wValue integerValue] : 0;
    
    id hValue = dictionary[@"h"];
    bid.h = (hValue && ![hValue isKindOfClass:[NSNull class]]) ? [hValue integerValue] : 0;
    
    // Parse optional fields with NSNull safety
    id abTestIdValue = dictionary[@"abTestId"];
    if (abTestIdValue && ![abTestIdValue isKindOfClass:[NSNull class]]) {
        bid.abTestId = [abTestIdValue longLongValue];
    }
    if (dictionary[@"abTestGroup"]) {
        bid.abTestGroup = dictionary[@"abTestGroup"];
    }
    
    // Parse arrays - match original inline parsing exactly
    NSArray *adomainArray = dictionary[@"adomain"];
    if (adomainArray && [adomainArray isKindOfClass:[NSArray class]]) {
        bid.adomain = [adomainArray copy];  // Match original: [adomainArray copy]
    }
    
    NSArray *catArray = dictionary[@"cat"];
    if ([catArray isKindOfClass:[NSArray class]]) {
        bid.cat = catArray;
    }
    
    // Parse ext
    NSDictionary *extDict = dictionary[@"ext"];
    if ([extDict isKindOfClass:[NSDictionary class]]) {
        bid.ext = [CLXBidResponse parseBidExtFromDictionary:extDict];
    }
    
    return bid;
}

+ (CLXBidResponseExt *)parseBidExtFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    
    // Parse origbidcpm and origbidcur with NSNull safety
    id origbidcpmValue = dictionary[@"origbidcpm"];
    if (origbidcpmValue && ![origbidcpmValue isKindOfClass:[NSNull class]]) {
        ext.origbidcpm = [origbidcpmValue doubleValue];
    }
    ext.origbidcur = dictionary[@"origbidcur"];
    
    // Parse skadn
    NSDictionary *skadnDict = dictionary[@"skadn"];
    if ([skadnDict isKindOfClass:[NSDictionary class]]) {
        ext.skadn = [CLXBidResponse parseSKAdFromDictionary:skadnDict];
    }
    
    // Parse cloudx
    NSDictionary *cloudxDict = dictionary[@"cloudx"];
    if ([cloudxDict isKindOfClass:[NSDictionary class]]) {
        ext.cloudx = [CLXBidResponse parseCloudXFromDictionary:cloudxDict];
    }
    
    // Parse prebid
    NSDictionary *prebidDict = dictionary[@"prebid"];
    if ([prebidDict isKindOfClass:[NSDictionary class]]) {
        ext.prebid = [CLXBidResponse parsePrebidFromDictionary:prebidDict];
    }
    
    return ext;
}

+ (CLXBidResponseSKAd *)parseSKAdFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponseSKAd *skad = [[CLXBidResponseSKAd alloc] init];
    
    // Parse basic fields
    skad.version = dictionary[@"version"];
    skad.network = dictionary[@"network"];
    skad.sourceidentifier = dictionary[@"sourceidentifier"];
    skad.campaign = dictionary[@"campaign"];
    skad.itunesitem = dictionary[@"itunesitem"];
    skad.productpageid = dictionary[@"productpageid"];
    skad.nonce = dictionary[@"nonce"];
    skad.sourceapp = dictionary[@"sourceapp"];
    skad.timestamp = dictionary[@"timestamp"];
    skad.signature = dictionary[@"signature"];
    
    // Parse fidelities array
    NSArray *fidelitiesArray = dictionary[@"fidelities"];
    if ([fidelitiesArray isKindOfClass:[NSArray class]]) {
        NSMutableArray<CLXBidResponseSKAdFidelity *> *fidelities = [NSMutableArray array];
        for (NSDictionary *fidelityDict in fidelitiesArray) {
                          CLXBidResponseSKAdFidelity *fidelity = [CLXBidResponse parseSKAdFidelityFromDictionary:fidelityDict];
            if (fidelity) {
                [fidelities addObject:fidelity];
            }
        }
        skad.fidelities = [fidelities copy];
    } else {
        skad.fidelities = @[];
    }
    
    return skad;
}

+ (CLXBidResponseSKAdFidelity *)parseSKAdFidelityFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    CLXBidResponseSKAdFidelity *fidelity = [[CLXBidResponseSKAdFidelity alloc] init];
    // Parse fields
    if (dictionary[@"fidelity"]) {
        fidelity.fidelity = [dictionary[@"fidelity"] integerValue];
    }
    fidelity.nonce = dictionary[@"nonce"];
    fidelity.signature = dictionary[@"signature"];
    fidelity.timestamp = dictionary[@"timestamp"];
    return fidelity;
}

+ (CLXBidResponseCloudX *)parseCloudXFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    //_logger = [[CLXLogger alloc] initWithCategory:@"WinLossFieldResolver"];
    CLXBidResponseCloudX *cloudx = [[CLXBidResponseCloudX alloc] init];
    // Parse rank with NSNull safety
    id rankValue = dictionary[@"rank"];
    if (rankValue && ![rankValue isKindOfClass:[NSNull class]]) {
        cloudx.rank = [rankValue integerValue];
    }
    id testValue = dictionary[@"test"];
    if (testValue && ![testValue isKindOfClass:[NSNull class]]) {
        cloudx.test = [testValue integerValue];
    }
    // Parse adapterExtras
    NSDictionary *adapterExtrasDict = dictionary[@"adapter_extras"];
    if ([adapterExtrasDict isKindOfClass:[NSDictionary class]]) {
        cloudx.adapterExtras = adapterExtrasDict;
    }
    
    return cloudx;
}

+ (CLXBidResponsePrebid *)parsePrebidFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    CLXBidResponsePrebid *prebid = [[CLXBidResponsePrebid alloc] init];
    
    // Parse meta
    NSDictionary *metaDict = dictionary[@"meta"];
    if ([metaDict isKindOfClass:[NSDictionary class]]) {
        prebid.meta = [CLXBidResponse parseCloudXMetaFromDictionary:metaDict];
        prebid.type = dictionary[@"type"];
    }
    
    return prebid;
}

+ (CLXBidResponseCloudXMeta *)parseCloudXMetaFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    CLXBidResponseCloudXMeta *meta = [[CLXBidResponseCloudXMeta alloc] init];
    meta.adaptercode = dictionary[@"adaptercode"];
    return meta;
}

@end 
