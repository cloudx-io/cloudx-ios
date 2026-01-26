/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file PublisherBanner.m
 * @brief Publisher banner implementation
 */

#import <CloudXCore/CLXPublisherBanner.h>

#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXAdType.h>

#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLossReasonMapper.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXBannerTimerService.h>


#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDebugOverlayManager.h>
#import <CloudXCore/CLXDebugClickFeedback.h>

NS_ASSUME_NONNULL_BEGIN

// Private category to access internal SDK methods (framework-internal only, not exposed in public API)
@interface CloudXCore (Internal)
@property (nonatomic, strong, readonly) CLXAdNetworkFactories *adNetworkFactories;
- (nullable CLXConfigImpressionModel *)createImpModelWithAuctionID:(NSString *)auctionID;
@end

@interface CLXPublisherBanner () <CLXAdapterBannerDelegate>

// CLXAdLifecycle properties
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL isDestroyed;

@property (nonatomic, strong, readwrite) CLXSettings *settings;

// Correlation ID for request tracing
@property (nonatomic, copy, nullable) NSString *currentCorrelationId;

// Private properties
@property (nonatomic, strong, nullable) id<CLXBidAdSourceProtocol> bidAdSource;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> currentLoadingBanner;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> previousBanner;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> bannerOnScreen;
@property (nonatomic, assign) NSTimeInterval refreshSeconds;
@property (nonatomic, strong) CLXBannerTimerService *timerService;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *placementName;
@property (nonatomic, copy, nullable) NSString *dealID;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong, nullable) id requestBannerTask;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL successWin;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong, nullable) NSDate *lastManualRefreshTime;
@property (nonatomic, assign) CLXBannerType bannerType;

// Visibility and prefetch properties
@property (nonatomic, assign, readwrite) BOOL isVisible;
@property (nonatomic, assign) BOOL hasPendingRefresh;
// Set to YES after load failure to allow retry even when not visible
@property (nonatomic, assign) BOOL bypassVisibilityCheck;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> prefetchedBanner;
@property (nonatomic, copy) NSString *placementSuffix;
@property (nonatomic, assign) NSInteger impressionIndexStart;
@property (nonatomic, assign) NSInteger impressionIndexEnd;
@property (nonatomic, strong, nullable) CLXSDKConfigPlacement *placement;
@property (nonatomic, strong, nullable) CLXConfigImpressionModel *impModel;
@property (nonatomic, strong, nullable) NSNumber *tmax;
@property (nonatomic, copy, nullable) NSString *requestedPlacementName; // Stored for deferred initialization

// Store the last bid request error to preserve detailed server messages
@property (nonatomic, strong, nullable) NSError *lastBidError;
@property (nonatomic, strong, nullable) NSDate *adLoadStartTime;
// Analytics tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) CLXAppSessionService *appSessionService;
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;

// Queued load request handling (for SDK init race condition)
@property (nonatomic, assign) NSUInteger pendingLoadRequestCount;

// Deferred error (set during create if validation fails)
@property (nonatomic, strong, nullable) CLXError *deferredError;

// Injected factories for testability (falls back to CloudXCore if empty)
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *adFactories;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources;

@end

@implementation CLXPublisherBanner

#pragma mark - Initialization

