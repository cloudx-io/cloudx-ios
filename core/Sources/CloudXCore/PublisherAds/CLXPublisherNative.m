/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherNative.m
 * @brief Publisher native ad implementation
 */

#import <CloudXCore/CLXPublisherNative.h>

#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLossReasonMapper.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXDIContainer.h>

#import <CloudXCore/CLXBannerTimerService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXDebugOverlayManager.h>
#import <CloudXCore/CLXDebugClickFeedback.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CloudXCoreInternal.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPublisherNative () <CLXAdapterNativeDelegate>

// CLXAdLifecycle properties
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL isDestroyed;

// Correlation ID for request tracing
@property (nonatomic, copy, nullable) NSString *currentCorrelationId;

// Private properties
@property (nonatomic, strong, nullable) CLXBidAdSource *bidAdSource;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *adFactories;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> currentLoadingNative;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> previousNative;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> nativeOnScreen;
@property (nonatomic, assign) NSTimeInterval refreshSeconds;
@property (nonatomic, strong) CLXBannerTimerService *timerService;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSString *adUnitName;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong, nullable) id requestNativeTask;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL successWin;
@property (nonatomic, assign) NSInteger loadNativeTimesCount;
@property (nonatomic, strong) CLXSDKConfigAdUnit *adUnit;
@property (nonatomic, strong, nullable) NSDate *adLoadStartTime;

// Analytics tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) CLXConfigImpressionModel *impModel;
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;

// Queued load request handling (for SDK init race condition)
@property (nonatomic, assign) NSUInteger pendingLoadRequestCount;

// Store requested ad unit ID for deferred initialization
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;

// Deferred error (set during create if validation fails)
@property (nonatomic, strong, nullable) CLXError *deferredError;

// Store bid token sources for deferred initialization
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources;

@end

@implementation CLXPublisherNative



#pragma mark - Initialization

- (instancetype)initWithViewController:(UIViewController *)viewController
                             adUnit:(nullable CLXSDKConfigAdUnit *)adUnit
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXAdapterNativeDelegate>)delegate
                             nativeType:(CLXNativeTemplate)nativeType
                               impModel:(nullable CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *)adFactories
                           bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                         reportingService:(id<CLXAdEventReporting>)reportingService {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _refreshSeconds = (adUnit.bannerRefreshRateMs ?: 10000) / 1000.0;
        _adUnitId = [adUnit.id copy];
        _adUnitName = [adUnit.name copy];
        _reportingService = reportingService;
        _adUnit = adUnit;
        _adFactories = adFactories;
        _bidTokenSources = bidTokenSources; // Store for deferred init
        _impModel = impModel;
        _isReady = NO;
        _isLoading = NO;
        _isDestroyed = NO;
        _forceStop = NO;
        _successWin = NO;
        _loadNativeTimesCount = 0;
        _pendingLoadRequestCount = 0;
        _delegate = delegate;
        
        // Initialize Analytics tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:reportingService];
        
        // Listen for SDK initialization completion (internal notification)
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleSDKInitialized:) 
                                                     name:CLXSDKInitializedNotification 
                                                   object:nil];
        
        // Initialize win/loss tracker
        _winLossTracker = [CLXWinLossTracker shared];
        
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXNative"];

        // Initialize timer service
        _timerService = [[CLXBannerTimerService alloc] init];

        // Only create bidAdSource if ad unit is available (defer if SDK not initialized)
        if (adUnit) {
            __weak typeof(self) weakSelf = self;

            _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                                   adUnitId:_adUnitId
                                                        dealID:adUnit.dealId
                                                 hasCloseButton:NO
                                                   publisherID:publisherID
                                                        adType:CLXAdTypeNative
                                                bidTokenSources:bidTokenSources
                                         nativeAdRequirements:[CLXNativeTemplateHelper nativeAdRequirementsForTemplate:nativeType]
                                            bidRequestTimeout:adUnit.bidRequestTimeoutSeconds
                                               reportingService:_reportingService
                                                   createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSError * _Nullable * _Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return nil;
                return [strongSelf createNativeInstanceWithAdId:adId
                                                          bidId:bidId
                                                             adm:adm
                                                   adapterExtras:adapterExtras
                                                            burl:burl
                                                          network:network
                                                            error:error];
            }];
            
            [_logger debug:[NSString stringWithFormat:@"Initialized CLXPublisherNative for ad unit: %@", _adUnitId]];
        } else {
            [_logger debug:@"Initialized CLXPublisherNative with deferred ad unit (SDK not yet initialized)"];
        }
    }
    return self;
}

