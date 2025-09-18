/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file PublisherFullscreenAd.m
 * @brief Publisher fullscreen ad implementation (interstitial and rewarded)
 */

#import <CloudXCore/CLXPublisherFullscreenAd.h>

#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ad state enumeration defining the lifecycle states of fullscreen ads
 */
typedef NS_ENUM(NSInteger, CLXInterstitialState) {
    CLXInterstitialStateIDLE,      // No ad loaded, ready to start loading
    CLXInterstitialStateLOADING,   // Ad request in progress
    CLXInterstitialStateREADY,     // Ad loaded and ready to display
    CLXInterstitialStateSHOWING,   // Ad currently visible to user
    CLXInterstitialStateDESTROYED  // Ad destroyed, no further operations allowed
};

@interface CLXPublisherFullscreenAd () <CLXAdapterInterstitialDelegate, CLXAdapterRewardedDelegate>

// State management
@property (nonatomic, assign) CLXInterstitialState currentState;

// CLXAdFormat properties are computed from currentState - no redeclaration needed

// Core properties
@property (nonatomic, strong, nullable) CLXAdNetworkFactories *adFactories;
@property (nonatomic, copy, nullable) NSString *userID;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *placementName;
@property (nonatomic, copy, nullable) NSString *rewardedCallbackUrl;
@property (nonatomic, assign) NSInteger adType;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) id<CLXAppSessionService> appSessionService;
@property (nonatomic, strong, nullable) CLXBidAdSource *bidAdSource;
@property (nonatomic, strong) CLXSettings *settings;

// Current adapter instances for interstitial and rewarded ads
@property (nonatomic, strong, nullable) id<CLXAdapterInterstitial> currentInterstitialAdapter;
@property (nonatomic, strong, nullable) id<CLXAdapterRewarded> currentRewardedAdapter;

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


@end

@implementation CLXPublisherFullscreenAd

#pragma mark - Initialization

- (instancetype)initWithInterstitialDelegate:(nullable id<CLXInterstitialDelegate>)interstitialDelegate
                            rewardedDelegate:(nullable id<CLXRewardedDelegate>)rewardedDelegate
                                   placement:(CLXSDKConfigPlacement *)placement
                                publisherID:(NSString *)publisherID
                                     userID:(nullable NSString *)userID
                        rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                                    impModel:(CLXConfigImpressionModel *)impModel
                                adFactories:(nullable CLXAdNetworkFactories *)adFactories
                     waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                              bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                           bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                            reportingService:(id<CLXAdEventReporting>)reportingService
                                    settings:(CLXSettings *)settings
                                     adType:(NSInteger)adType {
    self = [super init];
    if (self) {
        // Set up logging for this fullscreen ad instance
        _logger = [[CLXLogger alloc] initWithCategory:@"FullscreenAd"];
        
        [self.logger debug:[NSString stringWithFormat:@"Initializing fullscreen ad - Placement: %@, Type: %ld", placement.id, (long)adType]];
        
        // Start in idle state, ready to load ads
        _currentState = CLXInterstitialStateIDLE;
        
        // Configure delegates and instance properties
        self.interstitialDelegate = interstitialDelegate;
        self.rewardedDelegate = rewardedDelegate;
        _adFactories = adFactories;
        _rewardedCallbackUrl = [rewardedCallbackUrl copy];
        _placementID = [placement.id copy];
        _placementName = [placement.name copy];
        _reportingService = reportingService;
        _userID = [userID copy];
        _adType = adType;
        _settings = settings;
        _impModel = impModel;
        _forceCloseEventDelay = 30.0;
        _closeEventReceived = NO;
        
        // Initialize Rill tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:_reportingService];
        
        // Set up session tracking for metrics collection
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        // Use metrics URL from SDK response (stored in user defaults)
        NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        _appSessionService = [[CLXAppSessionServiceImplementation alloc] initWithSessionID:sessionID
                                                                                 appKey:appKey
                                                                                    url:metricsURL];
        
        // Configure bid source for ad request management
        BOOL hasCloseButton = placement.hasCloseButton ?: NO;
        NSInteger bidAdType = (self.adType == 0) ? CLXAdTypeInterstitial : CLXAdTypeRewarded;
        
        __weak typeof(self) weakSelf = self;
        _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                               placementID:_placementID
                                                    dealID:placement.dealId
                                             hasCloseButton:hasCloseButton
                                               publisherID:publisherID
                                                    adType:bidAdType
                                            bidTokenSources:bidTokenSources
                                     nativeAdRequirements:nil
                                                      tmax:nil
                                           reportingService:_reportingService
                                               createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return nil;
            }
            
            if (strongSelf.adType == 0) { // interstitial
                return [strongSelf createInterstitialInstanceWithAdId:adId
                                                               bidId:bidId
                                                                  adm:adm
                                                        adapterExtras:adapterExtras
                                                                 burl:burl
                                                              network:network];
            } else { // rewarded
                return [strongSelf createRewardedInstanceWithAdId:adId
                                                           bidId:bidId
                                                              adm:adm
                                                    adapterExtras:adapterExtras
                                                             burl:burl
                                                          network:network];
            }
        }];
        
        [self.logger debug:[NSString stringWithFormat:@"Initialized fullscreen ad in IDLE state for placement: %@", _placementID]];
    }
    return self;
}