- (instancetype)initWithViewController:(UIViewController *)viewController
                             placement:(nullable CLXSDKConfigPlacement *)placement
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXBannerDelegate>)delegate
                             bannerType:(CLXBannerType)bannerType
                               impModel:(nullable CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *)adFactories
                           bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                         reportingService:(id<CLXAdEventReporting>)reportingService
                              settings:(CLXSettings *)settings
                                     tmax:(nullable NSNumber *)tmax {
    self = [super init];
    if (self) {
        _settings = settings;
        _tmax = tmax;
        _suspendPreloadWhenInvisible = suspendPreloadWhenInvisible;
        _delegate = delegate;
        _bannerType = bannerType;
        _viewController = viewController;
        _adFactories = [adFactories copy];
        _bidTokenSources = [bidTokenSources copy];
        
        // Initialize from placement config if available, otherwise defer
        if (placement) {
            _refreshSeconds = (placement.bannerRefreshRateMs ?: 10000) / 1000.0;
            _placementID = [placement.id copy];
            _placementName = [placement.name copy];
            _dealID = [placement.dealId copy];
            _placement = placement;
            _placementSuffix = [placement.firstImpressionPlacementSuffix ?: @"" copy];
            _impressionIndexStart = placement.firstImpressionLoopIndexStart ?: 0;
            _impressionIndexEnd = placement.firstImpressionLoopIndexEnd ?: 0;
        } else {
            // SDK not initialized - set defaults, real values will be populated in performLoad
            _refreshSeconds = 30.0; // Default refresh
            _placementID = nil;
            _placementName = nil; // Will be set via KVC
            _dealID = nil;
            _placement = nil;
            _placementSuffix = @"";
            _impressionIndexStart = 0;
            _impressionIndexEnd = 0;
        }
        
        _reportingService = reportingService;
        _impModel = impModel;
        _isLoading = NO;
        _isDestroyed = NO;
        _forceStop = NO;
        _successWin = NO;
        _autoRefreshEnabled = YES; // Auto-refresh is enabled by default
        _pendingLoadRequestCount = 0;
        // Initialize Analytics tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:reportingService];
        
        // Listen for SDK initialization completion (internal notification)
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleSDKInitialized:) 
                                                     name:CLXSDKInitializedNotification 
                                                   object:nil];
        
        // Initialize win/loss tracker
        _winLossTracker = [CLXWinLossTracker shared];
        
        NSString *logCategory = (bannerType == CLXBannerTypeMREC) ? @"CloudXMREC" : @"CloudXBanner";
        _logger = [[CLXLogger alloc] initWithCategory:logCategory];
        
        // Initialize visibility and prefetch properties
        _isVisible = YES;
        _hasPendingRefresh = NO;
        _bypassVisibilityCheck = NO;
        _prefetchedBanner = nil;
        
        // Initialize timer service
        _timerService = [[CLXBannerTimerService alloc] init];
        
        // Initialize app session service (singleton)
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreBannerAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreBannerSessionIDKey] ?: @"";
        // Use metrics URL from SDK response (stored in user defaults)
        NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        _appSessionService = [[CLXAppSessionService alloc] initWithSessionID:sessionID
                                                                                 appKey:appKey
                                                                                    url:metricsURL];
        
        // Initialize bid ad source only if placement is available
        if (placement) {
            _bidAdSource = [self createBidAdSourceForPlacement:placement];
        } else {
            // SDK not initialized - bid source will be created in performLoad
            _bidAdSource = nil;
            [_logger debug:@"Deferring bid source creation until SDK initialization"];
        }
        
        [_logger debug:[NSString stringWithFormat:@"Initialized PublisherBanner for placement: %@", _placementID]];
    }
    return self;
}

- (void)dealloc {
    // CRITICAL: Remove notification observer to prevent crashes if banner deallocated without destroy
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - CloudXBanner Protocol

/// Checks if the banner has been destroyed and triggers error callback if so.
/// @return YES if destroyed (caller should return early), NO otherwise.
- (BOOL)handleDestroyedStateError {
    if (!self.forceStop) {
        return NO;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Banner load stopped due to forceStop flag for placement: %@", self.placementID]];
    // Trigger error callback - publishers expect a response to API calls
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                          description:@"Cannot load ad after destroy() has been called. Create a new ad instance to load another ad."];
            [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:error];
            [self.delegate didFailToLoadAd:self.placementName error:error];
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
                [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:self.deferredError];
                [self.delegate didFailToLoadAd:self.placementName error:self.deferredError];
            }
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
            
            self.placement = realPlacement;
            self.placementID = realPlacement.id;
            self.placementName = realPlacement.name;
            self.dealID = realPlacement.dealId;
            self.refreshSeconds = (realPlacement.bannerRefreshRateMs ?: 30000) / 1000.0;
            self.placementSuffix = realPlacement.firstImpressionPlacementSuffix ?: @"";
            self.impressionIndexStart = realPlacement.firstImpressionLoopIndexStart ?: 0;
            self.impressionIndexEnd = realPlacement.firstImpressionLoopIndexEnd ?: 0;
            
            // Create impression model now that SDK is initialized (ensures app.id is populated)
            NSString *auctionID = [[NSUUID UUID] UUIDString];
            self.impModel = [[CloudXCore shared] createImpModelWithAuctionID:auctionID];
            if (self.impModel) {
                [self.logger debug:[NSString stringWithFormat:@"Created impression model with appID: %@", self.impModel.sdkConfig.appID]];
            } else {
                [self.logger error:@"Failed to create impression model after SDK initialization"];
            }
            
            // Create bid source now that we have real placement data
            self.bidAdSource = [self createBidAdSourceForPlacement:realPlacement];
            
            // Clear the requested placement name since initialization is complete
            self.requestedPlacementName = nil;
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
                // Provide detailed error message with available placements (mirrors Android PlacementValidator)
                NSArray<NSString *> *availablePlacements = [[CloudXCore shared] availablePlacementNames];
                NSString *availablePlacementsString = availablePlacements.count > 0 
                    ? [availablePlacements componentsJoinedByString:@", "] 
                    : @"none";
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit 
                                              description:[NSString stringWithFormat:@"Placement '%@' not found in SDK configuration. Available placements: [%@].", 
                                                          self.requestedPlacementName, availablePlacementsString]];
                [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:error];
                [self.delegate didFailToLoadAd:self.placementName error:error];
            }
            return;
        }
    }
    
    // Generate correlation ID for this ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    [self.logger info:[NSString stringWithFormat:@"[%@] Ad load started for placement: %@", self.currentCorrelationId, self.placementID]];
    
    if (self.isLoading) {
        [self.logger debug:[NSString stringWithFormat:@"[%@] Banner load already in progress for placement: %@", self.currentCorrelationId, self.placementID]];
        return;
    }
    
    // Defensive guard: forceStop is already handled in load(), but check again in case
    // performLoad() is called directly (e.g., after SDK initialization notification)
    if ([self handleDestroyedStateError]) {
        return;
    }
    
    if (!self.bidAdSource) {
        [self.logger error:[NSString stringWithFormat:@"[%@] No CLXBidAdSource available for placement: %@", self.currentCorrelationId, self.placementID]];
        // Trigger error callback - publishers expect a response to API calls
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                              description:@"Internal error: BidAdSource not available. SDK may not be properly initialized."];
                [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:error];
                [self.delegate didFailToLoadAd:self.placementName error:error];
            }
        });
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"[%@] Starting banner load process for placement: %@", self.currentCorrelationId, self.placementID]];
    self.isLoading = YES;
    self.adLoadStartTime = [NSDate date];
    [self.logger debug:[NSString stringWithFormat:@"[%@] Ad load start time set: %@", self.currentCorrelationId, self.adLoadStartTime]];
    
    // Implement async banner update request
    [self requestBannerUpdate];
}

