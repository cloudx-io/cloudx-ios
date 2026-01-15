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
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>
#import "CLXUIApplicationProxy.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Force Close Timeout Constants
/**
 * Maximum time (in seconds) a fullscreen ad can remain on-screen before the SDK forcibly closes it.
 * This is a SAFETY mechanism for stuck/broken ads, NOT a constraint on video content length.
 *
 * IMPORTANT: This is different from bid request `video.maxduration`:
 *   - `maxduration` = max video FILE length sent to bidders (60s)
 *   - Force close timeout = max TOTAL on-screen time (video + end card + user interaction)
 *
 * Timeline for a 60s rewarded video:
 *   [0s]     Video starts
 *   [60s]    Video ends, end card appears
 *   [60-90s] User views end card, may interact with CTA
 *   [90s+]   User dismisses or SDK force-closes if stuck
 *
 * Values chosen to be generous enough for legitimate ad experiences while still
 * protecting users from truly stuck ads.
 *
 * 🔧 PUBLISHER CONFIGURABILITY CANDIDATE:
 *    These values could potentially be configurable via server-side placement settings
 *    if publishers need different timeout behaviors for their specific use cases.
 */

/// Force close timeout for REWARDED ads (120 seconds / 2 minutes)
/// Rationale: Users must complete video to earn reward, so we allow extra time for:
///   - Full video playback (up to 60s)
///   - End card display and interaction (30-60s)
///   - Network latency/buffering
static const NSTimeInterval kCLXForceCloseTimeoutRewarded = 120.0;

/// Force close timeout for INTERSTITIAL ads (90 seconds)
/// Rationale: Shorter than rewarded because:
///   - Skippable after ~5s (user can exit early)
///   - Typically shorter video content
///   - User didn't opt-in for extended experience
static const NSTimeInterval kCLXForceCloseTimeoutInterstitial = 90.0;

// Private category to access internal SDK methods (framework-internal only, not exposed in public API)
@interface CloudXCore (Internal)
- (nullable CLXConfigImpressionModel *)createImpModelWithAuctionID:(NSString *)auctionID;
@end

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
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;

// Bid response data for NURL firing
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;

// Analytics tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) CLXConfigImpressionModel *impModel;
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;

// Queued load request handling (for SDK init race condition)
@property (nonatomic, assign) NSUInteger pendingLoadRequestCount;

// Deferred error (set during create if validation fails)
@property (nonatomic, strong, nullable) NSError *deferredError;

// Requested placement name for deferred initialization
@property (nonatomic, copy, nullable) NSString *requestedPlacementName;

@end

@implementation CLXPublisherFullscreenAdBase

#pragma mark - Initialization

- (instancetype)initWithPlacement:(nullable CLXSDKConfigPlacement *)placement
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(nullable CLXConfigImpressionModel *)impModel
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
        
        [self.logger debug:[NSString stringWithFormat:@"Initializing fullscreen ad - Placement: %@, Type: %ld", placement.id ?: @"(deferred)", (long)[self adType]]];
        
        // Start in idle state, ready to load ads
        _currentState = CLXFullscreenAdStateIDLE;
        
        // Configure instance properties
        _adFactories = adFactories;
        _rewardedCallbackUrl = [rewardedCallbackUrl copy];
        _placementID = placement ? [placement.id copy] : nil;
        _placementName = placement ? [placement.name copy] : nil;
        _reportingService = reportingService;
        _userID = [userID copy];
        _settings = settings;
        _impModel = impModel;
        
        // Set force close timeout based on ad type
        // See constant definitions above for detailed rationale
        _forceCloseEventDelay = ([self adType] == CLXAdTypeRewarded) 
            ? kCLXForceCloseTimeoutRewarded 
            : kCLXForceCloseTimeoutInterstitial;
        
        _closeEventReceived = NO;
        _pendingLoadRequestCount = 0;
        
        // Initialize Analytics tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:_reportingService];
        
        // Listen for SDK initialization completion (internal notification)
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleSDKInitialized:) 
                                                     name:CLXSDKInitializedNotification 
                                                   object:nil];
        
        // Initialize win/loss tracker
        _winLossTracker = [CLXWinLossTracker shared];
        
        // Set up session tracking for metrics collection
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        _appSessionService = [[CLXAppSessionService alloc] initWithSessionID:sessionID
                                                                       appKey:appKey
                                                                          url:metricsURL];
        
        // Configure bid source for ad request management (only if placement available)
        if (placement) {
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
        } else {
            // SDK not initialized - bid source will be created in performLoad
            _bidAdSource = nil;
            [self.logger debug:@"Deferring bid source creation until SDK initialization"];
        }
    }
    return self;
}

