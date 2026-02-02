/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSource.m
 * @brief Bid ad source implementation
 */

#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CloudXCore.h>

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Utilities

static inline CLXAdFormat CLXAdFormatFromAdType(CLXAdType adType) {
    switch (adType) {
        case CLXAdTypeBanner:
            return CLXAdFormatBanner;
        case CLXAdTypeMrec:
            return CLXAdFormatMREC;
        case CLXAdTypeInterstitial:
            return CLXAdFormatInterstitial;
        case CLXAdTypeRewarded:
            return CLXAdFormatRewarded;
        case CLXAdTypeNative:
            return CLXAdFormatNative;
    }
    return CLXAdFormatBanner;
}

#pragma mark - CLXBidAdSourceResponse

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
@property (nonatomic, assign) NSTimeInterval bidRequestTimeout;
@property (nonatomic, assign) double latency;
@property (nonatomic, strong) id<CLXBidNetworkService> bidNetworkService;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;
@property (nonatomic, copy, nullable) NSString *currentCorrelationId;

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
            bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
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
        _bidRequestTimeout = bidRequestTimeout;
        _createBidAd = [createBidAd copy];
        _reportingService = reportingService;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXBidAdSource"];
        _latency = 0;
        
        // Get services from dependency injection
        CLXDIContainer *container = [CLXDIContainer shared];
        _bidNetworkService = [container resolveType:ServiceTypeSingleton class:[CLXBidNetworkServiceClass class]];
        
        // Initialize win/loss tracker
        _winLossTracker = [CLXWinLossTracker shared];
    }
    return self;
}

- (void)requestBidWithAdUnitID:(NSString *)adUnitID
              storedImpressionId:(NSString *)storedImpressionId
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      successWin:(BOOL)successWin
                   correlationId:(NSString *)correlationId
                      completion:(void (^)(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error))completion {
    
    // Store correlation ID for this request
    self.currentCorrelationId = correlationId;
    
    // Re-resolve bidNetworkService if nil (happens when banner created before SDK init)
    if (!self.bidNetworkService) {
        CLXDIContainer *container = [CLXDIContainer shared];
        self.bidNetworkService = [container resolveType:ServiceTypeSingleton class:[CLXBidNetworkServiceClass class]];
        if (self.bidNetworkService) {
            [self.logger debug:@"BidNetworkService resolved from DI container"];
        } else {
            [self.logger error:@"BidNetworkService not available in DI container - SDK may not be initialized"];
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:2 userInfo:@{NSLocalizedDescriptionKey: @"BidNetworkService not available"}]);
            }
            return;
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] Auction started - AdUnit: %@, Placement: %@, AdType: %ld", correlationId, adUnitID, self.placementID, (long)self.adType]];
    
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
        [self.logger verbose:[NSString stringWithFormat:@"Network name token dict: %@", networkNameTokenDict]];
        
        // Create bid request
        [self.logger debug:[NSString stringWithFormat:@"[%@] Creating bid request...", correlationId]];
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
                                                        tmax:self.bidRequestTimeout > 0 ? @((NSInteger)(self.bidRequestTimeout * 1000)) : nil
                                                    impModel:impModel
                                                correlationId:correlationId
                                                  completion:^(id _Nullable bidRequest, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                [self.logger error:@"Self reference lost in bid request creation block"];
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Self reference lost"}]);
                }
                return;
            }
            
            [self.logger debug:[NSString stringWithFormat:@"[%@] [CLXBidAdSource] Bid request creation completion called", correlationId]];
            
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"Bid request creation failed with error: %@", error.localizedDescription]];
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            [self.logger debug:[NSString stringWithFormat:@"[%@] Bid request created successfully", correlationId]];
            
            // Store bid request JSON in tracking field resolver
            if ([bidRequest isKindOfClass:[NSDictionary class]]) {
                NSString *auctionId = bidRequest[@"id"];
                if (auctionId) {
                    [[CLXTrackingFieldResolver shared] setRequestData:auctionId bidRequestJSON:(NSDictionary *)bidRequest];
                    [self.logger debug:[NSString stringWithFormat:@"[%@] Stored bid request JSON for auction: %@", correlationId, auctionId]];
                }
            }
            
            // Proceed directly to auction
            [strongSelf startAuctionWithFinalBidRequest:bidRequest
                                          correlationId:correlationId
                                             completion:completion];
        }];
    }];
}

