/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherFullscreenAdBase.m
 * @brief Base class implementation for fullscreen ads
 */

#import <CloudXCore/CLXPublisherFullscreenAdBase.h>

#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXAd.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ad state enumeration defining the lifecycle states of fullscreen ads
 */
typedef NS_ENUM(NSInteger, CLXFullscreenAdState) {
    CLXFullscreenAdStateIDLE,      // No ad loaded, ready to start loading
    CLXFullscreenAdStateLOADING,   // Ad request in progress
    CLXFullscreenAdStateREADY,     // Ad loaded and ready to display
    CLXFullscreenAdStateSHOWING,   // Ad currently visible to user
    CLXFullscreenAdStateDESTROYED  // Ad destroyed, no further operations allowed
};

@interface CLXPublisherFullscreenAdBase ()

// State management
@property (nonatomic, assign) CLXFullscreenAdState currentState;

// Correlation ID for request tracing
@property (nonatomic, copy, nullable) NSString *currentCorrelationId;

// Core properties
@property (nonatomic, strong, nullable) CLXAdNetworkFactories *adFactories;
@property (nonatomic, copy, nullable) NSString *userID;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *placementName;
@property (nonatomic, copy, nullable) NSString *rewardedCallbackUrl;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXAppSessionService *appSessionService;
@property (nonatomic, strong, nullable) CLXBidAdSource *bidAdSource;
@property (nonatomic, strong) CLXSettings *settings;

// Display state tracking
@property (nonatomic, strong, nullable) NSTimer *closeTimer;
@property (nonatomic, assign) NSTimeInterval forceCloseEventDelay;
@property (nonatomic, assign) BOOL closeEventReceived;
@property (nonatomic, strong, nullable) NSDate *impressionTime;

// Bid response data for NURL firing
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;

// Rill tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) CLXConfigImpressionModel *impModel;
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;

@end

@implementation CLXPublisherFullscreenAdBase

#pragma mark - Initialization

- (instancetype)initWithPlacement:(CLXSDKConfigPlacement *)placement
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(CLXConfigImpressionModel *)impModel
                      adFactories:(nullable CLXAdNetworkFactories *)adFactories
         waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                  bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
               bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                reportingService:(id<CLXAdEventReporting>)reportingService
                        settings:(CLXSettings *)settings {
    self = [super init];
    if (self) {
        // Set up logging for this fullscreen ad instance
        _logger = [[CLXLogger alloc] initWithCategory:@"FullscreenAd"];
        
        [self.logger debug:[NSString stringWithFormat:@"Initializing fullscreen ad - Placement: %@, Type: %ld", placement.id, (long)[self adType]]];
        
        // Start in idle state, ready to load ads
        _currentState = CLXFullscreenAdStateIDLE;
        
        // Configure instance properties
        _adFactories = adFactories;
        _rewardedCallbackUrl = [rewardedCallbackUrl copy];
        _placementID = [placement.id copy];
        _placementName = [placement.name copy];
        _reportingService = reportingService;
        _userID = [userID copy];
        _settings = settings;
        _impModel = impModel;
        _forceCloseEventDelay = 30.0;
        _closeEventReceived = NO;
        
        // Initialize Rill tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:_reportingService];
        
        // Initialize win/loss tracker
        _winLossTracker = [CLXWinLossTracker shared];
        
        // Set up session tracking for metrics collection
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        _appSessionService = [[CLXAppSessionService alloc] initWithSessionID:sessionID
                                                                       appKey:appKey
                                                                          url:metricsURL];
        
        // Configure bid source for ad request management
        BOOL hasCloseButton = placement.hasCloseButton ?: NO;
        
        __weak typeof(self) weakSelf = self;
        _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                               placementID:_placementID
                                                    dealID:placement.dealId
                                             hasCloseButton:hasCloseButton
                                               publisherID:publisherID
                                                    adType:[self adType]
                                            bidTokenSources:bidTokenSources
                                     nativeAdRequirements:nil
                                                      tmax:nil
                                           reportingService:_reportingService
                                               createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return nil;
            }
            
            return [strongSelf createAdapterWithAdId:adId
                                               bidId:bidId
                                                 adm:adm
                                       adapterExtras:adapterExtras
                                                burl:burl
                                             network:network];
        }];
        
        [self.logger debug:[NSString stringWithFormat:@"Initialized fullscreen ad in IDLE state for placement: %@", _placementID]];
    }
    return self;
}

#pragma mark - CLXAdFormat Properties

- (BOOL)isReady {
    return self.currentState == CLXFullscreenAdStateREADY;
}

- (BOOL)isLoading {
    return self.currentState == CLXFullscreenAdStateLOADING;
}

- (BOOL)isDestroyed {
    return self.currentState == CLXFullscreenAdStateDESTROYED;
}

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying fullscreen ad for placement: %@", self.placementID]];
    
    // Set state to destroyed
    self.currentState = CLXFullscreenAdStateDESTROYED;
    
    // Clean up current adapter
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }
}

