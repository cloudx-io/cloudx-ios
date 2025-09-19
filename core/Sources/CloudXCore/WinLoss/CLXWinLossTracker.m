/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTracker.m
 * @brief Implementation of Win/Loss tracker matching Android WinLossTrackerImpl exactly
 */

#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/URLSession+CLX.h>

@interface CLXWinLossTracker ()
@property (nonatomic, strong) CLXAuctionBidManager *auctionBidManager;
@property (nonatomic, strong) CLXWinLossFieldResolver *winLossFieldResolver;
@property (nonatomic, strong) CLXWinLossNetworkService *networkService;
@property (nonatomic, strong) CLXLogger *logger;

@property (nonatomic, copy, nullable) NSString *appKey;
@property (nonatomic, copy, nullable) NSString *endpointUrl;

// TODO: Add database persistence layer for failed requests
@end

@implementation CLXWinLossTracker

static id<CLXWinLossTracking> _testInstance = nil;

+ (instancetype)shared {
    // Return test instance if set (for testing)
    if (_testInstance) {
        return (CLXWinLossTracker *)_testInstance;
    }
    
    // Default production singleton
    static CLXWinLossTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXWinLossTracker alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Testing Support

+ (void)setSharedInstanceForTesting:(id<CLXWinLossTracking>)testInstance {
    _testInstance = testInstance;
}

+ (void)resetSharedInstance {
    _testInstance = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _auctionBidManager = [[CLXAuctionBidManager alloc] init];
        _winLossFieldResolver = [[CLXWinLossFieldResolver alloc] init];
        _logger = [[CLXLogger alloc] initWithCategory:@"WinLossTracker"];
        
        // Initialize network service with placeholder URL (will be updated when endpoint is set)
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"winloss"];
        _networkService = [[CLXWinLossNetworkService alloc] initWithBaseURL:@"" urlSession:urlSession];
    }
    return self;
}

#pragma mark - CLXWinLossTracking Implementation

- (void)setAppKey:(NSString *)appKey {
    _appKey = [appKey copy];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossTracker] App key set: %@", appKey ? @"YES" : @"NO"]];
}

- (void)setEndpoint:(nullable NSString *)endpointUrl {
    self.endpointUrl = [endpointUrl copy];
    
    // Recreate network service with new endpoint
    if (endpointUrl) {
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"winloss"];
        self.networkService = [[CLXWinLossNetworkService alloc] initWithBaseURL:endpointUrl urlSession:urlSession];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossTracker] Endpoint set: %@", endpointUrl ?: @"(nil)"]];
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    [self.winLossFieldResolver setConfig:config];
    [self.logger debug:@"🔧 [WinLossTracker] Config set for field resolver"];
}

- (void)trySendingPendingWinLossEvents {
    // TODO: Implement database persistence and retry logic
    [self.logger debug:@"📊 [WinLossTracker] Pending events retry not yet implemented"];
}

- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid {
    [self.auctionBidManager addBid:auctionId bid:bid];
    [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] Added bid %@ to auction %@", bid.id, auctionId]];
}

- (void)setBidLoadResult:(NSString *)auctionId
                   bidId:(NSString *)bidId
                 success:(BOOL)success
              lossReason:(nullable NSNumber *)lossReason {
    [self.auctionBidManager setBidLoadResult:auctionId bidId:bidId success:success lossReason:lossReason];
    [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] Set bid %@ load result - success: %@", 
                       bidId, success ? @"YES" : @"NO"]];
}

- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    [self.auctionBidManager setBidWinner:auctionId winningBidId:winningBidId];
    [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] Set winner for auction %@: %@", auctionId, winningBidId]];
}

- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
        NSNumber *lossReason = [self.auctionBidManager getBidLossReason:auctionId bidId:bidId];
        double loadedBidPrice = [self.auctionBidManager getLoadedBidPrice:auctionId];
        
        if (!bid) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] No bid found for loss notification: %@", bidId]];
            return;
        }
        
        // Build payload using field resolver (matches Android's buildWinLossPayload)
        NSDictionary<NSString *, id> *payload = [self.winLossFieldResolver buildWinLossPayloadWithAuctionId:auctionId
                                                                                                         bid:bid
                                                                                                  lossReason:lossReason
                                                                                                       isWin:NO
                                                                                               loadedBidPrice:loadedBidPrice];
        
        if (payload) {
            [self trackWinLoss:payload];
        } else {
            [self.logger debug:@"📊 [WinLossTracker] No payload mapping configured for loss notification"];
        }
    });
}

- (void)sendWin:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
        
        if (!bid) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] No bid found for win notification: %@", bidId]];
            return;
        }
        
        double winnerBidPrice = bid.price;
        
        // Build payload using field resolver (matches Android's buildWinLossPayload)
        NSDictionary<NSString *, id> *payload = [self.winLossFieldResolver buildWinLossPayloadWithAuctionId:auctionId
                                                                                                         bid:bid
                                                                                                  lossReason:nil
                                                                                                       isWin:YES
                                                                                               loadedBidPrice:winnerBidPrice];
        
        if (payload) {
            [self trackWinLoss:payload];
        } else {
            [self.logger debug:@"📊 [WinLossTracker] No payload mapping configured for win notification"];
        }
        
        // Clear auction data after successful win notification (matches Android)
        [self.auctionBidManager clearAuction:auctionId];
    });
}

- (void)clearAuction:(NSString *)auctionId {
    [self.auctionBidManager clearAuction:auctionId];
    [self.logger debug:[NSString stringWithFormat:@"🧹 [WinLossTracker] Cleared auction: %@", auctionId]];
}

#pragma mark - Private Methods

/**
 * Sends win/loss payload to server - matches Android's trackWinLoss method
 */
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload {
    // TODO: Save to database for retry logic (matches Android's saveToDb)
    
    NSString *endpoint = self.endpointUrl;
    if (!endpoint || endpoint.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No endpoint configured for win/loss notification"];
        return;
    }
    
    NSString *appKey = self.appKey;
    if (!appKey || appKey.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No app key configured for win/loss notification"];
        return;
    }
    
    // Send to server (matches Android's trackerApi.send)
    [self.networkService sendWithAppKey:appKey
                            endpointUrl:endpoint
                                payload:payload
                             completion:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            [self.logger debug:@"✅ [WinLossTracker] Win/loss notification sent successfully"];
            // TODO: Remove from database cache if successful
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Win/loss notification failed: %@", 
                               error ? error.localizedDescription : @"Unknown error"]];
            // TODO: Keep in database for retry
        }
    }];
}

@end