// Helper method to start auction 
- (void)startAuctionWithFinalBidRequest:(id)bidRequest
                          correlationId:(NSString *)correlationId
                             completion:(void (^)(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error))completion {
    // Start auction
    NSString *currentAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    if (!currentAppKey || currentAppKey.length == 0) {
        [self.logger error:[NSString stringWithFormat:@"[%@] No app key found in UserDefaults", correlationId]];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No app key found"}]);
        }
        return;
    }
    [self.logger debug:[NSString stringWithFormat:@"[%@] [CLXBidAdSource] Starting auction with AppKey: %@", correlationId, currentAppKey]];
    
    // Use bidRequestTimeout for HTTP timeout, 0 = session default
    NSTimeInterval timeout = self.bidRequestTimeout;

    __weak typeof(self) weakSelf = self;
    [self.bidNetworkService startAuctionWithBidRequest:bidRequest
                                                 appKey:currentAppKey
                                                timeout:timeout
                                          correlationId:correlationId
                                             completion:^(CLXBidResponse * _Nullable response, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [self.logger error:@"Self reference lost in auction completion block"];
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Self reference lost"}]);
            }
            return;
        }

        [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] [CLXBidAdSource] Auction completion - Response: %@, Error: %@", correlationId, response ? @"YES" : @"NO", error ? error.localizedDescription : @"None"]];
        
        if (error) {
            // Error already logged by network layer - just propagate to delegate
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        // Store the bid response for LURL firing
        strongSelf.currentBidResponse = response;
        
        // Store original bid response JSON in tracking field resolver for efficient field resolution
        if (response.id && rawJSON) {
            [[CLXTrackingFieldResolver shared] setResponseData:response.id bidResponseJSON:rawJSON];
            [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] Stored original bid response JSON for auction: %@", correlationId, response.id]];
        }
        
        // Pre-cache all bids with loss payloads for win/loss tracking
        if (response.id) {
            NSArray<CLXBidResponseBid *> *allBids = [response allBids];
            
            // Add bids to auction bid manager for tracking
            for (CLXBidResponseBid *bid in allBids) {
                [strongSelf.winLossTracker addBid:response.id bid:bid];
            }
            
            // No pre-caching - events fire immediately when they occur
            [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] Registered %lu bids for auction: %@", 
                                     correlationId, (unsigned long)allBids.count, response.id]];
        }
        
        // Implement true waterfall logic 
        [strongSelf tryWaterfallBidsFromResponse:response 
                                       auctionID:response.id 
                                      bidRequest:bidRequest 
                                   correlationId:correlationId
                                      completion:completion];
    }];
}

- (void)makeNetworkNameTokenDictWithCompletion:(void (^)(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict))completion {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict = [NSMutableDictionary dictionary];
    
    if (self.bidTokenSources.count == 0) {
        [self.logger debug:@"[CLXBidAdSource] No bid token sources available"];
        if (completion) {
            completion([networkNameTokenDict copy]);
        }
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // Request bid tokens from all available adapters
    // Note: All adapters are guaranteed initialized when SDK is ready (blocking init)
    
    for (NSString *adapterName in self.bidTokenSources.allKeys) {
        id<CLXBidTokenSource> tokenSource = self.bidTokenSources[adapterName];
        
        dispatch_group_enter(group);
        [tokenSource getTokenWithCompletion:^(NSDictionary<NSString *,NSString *> * _Nullable token, NSError * _Nullable error) {
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"Failed to get token for adapter %@: %@", adapterName, error.localizedDescription]];
            } else if (token) {
                [self.logger verbose:[NSString stringWithFormat:@"Got token for adapter %@: %@", adapterName, token]];
                networkNameTokenDict[adapterName] = token;
            } else {
                [self.logger debug:[NSString stringWithFormat:@"[CLXBidAdSource] No token returned for adapter %@", adapterName]];
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, queue, ^{
        [self.logger verbose:[NSString stringWithFormat:@"Network name token dict created: %@", networkNameTokenDict]];
        if (completion) {
            completion([networkNameTokenDict copy]);
        }
    });
}

- (void)tryWaterfallBidsFromResponse:(CLXBidResponse *)response 
                           auctionID:(nullable NSString *)auctionID 
                          bidRequest:(NSDictionary *)bidRequest 
                       correlationId:(NSString *)correlationId
                          completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion {
    
    NSArray<CLXBidResponseBid *> *sortedBids = [response getAllBidsForWaterfall];
    
    if (sortedBids.count == 0) {
        [self.logger error:[NSString stringWithFormat:@"[%@] No bids found in response", correlationId]];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:@{NSLocalizedDescriptionKey: @"No bids in auction response."}]);
        }
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] [CLXBidAdSource] Starting waterfall with %lu bids", correlationId, (unsigned long)sortedBids.count]];
    
    // Try bids in waterfall order with failure tracking
    NSMutableArray<NSString *> *failureReasons = [NSMutableArray array];
    [self tryNextBidInWaterfall:sortedBids 
                      bidIndex:0 
                     auctionID:auctionID 
                    bidRequest:bidRequest 
                 correlationId:correlationId
                failureReasons:failureReasons
                    completion:completion];
}