#pragma mark - Lifecycle

- (void)dealloc {
    // CRITICAL: Remove notification observer to prevent crashes if native ad deallocated without destroy
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLXSDKInitializedNotification object:nil];
}

#pragma mark - CloudXNative Protocol

/// Checks if the native ad has been destroyed and triggers error callback if so.
/// @return YES if destroyed (caller should return early), NO otherwise.
- (BOOL)handleDestroyedStateError {
    if (!self.forceStop) {
        return NO;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Native load stopped due to forceStop flag for ad unit: %@", self.adUnitId]];
    // Trigger error callback - publishers expect a response to API calls
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                          description:@"Cannot load ad after destroy() has been called. Create a new ad instance to load another ad."];
            [self.logger logDelegateError:@"❌ Native didFailToLoadAd" error:error];
            [self.delegate didFailToLoadAd:self.adUnitId error:error];
        }
    });
    
    return YES;
}

- (void)load {
    // Check if destroyed - must be first to catch load-after-destroy scenario
    if ([self handleDestroyedStateError]) {
        return;
    }
    
    // Check for deferred error from create method
    if (self.deferredError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
                [self.logger logDelegateError:@"❌ Native didFailToLoadAd" error:self.deferredError];
                [self.delegate didFailToLoadAd:self.adUnitId error:self.deferredError];
            }
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
    // Defensive guard: forceStop is already handled in load(), but check again in case
    // performLoad() is called directly (e.g., after SDK initialization notification)
    if ([self handleDestroyedStateError]) {
        return;
    }
    
    // Check if we need to complete deferred initialization (bidAdSource is nil)
    if (!self.bidAdSource && self.requestedAdUnitId && [[CloudXCore shared] isInitialized]) {
        // SDK is now initialized - complete initialization with real ad unit config
        CLXSDKConfigAdUnit *realAdUnit = [[CloudXCore shared] adUnitConfigForId:self.requestedAdUnitId];
        if (realAdUnit) {
            [self.logger debug:[NSString stringWithFormat:@"Completing deferred initialization for: %@ (ID: %@)", self.requestedAdUnitId, realAdUnit.id]];
            
            self.adUnit = realAdUnit;
            self.adUnitId = realAdUnit.id;
            self.adUnitName = realAdUnit.name;
            self.refreshSeconds = (realAdUnit.bannerRefreshRateMs ?: 10000) / 1000.0;
            
            // Create impression model now that SDK is initialized
            NSString *auctionID = [[NSUUID UUID] UUIDString];
            self.impModel = [[CloudXCore shared] createImpModelWithAuctionID:auctionID];
            if (self.impModel) {
                [self.logger debug:[NSString stringWithFormat:@"Created impression model with appID: %@", self.impModel.sdkConfig.appID]];
            } else {
                [self.logger error:@"Failed to create impression model after SDK initialization"];
            }
            
            // Create bid source now that we have real ad unit data
            self.bidAdSource = [self createBidAdSourceForAdUnit:realAdUnit];
            
            // Clear the requested ad unit ID since initialization is complete
            self.requestedAdUnitId = nil;
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
                // Provide detailed error message with available ad units (mirrors Android AdUnitValidator)
                NSArray<NSString *> *availableAdUnits = [[CloudXCore shared] availableAdUnitIds];
                NSString *availableAdUnitsString = availableAdUnits.count > 0 
                    ? [availableAdUnits componentsJoinedByString:@", "] 
                    : @"none";
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit 
                                              description:[NSString stringWithFormat:@"Ad unit '%@' not found in SDK configuration. Available ad units: [%@].", 
                                                          self.requestedAdUnitId, availableAdUnitsString]];
                [self.logger logDelegateError:@"❌ Native didFailToLoadAd" error:error];
                [self.delegate didFailToLoadAd:self.adUnitId error:error];
            }
            return;
        }
    }
    
    // Generate correlation ID for this ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    if (self.isLoading) {
        [self.logger debug:[NSString stringWithFormat:@"[%@] Native load already in progress", self.currentCorrelationId]];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"[%@] 🎬 [PublisherNative] Ad load started for ad unit: %@", self.currentCorrelationId, self.adUnitId]];
    self.isLoading = YES;
    
    // Implement async native update request
    [self requestNativeUpdate];
}

