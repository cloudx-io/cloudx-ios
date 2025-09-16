/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSource.m
 * @brief Bid ad source implementation
 */

#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXEnvironmentConfig.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAd.h>

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAppSessionServiceImplementation.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXBidAdSourceResponse ()

@property (nonatomic, assign, readwrite) double price;
@property (nonatomic, copy, readwrite, nullable) NSString *auctionId;
@property (nonatomic, copy, readwrite, nullable) NSString *dealId;
@property (nonatomic, assign, readwrite) double latency;
@property (nonatomic, copy, readwrite, nullable) NSString *nurl;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, copy, readwrite) NSString *networkName;
@property (nonatomic, strong, readwrite) CLXBidResponseBid *bid;
@property (nonatomic, strong, readwrite) CLXBiddingConfigRequest *bidRequest;
@property (nonatomic, copy, readwrite) id (^createBidAd)(void);

@end

@implementation CLXBidAdSourceResponse

- (instancetype)initWithPrice:(double)price
                   auctionId:(nullable NSString *)auctionId
                      dealId:(nullable NSString *)dealId
                     latency:(double)latency
                         nurl:(nullable NSString *)nurl
                        bidID:(NSString *)bidID
                          bid:(CLXBidResponseBid *)bid
                   bidRequest:(NSDictionary *)bidRequest
                  networkName:(NSString *)networkName
                       clxAd:(nullable CLXAd *)clxAd
                  createBidAd:(id (^)(void))createBidAd {
    self = [super init];
    if (self) {
        _price = price;
        _auctionId = [auctionId copy];
        _dealId = [dealId copy];
        _latency = latency;
        _nurl = [nurl copy];
        _bidID = [bidID copy];
        _bid = bid;
        _bidRequest = bidRequest;
        _networkName = [networkName copy];
        _clxAd = clxAd;
        _createBidAd = [createBidAd copy];
    }
    return self;
}

@end

@interface CLXBidAdSource ()

@property (nonatomic, copy) NSString *publisherID;
@property (nonatomic, copy) NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources;
@property (nonatomic, copy) id (^createBidAd)(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network);
@property (nonatomic, copy, nullable) NSString *userID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *dealID;
@property (nonatomic, assign) BOOL hasCloseButton;
@property (nonatomic, assign) NSInteger adType;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) id nativeAdRequirements;
@property (nonatomic, strong, nullable) NSNumber *tmax;
@property (nonatomic, assign) double latency;
@property (nonatomic, strong) id<CLXBidNetworkService> bidNetworkService;
@property (nonatomic, strong) id<CLXAppSessionService> appSessionService;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;

@end

@implementation CLXBidAdSource

- (instancetype)initWithUserID:(nullable NSString *)userID
                   placementID:(NSString *)placementID
                        dealID:(nullable NSString *)dealID
                 hasCloseButton:(BOOL)hasCloseButton
                   publisherID:(NSString *)publisherID
                        adType:(NSInteger)adType
                bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
         nativeAdRequirements:(nullable id)nativeAdRequirements
                          tmax:(nullable NSNumber *)tmax
               reportingService:(id<CLXAdEventReporting>)reportingService
                   createBidAd:(id (^)(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network))createBidAd {
    self = [super init];
    if (self) {
        _userID = [userID copy];
        _placementID = [placementID copy];
        _dealID = [dealID copy];
        _hasCloseButton = hasCloseButton;
        _publisherID = [publisherID copy];
        _adType = adType;
        _bidTokenSources = [bidTokenSources copy];
        _nativeAdRequirements = nativeAdRequirements;
        _tmax = tmax;
        _createBidAd = [createBidAd copy];
        _reportingService = reportingService;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXBidAdSource"];
        _latency = 0;
        
        // Get services from dependency injection
        CLXDIContainer *container = [CLXDIContainer shared];
        _bidNetworkService = [container resolveType:ServiceTypeSingleton class:[CLXBidNetworkServiceClass class]];
        
        // Get app key from UserDefaults (matching Swift SDK behavior)
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        _appSessionService = [[CLXAppSessionServiceImplementation alloc] initWithSessionID:sessionID
                                                                                  appKey:appKey
                                                                                     url:[CLXEnvironmentConfig shared].metricsEndpointURL];
    }
    return self;
}