#pragma mark - CLXFullscreenAd Properties

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
    
    // Remove notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CLXSDKInitializedNotification" object:nil];
    
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
    
    // CRITICAL: Remove notification observer to prevent crashes if ad deallocated without destroy
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLXSDKInitializedNotification object:nil];
    
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
    // Check for deferred error from create method
    if (self.deferredError) {
        [self.logger error:[NSString stringWithFormat:@"Fullscreen ad creation failed with deferred error: %@", self.deferredError.localizedDescription]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyLoadFailure:self.deferredError];
        });
        return;
    }
    
    // Check if SDK is initialized
    if (![[CloudXCore shared] isInitialized]) {
        self.pendingLoadRequestCount++;
        [self.logger info:[NSString stringWithFormat:@"SDK not yet initialized, queuing load request #%lu for placement: %@", (unsigned long)self.pendingLoadRequestCount, self.requestedPlacementName ?: self.placementID]];
        return;
    }
    
    // SDK is ready, proceed with load
    [self performLoad];
}

// Internal method to actually perform the load operation
- (void)performLoad {
    // Check if we need to complete deferred initialization (bidAdSource is nil)
    if (!self.bidAdSource && self.requestedPlacementName && [[CloudXCore shared] isInitialized]) {
        // SDK is now initialized - complete initialization with real placement config
        CLXSDKConfigPlacement *realPlacement = [[CloudXCore shared] placementConfigForName:self.requestedPlacementName];
        if (realPlacement) {
            [self.logger debug:[NSString stringWithFormat:@"Completing deferred initialization for: %@ (ID: %@)", self.requestedPlacementName, realPlacement.id]];
            _placementID = realPlacement.id;
            _placementName = realPlacement.name;
            
            // Create impression model now that SDK is initialized (ensures app.id is populated)
            NSString *auctionID = [[NSUUID UUID] UUIDString];
            self.impModel = [[CloudXCore shared] createImpModelWithAuctionID:auctionID];
            if (self.impModel) {
                [self.logger debug:[NSString stringWithFormat:@"Created impression model with appID: %@", self.impModel.sdkConfig.appID]];
            } else {
                [self.logger error:@"Failed to create impression model after SDK init"];
            }
            
            // Create bid source now
            BOOL hasCloseButton = realPlacement.hasCloseButton ?: NO;
            NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources = self.adFactories.bidTokenSources;
            
            __weak typeof(self) weakSelf = self;
            self.bidAdSource = [[CLXBidAdSource alloc] initWithUserID:self.userID
                                                          placementID:_placementID
                                                               dealID:realPlacement.dealId
                                                        hasCloseButton:hasCloseButton
                                                          publisherID:@""
                                                               adType:[self adType]
                                                       bidTokenSources:bidTokenSources
                                                nativeAdRequirements:nil
                                                                 tmax:nil
                                                      reportingService:self.reportingService
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
            
            // Clear the requested placement name since initialization is complete
            self.requestedPlacementName = nil;
        } else {
            // Provide detailed error message with available placements (mirrors Android PlacementValidator)
            NSArray<NSString *> *availablePlacements = [[CloudXCore shared] availablePlacementNames];
            NSString *availablePlacementsString = availablePlacements.count > 0 
                ? [availablePlacements componentsJoinedByString:@", "] 
                : @"none";
            [self.logger error:[NSString stringWithFormat:@"Placement '%@' not found. Available: [%@]", self.requestedPlacementName, availablePlacementsString]];
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidPlacement 
                                          description:[NSString stringWithFormat:@"Placement '%@' not found in SDK configuration. Available placements: [%@].", 
                                                      self.requestedPlacementName, availablePlacementsString]];
            [self handleBidResponse:nil error:error];
            return;
        }
    }
    
    // Generate correlation ID for this ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    [self.logger info:[NSString stringWithFormat:@"[%@] 🎬 [PublisherFullscreenAd] Ad load started - Placement: %@, Type: %ld", self.currentCorrelationId, _placementID, (long)[self adType]]];
    
    // Check current state to determine if loading is allowed
    switch (self.currentState) {
        case CLXFullscreenAdStateIDLE:
            break;
        case CLXFullscreenAdStateLOADING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Already loading, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateREADY:
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Already loaded, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateSHOWING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Currently showing, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateDESTROYED:
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Ad destroyed, cannot load", self.currentCorrelationId]];
            return;
    }
    
    // Transition to loading state
    self.currentState = CLXFullscreenAdStateLOADING;
    [self.logger debug:[NSString stringWithFormat:@"[%@] State transitioned to LOADING", self.currentCorrelationId]];
    
    // Initiate bid request for ad content
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:self.placementID
                                    impModel:self.impModel
                                   successWin:NO
                                correlationId:self.currentCorrelationId
                                   completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        [self handleBidResponse:response error:error];
    }];
}

