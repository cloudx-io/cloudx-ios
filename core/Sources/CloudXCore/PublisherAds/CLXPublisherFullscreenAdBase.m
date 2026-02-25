/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherFullscreenAdBase.m
 * @brief Base class implementation for fullscreen ads
 */

#import <CloudXCore/CLXPublisherFullscreenAdBase.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLossReasonMapper.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CloudXCoreInternal.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdapterLoader.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

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
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSString *adUnitName;
@property (nonatomic, assign) int64_t adLoadTimeoutMs;
@property (nonatomic, copy, nullable) NSString *rewardedCallbackUrl;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) CLXBidAdSource *bidAdSource;
@property (nonatomic, strong) CLXSettings *settings;

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
@property (nonatomic, strong, nullable) CLXError *deferredError;

// Requested ad unit ID for deferred initialization
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;

// Adapter load timing
@property (nonatomic, strong, nullable) NSDate *adapterLoadStartTime;

// Timeout configuration
@property (nonatomic, assign) NSTimeInterval bidRequestTimeout;

// Publisher-provided placement and customData (set at show time)
@property (nonatomic, copy, nullable) NSString *publisherPlacement;
@property (nonatomic, copy, nullable) NSString *publisherCustomData;

@end

@implementation CLXPublisherFullscreenAdBase

#pragma mark - Initialization

- (instancetype)initWithAdUnit:(nullable CLXSDKConfigAdUnit *)adUnit
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(nullable CLXConfigImpressionModel *)impModel
                      adFactories:(nullable CLXAdNetworkFactories *)adFactories
                  bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
               bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                reportingService:(id<CLXAdEventReporting>)reportingService
                        settings:(CLXSettings *)settings {
    self = [super init];
    if (self) {
        // Set up logging for this fullscreen ad instance
        _logger = [[CLXLogger alloc] initWithCategory:@"FullscreenAd"];

        [self.logger debug:[NSString stringWithFormat:@"Initializing fullscreen ad - AdUnit: %@, Type: %ld", adUnit.id ?: @"(deferred)", (long)[self adType]]];

        // Start in idle state, ready to load ads
        _currentState = CLXFullscreenAdStateIDLE;

        // Configure instance properties
        _adFactories = adFactories;
        _rewardedCallbackUrl = [rewardedCallbackUrl copy];
        _adUnitId = adUnit ? [adUnit.id copy] : nil;
        _adUnitName = adUnit ? [adUnit.name copy] : nil;
        _adLoadTimeoutMs = (adUnit && adUnit.adLoadTimeoutMs > 0) ? adUnit.adLoadTimeoutMs : CLXDefaultAdLoadTimeoutMs;
        _reportingService = reportingService;
        _userID = [userID copy];
        _settings = settings;
        _impModel = impModel;
        _bidRequestTimeout = bidRequestTimeout;
        
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

        // Configure bid source for ad request management (only if ad unit available)
        if (adUnit) {
            BOOL hasCloseButton = adUnit.hasCloseButton ?: NO;

            __weak typeof(self) weakSelf = self;
            _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                                   adUnitId:_adUnitId
                                                        dealID:adUnit.dealId
                                                 hasCloseButton:hasCloseButton
                                                   publisherID:publisherID
                                                        adType:[self adType]
                                                bidTokenSources:bidTokenSources
                                         nativeAdRequirements:nil
                                            bidRequestTimeout:_bidRequestTimeout
                                               reportingService:_reportingService
                                                   createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSError * _Nullable * _Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return nil;
                }

                return [strongSelf createAdapterWithAdId:adId
                                                   bidId:bidId
                                                     adm:adm
                                           adapterExtras:adapterExtras
                                                    burl:burl
                                                 network:network
                                                   error:error];
            }];
            [self.logger debug:[NSString stringWithFormat:@"Initialized fullscreen ad in IDLE state for ad unit: %@", _adUnitId]];
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

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying fullscreen ad for ad unit: %@", self.adUnitId]];
    
    // Remove notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLXSDKInitializedNotification object:nil];
    
    // Set state to destroyed
    self.currentState = CLXFullscreenAdStateDESTROYED;
    
    // Clean up current adapter
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }
}

- (void)dealloc {
    [self.logger debug:[NSString stringWithFormat:@"Deallocating fullscreen ad for ad unit: %@", _adUnitId]];
    
    // CRITICAL: Remove notification observer to prevent crashes if ad deallocated without destroy
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLXSDKInitializedNotification object:nil];
    
    // Clean up current adapter
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }
}

#pragma mark - Public Methods