#pragma mark - CLXAdLifecycle Properties

- (BOOL)isReady {
    return self.currentState == CLXInterstitialStateREADY;
}

- (BOOL)isLoading {
    return self.currentState == CLXInterstitialStateLOADING;
}

- (BOOL)isDestroyed {
    return self.currentState == CLXInterstitialStateDESTROYED;
}

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying fullscreen ad for placement: %@", self.placementID]];
    
    // Set state to destroyed
    self.currentState = CLXInterstitialStateDESTROYED;
    
    // Clean up current adapters
    if (self.currentInterstitialAdapter) {
        if ([self.currentInterstitialAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
            [(id<CLXDestroyable>)self.currentInterstitialAdapter destroy];
        }
        self.currentInterstitialAdapter = nil;
    }
    
    if (self.currentRewardedAdapter) {
        if ([self.currentRewardedAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
            [(id<CLXDestroyable>)self.currentRewardedAdapter destroy];
        }
        self.currentRewardedAdapter = nil;
    }
}

- (void)dealloc {
    [self.logger debug:[NSString stringWithFormat:@"Deallocating fullscreen ad for placement: %@", _placementID]];
    
    // Clean up current adapters
    if ([self.currentInterstitialAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)self.currentInterstitialAdapter destroy];
    }
    if ([self.currentRewardedAdapter conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)self.currentRewardedAdapter destroy];
    }
    
    // Invalidate timers
    [self.closeTimer invalidate];
}

#pragma mark - CloudXInterstitial Protocol

- (void)load {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] load called - Placement: %@, Type: %ld, State: %ld", _placementID, (long)_adType, (long)self.currentState]];
    
    // Check current state to determine if loading is allowed
    switch (self.currentState) {
        case CLXInterstitialStateIDLE:
            break;
        case CLXInterstitialStateLOADING:
            [self.logger debug:@"⚠️ [PublisherFullscreenAd] Already loading, ignoring load request"];
            return;
        case CLXInterstitialStateREADY:
            [self.logger debug:@"⚠️ [PublisherFullscreenAd] Already loaded, ignoring load request"];
            return;
        case CLXInterstitialStateSHOWING:
            [self.logger debug:@"⚠️ [PublisherFullscreenAd] Currently showing, ignoring load request"];
            return;
        case CLXInterstitialStateDESTROYED:
            [self.logger error:@"❌ [PublisherFullscreenAd] Ad destroyed, cannot load"];
            return;
    }
    
    // Transition to loading state
    self.currentState = CLXInterstitialStateLOADING;
    [self.logger debug:@"State transitioned to LOADING"];
    
    // Initiate bid request for ad content
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:self.placementID
                                    impModel:nil
                                   successWin:NO
                                   completion:^(CLXBidAdSourceResponse *response, NSError *error) {
        [self handleBidResponse:response error:error];
    }];
}