// Handle SDK initialization notification
- (void)handleSDKInitialized:(NSNotification *)notification {
    NSUInteger queuedRequests = self.pendingLoadRequestCount;
    if (queuedRequests > 0) {
        [self.logger info:[NSString stringWithFormat:@"SDK initialized, executing %lu queued load request(s) for placement: %@", (unsigned long)queuedRequests, self.placementID]];
        self.pendingLoadRequestCount = 0;
        // Execute load once (multiple load() calls for same banner are redundant)
        [self performLoad];
    }
}

#pragma mark - Private Methods

- (void)requestBannerUpdate {
    [self.logger debug:[NSString stringWithFormat:@"[%@] requestBannerUpdate() called for placement: %@", self.currentCorrelationId, self.placementID]];
    
    if (self.forceStop) {
        [self.logger debug:[NSString stringWithFormat:@"[%@] Request stopped due to forceStop flag", self.currentCorrelationId]];
        return;
    }
    
    // Use placement ID directly as stored impression ID
    NSString *storedImpressionId = self.placementID;

    // Request bid from bid ad source
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:storedImpressionId
                                    impModel:self.impModel
                                   successWin:self.successWin
                                correlationId:self.currentCorrelationId
                                   completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"[%@] Bid request completion - Response: %@, Error: %@", strongSelf.currentCorrelationId, response ? @"YES" : @"NO", error ? error.localizedDescription : @"None"]];

        if (error) {
            [self.logger error:[NSString stringWithFormat:@"[%@] Bid request failed - %@ (Domain: %@, Code: %ld)", strongSelf.currentCorrelationId, error.clx_fullErrorMessage, error.domain, (long)error.code]];
            
            // Store the original error to preserve detailed server messages
            strongSelf.lastBidError = error;
            
            // Continue with waterfall - continueBannerChain will use the stored error
            [strongSelf continueBannerChain];
            return;
        }
        
        if (!response) {
            [self.logger error:[NSString stringWithFormat:@"[%@] Bid request returned nil response", strongSelf.currentCorrelationId]];
            
            // Continue with waterfall - let continueBannerChain handle the nil response
            [strongSelf continueBannerChain];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"[%@] Bid response received - Network: %@, BidID: %@, Price: %.2f, CreateBidAd: %d", strongSelf.currentCorrelationId, response.networkName, response.bidID, response.price, response.createBidAd != nil]];
        
        strongSelf.lastBidResponse = response;
        
        // Store the full bid response for LURL firing by getting it from bidAdSource
        strongSelf.currentBidResponse = [strongSelf.bidAdSource getCurrentBidResponse];
        
        // Set up Analytics tracking data
        [strongSelf.rillTrackingService setupTrackingDataFromBidResponse:response
                                                                impModel:strongSelf.impModel
                                                             placementID:storedImpressionId
                                                               loadCount:0];
        
        NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreBannerMetricsDictKey];
        NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
        if ([metricsDict.allKeys containsObject:@"method_banner_refresh"]) {
            NSString *value = metricsDict[@"method_banner_refresh"];
            int number = [value intValue];
            int new = number + 1;
            metricsDict[@"method_banner_refresh"] = [NSString stringWithFormat:@"%d", new];
        } else {
            metricsDict[@"method_banner_refresh"] = @"1";
        }
        [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreBannerMetricsDictKey];
        
        // Continue banner chain
        [strongSelf continueBannerChain];
    }];
}