- (void)dealloc {
    [self.logger debug:[NSString stringWithFormat:@"Deallocating fullscreen ad for placement: %@", _placementID]];
    
    // Clean up current adapter
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }
    
    // Invalidate timers
    [self.closeTimer invalidate];
}

#pragma mark - Public Methods

- (void)load {
    // Generate correlation ID for this ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    [self.logger info:[NSString stringWithFormat:@"[%@] 🎬 [PublisherFullscreenAd] Ad load started - Placement: %@, Type: %ld", self.currentCorrelationId, _placementID, (long)[self adType]]];
    
    // Check current state to determine if loading is allowed
    switch (self.currentState) {
        case CLXFullscreenAdStateIDLE:
            break;
        case CLXFullscreenAdStateLOADING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] ⚠️ [PublisherFullscreenAd] Already loading, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateREADY:
            [self.logger debug:[NSString stringWithFormat:@"[%@] ⚠️ [PublisherFullscreenAd] Already loaded, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateSHOWING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] ⚠️ [PublisherFullscreenAd] Currently showing, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateDESTROYED:
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Ad destroyed, cannot load", self.currentCorrelationId]];
            return;
    }
    
    // Transition to loading state
    self.currentState = CLXFullscreenAdStateLOADING;
    [self.logger debug:[NSString stringWithFormat:@"[%@] State transitioned to LOADING", self.currentCorrelationId]];
    
    // Initiate bid request for ad content
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:self.placementID
                                    impModel:self.impModel
                                   successWin:NO
                                correlationId:self.currentCorrelationId
                                   completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf handleBidResponse:response error:error];
    }];
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] showFromViewController called - Ready: %d, State: %ld", self.isReady, (long)self.currentState]];
    
    // Verify ad is ready before attempting to show
    if (self.currentState != CLXFullscreenAdStateREADY) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] Cannot show ad - invalid state: %ld", (long)self.currentState]];
        NSError *error = [NSError errorWithDomain:@"CLXErrorDomain" 
                                             code:CLXErrorCodeNoFill 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Ad not ready"}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyShowFailure:error];
        });
        return;
    }
    
    // Transition to showing state
    self.currentState = CLXFullscreenAdStateSHOWING;
    [self.logger debug:@"State transitioned to SHOWING"];
    
    // Set up display state
    self.closeEventReceived = NO;
    
    // Set up force close timer
    self.closeTimer = [NSTimer scheduledTimerWithTimeInterval:self.forceCloseEventDelay
                                                       repeats:NO
                                                         block:^(NSTimer * _Nonnull timer) {
        if (!self.closeEventReceived) {
            [self.logger debug:@"Force close timer fired - no close event received"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyForceClose];
            });
        }
        [self.closeTimer invalidate];
    }];
    
    // Display the loaded ad using the appropriate adapter
    [self showCurrentAdapterFromViewController:viewController];
}

#pragma mark - Abstract Methods (must be overridden)

- (NSInteger)adType {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
    return 0;
}

- (nullable id)createAdapterWithAdId:(NSString *)adId
                              bidId:(NSString *)bidId
                                 adm:(NSString *)adm
                       adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                burl:(nullable NSString *)burl
                             network:(NSString *)network {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (nullable id)getCurrentAdapter {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (void)setupAdapterAndLoad:(id)adapter {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)showCurrentAdapterFromViewController:(UIViewController *)viewController {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)notifyLoadSuccess {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)notifyLoadFailure:(NSError *)error {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)notifyShowFailure:(NSError *)error {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)notifyForceClose {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

#pragma mark - Protected Helper Methods

- (void)handleBidResponse:(CLXBidAdSourceResponse *)response error:(NSError *)error {
    if (error) {
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Bid request failed: %@ (Code: %ld)", self.currentCorrelationId, error.localizedDescription, (long)error.code]];
        
        // Kill switch errors should fail immediately with the actual error
        if (error.code == CLXErrorCodeSDKDisabled || error.code == CLXErrorCodeAdsDisabled) {
            [self.logger error:[NSString stringWithFormat:@"[%@] 🚫 [PublisherFullscreenAd] Kill switch active - failing immediately", self.currentCorrelationId]];
        }
        
        // Transition back to idle
        self.currentState = CLXFullscreenAdStateIDLE;
        
        // Call failure delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyLoadFailure:error];
        });
        return;
    }
    
    // Create adapter instance from bid response
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] createBidAd - AdID: %@, BidID: %@, Network: %@", response.bid.adid, response.bidID, response.networkName]];
    
    id adapter = response.createBidAd();
    if (!adapter) {
        [self.logger error:@"Failed to create adapter from bid response"];
        [self handleBidResponse:nil error:[NSError errorWithDomain:@"CLXErrorDomain" 
                                                              code:CLXErrorCodeNoFill 
                                                          userInfo:@{NSLocalizedDescriptionKey: @"Failed to create adapter"}]];
        return;
    }
    
    // Store bid response for NURL firing
    self.currentBidResponse = [self.bidAdSource getCurrentBidResponse];
    self.lastBidResponse = response;
    
    // Set up Rill tracking data
    [self.rillTrackingService setupTrackingDataFromBidResponse:response
                                                      impModel:self.impModel
                                                   placementID:self.placementID
                                                     loadCount:0];
    
    // Configure adapter delegate and initiate loading with timeout protection
    [self setupAdapterAndLoad:adapter];
}