- (void)requestBidWithAdUnitID:(NSString *)adUnitID
              storedImpressionId:(NSString *)storedImpressionId
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      successWin:(BOOL)successWin
                      completion:(void (^)(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error))completion {
    
    [self.logger info:[NSString stringWithFormat:@"🚀 [CLXBidAdSource] requestBidWithAdUnitID called - AdUnit: %@, Placement: %@, AdType: %ld", adUnitID, self.placementID, (long)self.adType]];
    
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    if ([metricsDict.allKeys containsObject:@"network_call_bid_req"]) {
        NSString *value = metricsDict[@"network_call_bid_req"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"network_call_bid_req"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"network_call_bid_req"] = @"1";
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
    
    // Create network name token dictionary from bidTokenSources
    [self makeNetworkNameTokenDictWithCompletion:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] Network name token dict: %@", networkNameTokenDict]];
        
        // Create bid request
        [self.logger debug:@"🔧 [CLXBidAdSource] Creating bid request..."];
        __weak typeof(self) weakSelf = self;
        [self.bidNetworkService createBidRequestWithAdUnitID:adUnitID
                                          storedImpressionId:storedImpressionId
                                                      adType:self.adType
                                                       dealID:self.dealID
                                                    bidFloor:0.01
                                                publisherID:self.publisherID
                                                      userID:self.userID ?: @""
                                                adapterInfo:networkNameTokenDict
                                       nativeAdRequirements:self.nativeAdRequirements
                                                        tmax:self.tmax
                                                    impModel:impModel
                                                  completion:^(id _Nullable bidRequest, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                [self.logger error:@"❌ [CLXBidAdSource] Self reference lost in bid request creation block"];
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Self reference lost"}]);
                }
                return;
            }
            
            [self.logger debug:@"📥 [CLXBidAdSource] Bid request creation completion called"];
            
            // Log the actual bid request JSON
            if (bidRequest) {
                NSError *jsonError;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:NSJSONWritingPrettyPrinted error:&jsonError];
                if (jsonData && !jsonError) {
                    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] BidRequest JSON:\n%@", jsonString]];
                } else {
                    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] BidRequest: %@", bidRequest]];
                }
            } else {
                [self.logger debug:@"📊 [CLXBidAdSource] BidRequest: (null)"];
            }
            
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] Error: %@", error]];
            
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"❌ [CLXBidAdSource] Bid request creation failed with error: %@", error.localizedDescription]];
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            [self.logger info:@"✅ [CLXBidAdSource] Bid request created successfully"];
            
            // Store bid request JSON in tracking field resolver (Android parity)
            if ([bidRequest isKindOfClass:[NSDictionary class]]) {
                NSString *auctionId = bidRequest[@"id"];
                if (auctionId) {
                    [[CLXTrackingFieldResolver shared] setRequestData:auctionId bidRequestJSON:(NSDictionary *)bidRequest];
                    [self.logger debug:[NSString stringWithFormat:@"Stored bid request JSON for auction: %@", auctionId]];
                }
            }
            
            // Start auction
            NSString *currentAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
            if (!currentAppKey || currentAppKey.length == 0) {
                [self.logger error:@"❌ [CLXBidAdSource] No app key found in UserDefaults"];
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No app key found"}]);
                }
                return;
            }
            [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXBidAdSource] Starting auction with AppKey: %@", currentAppKey]];
            [strongSelf.bidNetworkService startAuctionWithBidRequest:bidRequest
                                                              appKey:currentAppKey
                                                          completion:^(CLXBidResponse * _Nullable response, NSError * _Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    [self.logger error:@"❌ [CLXBidAdSource] Self reference lost in auction completion block"];
                    if (completion) {
                        completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Self reference lost"}]);
                    }
                    return;
                }

                [self.logger debug:[NSString stringWithFormat:@"📥 [CLXBidAdSource] Auction completion - Response: %@, Error: %@", response ? @"YES" : @"NO", error ? error.localizedDescription : @"None"]];
                
                if (error) {
                    [self.logger error:[NSString stringWithFormat:@"❌ [CLXBidAdSource] Auction failed with error: %@", error.localizedDescription]];
                    if (completion) {
                        completion(nil, error);
                    }
                    return;
                }
                
                // Store the bid response for LURL firing
                strongSelf.currentBidResponse = response;
                
                // Store bid response JSON in tracking field resolver (Android parity)
                if (response.id) {
                    // Convert CLXBidResponse back to JSON dictionary for field resolution
                    // Note: In a complete implementation, we'd store the original JSON response
                    // For now, we'll create a basic representation from the parsed response
                    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
                    responseDict[@"id"] = response.id;
                    
                    if (response.seatbid && response.seatbid.count > 0) {
                        NSMutableArray *seatbidArray = [NSMutableArray array];
                        for (CLXBidResponseSeatBid *seatbid in response.seatbid) {
                            NSMutableDictionary *seatDict = [NSMutableDictionary dictionary];
                            seatDict[@"seat"] = seatbid.seat ?: @"";
                            
                            if (seatbid.bid && seatbid.bid.count > 0) {
                                NSMutableArray *bidArray = [NSMutableArray array];
                                for (CLXBidResponseBid *bid in seatbid.bid) {
                                    NSMutableDictionary *bidDict = [NSMutableDictionary dictionary];
                                    bidDict[@"id"] = bid.id ?: @"";
                                    bidDict[@"price"] = @(bid.price);
                                    bidDict[@"crid"] = bid.crid ?: @"";
                                    bidDict[@"dealid"] = bid.dealid ?: @"";
                                    bidDict[@"w"] = @(bid.w);
                                    bidDict[@"h"] = @(bid.h);
                                    [bidArray addObject:bidDict];
                                }
                                seatDict[@"bid"] = bidArray;
                            }
                            [seatbidArray addObject:seatDict];
                        }
                        responseDict[@"seatbid"] = seatbidArray;
                    }
                    
                    [[CLXTrackingFieldResolver shared] setResponseData:response.id bidResponseJSON:responseDict];
                    [strongSelf.logger debug:[NSString stringWithFormat:@"Stored bid response JSON for auction: %@", response.id]];
                }
                
                // Implement true waterfall logic 
                [strongSelf tryWaterfallBidsFromResponse:response 
                                               auctionID:response.id 
                                              bidRequest:bidRequest 
                                              completion:completion];
            }];
        }];
    }];
}