// Helper method to create bid ad source for an ad unit
- (CLXBidAdSource *)createBidAdSourceForAdUnit:(CLXSDKConfigAdUnit *)adUnit {
    __weak typeof(self) weakSelf = self;
    return [[CLXBidAdSource alloc] initWithUserID:@""
                                      adUnitId:adUnit.id
                                           dealID:adUnit.dealId
                                    hasCloseButton:NO
                                      publisherID:@""
                                           adType:CLXAdTypeNative
                                   bidTokenSources:self.bidTokenSources
                            nativeAdRequirements:[CLXNativeTemplateHelper nativeAdRequirementsForTemplate:CLXNativeTemplateDefault]
                                bidRequestTimeout:adUnit.bidRequestTimeoutSeconds
                                  reportingService:self.reportingService
                                      createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSError * _Nullable * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return nil;
        return [strongSelf createNativeInstanceWithAdId:adId
                                                  bidId:bidId
                                                     adm:adm
                                           adapterExtras:adapterExtras
                                                    burl:burl
                                                  network:network
                                                    error:error];
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



#pragma mark - Private Methods

- (void)requestNativeUpdate {
    if (self.forceStop) {
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] [PublisherNative] Requesting native update", self.currentCorrelationId]];
    
    // Request bid from bid ad source
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.adUnitId
                           storedImpressionId:self.adUnitId
                                    impModel:self.impModel
                                   successWin:self.successWin
                                correlationId:self.currentCorrelationId
                                   completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"[%@] Bid request failed: %@", strongSelf.currentCorrelationId, error.clx_fullErrorMessage]];
            [strongSelf failToLoadWithNative:nil error:error];
            return;
        } else {
            strongSelf.lastBidResponse = response;
            
            // Store the full bid response for LURL firing by getting it from bidAdSource
            strongSelf.currentBidResponse = [strongSelf.bidAdSource getCurrentBidResponse];
            
            // Set up Analytics tracking data
            [strongSelf.rillTrackingService setupTrackingDataFromBidResponse:response
                                                                    impModel:strongSelf.impModel
                                                                 adUnitId:strongSelf.adUnitId
                                                                   loadCount:0];
            
            strongSelf.loadNativeTimesCount += 1;
            
            // Handle bid response
            if (response) {
                [strongSelf.logger debug:[NSString stringWithFormat:@"Received bid response for network: %@", response.networkName]];
            }
            
            // Continue native chain
            [strongSelf continueNativeChain];
        }
    }];
}