- (void)applyMetrics {
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter respondsToSelector:@selector(price)]) {
        double price = [currentAdapter price];
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:price];
    }
}

- (void)sendLossNotificationForFailedAd {
    if (self.lastBidResponse && self.lastBidResponse.bid.id && self.currentBidResponse && self.currentBidResponse.id) {
        [self.winLossTracker setBidLoadResult:self.currentBidResponse.id 
                                       bidId:self.lastBidResponse.bid.id 
                                     success:NO 
                                  lossReason:@(CLXLossReasonInternalError)];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                  bidId:self.lastBidResponse.bid.id
                                  event:[CLXBidLifecycleEvent lossEvent]
                             lossReason:@(CLXLossReasonInternalError)
                         winnerBidPrice:-1.0];
        
        [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherFullscreenAd] Sent LOSS event for failed ad type %ld, reason=InternalError", (long)[self adType]]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] Missing data for ad type %ld loss notification: bidID=%@, auctionID=%@", 
                           (long)[self adType], self.lastBidResponse.bid.id ?: @"(nil)", self.currentBidResponse.id ?: @"(nil)"]];
    }
}

- (void)fireLosingBidLurls {
    if (!self.currentBidResponse || !self.lastBidResponse) {
        return;
    }
    
    NSArray<CLXBidResponseBid *> *allBids = [self.currentBidResponse getAllBidsForWaterfall];
    NSString *winnerBidId = self.lastBidResponse.bid.id;
    NSString *auctionId = self.currentBidResponse.id;
    
    [self.winLossTracker sendLossNotificationsForLosingBids:auctionId
                                              winningBidId:winnerBidId
                                                   allBids:allBids];
}

- (void)transitionToReadyState {
    self.currentState = CLXFullscreenAdStateREADY;
    [self.logger debug:@"📊 [PublisherFullscreenAd] State transitioned to READY"];
}

- (void)transitionToIdleState {
    self.currentState = CLXFullscreenAdStateIDLE;
    [self.logger debug:@"📊 [PublisherFullscreenAd] State transitioned to IDLE"];
}

- (void)handleAdClose {
    // Calculate display latency if we have impression time
    if (self.impressionTime) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:self.impressionTime] * 1000;
        [self.appSessionService addCloseWithPlacementID:self.placementID latency:latency];
    }
    
    // Mark close event received and cleanup
    self.closeEventReceived = YES;
    [self.closeTimer invalidate];
    
    // Destroy the adapter
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }
    
    // Transition back to idle
    self.currentState = CLXFullscreenAdStateIDLE;
}

- (void)fireLoadSuccessEventForBidID:(NSString *)bidID price:(double)price {
    if (bidID && self.currentBidResponse && self.currentBidResponse.id) {
        [self.winLossTracker setBidLoadResult:self.currentBidResponse.id
                                        bidId:bidID
                                      success:YES
                                   lossReason:nil];

        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:bidID
                                 event:[CLXBidLifecycleEvent loadSuccessEvent]
                            lossReason:@(CLXLossReasonBidWon)
                        winnerBidPrice:price];
        
        [self.logger debug:[NSString stringWithFormat:@"🚀 [PublisherFullscreenAd] Fired LOAD_SUCCESS event (nurl) for bidID=%@", bidID]];
    }
}

- (void)fireRenderSuccessEventForBidID:(NSString *)bidID adType:(CLXAdType)adType {
    self.impressionTime = [NSDate date];
    [self applyMetrics];
    
    [[CLXSessionMetricsTracker sharedInstance] recordImpressionForPlacement:self.placementName adType:adType];
    [self.appSessionService addImpressionWithPlacementID:self.placementID];
    [self.rillTrackingService sendImpressionEvent];
    
    CLXBidResponseBid *winningBid = [self.currentBidResponse findBidWithID:bidID];
    if (winningBid && bidID && self.currentBidResponse && self.currentBidResponse.id) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherFullscreenAd] Firing RENDER_SUCCESS event (burl) for impression: bidID=%@, price=%.2f", bidID, winningBid.price]];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:bidID
                                 event:[CLXBidLifecycleEvent renderSuccessEvent]
                            lossReason:@(CLXLossReasonBidWon)
                        winnerBidPrice:winningBid.price];
        
        [self.logger debug:@"🚀 [PublisherFullscreenAd] RENDER_SUCCESS event (burl) fired"];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] No NURL to fire: bidID=%@, winningBid=%@", bidID, winningBid ? @"found" : @"not found"]];
    }
}

- (void)handleClickTracking {
    [self.logger debug:@"Clicked on ad"];
    [self.appSessionService addClickWithPlacementID:self.placementID];
    [self.rillTrackingService sendClickEvent];
}

- (CLXAd *)createAdObject {
    return [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
}

@end

NS_ASSUME_NONNULL_END