- (void)load {
    // Check if destroyed - must be first to catch load-after-destroy scenario
    if (self.currentState == CLXFullscreenAdStateDESTROYED) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] Ad destroyed, cannot load"]];
        // Trigger error callback - publishers expect a response to API calls
        dispatch_async(dispatch_get_main_queue(), ^{
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                          description:@"Cannot load ad after destroy() has been called. Create a new ad instance to load another ad."];
            [self notifyLoadFailure:error];
        });
        return;
    }
    
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
        [self.logger info:[NSString stringWithFormat:@"SDK not yet initialized, queuing load request #%lu for ad unit: %@", (unsigned long)self.pendingLoadRequestCount, self.requestedAdUnitId ?: self.adUnitId]];
        return;
    }
    
    // SDK is ready, proceed with load
    [self performLoad];
}

// Internal method to actually perform the load operation
- (void)performLoad {
    // Check if we need to complete deferred initialization (bidAdSource is nil)
    if (!self.bidAdSource && self.requestedAdUnitId && [[CloudXCore shared] isInitialized]) {
        // SDK is now initialized - complete initialization with real ad unit config
        CLXSDKConfigAdUnit *realAdUnit = [[CloudXCore shared] adUnitConfigForId:self.requestedAdUnitId];
        if (realAdUnit) {
            [self.logger debug:[NSString stringWithFormat:@"Completing deferred initialization for: %@ (ID: %@)", self.requestedAdUnitId, realAdUnit.id]];
            _adUnitId = realAdUnit.id;
            _adUnitName = realAdUnit.name;
            _adLoadTimeoutMs = (realAdUnit.adLoadTimeoutMs > 0) ? realAdUnit.adLoadTimeoutMs : 10000;
            _bidRequestTimeout = realAdUnit.bidRequestTimeoutSeconds;

            // Create impression model now that SDK is initialized (ensures app.id is populated)
            NSString *auctionID = [[NSUUID UUID] UUIDString];
            self.impModel = [[CloudXCore shared] createImpModelWithAuctionID:auctionID];
            if (self.impModel) {
                [self.logger debug:[NSString stringWithFormat:@"Created impression model with appID: %@", self.impModel.sdkConfig.appID]];
            } else {
                [self.logger error:@"Failed to create impression model after SDK init"];
            }
            
            // Create bid source now
            BOOL hasCloseButton = realAdUnit.hasCloseButton ?: NO;
            NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources = self.adFactories.bidTokenSources;

            __weak typeof(self) weakSelf = self;
            self.bidAdSource = [[CLXBidAdSource alloc] initWithUserID:self.userID
                                                          adUnitId:_adUnitId
                                                               dealID:realAdUnit.dealId
                                                        hasCloseButton:hasCloseButton
                                                          publisherID:@""
                                                               adType:[self adType]
                                                       bidTokenSources:bidTokenSources
                                                nativeAdRequirements:nil
                                                    bidRequestTimeout:self.bidRequestTimeout
                                                      reportingService:self.reportingService
                                                          createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSError * _Nullable * _Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return nil;
                }

                return [strongSelf createAdapterWithAdId:adId
                                                   bidId:bidId
                                                     adm:adm
                                           adapterExtras:adapterExtras
                                                    burl:burl
                                                 network:network
                                                   error:error];
            }];
            
            // Clear the requested ad unit ID since initialization is complete
            self.requestedAdUnitId = nil;
        } else {
            // Provide detailed error message with available ad units (mirrors Android AdUnitValidator)
            NSArray<NSString *> *availableAdUnits = [[CloudXCore shared] availableAdUnitIds];
            NSString *availableAdUnitsString = availableAdUnits.count > 0 
                ? [availableAdUnits componentsJoinedByString:@", "] 
                : @"none";
            [self.logger error:[NSString stringWithFormat:@"Ad unit '%@' not found. Available: [%@]", self.requestedAdUnitId, availableAdUnitsString]];
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit 
                                          description:[NSString stringWithFormat:@"Ad unit '%@' not found in SDK configuration. Available ad units: [%@].", 
                                                      self.requestedAdUnitId, availableAdUnitsString]];
            [self handleBidResponse:nil error:error];
            return;
        }
    }
    
    // Generate correlation ID for this ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    [self.logger info:[NSString stringWithFormat:@"[%@] 🎬 [PublisherFullscreenAd] Ad load started - Ad Unit: %@, Type: %ld", self.currentCorrelationId, _adUnitId, (long)[self adType]]];
    
    // Check current state to determine if loading is allowed
    switch (self.currentState) {
        case CLXFullscreenAdStateIDLE:
            break;
        case CLXFullscreenAdStateLOADING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Already loading, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateREADY: {
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Already loaded, invoking success callback", self.currentCorrelationId]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyLoadSuccess];
            });
            return;
        }
        case CLXFullscreenAdStateSHOWING:
            [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherFullscreenAd] Currently showing, ignoring load request", self.currentCorrelationId]];
            return;
        case CLXFullscreenAdStateDESTROYED:
            // Defensive guard: DESTROYED state is already handled in load() at the top.
            // This case handles edge scenarios where performLoad() is called directly
            // (e.g., after SDK initialization notification when ad was destroyed while queued).
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Ad destroyed, cannot load", self.currentCorrelationId]];
            // Trigger error callback - publishers expect a response to API calls
            dispatch_async(dispatch_get_main_queue(), ^{
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                              description:@"Cannot load ad after destroy() has been called. Create a new ad instance to load another ad."];
                [self notifyLoadFailure:error];
            });
            return;
    }
    
    // Transition to loading state
    self.currentState = CLXFullscreenAdStateLOADING;
    [self.logger debug:[NSString stringWithFormat:@"[%@] State transitioned to LOADING", self.currentCorrelationId]];
    
    // Initiate bid request for ad content
    [self.bidAdSource requestBidWithAdUnitID:self.adUnitId
                           storedImpressionId:self.adUnitId
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
        [self.logger info:[NSString stringWithFormat:@"SDK initialized, executing %lu queued load request(s) for ad unit: %@", (unsigned long)queuedRequests, self.adUnitId]];
        self.pendingLoadRequestCount = 0;
        // Execute load once (multiple load() calls for same ad are redundant)
        [self performLoad];
    }
}