- (void)continueBannerChain {
    [self.logger debug:[NSString stringWithFormat:@"continueBannerChain() called for placement: %@ (forceStop:%d, loading:%d, hasResponse:%d, hasCreateBidAd:%d)", self.placementID, self.forceStop, self.isLoading, self.lastBidResponse != nil, self.lastBidResponse.createBidAd != nil]];
    
    if (self.forceStop) {
        [self.logger debug:@"Banner chain stopped due to forceStop flag"];
        return;
    }
    
    // Implement actual banner creation from bid response
    if (self.lastBidResponse && self.lastBidResponse.createBidAd) {
        [self.logger debug:@"Calling createBidAd function..."];
        id bidItem = self.lastBidResponse.createBidAd();

        if ([bidItem conformsToProtocol:@protocol(CLXAdapterBanner)]) {
            id<CLXAdapterBanner> banner = (id<CLXAdapterBanner>)bidItem;
            
            // CRITICAL: Set delegate so adapter can call didShowBanner: on CLXPublisherBanner
            banner.delegate = self;
            NSLog(@"🔵 [CLXPublisherBanner] Set adapter delegate to self for placement: %@", self.placementID);
            
            [self.logger success:[NSString stringWithFormat:@"Successfully created banner from bid for placement: %@ (%@)", self.placementID, NSStringFromClass([(NSObject *)banner class])]];
            [self loadAdItem:banner];
        } else {
            [self.logger error:[NSString stringWithFormat:@"Bid item creation failed - Item: %@, ConformsToProtocol: %d", bidItem, bidItem ? [bidItem conformsToProtocol:@protocol(CLXAdapterBanner)] : NO]];
            
            // Treat as technical error - create appropriate error and handle per spec
            NSError *technicalError = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                                   description:@"Banner adapter creation failed"];
            
            [self failToLoadBanner:nil error:technicalError];
        }
    } else {
        [self.logger info:[NSString stringWithFormat:@"[%@] Waterfall exhausted (no fill) - propagating to delegate", self.currentCorrelationId]];
        
        // Preserve original error if available, otherwise create no-fill error
        NSError *errorToReport;
        if (self.lastBidError) {
            // Preserve the original error code and detailed message
            NSString *message = self.lastBidError.clx_fullErrorMessage;
            errorToReport = [CLXError errorWithCode:self.lastBidError.code description:message];
        } else {
            // No error but no response either - genuine no fill
            errorToReport = [CLXError errorWithCode:CLXErrorCodeNoFill description:@"No ad available - waterfall exhausted"];
        }
        
        [self failToLoadBanner:nil error:errorToReport];
    }
}

- (CLXBidAdSource *)createBidAdSourceForPlacement:(CLXSDKConfigPlacement *)placement {
    BOOL hasCloseButton = placement.hasCloseButton ?: NO;
    NSInteger adType = (self.bannerType == CLXBannerTypeW320H50) ? CLXAdTypeBanner : CLXAdTypeMrec;
    
    // Use injected bidTokenSources if populated (for testability), otherwise fetch from CloudXCore
    NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources = self.bidTokenSources;
    if (!bidTokenSources || bidTokenSources.count == 0) {
        // Fallback to CloudXCore for deferred init case or when not injected
        bidTokenSources = [[CloudXCore shared] adNetworkFactories].bidTokenSources;
    }
    
    // These fields are always empty strings in CloudX implementation
    NSString *userID = @"";
    NSString *publisherID = @"";
    
    // Warn if bidTokenSources is still missing after fallback
    if (!bidTokenSources || bidTokenSources.count == 0) {
        [self.logger error:@"bidTokenSources is nil or empty - SDK may not be fully initialized"];
    }
    
    __weak typeof(self) weakSelf = self;
    return [[CLXBidAdSource alloc] initWithUserID:userID
                                       placementID:self.placementID
                                            dealID:self.dealID
                                     hasCloseButton:hasCloseButton
                                       publisherID:publisherID
                                            adType:adType
                                   bidTokenSources:bidTokenSources
                            nativeAdRequirements:nil
                                              tmax:self.tmax
                                  reportingService:self.reportingService
                                       createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return nil;
        return [strongSelf createBannerInstanceWithAdId:adId
                                                  bidId:bidId
                                                     adm:adm
                                           adapterExtras:adapterExtras
                                                    burl:burl
                                          hasClosedButton:hasCloseButton
                                                  network:network];
    }];
}

