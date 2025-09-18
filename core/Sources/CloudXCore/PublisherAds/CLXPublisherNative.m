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
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXRetryHelper.h>

#import <CloudXCore/CLXBannerTimerService.h>
#import <CloudXCore/CLXExponentialBackoffStrategy.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXEnvironmentConfig.h>


NS_ASSUME_NONNULL_BEGIN

@interface CLXPublisherNative () <CLXAdapterNativeDelegate>

// CLXAdLifecycle properties
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL isDestroyed;

// Private properties
@property (nonatomic, strong, nullable) CLXBidAdSource *bidAdSource;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *adFactories;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> currentLoadingNative;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> previousNative;
@property (nonatomic, strong, nullable) id<CLXAdapterNative> nativeOnScreen;
@property (nonatomic, assign) NSTimeInterval refreshSeconds;
@property (nonatomic, strong) CLXBannerTimerService *timerService;
@property (nonatomic, strong) CLXExponentialBackoffStrategy *waterfallBackoffAlgorithm;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *placementName;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong, nullable) id requestNativeTask;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL successWin;
@property (nonatomic, assign) NSInteger loadNativeTimesCount;
@property (nonatomic, strong) CLXSDKConfigPlacement *placement;
@property (nonatomic, strong, nullable) NSDate *adLoadStartTime;
@property (nonatomic, strong) id<CLXAppSessionService> appSessionService;

// Rill tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) CLXConfigImpressionModel *impModel;


@end

@implementation CLXPublisherNative



#pragma mark - Initialization

- (instancetype)initWithViewController:(UIViewController *)viewController
                             placement:(CLXSDKConfigPlacement *)placement
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXAdapterNativeDelegate>)delegate
                             nativeType:(CLXNativeTemplate)nativeType
                   waterfallMaxBackOffTime:(NSTimeInterval)waterfallMaxBackOffTime
                                  impModel:(CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *)adFactories
                           bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                         reportingService:(id<CLXAdEventReporting>)reportingService
                        environmentConfig:(CLXEnvironmentConfig *)environmentConfig {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _refreshSeconds = (placement.bannerRefreshRateMs ?: 10000) / 1000.0;
        _placementID = [placement.id copy];
        _placementName = [placement.name copy];
        _reportingService = reportingService;
        _placement = placement;
        _adFactories = adFactories;
        _impModel = impModel;
        _isReady = NO;
        _isLoading = NO;
        _isDestroyed = NO;
        _forceStop = NO;
        _successWin = NO;
        _loadNativeTimesCount = 0;
        
        // Initialize Rill tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:reportingService];
        
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXNative"];
        
        // Initialize waterfall backoff algorithm
        _waterfallBackoffAlgorithm = [[CLXExponentialBackoffStrategy alloc] initWithInitialDelay:1.0 maxDelay:waterfallMaxBackOffTime];
        
        // Initialize timer service
        _timerService = [[CLXBannerTimerService alloc] init];
        
        // Initialize app session service (singleton)
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        _appSessionService = [[CLXAppSessionServiceImplementation alloc] initWithSessionID:sessionID
                                                                                 appKey:appKey
                                                                                    url:[CLXEnvironmentConfig shared].metricsEndpointURL];
        
        // Get app key from UserDefaults (matching Swift SDK behavior)
        __weak typeof(self) weakSelf = self;
        
        // Calculate TMAX from placement configuration (convert milliseconds to seconds)
        // Use nil to match Swift version behavior (no timeout)
        NSNumber *tmax = nil; // nil means omit tmax from JSON
        
        _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                               placementID:_placementID
                                                    dealID:placement.dealId
                                             hasCloseButton:NO
                                               publisherID:publisherID
                                                    adType:CLXAdTypeNative
                                            bidTokenSources:bidTokenSources
                                     nativeAdRequirements:[CLXNativeTemplateHelper nativeAdRequirementsForTemplate:nativeType]
                                                      tmax:tmax
                                           reportingService:_reportingService
                                          environmentConfig:environmentConfig
                                               createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return nil;
            return [strongSelf createNativeInstanceWithAdId:adId
                                                      bidId:bidId
                                                         adm:adm
                                               adapterExtras:adapterExtras
                                                        burl:burl
                                                      network:network];
        }];
        
        [_logger debug:[NSString stringWithFormat:@"Initialized CLXPublisherNative for placement: %@", _placementID]];
    }
    return self;
}

#pragma mark - CloudXNative Protocol

- (void)load {
    if (self.isLoading) {
        [self.logger debug:@"Native load already in progress"];
        return;
    }
    
    [self.logger debug:@"Starting native load process"];
    self.isLoading = YES;
    
    // Implement async native update request
    [self requestNativeUpdate];
}



#pragma mark - Private Methods