- (void)handleBidResponse:(CLXBidAdSourceResponse *)response error:(NSError *)error {
    if (error) {
        [self.logger error:[NSString stringWithFormat:@"Bid request failed: %@", error.localizedDescription]];
        
        // Transition back to idle
        self.currentState = CLXInterstitialStateIDLE;
        
        // Call failure delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (self.adType) {
                case 0: // interstitial
                    if ([self.interstitialDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
                        [self.interstitialDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
                    }
                    break;
                case 1: // rewarded
                    if ([self.rewardedDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
                        [self.rewardedDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
                    }
                    break;
            }
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
    if (self.adType == 0) { // interstitial
        id<CLXAdapterInterstitial> interstitialAdapter = (id<CLXAdapterInterstitial>)adapter;
        self.currentInterstitialAdapter = interstitialAdapter;
        interstitialAdapter.delegate = self;
        
        // Set up 30-second timeout for adapter loading
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.currentState == CLXInterstitialStateLOADING) {
                [self.logger error:@"Interstitial load timeout after 30 seconds"];
                self.currentState = CLXInterstitialStateIDLE;
                
                NSError *timeoutError = [NSError errorWithDomain:@"CLXErrorDomain" 
                                                            code:CLXErrorCodeLoadTimeout 
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Load timeout"}];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.interstitialDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
                        [self.interstitialDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:timeoutError];
                    }
                });
            }
        });
        
        [interstitialAdapter load];
    } else { // rewarded
        id<CLXAdapterRewarded> rewardedAdapter = (id<CLXAdapterRewarded>)adapter;
        self.currentRewardedAdapter = rewardedAdapter;
        rewardedAdapter.delegate = self;
        
        // Set up 30-second timeout for adapter loading
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.currentState == CLXInterstitialStateLOADING) {
                [self.logger error:@"Rewarded load timeout after 30 seconds"];
                self.currentState = CLXInterstitialStateIDLE;
                
                NSError *timeoutError = [NSError errorWithDomain:@"CLXErrorDomain" 
                                                            code:CLXErrorCodeLoadTimeout 
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Load timeout"}];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.rewardedDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
                        [self.rewardedDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:timeoutError];
                    }
                });
            }
        });
        
        [rewardedAdapter load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] showFromViewController called - Ready: %d, State: %ld", self.isReady, (long)self.currentState]];
    
    // Verify ad is ready before attempting to show
    if (self.currentState != CLXInterstitialStateREADY) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] Cannot show ad - invalid state: %ld", (long)self.currentState]];
        NSError *error = [NSError errorWithDomain:@"CLXErrorDomain" 
                                             code:CLXErrorCodeNoFill 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Ad not ready"}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (self.adType) {
                case 0: // interstitial
                    if ([self.interstitialDelegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
                        [self.interstitialDelegate failToShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
                    }
                    break;
                case 1: // rewarded
                    if ([self.rewardedDelegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
                        [self.rewardedDelegate failToShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
                    }
                    break;
            }
        });
        return;
    }
    
    // Transition to showing state
    self.currentState = CLXInterstitialStateSHOWING;
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
                switch (self.adType) {
                    case 0: // interstitial
                        if ([self.interstitialDelegate respondsToSelector:@selector(didHideWithAd:)]) {
                            [self.interstitialDelegate didHideWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
                        }
                        break;
                    case 1: // rewarded
                        if ([self.rewardedDelegate respondsToSelector:@selector(didHideWithAd:)]) {
                            [self.rewardedDelegate didHideWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
                        }
                        break;
                }
            });
        }
        [self.closeTimer invalidate];
    }];
    
    // Display the loaded ad using the appropriate adapter
    if (self.adType == 0) { // interstitial
        [self.currentInterstitialAdapter showFromViewController:viewController];
    } else { // rewarded
        [self.currentRewardedAdapter showFromViewController:viewController];
    }
}



#pragma mark - Private Methods

- (void)applyMetrics {
    // Apply metrics tracking using the active adapter
    id currentAdapter = nil;
    if (self.adType == 0 && self.currentInterstitialAdapter) {
        currentAdapter = self.currentInterstitialAdapter;
    } else if (self.adType == 1 && self.currentRewardedAdapter) {
        currentAdapter = self.currentRewardedAdapter;
    }
    
    if ([currentAdapter respondsToSelector:@selector(price)]) {
        double price = [currentAdapter price];
        // Call appSessionService.addSpend
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:price];
    }
}