- (nullable id<CLXAdapterBanner>)createBannerInstanceWithAdId:(NSString *)adId
                                                           bidId:(NSString *)bidId
                                                              adm:(NSString *)adm
                                                    adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                                             burl:(nullable NSString *)burl
                                                   hasClosedButton:(BOOL)hasClosedButton
                                                           network:(NSString *)network {
    [self.logger debug:[NSString stringWithFormat:@"Creating banner instance - AdID: %@, BidID: %@, Network: %@", adId, bidId, network]];
    
    // Use injected adFactories if populated (for testability), otherwise fetch from CloudXCore
    id<CLXAdapterBannerFactory> factory = self.adFactories[network];
    if (!factory) {
        // Fallback to CloudXCore for deferred init case or when not injected
        factory = [[CloudXCore shared] adNetworkFactories].banners[network];
    }
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"No factory found for network: %@", network]];
        return nil;
    }
    
    if (!self.viewController) {
        [self.logger error:@"No view controller available for banner creation"];
        return nil;
    }
    
    id<CLXAdapterBanner> creativeBanner = [factory createWithViewController:self.viewController
                                                                          type:self.bannerType
                                                                          adId:adId
                                                                         bidId:bidId
                                                                            adm:adm
                                                                hasClosedButton:hasClosedButton
                                                                        extras:adapterExtras
                                                                  placementName:self.placementName
                                                                      delegate:self];
    
    if (!creativeBanner) {
        [self.logger error:[NSString stringWithFormat:@"Factory failed to create banner for network: %@", network]];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Successfully created banner instance for network: %@", network]];
    return creativeBanner;
}

- (void)timerDidReachEnd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _timerDidReachEndSynchronous];
    });
}

- (void)_timerDidReachEndSynchronous {
    [self.logger debug:@"Timer reached end"];
    
    if (!self.autoRefreshEnabled) {
        [self.logger debug:@"Auto-refresh is disabled - skipping refresh"];
        return;
    }
    
    // Timer runs when: (visible OR bypassing visibility) AND autoRefreshEnabled
    // The bypass allows retries after load failures even when the banner view isn't visible
    if (self.isVisible || self.bypassVisibilityCheck) {
        [self.logger debug:[NSString stringWithFormat:@"Requesting update (visible=%d, bypass=%d)", self.isVisible, self.bypassVisibilityCheck]];
        self.previousBanner = self.currentLoadingBanner;
        [self requestBannerUpdate];
    } else {
        [self.logger debug:@"Banner is hidden - queuing refresh for when visible"];
        self.hasPendingRefresh = YES;
    }
}

- (void)loadAdItem:(id<CLXAdapterBanner>)item {
    [self.logger info:[NSString stringWithFormat:@"Loading %@ for placement %@", NSStringFromClass([(NSObject *)item class]), self.placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        item.timeout = NO;
        item.delegate = self;  // Set delegate so adapter can call didShowBanner:
        self.currentLoadingBanner = item;
        self.adLoadStartTime = [NSDate date];
        [self.logger debug:@"Calling item.load()"];
        [item load];
    });
}