- (void)requestNativeUpdate {
    if (self.forceStop) {
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Requesting native update - loop-index: %ld", (long)self.loadNativeTimesCount]];
    
    // Request bid from bid ad source
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:self.placementID
                                    impModel:nil
                                   successWin:self.successWin
                                   completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (error) {
            [strongSelf.logger debug:[NSString stringWithFormat:@"Failed to receive bid: %@", error.localizedDescription]];
            
            // Implement waterfall backoff delay logic
            NSError *backoffError;
            NSTimeInterval delay = [strongSelf.waterfallBackoffAlgorithm nextDelayWithError:&backoffError];
            if (backoffError) {
                delay = 1.0; // Default delay if backoff fails
            }
            
            [strongSelf.logger debug:[NSString stringWithFormat:@"Sleep for %f seconds", delay]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf requestNativeUpdate];
            });
        } else {
            strongSelf.lastBidResponse = response;
            
            // Set up Rill tracking data
            [strongSelf.rillTrackingService setupTrackingDataFromBidResponse:response
                                                                    impModel:strongSelf.impModel
                                                                 placementID:strongSelf.placementID
                                                                   loadCount:0];
            
            // Reset waterfall backoff algorithm
            [strongSelf.waterfallBackoffAlgorithm reset];
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
    
    [self.logger debug:[NSString stringWithFormat:@"Continuing native chain for placement: %@", self.placementID]];
    
    // Implement actual native creation from bid response
    if (self.lastBidResponse && self.lastBidResponse.createBidAd) {
        id bidItem = self.lastBidResponse.createBidAd();
        if ([bidItem conformsToProtocol:@protocol(CLXAdapterNative)]) {
        id<CLXAdapterNative> native = (id<CLXAdapterNative>)bidItem;
            [self.logger debug:[NSString stringWithFormat:@"Successfully created native from bid for placement: %@", self.placementID]];
            [self loadAdItem:native];
        } else {
            [self.logger debug:@"No valid native created from bid for placement"];
            // Early returns for cleaner code flow
            if (!self.isLoading) {
                [self.logger debug:@"⚠️ [PublisherNative] Not retrying - isLoading=false"];
                return;
            }
            
            if (![CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                             settings:[CLXSettings sharedInstance] 
                                               logger:self.logger 
                                         failureBlock:^(NSError *error) {
                self.isLoading = NO;
                [self failToLoadWithNative:nil error:error];
            }]) {
                return;
            }
            
            [self.logger debug:@"Retrying native request due to isLoading=true"];
            [self requestNativeUpdate];
        }
    } else {
        [self.logger debug:@"No valid native created from bid for placement"];
        // Early returns for cleaner code flow
        if (!self.isLoading) {
            [self.logger debug:@"⚠️ [PublisherNative] Not retrying - isLoading=false"];
            return;
        }
        
        if (![CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                         settings:[CLXSettings sharedInstance] 
                                           logger:self.logger 
                                     failureBlock:^(NSError *error) {
            self.isLoading = NO;
            [self failToLoadWithNative:nil error:error];
        }]) {
            return;
        }
        
        [self.logger debug:@"Retrying native request due to isLoading=true"];
        [self requestNativeUpdate];
    }
}

- (nullable id<CLXAdapterNative>)createNativeInstanceWithAdId:(NSString *)adId
                                                          bidId:(NSString *)bidId
                                                             adm:(NSString *)adm
                                                   adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                                            burl:(nullable NSString *)burl
                                                          network:(NSString *)network {
    [self.logger debug:[NSString stringWithFormat:@"Creating native instance - AdID: %@, BidID: %@, Network: %@", adId, bidId, network]];
    
    id<CLXAdapterNativeFactory> factory = self.adFactories[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"No factory found for network: %@", network]];
        return nil;
    }
    
    if (!self.viewController) {
        [self.logger error:@"No view controller available for native creation"];
        return nil;
    }
    
    id<CLXAdapterNative> creativeNative = [factory createWithViewController:self.viewController
                                                                          type:_nativeType
                                                                          adId:adId
                                                                         bidId:bidId
                                                                            adm:adm
                                                                        extras:adapterExtras
                                                                      delegate:self];
    
    if (!creativeNative) {
        [self.logger error:[NSString stringWithFormat:@"Factory failed to create native for network: %@", network]];
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
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Native] Instantiating AdapterNative: %@", NSStringFromClass([item class])]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.logger debug:[NSString stringWithFormat:@"[CloudX][Native] Calling load() on AdapterNative: %@", NSStringFromClass([item class])]];
        item.timeout = NO;
        self.currentLoadingNative = item;
        self.adLoadStartTime = [NSDate date];
        [item load];
    });
}

#pragma mark - CLXAdapterNativeDelegate

- (void)closeWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:@"Native clicked"];
    [native destroy];
    self.loadNativeTimesCount = 0;
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(closeWithNative:)]) {
        [self.delegate closeWithNative:native];
    }
    if ([self.delegate respondsToSelector:@selector(closedByUserActionWithAd:)]) {
        [self.delegate closedByUserActionWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
    }
}