- (void)continueNativeChain {
    if (self.forceStop) {
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Continuing native chain for ad unit: %@", self.adUnitId]];
    
    // Implement actual native creation from bid response
    if (self.lastBidResponse && self.lastBidResponse.createBidAd) {
        NSError *creationError = nil;
        id bidItem = self.lastBidResponse.createBidAd(&creationError);
        if ([bidItem conformsToProtocol:@protocol(CLXAdapterNative)]) {
        id<CLXAdapterNative> native = (id<CLXAdapterNative>)bidItem;
            [self.logger debug:[NSString stringWithFormat:@"Successfully created native from bid for ad unit: %@", self.adUnitId]];
            [self loadAdItem:native];
        } else {
            NSString *errorDescription = creationError.localizedDescription ?: @"No valid native created from bid response";
            [self.logger debug:[NSString stringWithFormat:@"Native creation failed for ad unit: %@", errorDescription]];
            self.isLoading = NO;
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidResponse description:errorDescription];
            [self failToLoadWithNative:nil error:error];
        }
    } else {
        [self.logger debug:@"No valid native created from bid for ad unit"];
        self.isLoading = NO;
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidResponse description:@"No valid native created from bid response"];
        [self failToLoadWithNative:nil error:error];
    }
}

- (nullable id<CLXAdapterNative>)createNativeInstanceWithAdId:(NSString *)adId
                                                          bidId:(NSString *)bidId
                                                             adm:(NSString *)adm
                                                   adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                                            burl:(nullable NSString *)burl
                                                          network:(NSString *)network
                                                            error:(NSError * _Nullable *)outError {
    [self.logger debug:[NSString stringWithFormat:@"Creating native instance - AdID: %@, BidID: %@, Network: %@", adId, bidId, network]];
    
    id<CLXAdapterNativeFactory> factory = self.adFactories[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"No factory found for network: %@", network]];
        [CLXError setError:outError code:CLXErrorCodeLoadFailed description:[NSString stringWithFormat:@"No native factory found for network: %@", network]];
        return nil;
    }
    
    if (!self.viewController) {
        [self.logger error:@"No view controller available for native creation"];
        [CLXError setError:outError code:CLXErrorCodeLoadFailed description:@"No view controller available for native creation"];
        return nil;
    }
    
    id<CLXAdapterNative> creativeNative = [factory createWithViewController:self.viewController
                                                                          type:_nativeType
                                                                          adId:adId
                                                                         bidId:bidId
                                                                            adm:adm
                                                                        extras:adapterExtras
                                                                  adUnitName:self.adUnitName
                                                                      delegate:self];
    
    if (!creativeNative) {
        [self.logger error:[NSString stringWithFormat:@"Factory failed to create native for network: %@", network]];
        [CLXError setError:outError code:CLXErrorCodeLoadFailed description:[NSString stringWithFormat:@"Native factory returned nil for network: %@", network]];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Successfully created native instance for network: %@", network]];
    return creativeNative;
}

- (void)timerDidReachEnd {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previousNative = self.currentLoadingNative;
        [self requestNativeUpdate];
    });
}

- (void)loadAdItem:(id<CLXAdapterNative>)item {
    [self.logger debug:[NSString stringWithFormat:@"Instantiating AdapterNative: %@", NSStringFromClass([item class])]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.logger debug:[NSString stringWithFormat:@"Calling load() on AdapterNative: %@", NSStringFromClass([item class])]];
        item.timeout = NO;
        self.currentLoadingNative = item;
        self.adLoadStartTime = [NSDate date];
        [item load];
    });
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

#pragma mark - CLXAdapterNativeDelegate

- (void)closeWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:@"Native clicked"];
    [native destroy];
    self.loadNativeTimesCount = 0;
    
    if ([self.delegate respondsToSelector:@selector(closeWithNative:)]) {
        [self.delegate closeWithNative:native];
    }
}