#pragma mark - CloudXAdapterBannerDelegate

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    [self.logger info:[NSString stringWithFormat:@"didLoadBanner called for placement: %@ (class: %@, timeout: %d)", self.placementID, NSStringFromClass([(NSObject *)banner class]), banner.timeout]];

    if (banner.timeout) {
        [banner destroy];
        return;
    }

    NSTimeInterval latency = 0;
    if (self.adLoadStartTime) {
        latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
    }
    [self.logger debug:[NSString stringWithFormat:@"Ad loaded with latency: %.1f ms", latency]];
    [self.appSessionService adLoadedWithPlacementID:self.placementID latency:latency];
    
    // Track adapter load latency with metrics tracker
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkAdapterLoad latency:(NSInteger)latency error:nil];
    
    // SECOND PHASE - Winner has successfully loaded, now fire lurls for all losing bids
    // All remaining bids that could create banners but lost to this winner get LostToHigherBid
    [self fireLosingBidLurls];
    
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreBannerMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    if ([metricsDict.allKeys containsObject:@"method_create_banner"]) {
        NSString *value = metricsDict[@"method_create_banner"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"method_create_banner"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"method_create_banner"] = @"1";
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreBannerMetricsDictKey];

    [self.logger debug:@"Cleaning up previous banner..."];
    if (self.previousBanner) {
        [self.logger debug:@"Cleaning up previous banner"];
        self.previousBanner.delegate = nil;
        [self.previousBanner destroy];
        [self.previousBanner.bannerView removeFromSuperview];
    }

    self.successWin = YES;
    self.isLoading = NO;
    
    // Handle visibility-aware display and prefetching
    if (self.isVisible) {
        [self.logger debug:@"Banner visible - displaying immediately"];
        self.bannerOnScreen = self.currentLoadingBanner;
    } else {
        [self.logger debug:@"Banner hidden - prefetching for later display"];
        self.prefetchedBanner = self.currentLoadingBanner;
    }


    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"Ad loaded for bidID=%@", self.lastBidResponse.bidID]];
        
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
            
            [self.logger debug:[NSString stringWithFormat:@"Fired LOAD_SUCCESS event (nurl) for bidID=%@", self.lastBidResponse.bidID]];
        }
    } else {
        [self.logger debug:@"No lastBidResponse to report win"];
    }

    // Call the publisher delegate immediately upon successful load (industry standard)
    if ([self.delegate respondsToSelector:@selector(didLoadAd:)]) {
        CLXAd *ad = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
        [self.logger logDelegateCallback:@"✅ Banner didLoadAd" ad:ad];
        [self.delegate didLoadAd:ad];
    }

    // Reset bypass flag on successful load - return to normal visibility-gated behavior
    self.bypassVisibilityCheck = NO;
    
    // Set manual refresh time to prevent impression fraud through rapid refresh manipulation.
    // This protects against two attack vectors:
    // 1) Show Banner -> Stop Auto-Refresh -> Start Auto-Refresh: Without this timestamp,
    //    startAutoRefresh would trigger an immediate load since lastManualRefreshTime is nil,
    //    creating a double impression within seconds of the initial banner load.
    // 2) Rapid Start/Stop Auto-Refresh toggling: By setting the timestamp on every successful
    //    load, we ensure the 30-second rate limit applies to all subsequent startAutoRefresh
    //    calls, preventing publishers from gaming the system with button automation or scripts.
    self.lastManualRefreshTime = [NSDate date];
    
    // Start timer for next refresh cycle (only if auto-refresh is enabled)
    if (self.autoRefreshEnabled) {
        [self.logger debug:@"Starting timer service for next auto-refresh cycle..."];
        [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
            [self.logger debug:@"Timer reached end, calling timerDidReachEnd"];
            [self timerDidReachEnd];
        }];
    } else {
        [self.logger debug:@"Auto-refresh disabled - not starting timer"];
    }
}

- (void)fireLosingBidLurls {
    if (!self.currentBidResponse || !self.lastBidResponse) {
        return;
    }
    
    NSArray<CLXBidResponseBid *> *allBids = [self.currentBidResponse getAllBidsForWaterfall];
    NSString *winnerBidId = self.lastBidResponse.bidID;
    NSString *auctionId = self.currentBidResponse.id;
    
    [self.winLossTracker sendLossNotificationsForLosingBids:auctionId
                                              winningBidId:winnerBidId
                                                   allBids:allBids];
}


- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error {
    [self.logger info:[NSString stringWithFormat:@"[%@] failToLoadBanner for placement: %@ - %@", self.currentCorrelationId, self.placementID, error.localizedDescription ?: @"Unknown error"]];
    
    [self.appSessionService adFailedToLoadWithPlacementID:self.placementID];
    
    // Track adapter load latency with metrics tracker (failure)
    if (self.adLoadStartTime) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
        id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkAdapterLoad latency:(NSInteger)latency error:error];
    }

    // Destroy the failed banner
    [banner destroy];
    
    // Send server-side loss notification for technical errors (replaces client-side LURL firing)
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
        
        [self.logger debug:[NSString stringWithFormat:@"Sent LOSS event for failed winner rank=%ld, reason=%ld", (long)self.lastBidResponse.bid.ext.cloudx.rank, (long)lossReason]];
    }
    
    // Reset state for next interval
    self.lastBidResponse = nil;
    self.currentBidResponse = nil;
    self.lastBidError = nil; // Clear the stored error
    self.successWin = NO;
    self.isLoading = NO;
    
    // Convert internal BidAdSource errors to public CLXError domain
    CLXError *delegateError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeLoadFailed];
    if (!delegateError) {
        delegateError = [CLXError errorWithCode:CLXErrorCodeLoadFailed];
    }
    
    // Set bypass flag to allow retry even when banner isn't visible
    // This ensures refresh continues after failures, enabling recovery without requiring visibility
    self.bypassVisibilityCheck = YES;
    [self.logger debug:@"Bypass visibility check enabled for retry after failure"];
    
    // Start timer for next refresh interval (no banner-level retry)
    [self.logger debug:@"Starting timer for next refresh interval..."];
    [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
        [self.logger debug:@"Timer reached end, calling timerDidReachEnd"];
        [self timerDidReachEnd];
    }];
    
    // Flash debug button to indicate error
    [[CLXDebugOverlayManager shared] flashError];
    
    // Emit error to delegate
    if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
        [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:delegateError];
        [self.delegate didFailToLoadAd:self.placementName error:delegateError];
    }
   
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
}