- (nullable id)createInterstitialInstanceWithAdId:(NSString *)adId
                                           bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                    adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                             burl:(nullable NSString *)burl
                                           network:(NSString *)network {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] Creating interstitial: AdID=%@, BidID=%@, Network=%@, ADM=%lu chars", adId, bidId, network, (unsigned long)adm.length]];
    
    // Check if adFactories exists
    if (!self.adFactories) {
        [self.logger error:@"❌ [PublisherFullscreenAd] adFactories is nil!"];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] Available factories: %lu (%@)", (unsigned long)self.adFactories.interstitials.count, [[self.adFactories.interstitials allKeys] componentsJoinedByString:@", "]]];
    
    // Get factory for network
    id<CLXAdapterInterstitialFactory> factory = self.adFactories.interstitials[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] No factory found for network: %@ (Available: %@)", network, [self.adFactories.interstitials allKeys]]];
        
        // Try to find the factory with different key variations
        for (NSString *key in [self.adFactories.interstitials allKeys]) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] Checking key: '%@' against network: '%@'", key, network]];
            if ([key isEqualToString:network]) {
                [self.logger info:[NSString stringWithFormat:@"✅ [PublisherFullscreenAd] Found exact match for key: %@", key]];
                factory = self.adFactories.interstitials[key];
                break;
            }
        }
        
        if (!factory) {
            [self.logger error:@"❌ [PublisherFullscreenAd] Still no factory found after checking all keys - TestVastNetworkInterstitialFactory not loaded properly"];
            return nil;
        }
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherFullscreenAd] Factory found for network: %@", network]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] Factory class: %@", NSStringFromClass([factory class])]];
    
    // Create interstitial instance
    id<CLXAdapterInterstitial> interstitial = [factory createWithAdId:adId
                                                                   bidId:bidId
                                                                      adm:adm
                                                                    extras:adapterExtras
                                                                  delegate:self];
    
    if (!interstitial) {
        [self.logger error:@"❌ [PublisherFullscreenAd] Factory returned nil interstitial"];
        return nil;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherFullscreenAd] Interstitial created - Network: %@, BidID: %@", interstitial.network, interstitial.bidID]];
    
    return interstitial;
}

- (nullable id)createRewardedInstanceWithAdId:(NSString *)adId
                                       bidId:(NSString *)bidId
                                          adm:(NSString *)adm
                                adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                         burl:(nullable NSString *)burl
                                       network:(NSString *)network {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] createRewardedInstanceWithAdId - AdID: %@, BidID: %@, Network: %@", adId, bidId, network]];
    
    // Check if adFactories exists
    if (!self.adFactories) {
        [self.logger error:@"❌ [PublisherFullscreenAd] adFactories is nil!"];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] adFactories.rewardedInterstitials: %@", self.adFactories.rewardedInterstitials]];
    
    // Get factory for network
    id<CLXAdapterRewardedFactory> factory = self.adFactories.rewardedInterstitials[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] No rewarded factory found for network: %@ (Available: %@)", network, [self.adFactories.rewardedInterstitials allKeys]]];
        return nil;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherFullscreenAd] Factory found for network: %@", network]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] Factory class: %@", NSStringFromClass([factory class])]];
    
    // Create rewarded instance
    id<CLXAdapterRewarded> rewarded = [factory createWithAdId:adId
                                                          bidId:bidId
                                                             adm:adm
                                                           extras:adapterExtras
                                                         delegate:self];
    
    if (!rewarded) {
        [self.logger error:@"❌ [PublisherFullscreenAd] Factory returned nil rewarded"];
        return nil;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherFullscreenAd] Rewarded created - Network: %@, BidID: %@", rewarded.network, rewarded.bidID]];
    
    return rewarded;
}

#pragma mark - CloudXAdapterInterstitialDelegate

- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] didLoadWithInterstitial - Class: %@", NSStringFromClass([(NSObject *)interstitial class])]];
    
    // Cache the adapter
    self.currentInterstitialAdapter = interstitial;
    
    // Transition to ready state
    self.currentState = CLXInterstitialStateREADY;
    [self.logger debug:@"📊 [PublisherFullscreenAd] State transitioned to READY"];
    
    // Call success delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(didLoadWithAd:)]) {
            [self.logger debug:@"✅ [PublisherFullscreenAd] Calling didLoadWithAd delegate"];
            [self.interstitialDelegate didLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ [PublisherFullscreenAd] didFailToLoadWithInterstitial: %@", error.localizedDescription]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] - Failed interstitial: %@", interstitial]];
    
    // Clear cached adapter
    self.currentInterstitialAdapter = nil;
    
    // Transition back to idle
    self.currentState = CLXInterstitialStateIDLE;
    [self.logger debug:@"📊 [PublisherFullscreenAd] State transitioned back to IDLE"];
    
    // Call failure delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
            [self.logger debug:@"📊 [PublisherFullscreenAd] Calling failToLoadWithAd delegate"];
            [self.interstitialDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
        }
    });
}

- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherFullscreenAd] didShowWithInterstitial - %@", interstitial]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(didShowWithAd:)]) {
            [self.logger debug:@"📊 [PublisherFullscreenAd] Calling didShowWithAd delegate"];
            [self.interstitialDelegate didShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:@"🎯 [PublisherFullscreenAd] impressionWithInterstitial called!"];
    self.impressionTime = [NSDate date];
    [self.reportingService impressionWithBidID:interstitial.bidID];
    [self applyMetrics];
    
    [self.appSessionService addImpressionWithPlacementID:self.placementID];
    
    // Send Rill tracking impression event
    [self.rillTrackingService sendImpressionEvent];
    
    // Debug: Log detailed information about bid response and bid ID
    [self.logger debug:[NSString stringWithFormat:@"🔍 [PublisherFullscreenAd] NURL firing debug - bidID: %@, response: %@", interstitial.bidID, self.currentBidResponse.id]];
    
    NSArray<CLXBidResponseBid *> *allBids = [self.currentBidResponse allBids];
    [self.logger debug:[NSString stringWithFormat:@"🔍 [PublisherFullscreenAd] Total bids in response: %lu", (unsigned long)allBids.count]];
    
    for (CLXBidResponseBid *bid in allBids) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [PublisherFullscreenAd] Bid ID: %@, NURL: %@, Price: %.2f", bid.id, bid.nurl, bid.price]];
    }
    
    // Fire NURL for interstitial impression with revenue callback
    CLXBidResponseBid *winningBid = [self.currentBidResponse findBidWithID:interstitial.bidID];
    if (winningBid && winningBid.nurl) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherFullscreenAd] Firing NURL for interstitial impression with revenue callback: bidID=%@, price=%.2f", interstitial.bidID, winningBid.price]];
        
        __weak typeof(self) weakSelf = self;
        [self.reportingService fireNurlForRevenueWithPrice:winningBid.price nUrl:winningBid.nurl completion:^(BOOL success, CLXAd * _Nullable ad) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if (success) {
                // Create CLXAd object and trigger revenue callback
                CLXAd *adObject = [CLXAd adFromBid:strongSelf.lastBidResponse.bid placementId:strongSelf.placementID placementName:strongSelf.placementName];
                if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(revenuePaid:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.interstitialDelegate revenuePaid:adObject];
                    });
                }
            }
        }];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] No NURL to fire for interstitial: bidID=%@, winningBid=%@, nurl=%@", interstitial.bidID, winningBid ? @"found" : @"not found", winningBid ? winningBid.nurl : @"N/A"]];
    }
    
    if ([self.interstitialDelegate respondsToSelector:@selector(impressionOn:)]) {
        [self.interstitialDelegate impressionOn:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
    }
}

- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:@"Interstitial closed"];
    
    // Calculate display latency if we have impression time
    if (self.impressionTime) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:self.impressionTime] * 1000;
        [self.appSessionService addCloseWithPlacementID:self.placementID latency:latency];
    }
    
    // Mark close event received and cleanup
    self.closeEventReceived = YES;
    [self.closeTimer invalidate];
    
    // Destroy the adapter
    if ([interstitial conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)interstitial destroy];
    }
    
    // Clear cached adapter and transition back to idle
    self.currentInterstitialAdapter = nil;
    self.currentState = CLXInterstitialStateIDLE;
    
    // Call delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(didHideWithAd:)]) {
            [self.interstitialDelegate didHideWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}



- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
            [self.interstitialDelegate failToShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
        }
    });
}

- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [_logger debug:@"Clicked on interstitial ad"];
    
    // Call appSessionService.addClick
    [self.appSessionService addClickWithPlacementID:self.placementID];
    
    // Send Rill tracking click event
    [self.rillTrackingService sendClickEvent];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.interstitialDelegate respondsToSelector:@selector(didClickWithAd:)]) {
            [self.interstitialDelegate didClickWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:@"Interstitial adapter expired"];
    // Expired ads are handled by transitioning back to idle state
    self.currentInterstitialAdapter = nil;
    self.currentState = CLXInterstitialStateIDLE;
}

#pragma mark - CloudXAdapterRewardedDelegate