- (void)makeNetworkNameTokenDictWithCompletion:(void (^)(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict))completion {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict = [NSMutableDictionary dictionary];
    
    if (self.bidTokenSources.count == 0) {
        [self.logger debug:@"⚠️ [CLXBidAdSource] No bid token sources available"];
        if (completion) {
            completion([networkNameTokenDict copy]);
        }
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSString *adapterName in self.bidTokenSources.allKeys) {
        id<CLXBidTokenSource> tokenSource = self.bidTokenSources[adapterName];
        
        dispatch_group_enter(group);
        [tokenSource getTokenWithCompletion:^(NSDictionary<NSString *,NSString *> * _Nullable token, NSError * _Nullable error) {
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"❌ [CLXBidAdSource] Failed to get token for adapter %@: %@", adapterName, error.localizedDescription]];
            } else if (token) {
                [self.logger debug:[NSString stringWithFormat:@"✅ [CLXBidAdSource] Got token for adapter %@: %@", adapterName, token]];
                networkNameTokenDict[adapterName] = token;
            } else {
                [self.logger debug:[NSString stringWithFormat:@"⚠️ [CLXBidAdSource] No token returned for adapter %@", adapterName]];
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, queue, ^{
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] Network name token dict created: %@", networkNameTokenDict]];
        if (completion) {
            completion([networkNameTokenDict copy]);
        }
    });
}

- (void)tryWaterfallBidsFromResponse:(CLXBidResponse *)response 
                           auctionID:(nullable NSString *)auctionID 
                          bidRequest:(NSDictionary *)bidRequest 
                          completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion {
    
    NSArray<CLXBidResponseBid *> *sortedBids = [response getAllBidsForWaterfall];
    
    if (sortedBids.count == 0) {
        [self.logger error:@"❌ [CLXBidAdSource] No bids found in response"];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:@{NSLocalizedDescriptionKey: @"No bids in auction response."}]);
        }
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔄 [CLXBidAdSource] Starting waterfall with %lu bids", (unsigned long)sortedBids.count]];
    
    // Try bids in waterfall order 
    [self tryNextBidInWaterfall:sortedBids 
                      bidIndex:0 
                     auctionID:auctionID 
                    bidRequest:bidRequest 
                    completion:completion];
}