- (void)impressionBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"impression delegate called for placement: %@", self.placementID]];
    
    // Record session depth impression
    NSInteger adType = (self.bannerType == CLXBannerTypeW320H50) ? CLXAdTypeBanner : CLXAdTypeMrec;
    [[CLXSessionMetricsTracker sharedInstance] recordImpressionForPlacement:self.placementName adType:adType];
    
    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"Reporting impression for bidID=%@", self.lastBidResponse.bidID]];
        [self.appSessionService addImpressionWithPlacementID:self.placementID];
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:self.lastBidResponse.price];
        
        // Fire RENDER_SUCCESS lifecycle event (burl) on impression
        if (self.lastBidResponse.bidID && self.currentBidResponse && self.currentBidResponse.id) {
            [self.logger debug:[NSString stringWithFormat:@"Firing RENDER_SUCCESS event (burl) on impression for bidID=%@", self.lastBidResponse.bidID]];
            
            [self.winLossTracker sendEvent:self.currentBidResponse.id
                                     bidId:self.lastBidResponse.bidID
                                     event:[CLXBidLifecycleEvent renderSuccessEvent]
                                lossReason:@(CLXLossReasonBidWon)
                            winnerBidPrice:self.lastBidResponse.price];
            
            [self.logger debug:@"RENDER_SUCCESS event (burl) fired"];
            
            // Trigger revenue callback immediately (no longer depends on NURL network call)
            CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
            if (self.revenueDelegate && [self.revenueDelegate respondsToSelector:@selector(didPayRevenueForAd:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.revenueDelegate didPayRevenueForAd:adObject];
                });
            }
        } else {
            [self.logger debug:[NSString stringWithFormat:@"Missing auction ID or bid ID for win notification: bidID=%@, auctionID=%@", 
                               self.lastBidResponse.bidID ?: @"(nil)", self.currentBidResponse.id ?: @"(nil)"]];
        }
        
        // Send Analytics tracking impression event
        [self.rillTrackingService sendImpressionEvent];
    }
}

- (void)clickBanner:(id<CLXAdapterBanner>)banner {
    [self.appSessionService addClickWithPlacementID:self.placementID];
    [self.rillTrackingService sendClickEvent];
    
    // Show click confirmed feedback - stops pending animation and shows green border
    if (banner.bannerView) {
        [CLXDebugClickFeedback showClickConfirmedOnView:banner.bannerView];
    }
    
    if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
        CLXAd *ad = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
        [self.logger logDelegateCallback:@"👆 Banner didClickAd" ad:ad];
        [self.delegate didClickAd:ad];
    }
}

- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"closedByUserAction delegate called for placement: %@", self.placementID]];
    [self.appSessionService addCloseWithPlacementID:self.placementID latency:1.0];
}

- (void)didExpandBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"didExpandBanner delegate called for placement: %@", self.placementID]];
    if ([self.delegate respondsToSelector:@selector(didExpandAd:)]) {
        CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
        [self.delegate didExpandAd:adObject];
    }
}

- (void)didCollapseBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"didCollapseBanner delegate called for placement: %@", self.placementID]];
    if ([self.delegate respondsToSelector:@selector(didCollapseAd:)]) {
        CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
        [self.delegate didCollapseAd:adObject];
    }
}