// Handle SDK initialization notification
- (void)handleSDKInitialized:(NSNotification *)notification {
    NSUInteger queuedRequests = self.pendingLoadRequestCount;
    if (queuedRequests > 0) {
        [self.logger info:[NSString stringWithFormat:@"SDK initialized, executing %lu queued load request(s) for placement: %@", (unsigned long)queuedRequests, self.placementID]];
        self.pendingLoadRequestCount = 0;
        // Execute load once (multiple load() calls for same ad are redundant)
        [self performLoad];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.logger debug:[NSString stringWithFormat:@"showFromViewController called - Ready: %d, State: %ld", self.isReady, (long)self.currentState]];
    
    // Verify ad is ready before attempting to show
    if (self.currentState != CLXFullscreenAdStateREADY) {
        [self.logger error:[NSString stringWithFormat:@"Cannot show ad - invalid state: %ld", (long)self.currentState]];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdNotReady];
        
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
    self.presentingViewController = viewController;
    
    // Set up force close timer
    self.closeTimer = [NSTimer scheduledTimerWithTimeInterval:self.forceCloseEventDelay
                                                       repeats:NO
                                                         block:^(NSTimer * _Nonnull timer) {
        if (!self.closeEventReceived) {
            [self.logger debug:@"Force close timer fired - no close event received"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self forceCloseAdAndNotify];
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

#pragma mark - Force Close Implementation

- (void)forceCloseAdAndNotify {
    NSString *networkName = self.lastBidResponse.networkName ?: @"unknown";
    [self.logger error:[NSString stringWithFormat:@"⚠️ FORCE CLOSE: %@ adapter failed to dismiss after %.0fs timeout - this indicates an SDK bug", 
                       networkName, self.forceCloseEventDelay]];
    
    // Try to dismiss any presented view controller on our presenting VC
    UIViewController *presentingVC = self.presentingViewController;
    if (presentingVC && presentingVC.presentedViewController) {
        [self.logger debug:@"Found presented view controller - dismissing it"];
        [presentingVC dismissViewControllerAnimated:NO completion:^{
            [self.logger debug:@"Presented view controller dismissed successfully"];
            self.presentingViewController = nil;
            [self notifyForceClose];
        }];
    } else {
        // No presented VC found, or it was already dismissed
        // Try to find and dismiss from the root view controller as a fallback
        UIViewController *rootVC = [CLXUIApplicationProxy keyWindow].rootViewController;
        if (rootVC && rootVC.presentedViewController) {
            [self.logger debug:@"Fallback: dismissing from root view controller"];
            [rootVC dismissViewControllerAnimated:NO completion:^{
                [self.logger debug:@"Root VC presented view controller dismissed"];
                self.presentingViewController = nil;
                [self notifyForceClose];
            }];
        } else {
            [self.logger debug:@"No presented view controller found to dismiss"];
            self.presentingViewController = nil;
            [self notifyForceClose];
        }
    }
}

#pragma mark - Protected Helper Methods

- (void)handleBidResponse:(CLXBidAdSourceResponse *)response error:(NSError *)error {
    if (error) {
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Bid request failed: %@", self.currentCorrelationId, error.clx_fullErrorMessage]];
        
        // Transition back to idle
        self.currentState = CLXFullscreenAdStateIDLE;
        
        // Call failure delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyLoadFailure:error];
        });
        return;
    }
    
    // Create adapter instance from bid response
    [self.logger debug:[NSString stringWithFormat:@"createBidAd - AdID: %@, BidID: %@, Network: %@", response.bid.adid, response.bidID, response.networkName]];
    
    id adapter = response.createBidAd();
    if (!adapter) {
        [self.logger error:@"Failed to create adapter from bid response"];
        [self handleBidResponse:nil error:[NSError errorWithDomain:@"CLXErrorDomain" 
                                                              code:CLXErrorCodeLoadFailed 
                                                          userInfo:@{NSLocalizedDescriptionKey: @"Failed to create adapter"}]];
        return;
    }
    
    // Store bid response for NURL firing
    self.currentBidResponse = [self.bidAdSource getCurrentBidResponse];
    self.lastBidResponse = response;
    
    // Set up Analytics tracking data
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
        
        [self.logger debug:[NSString stringWithFormat:@"Sent LOSS event for failed ad type %ld, reason=InternalError", (long)[self adType]]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Missing data for ad type %ld loss notification: bidID=%@, auctionID=%@", 
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
    [self.logger debug:@"State transitioned to READY"];
}

- (void)transitionToIdleState {
    self.currentState = CLXFullscreenAdStateIDLE;
    [self.logger debug:@"State transitioned to IDLE"];
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
        
        [self.logger debug:[NSString stringWithFormat:@"[PublisherFullscreenAd] Fired LOAD_SUCCESS event (nurl) for bidID=%@", bidID]];
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
        [self.logger debug:[NSString stringWithFormat:@"Firing RENDER_SUCCESS event (burl) for impression: bidID=%@, price=%.2f", bidID, winningBid.price]];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:bidID
                                 event:[CLXBidLifecycleEvent renderSuccessEvent]
                            lossReason:@(CLXLossReasonBidWon)
                        winnerBidPrice:winningBid.price];
        
        [self.logger debug:@"[PublisherFullscreenAd] RENDER_SUCCESS event (burl) fired"];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"No NURL to fire: bidID=%@, winningBid=%@", bidID, winningBid ? @"found" : @"not found"]];
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