- (void)tryNextBidInWaterfall:(NSArray<CLXBidResponseBid *> *)sortedBids 
                     bidIndex:(NSInteger)bidIndex 
                    auctionID:(nullable NSString *)auctionID 
                   bidRequest:(NSDictionary *)bidRequest 
                correlationId:(NSString *)correlationId
               failureReasons:(NSMutableArray<NSString *> *)failureReasons
                   completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion {
    
    if (bidIndex >= sortedBids.count) {
        // All bids failed - return specific error for single bid, generic NO_FILL for multiple
        // This matches Android behavior: surface specific adapter errors when there's only one bid
        NSUInteger bidCount = sortedBids.count;
        
        if (bidCount == 1 && failureReasons.count > 0) {
            // Single bid failure - surface the specific error rather than generic NO_FILL
            NSString *specificError = failureReasons.firstObject;
            [self.logger error:[NSString stringWithFormat:@"[%@] Single bid failed: %@", correlationId, specificError]];
            if (completion) {
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: specificError,
                    @"CLXBidFailureReasons": failureReasons
                };
                // Use a more specific error code for single bid failures
                completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorAdapterCreationFailed userInfo:userInfo]);
            }
        } else {
            // Multiple bids failed - return generic NO_FILL with combined failure summary
            NSString *failureSummary = [self buildWaterfallFailureSummary:failureReasons bidCount:bidCount];
            [self.logger error:[NSString stringWithFormat:@"[%@] Waterfall exhausted: %@", correlationId, failureSummary]];
            if (completion) {
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: failureSummary,
                    @"CLXBidFailureReasons": failureReasons ?: @[]
                };
                completion(nil, [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:userInfo]);
            }
        }
        return;
    }
    
    CLXBidResponseBid *currentBid = sortedBids[bidIndex];
    [self.logger debug:[NSString stringWithFormat:@"[%@] [CLXBidAdSource] Trying bid %ld/%lu: rank=%ld, id=%@", 
                       correlationId, (long)bidIndex + 1, (unsigned long)sortedBids.count, 
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
            [self.logger debug:[NSString stringWithFormat:@"[%@] Waterfall success with bid %ld: rank=%ld, id=%@",
                              correlationId, (long)bidIndex + 1, (long)currentBid.ext.cloudx.rank, currentBid.id]];

            // NOTE: Don't fire lurls here - wait until winner actually loads successfully
            // This prevents premature lurl firing for bids that might still be needed as fallbacks
            [self.logger debug:[NSString stringWithFormat:@"[%@] Deferring lurl firing until winner loads successfully", correlationId]];
            
            if (completion) {
                completion(bidAdSourceResponse, nil);
            }
            return;
        }
    }
    
    // FIRST FILTERING PHASE - This bid is completely discarded because it couldn't create a banner instance
    // We know it definitely can't show an ad, so send loss notification immediately with TechnicalError
    
    // Build diagnostic failure reason for this bid
    NSString *failureReason = [self diagnoseCreationFailure:currentBid bidIndex:bidIndex];
    [failureReasons addObject:failureReason];
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] Bid %ld failed: %@", 
                       correlationId, (long)bidIndex + 1, failureReason]];
    
    // Send server-side loss notification for adapter creation failures
    if (auctionID && currentBid.id) {
        [self.winLossTracker setBidLoadResult:auctionID 
                                       bidId:currentBid.id 
                                     success:NO 
                                  lossReason:@(CLXLossReasonInternalError)];
        
        [self.winLossTracker sendEvent:auctionID
                                  bidId:currentBid.id
                                  event:[CLXBidLifecycleEvent lossEvent]
                             lossReason:@(CLXLossReasonInternalError)
                         winnerBidPrice:-1.0];
        
        [self.logger debug:[NSString stringWithFormat:@"[%@] 📤 [CLXBidAdSource] Sent LOSS event for uncreatable bid rank=%ld, reason=InternalError", correlationId, (long)currentBid.ext.cloudx.rank]];
    }
    
    // Try next bid in waterfall
    [self tryNextBidInWaterfall:sortedBids 
                      bidIndex:bidIndex + 1 
                     auctionID:auctionID 
                    bidRequest:bidRequest 
                 correlationId:correlationId
               failureReasons:failureReasons
                    completion:completion];
}