- (void)didLoadWithNative:(id<CLXAdapterNative>)native {
    if (native.timeout) {
        [native destroy];
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Native did load %@", self.placementID]];
    NSTimeInterval latency = 0;
    if (self.adLoadStartTime) {
        latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
    }
    
    [self.appSessionService adLoadedWithPlacementID:self.placementID latency:latency];
    
    [self.previousNative setDelegate:nil];
    [self.previousNative destroy];
    [[self.previousNative nativeView] removeFromSuperview];
    
    self.nativeOnScreen = self.currentLoadingNative;
    self.successWin = YES;
    
    if (self.lastBidResponse) {
        [self.reportingService winWithBidID:self.lastBidResponse.bidID];
    }
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
        [self.delegate didLoadWithNative:native];
    }
            if ([self.delegate respondsToSelector:@selector(didLoadWithAd:)]) {
            CLXAd *delegateAd = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
            [self.delegate didLoadWithAd:delegateAd];
        }
    
    __weak typeof(self) weakSelf = self;
    [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
        [weakSelf timerDidReachEnd];
    }];
}

- (void)failToLoadWithNative:(nullable id<CLXAdapterNative>)native error:(nullable NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Native fail to load %@", error.localizedDescription ?: @"unknown"]];
    [self.appSessionService adFailedToLoadWithPlacementID:self.placementID];
    
    if (native && native.timeout) {
        [native destroy];
        return;
    }
    
    [native destroy];
    self.lastBidResponse = nil;
    self.successWin = NO;
    
    NSError *backoffError;
    NSTimeInterval delay = [self.waterfallBackoffAlgorithm nextDelayWithError:&backoffError];
    if (backoffError) {
        delay = 1.0;
    }
    
    // Early return if retries are disabled
    if (![CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                     settings:[CLXSettings sharedInstance] 
                                       logger:self.logger 
                                 failureBlock:nil]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    if (delay == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf requestNativeUpdate];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf requestNativeUpdate];
        });
    }
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(failToLoadWithNative:error:)]) {
        NSError *cloudXError = [NSError errorWithDomain:@"CLXErrorDomain"
                                                   code:CLXErrorCodeNoFill
                                               userInfo:nil];
        [self.delegate failToLoadWithNative:native error:cloudXError];
    }
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        NSError *cloudXError = [NSError errorWithDomain:@"CLXErrorDomain"
                                                   code:CLXErrorCodeNoFill
                                               userInfo:nil];
        [self.delegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName] error:cloudXError];
    }
}

- (void)didShowWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:@"[CloudX][Native] Native ad shown"];
    
    // Report impression if we have a bid response
    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"[CloudX][Native] Reporting impression for bidID=%@", self.lastBidResponse.bidID]];
        
        // Report impression to reporting service
        [self.reportingService impressionWithBidID:self.lastBidResponse.bidID];
        
        // Add spend to app session service
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:self.lastBidResponse.price];
        
        // Add impression to app session service
        [self.appSessionService addImpressionWithPlacementID:self.placementID];
    }
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(didShowWithNative:)]) {
        [self.delegate didShowWithNative:native];
    }
    if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
        [self.delegate didShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName]];
    }
}

- (void)impressionWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:[NSString stringWithFormat:@"Native impression %@", self.placementID]];
    
    if (self.lastBidResponse) {
        [self.reportingService impressionWithBidID:self.lastBidResponse.bidID];
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:self.lastBidResponse.price];
        [self.appSessionService addImpressionWithPlacementID:self.placementID];
        
        // Send Rill tracking impression event
        [self.rillTrackingService sendImpressionEvent];
        
        // Fire NURL for native impression with revenue callback
        if (self.lastBidResponse.nurl) {
            [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherNative] Firing NURL for native impression with revenue callback: bidID=%@, price=%.2f", self.lastBidResponse.bidID, self.lastBidResponse.price]];
            
            __weak typeof(self) weakSelf = self;
            [self.reportingService fireNurlForRevenueWithPrice:self.lastBidResponse.price nUrl:self.lastBidResponse.nurl completion:^(BOOL success, CLXAd * _Nullable ad) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                if (success) {
                    // Create CLXAd object and trigger revenue callback
                    CLXAd *adObject = [CLXAd adFromBid:strongSelf.lastBidResponse.bid placementId:strongSelf.placementID];
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(revenuePaid:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf.delegate revenuePaid:adObject];
                        });
                    }
                }
            }];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherNative] No NURL to fire for native: bidID=%@", self.lastBidResponse.bidID]];
        }
    }
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:native];
    }
            if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
            CLXAd *impressionAd = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
            [self.delegate impressionOn:impressionAd];
        }
}

- (void)clickWithNative:(id<CLXAdapterNative>)native {
    [self.logger debug:@"Native clicked"];
    
    // Call appSessionService.addClick
    [self.appSessionService addClickWithPlacementID:self.placementID];
    
    // Send Rill tracking click event
    [self.rillTrackingService sendClickEvent];
    
    // Call both old and new delegate methods for backward compatibility
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:native];
    }
            if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
            CLXAd *clickAd = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID placementName:self.placementName];
            [self.delegate didClickWithAd:clickAd];
        }
}

#pragma mark - CLXAdLifecycle

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"Destroying native ad for placement: %@", self.placementID]];
    
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