- (void)didLoadWithNative:(id<CLXAdapterNative>)native {
    if (native.timeout) {
        [native destroy];
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Native did load %@", self.adUnitId]];
    NSTimeInterval latency = 0;
    if (self.adLoadStartTime) {
        latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
    }


    // Track adapter load latency with metrics tracker
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkAdapterLoad latency:(NSInteger)latency error:nil];
    }
    
    [self.previousNative setDelegate:nil];
    [self.previousNative destroy];
    [[self.previousNative nativeView] removeFromSuperview];
    
    self.nativeOnScreen = self.currentLoadingNative;
    self.successWin = YES;
    
    // Fire LOAD_SUCCESS lifecycle event (nurl)
    if (self.lastBidResponse.bidID && self.currentBidResponse && self.currentBidResponse.id) {
        [self.winLossTracker setBidLoadResult:self.currentBidResponse.id 
                                        bidId:self.lastBidResponse.bidID 
                                      success:YES 
                                   lossReason:nil];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:self.lastBidResponse.bidID
                                 event:[CLXBidLifecycleEvent loadSuccessEvent]
                            lossReason:@(CLXLossReasonBidWon)
                        winnerBidPrice:self.lastBidResponse.price];
        
        [self.logger debug:[NSString stringWithFormat:@"[PublisherNative] Fired LOAD_SUCCESS event (nurl) for native bidID=%@", self.lastBidResponse.bidID]];
    }
    
    // Winner has successfully loaded, now fire loss notifications for all losing bids
    [self fireLosingBidLurls];
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
        [self.delegate didLoadWithNative:native];
    }
    if ([self.delegate respondsToSelector:@selector(didLoadAd:)]) {
        CLXAd *delegateAd = [CLXAd adFromBid:self.lastBidResponse.bid
                                 adUnitId:self.adUnitId
                               adUnitName:self.adUnitName
                                    adFormat:CLXAdFormatNative
                                   placement:nil];
        [self.logger logDelegateCallback:@"✅ Native didLoadAd" ad:delegateAd];
        [self.delegate didLoadAd:delegateAd];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
        [weakSelf timerDidReachEnd];
    }];
}

- (void)failToLoadWithNative:(nullable id<CLXAdapterNative>)native error:(nullable NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Native fail to load %@", error.localizedDescription ?: @"unknown"]];


    // Track adapter load latency with metrics tracker (failure)
    if (self.adLoadStartTime) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
        id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
        if (metricsTracker) {
            [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkAdapterLoad latency:(NSInteger)latency error:error];
        }
    }
    
    if (native && native.timeout) {
        [native destroy];
        return;
    }
    
    // Send server-side loss notification for technical errors
    if (self.lastBidResponse && self.lastBidResponse.bid.id && self.currentBidResponse && self.currentBidResponse.id) {
        CLXLossReason lossReason = [CLXLossReasonMapper lossReasonFromError:error];
        
        [self.winLossTracker setBidLoadResult:self.currentBidResponse.id 
                                       bidId:self.lastBidResponse.bid.id 
                                     success:NO 
                                  lossReason:@(lossReason)];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                  bidId:self.lastBidResponse.bid.id
                                  event:[CLXBidLifecycleEvent lossEvent]
                             lossReason:@(lossReason)
                         winnerBidPrice:-1.0];
        
        [self.logger debug:[NSString stringWithFormat:@"Sent LOSS event for failed native ad, reason=%ld", (long)lossReason]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Missing data for native loss notification: bidID=%@, auctionID=%@", 
                           self.lastBidResponse.bid.id ?: @"(nil)", self.currentBidResponse.id ?: @"(nil)"]];
    }
    
    [native destroy];
    self.lastBidResponse = nil;
    self.currentBidResponse = nil;
    self.successWin = NO;

    // Call both old and new delegate methods for backward compatibility
    // Preserve the original error to maintain detailed server messages
    // Ensure we always have a valid CLXError for delegate (fallback if error is nil)
    CLXError *delegateError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeLoadFailed];
    if (!delegateError) {
        delegateError = [CLXError errorWithCode:CLXErrorCodeLoadFailed];
    }
    
    if ([self.delegate respondsToSelector:@selector(failToLoadWithNative:error:)]) {
        [self.delegate failToLoadWithNative:native error:delegateError];
    }
    if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
        [[CLXDebugOverlayManager shared] flashError];
        [self.logger logDelegateError:@"❌ Native didFailToLoadAd" error:delegateError];
        [self.delegate didFailToLoadAd:self.adUnitId error:delegateError];
    }
}