#pragma mark - CLXAdLifecycle

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying banner for placement: %@", self.placementID]];
    
    // Remove notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CLXSDKInitializedNotification" object:nil];
    
    self.isDestroyed = YES;
    self.isLoading = NO;

    // Clean up any ongoing operations
    self.forceStop = YES;
    
    // Clean up current banner
    if (self.bannerOnScreen) {
        [self.bannerOnScreen destroy];
        self.bannerOnScreen = nil;
    }
    
    // Clean up loading banner
    if (self.currentLoadingBanner) {
        [self.currentLoadingBanner destroy];
        self.currentLoadingBanner = nil;
    }
    
    // Clean up previous banner
    if (self.previousBanner) {
        [self.previousBanner destroy];
        self.previousBanner = nil;
    }
    
    // Clear pending refresh flag and bypass flag
    self.hasPendingRefresh = NO;
    self.bypassVisibilityCheck = NO;
    
    // Clean up prefetched banner
    if (self.prefetchedBanner) {
        [self.prefetchedBanner destroy];
        self.prefetchedBanner = nil;
    }
}

#pragma mark - Visibility Management

- (void)setVisible:(BOOL)visible {
    if (self.isVisible != visible) {
        self.isVisible = visible;
        [self.logger debug:[NSString stringWithFormat:@"Visibility changed to: %@", visible ? @"visible" : @"hidden"]];
        
        if (visible) {
            // Banner became visible - reset bypass flag since we now have normal visibility
            self.bypassVisibilityCheck = NO;
            
            // Banner became visible - execute any pending refresh
            // Fix: Prevent double-loading during initial MREC setup by checking if we're already loading
            if (self.hasPendingRefresh && self.autoRefreshEnabled && !self.isLoading) {
                self.hasPendingRefresh = NO;
                [self.logger debug:@"Executing pending refresh after becoming visible"];
                [self load];
            } else if (self.isLoading) {
                [self.logger debug:@"Skipping pending refresh - already loading"];
            }
            
            // Display any prefetched banner
            if (self.prefetchedBanner) {
                [self.logger debug:@"Displaying prefetched banner"];
                self.bannerOnScreen = self.prefetchedBanner;
                self.prefetchedBanner = nil;
                // Note: didLoadWithAd was already called when banner loaded successfully
                // Industry standard: don't call delegate again when displaying prefetched banner
            }
        } else {
            // Banner became hidden - no immediate action needed
            [self.logger debug:@"Banner is now hidden"];
        }
    }
}

- (void)startAutoRefresh {
    [self.logger debug:@"Starting auto-refresh"];
    self.autoRefreshEnabled = YES;
    
    // Check for rate limiting (minimum 30 seconds between manual refreshes)
    NSTimeInterval minRefreshInterval = 30.0; // Industry standard: 30-60 seconds
    NSDate *now = [NSDate date];
    
    BOOL shouldRefreshImmediately = YES;
    if (self.lastManualRefreshTime) {
        NSTimeInterval timeSinceLastRefresh = [now timeIntervalSinceDate:self.lastManualRefreshTime];
        if (timeSinceLastRefresh < minRefreshInterval) {
            shouldRefreshImmediately = NO;
            [self.logger debug:[NSString stringWithFormat:@"Rate limiting: %.1f seconds since last manual refresh (min: %.1f)", 
                                              timeSinceLastRefresh, minRefreshInterval]];
        }
    }
    
    // If there's a pending refresh and banner is visible, execute it now
    if (self.hasPendingRefresh && self.isVisible && !self.isLoading) {
        self.hasPendingRefresh = NO;
        [self.logger debug:@"Executing pending refresh after enabling auto-refresh"];
        [self load];
        self.lastManualRefreshTime = now;
    } else if (self.hasPendingRefresh && self.isLoading) {
        [self.logger debug:@"Skipping pending refresh in startAutoRefresh - already loading"];
    }
    // Industry standard: Immediate refresh when auto-refresh is started (with rate limiting)
    else if (self.bannerOnScreen && self.isVisible && shouldRefreshImmediately && !self.isLoading) {
        [self.logger debug:@"Immediate refresh on auto-refresh start (industry standard)"];
        [self load];
        self.lastManualRefreshTime = now;
    } else if (self.bannerOnScreen && self.isLoading) {
        [self.logger debug:@"Skipping immediate refresh in startAutoRefresh - already loading"];
    }
    // Start timer for next refresh cycle
    else if (self.bannerOnScreen && self.isVisible) {
        [self.logger debug:@"Starting timer service for next auto-refresh cycle..."];
        [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
            [self.logger debug:@"Timer reached end, calling timerDidReachEnd"];
            [self timerDidReachEnd];
        }];
    }
}

- (void)stopAutoRefresh {
    [self.logger debug:@"Stopping auto-refresh"];
    self.autoRefreshEnabled = NO;
    
    // Stop the current timer
    [self.timerService stop];
}


@end

NS_ASSUME_NONNULL_END 