- (CLXBidAdSourceResponse *)createBidAdSourceResponseWithBid:(CLXBidResponseBid *)bid
                                                        auctionID:(nullable NSString *)auctionID
                                                         bidRequest:(NSDictionary *)bidRequest {
    
    NSString *networkName = bid.ext.prebid.meta.adaptercode ?: @"TestVastNetwork";
    
    // Map server-side network names to client-side adapter names
    if ([networkName isEqualToString:@"testbidder"]) {
        networkName = @"cloudXRenderer";
    }
    
    CLXAdFormat adFormat = CLXAdFormatFromAdType(self.adType);

    // Create CLXAd from bid response data
    CLXAd *clxAd = [CLXAd adFromBid:bid
                        placementId:self.placementID
                           adFormat:adFormat
                          placement:nil];

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
        NSString *correlationId = self.currentCorrelationId ?: @"unknown";
        [self.logger debug:[NSString stringWithFormat:@"[%@] createBidAd block called", correlationId]];
        if (self.createBidAd) {
            [self.logger debug:[NSString stringWithFormat:@"[%@] Calling original createBidAd function...", correlationId]];
            id result = self.createBidAd(bid.adid ?: @"", bid.id ?: @"", bid.adm ?: @"", bid.ext.cloudx.adapterExtras ?: @{}, bid.burl, self.hasCloseButton, networkName);
            [self.logger debug:[NSString stringWithFormat:@"[%@] createBidAd result: %@", correlationId, result]];
            return result;
        } else {
            [self.logger debug:[NSString stringWithFormat:@"[%@] createBidAd function is nil", correlationId]];
            return nil;
        }
    }];
}

- (nullable CLXBidResponse *)getCurrentBidResponse {
    return self.currentBidResponse;
}

#pragma mark - Diagnostic Helpers

/**
 * Diagnose why a bid failed to create an ad instance.
 * Provides actionable error messages for debugging.
 */
- (NSString *)diagnoseCreationFailure:(CLXBidResponseBid *)bid bidIndex:(NSInteger)bidIndex {
    NSMutableArray<NSString *> *issues = [NSMutableArray array];
    
    // Check for empty/nil adm (most common issue)
    if (!bid.adm || bid.adm.length == 0) {
        [issues addObject:@"adm is empty or nil"];
    }
    
    // Check for missing adaptercode (factory lookup will fail if adapter doesn't exist)
    NSString *adapterCode = bid.ext.prebid.meta.adaptercode;
    if (!adapterCode || adapterCode.length == 0) {
        [issues addObject:@"missing ext.prebid.meta.adaptercode"];
    }
    
    // Check for valid bid ID
    if (!bid.id || bid.id.length == 0) {
        [issues addObject:@"missing bid.id"];
    }
    
    // Check creative ID
    if (!bid.crid || bid.crid.length == 0) {
        [issues addObject:@"missing crid"];
    }
    
    // Build summary
    NSString *bidIdentifier = bid.crid ?: bid.id ?: [NSString stringWithFormat:@"index-%ld", (long)bidIndex];
    
    if (issues.count == 0) {
        // No obvious issues - factory returned nil for unknown reason
        return [NSString stringWithFormat:@"Bid '%@': adapter factory returned nil (check renderer logs for details)", bidIdentifier];
    }
    
    return [NSString stringWithFormat:@"Bid '%@': %@", bidIdentifier, [issues componentsJoinedByString:@", "]];
}

/**
 * Build a human-readable summary of all waterfall failures.
 */
- (NSString *)buildWaterfallFailureSummary:(NSArray<NSString *> *)failureReasons bidCount:(NSUInteger)bidCount {
    if (failureReasons.count == 0) {
        return @"All bids failed in waterfall (no diagnostic info available).";
    }
    
    NSMutableString *summary = [NSMutableString stringWithFormat:@"All %lu bid(s) failed:\n", (unsigned long)bidCount];
    
    for (NSUInteger i = 0; i < failureReasons.count; i++) {
        [summary appendFormat:@"  [%lu] %@", (unsigned long)(i + 1), failureReasons[i]];
        if (i < failureReasons.count - 1) {
            [summary appendString:@"\n"];
        }
    }
    
    return summary;
}

@end

NS_ASSUME_NONNULL_END 