- (void)showFromViewController:(UIViewController *)viewController
                     placement:(nullable NSString *)placement
                    customData:(nullable NSString *)customData {
    [self.logger debug:[NSString stringWithFormat:@"showFromViewController called - Ready: %d, State: %ld, Placement: %@, CustomData: %@", self.isReady, (long)self.currentState, placement, customData]];

    // Store publisher-provided placement and customData for use in CLXAd creation
    self.publisherPlacement = placement;
    self.publisherCustomData = customData;

    // Wire placement/customData to tracking resolver
    NSString *auctionId = self.currentBidResponse.id;
    if (auctionId) {
        CLXTrackingFieldResolver *resolver = [CLXTrackingFieldResolver shared];
        if (placement) {
            [resolver setSdkParam:auctionId key:@"sdk.placement" value:placement];
        }
        if (customData) {
            [resolver setSdkParam:auctionId key:@"sdk.customData" value:customData];
        }
    }

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

    // Trust network adapters to manage their own ad dismiss lifecycle.
    // A force-close timer was previously here but caused premature dismissal
    // of legitimate ad experiences (e.g. playable end cards on rewarded ads).

    // Display the loaded ad using the appropriate adapter
    [self showCurrentAdapterFromViewController:viewController];
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self showFromViewController:viewController placement:nil customData:nil];
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
                             network:(NSString *)network
                               error:(NSError * _Nullable *)outError {
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

- (void)notifyLoadFailure:(CLXError *)error {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

- (void)notifyShowFailure:(CLXError *)error {
    [NSException raise:NSInternalInconsistencyException 
                format:@"Subclass must override %@", NSStringFromSelector(_cmd)];
}

#pragma mark - Protected Helper Methods

- (void)handleBidResponse:(CLXBidAdSourceResponse *)response error:(NSError *)error {
    if (error) {
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [PublisherFullscreenAd] Bid request failed: %@", self.currentCorrelationId, error.clx_fullErrorMessage]];
        
        // Transition back to idle
        self.currentState = CLXFullscreenAdStateIDLE;
        
        CLXError *clxError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeLoadFailed];
        
        // Call failure delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyLoadFailure:clxError];
        });
        return;
    }
    
    // Create adapter instance from bid response
    [self.logger debug:[NSString stringWithFormat:@"createBidAd - AdID: %@, BidID: %@, Network: %@", response.bid.adid, response.bidID, response.networkName]];
    
    NSError *creationError = nil;
    id adapter = response.createBidAd(&creationError);
    if (!adapter) {
        NSString *errorDescription = creationError.localizedDescription ?: @"Failed to create adapter";
        [self.logger error:[NSString stringWithFormat:@"Failed to create adapter from bid response: %@", errorDescription]];
        [self handleBidResponse:nil error:[CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                                      description:errorDescription]];
        return;
    }
    
    // Store bid response for NURL firing
    self.currentBidResponse = [self.bidAdSource getCurrentBidResponse];
    self.lastBidResponse = response;
    
    // Set up Analytics tracking data
    [self.rillTrackingService setupTrackingDataFromBidResponse:response
                                                      impModel:self.impModel
                                                   adUnitId:self.adUnitId
                                                     loadCount:0];
    
    // Track adapter load start time for latency metrics
    self.adapterLoadStartTime = [NSDate date];
    
    // Configure adapter delegate and initiate loading with timeout protection
    [self setupAdapterAndLoad:adapter];
}