- (void)tryNextBidInWaterfall:(NSArray<CLXBidResponseBid *> *)sortedBids 
                     bidIndex:(NSInteger)bidIndex 
                    auctionID:(nullable NSString *)auctionID 
                   bidRequest:(NSDictionary *)bidRequest 
                   completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion {
    
    if (bidIndex >= sortedBids.count) {
        [self.logger error:@"❌ [CLXBidAdSource] All bids failed in waterfall"];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:@{NSLocalizedDescriptionKey: @"All bids failed in waterfall."}]);
        }
        return;
    }
    
    CLXBidResponseBid *currentBid = sortedBids[bidIndex];
    [self.logger debug:[NSString stringWithFormat:@"🔄 [CLXBidAdSource] Trying bid %ld/%lu: rank=%ld, id=%@", 
                       (long)bidIndex + 1, (unsigned long)sortedBids.count, 
                       (long)currentBid.ext.cloudx.rank, currentBid.id]];
    
    // Create bid response and test if it can create an ad
    CLXBidAdSourceResponse *bidAdSourceResponse = [self createBidAdSourceResponseWithBid:currentBid
                                                                              auctionID:auctionID
                                                                              bidRequest:bidRequest];
    
    // Test if this bid can create a valid ad
    if (bidAdSourceResponse && bidAdSourceResponse.createBidAd) {
        id testAd = bidAdSourceResponse.createBidAd();
        
        if (testAd != nil) {
            // SUCCESS - This bid can be created (but not yet confirmed as loaded)
            [self.logger info:[NSString stringWithFormat:@"✅ [CLXBidAdSource] Waterfall success with bid %ld: rank=%ld, id=%@", 
                              (long)bidIndex + 1, (long)currentBid.ext.cloudx.rank, currentBid.id]];
            
            [self.appSessionService bidLoadedWithPlacementID:currentBid.id latency:self.latency];
            
            // NOTE: Don't fire lurls here - wait until winner actually loads successfully
            // This prevents premature lurl firing for bids that might still be needed as fallbacks
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] Deferring lurl firing until winner loads successfully"]];
            
            if (completion) {
                completion(bidAdSourceResponse, nil);
            }
            return;
        }
    }
    
    // FIRST FILTERING PHASE - This bid is completely discarded because it couldn't create a banner instance
    // We know it definitely can't show an ad, so fire lurl immediately with TechnicalError
    [self.logger debug:[NSString stringWithFormat:@"❌ [CLXBidAdSource] Bid %ld failed creation: rank=%ld, id=%@", 
                       (long)bidIndex + 1, (long)currentBid.ext.cloudx.rank, currentBid.id]];
    
    // Fire LURL immediately for adapter creation failures
    if (currentBid.lurl && currentBid.lurl.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [CLXBidAdSource] Firing lurl for uncreatable bid rank=%ld, reason=TechnicalError", (long)currentBid.ext.cloudx.rank]];
        [self.reportingService fireLurlWithUrl:currentBid.lurl reason:CLXLossReasonTechnicalError];
    }
    
    // Try next bid in waterfall
    [self tryNextBidInWaterfall:sortedBids 
                      bidIndex:bidIndex + 1 
                     auctionID:auctionID 
                    bidRequest:bidRequest 
                    completion:completion];
}

- (CLXBidAdSourceResponse *)createBidAdSourceResponseWithBid:(CLXBidResponseBid *)bid
                                                        auctionID:(nullable NSString *)auctionID
                                                         bidRequest:(NSDictionary *)bidRequest {
    
    NSString *networkName = bid.ext.prebid.meta.adaptercode ?: @"TestVastNetwork";
    
    // Create CLXAd from bid response data
    CLXAd *clxAd = [CLXAd adFromBid:bid placementId:self.placementID];

    return [[CLXBidAdSourceResponse alloc] initWithPrice:bid.price
                                            auctionId:auctionID
                                               dealId:bid.dealid
                                              latency:self.latency
                                                 nurl:bid.nurl
                                                bidID:bid.id
                                                  bid:bid
                                           bidRequest:bidRequest
                                          networkName:networkName
                                               clxAd:clxAd
                                          createBidAd:^id{
        [self.logger debug:@"🔧 [CLXBidAdSource] createBidAd block called"];
        if (self.createBidAd) {
            [self.logger debug:@"✅ [CLXBidAdSource] Calling original createBidAd function..."];
            id result = self.createBidAd(bid.adid ?: @"", bid.id ?: @"", bid.adm ?: @"", bid.ext.cloudx.adapterExtras ?: @{}, bid.burl, self.hasCloseButton, networkName);
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXBidAdSource] createBidAd result: %@", result]];
            return result;
        } else {
            [self.logger debug:@"❌ [CLXBidAdSource] createBidAd function is nil"];
            return nil;
        }
    }];
}

- (nullable CLXBidResponse *)getCurrentBidResponse {
    return self.currentBidResponse;
}

@end

NS_ASSUME_NONNULL_END 