- (void)didLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self.logger debug:@"Rewarded adapter loaded successfully"];
    
    // Cache the adapter
    self.currentRewardedAdapter = rewarded;
    
    // Transition to ready state
    self.currentState = CLXInterstitialStateREADY;
    
    // Call success delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(didLoadWithAd:)]) {
            [self.rewardedDelegate didLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)didFailToLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Rewarded adapter failed to load: %@", error.localizedDescription]];
    
    // Clear cached adapter
    self.currentRewardedAdapter = nil;
    
    // Transition back to idle
    self.currentState = CLXInterstitialStateIDLE;
    
    // Call failure delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
            [self.rewardedDelegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
        }
    });
}

- (void)didShowWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(didShowWithAd:)]) {
            [self.rewardedDelegate didShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)impressionWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    self.impressionTime = [NSDate date];
    [self.reportingService impressionWithBidID:rewarded.bidID];
    [self applyMetrics];
    
    [self.appSessionService addImpressionWithPlacementID:self.placementID];
    
    // Send Rill tracking impression event
    [self.rillTrackingService sendImpressionEvent];
    
    // Fire NURL for rewarded impression with revenue callback
    CLXBidResponseBid *winningBid = [self.currentBidResponse findBidWithID:rewarded.bidID];
    if (winningBid && winningBid.nurl) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherFullscreenAd] Firing NURL for rewarded impression with revenue callback: bidID=%@, price=%.2f", rewarded.bidID, winningBid.price]];
        
        __weak typeof(self) weakSelf = self;
        [self.reportingService fireNurlForRevenueWithPrice:winningBid.price nUrl:winningBid.nurl completion:^(BOOL success, CLXAd * _Nullable ad) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if (success) {
                // Create CLXAd object and trigger revenue callback
                CLXAd *adObject = [CLXAd adFromBid:strongSelf.lastBidResponse.bid placementId:strongSelf.placementID placementName:strongSelf.placementName];
                if (strongSelf.rewardedDelegate && [strongSelf.rewardedDelegate respondsToSelector:@selector(revenuePaid:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.rewardedDelegate revenuePaid:adObject];
                    });
                }
            }
        }];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherFullscreenAd] No NURL to fire for rewarded: bidID=%@, winningBid=%@", rewarded.bidID, winningBid ? @"found" : @"not found"]];
    }
    
    if ([self.rewardedDelegate respondsToSelector:@selector(impressionOn:)]) {
        [self.rewardedDelegate impressionOn:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
    }
}

- (void)didCloseWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self.logger debug:@"Rewarded ad closed"];
    
    // Calculate display latency if we have impression time
    if (self.impressionTime) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:self.impressionTime] * 1000;
        [self.appSessionService addCloseWithPlacementID:self.placementID latency:latency];
    }
    
    // Mark close event received and cleanup
    self.closeEventReceived = YES;
    [self.closeTimer invalidate];
    
    // Destroy the adapter
    if ([rewarded conformsToProtocol:@protocol(CLXDestroyable)]) {
        [(id<CLXDestroyable>)rewarded destroy];
    }
    
    // Clear cached adapter and transition back to idle
    self.currentRewardedAdapter = nil;
    self.currentState = CLXInterstitialStateIDLE;
    
    // Call delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(didHideWithAd:)]) {
            [self.rewardedDelegate didHideWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}



- (void)clickWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [_logger debug:@"Clicked on rewarded ad"];
    [self.appSessionService addClickWithPlacementID:self.placementID];
    
    // Send Rill tracking click event
    [self.rillTrackingService sendClickEvent];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(didClickWithAd:)]) {
            [self.rewardedDelegate didClickWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
        }
    });
}

- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [_logger debug:@"User rewarded"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(rewardedVideoCompleted:)]) {
            [self.rewardedDelegate rewardedVideoCompleted:self];
        }
        if ([self.rewardedDelegate respondsToSelector:@selector(userRewarded:)]) {
            [self.rewardedDelegate userRewarded:self];
        }
    });
}

- (void)didFailToShowWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedDelegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
            [self.rewardedDelegate failToShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:error];
        }
    });
}

- (void)expiredWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self.logger debug:@"Rewarded adapter expired"];
    // Expired ads are handled by transitioning back to idle state
    self.currentRewardedAdapter = nil;
    self.currentState = CLXInterstitialStateIDLE;
}

@end

NS_ASSUME_NONNULL_END 