- (void)sendLossNotificationForFailedAdWithError:(nullable NSError *)error {
    if (self.lastBidResponse && self.lastBidResponse.bid.id && self.currentBidResponse && self.currentBidResponse.id) {
        CLXLossReason lossReason = [CLXLossReasonMapper lossReasonFromError:error];
        
        [self.winLossTracker setBidLoadResult:self.currentBidResponse.id 
                                       bidId:self.lastBidResponse.bid.id 
                                     success:NO 
                                  lossReason:@(lossReason)];
        
        CLXError *clxError = [error isKindOfClass:[CLXError class]] ? (CLXError *)error : nil;
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                  bidId:self.lastBidResponse.bid.id
                                  event:[CLXBidLifecycleEvent lossEvent]
                             lossReason:@(lossReason)
                         winnerBidPrice:-1.0
                                  error:clxError];
        
        [self.logger debug:[NSString stringWithFormat:@"Sent LOSS event for failed ad type %ld, reason=%ld", (long)[self adType], (long)lossReason]];
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

#pragma mark - Private Cleanup Helpers

/**
 * Cleans up ad display state. Called when ad display ends (close or failure).
 * Follows DRY principle - shared by handleAdClose and handleShowFailure.
 */
- (void)cleanupAdDisplayState {
    // Destroy the adapter (delegates to subclass via getCurrentAdapter)
    id currentAdapter = [self getCurrentAdapter];
    if (currentAdapter && [currentAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)currentAdapter destroy];
    }

    // Transition back to idle
    self.currentState = CLXFullscreenAdStateIDLE;
}

- (BOOL)handleAdClose {
    if (self.currentState != CLXFullscreenAdStateSHOWING) {
        [self.logger warn:@"Ignoring duplicate adapter close callback"];
        return NO;
    }
    [self cleanupAdDisplayState];
    return YES;
}

/**
 * Handles show failure cleanup. Clears state BEFORE callback to allow immediate reload.
 * Fixes: Publishers can now call load() in didFailToDisplayAd callback.
 */
- (void)handleShowFailure {
    [self cleanupAdDisplayState];
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
                        winnerBidPrice:price
                                 error:nil];
        
        [self.logger debug:[NSString stringWithFormat:@"[PublisherFullscreenAd] Fired LOAD_SUCCESS event (nurl) for bidID=%@", bidID]];
    }
}

- (void)fireRenderSuccessEventForBidID:(NSString *)bidID adType:(CLXAdType)adType {
    [[CLXSessionMetricsTracker sharedInstance] recordImpressionForAdUnit:self.adUnitName adType:adType];
    [self.rillTrackingService sendImpressionEvent];
    
    CLXBidResponseBid *winningBid = [self.currentBidResponse findBidWithID:bidID];
    if (winningBid && bidID && self.currentBidResponse && self.currentBidResponse.id) {
        [self.logger debug:[NSString stringWithFormat:@"Firing RENDER_SUCCESS event (burl) for impression: bidID=%@, price=%.2f", bidID, winningBid.price]];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:bidID
                                 event:[CLXBidLifecycleEvent renderSuccessEvent]
                            lossReason:@(CLXLossReasonBidWon)
                        winnerBidPrice:winningBid.price
                                 error:nil];
        
        [self.logger debug:@"[PublisherFullscreenAd] RENDER_SUCCESS event (burl) fired"];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"No NURL to fire: bidID=%@, winningBid=%@", bidID, winningBid ? @"found" : @"not found"]];
    }
}

- (void)handleClickTracking {
    [self.logger debug:@"Clicked on ad"];
    [self.rillTrackingService sendClickEvent];
}

- (CLXAd *)createAdObject {
    // Determine ad format based on ad type
    CLXAdFormat adFormat = ([self adType] == CLXAdTypeRewarded) ? CLXAdFormatRewarded : CLXAdFormatInterstitial;

    return [CLXAd adFromBid:self.lastBidResponse.bid
                adUnitId:self.adUnitId
              adUnitName:self.adUnitName
                   adFormat:adFormat
                  placement:self.publisherPlacement];
}

- (void)trackAdapterLoadLatencyWithError:(nullable NSError *)error {
    if (self.adapterLoadStartTime) {
        NSTimeInterval latencyMs = [[NSDate date] timeIntervalSinceDate:self.adapterLoadStartTime] * 1000;
        
        // Nil-safe tracking (matching Android's optional chaining)
        id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
        if (metricsTracker) {
            [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkAdapterLoad 
                                     latency:(NSInteger)latencyMs
                                       error:error];
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Tracked adapter load latency: %.0fms%@", 
                           latencyMs, error ? @" (failed)" : @""]];
        
        // Reset for next load
        self.adapterLoadStartTime = nil;
    }
}

@end

NS_ASSUME_NONNULL_END