- (void)didShowWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:@"Native ad shown"];
    
    // NEW: Record session depth impression (iOS feature parity with Android)
    [[CLXSessionMetricsTracker sharedInstance] recordImpressionForAdUnit:self.adUnitName adType:CLXAdTypeNative];
    
    // Report impression if we have a bid response
    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"Reporting impression for bidID=%@", self.lastBidResponse.bidID]];
    }
    
    if ([self.delegate respondsToSelector:@selector(didShowWithNative:)]) {
        [self.delegate didShowWithNative:native];
    }
}

- (void)impressionWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:[NSString stringWithFormat:@"Native impression %@", self.adUnitId]];
    
    if (self.lastBidResponse) {
        // Send Analytics tracking impression event
        [self.rillTrackingService sendImpressionEvent];
        
        // Fire RENDER_SUCCESS lifecycle event (burl) on impression
        if (self.lastBidResponse.bidID && self.currentBidResponse && self.currentBidResponse.id) {
            [self.logger debug:[NSString stringWithFormat:@"Firing RENDER_SUCCESS event (burl) for native impression: bidID=%@, price=%.2f", self.lastBidResponse.bidID, self.lastBidResponse.price]];
            
            [self.winLossTracker sendEvent:self.currentBidResponse.id
                                     bidId:self.lastBidResponse.bidID
                                     event:[CLXBidLifecycleEvent renderSuccessEvent]
                                lossReason:@(CLXLossReasonBidWon)
                            winnerBidPrice:self.lastBidResponse.price];
            
            [self.logger debug:@"[PublisherNative] RENDER_SUCCESS event (burl) fired"];

            // Trigger revenue callback immediately (no longer depends on NURL network call)
            CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid
                                   adUnitId:self.adUnitId
                                 adUnitName:self.adUnitName
                                      adFormat:CLXAdFormatNative
                                     placement:nil];
            if (self.revenueDelegate && [self.revenueDelegate respondsToSelector:@selector(didPayRevenueForAd:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.revenueDelegate didPayRevenueForAd:adObject];
                });
            }
        } else {
            [self.logger debug:[NSString stringWithFormat:@"Missing auction ID or bid ID for win notification: bidID=%@, auctionID=%@", 
                               self.lastBidResponse.bidID ?: @"(nil)", self.currentBidResponse.id ?: @"(nil)"]];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:native];
    }
}

- (void)clickWithNative:(id<CLXAdapterNative>)native {
    [self.rillTrackingService sendClickEvent];
    
    // Show click confirmed feedback - stops pending animation and shows green border
    if (native.nativeView) {
        [CLXDebugClickFeedback showClickConfirmedOnView:native.nativeView];
    }
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:native];
    }
    if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
        CLXAd *clickAd = [CLXAd adFromBid:self.lastBidResponse.bid
                              adUnitId:self.adUnitId
                            adUnitName:self.adUnitName
                                 adFormat:CLXAdFormatNative
                                placement:nil];
        [self.logger logDelegateCallback:@"👆 Native didClickAd" ad:clickAd];
        [self.delegate didClickAd:clickAd];
    }
}

#pragma mark - CLXAdLifecycle

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying native ad for ad unit: %@", self.adUnitId]];
    
    self.isDestroyed = YES;
    self.isLoading = NO;
    self.isReady = NO;
    
    // Clean up any ongoing operations
    self.forceStop = YES;
    
    // Clean up current native
    if (self.nativeOnScreen) {
        [self.nativeOnScreen destroy];
        self.nativeOnScreen = nil;
    }
    
    // Clean up loading native
    if (self.currentLoadingNative) {
        [self.currentLoadingNative destroy];
        self.currentLoadingNative = nil;
    }
    
    // Clean up previous native
    if (self.previousNative) {
        [self.previousNative destroy];
        self.previousNative = nil;
    }
}


@end

NS_ASSUME_NONNULL_END 
