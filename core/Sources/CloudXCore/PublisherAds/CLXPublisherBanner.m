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

#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXBannerTimerService.h>


#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillTrackingService.h>

#import <CloudXCore/CLXXorEncryption.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPublisherBanner () <CLXAdapterBannerDelegate>

// CLXAdLifecycle properties
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL isDestroyed;

@property (nonatomic, strong, readwrite) CLXSettings *settings;

// Private properties
@property (nonatomic, strong, nullable) id<CLXBidAdSourceProtocol> bidAdSource;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *adFactories;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, strong, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> currentLoadingBanner;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> previousBanner;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> bannerOnScreen;
@property (nonatomic, assign) NSTimeInterval refreshSeconds;
@property (nonatomic, strong) CLXBannerTimerService *timerService;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *dealID;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong, nullable) id requestBannerTask;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, assign) BOOL successWin;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong, nullable) NSDate *lastManualRefreshTime;

// Visibility and prefetch properties
@property (nonatomic, assign, readwrite) BOOL isVisible;
@property (nonatomic, assign) BOOL hasPendingRefresh;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> prefetchedBanner;
@property (nonatomic, assign) NSInteger loadBannerTimesCount;
@property (nonatomic, copy) NSString *placementSuffix;
@property (nonatomic, assign) NSInteger impressionIndexStart;
@property (nonatomic, assign) NSInteger impressionIndexEnd;
@property (nonatomic, strong) CLXSDKConfigPlacement *placement;
@property (nonatomic, strong) CLXConfigImpressionModel *impModel;
@property (nonatomic, strong, nullable) NSNumber *tmax;
@property (nonatomic, strong, nullable) NSDate *adLoadStartTime;
// Rill tracking service for analytics events
@property (nonatomic, strong) CLXRillTrackingService *rillTrackingService;
@property (nonatomic, strong) id<CLXAppSessionService> appSessionService;


@end

@implementation CLXPublisherBanner



#pragma mark - Initialization

- (instancetype)initWithViewController:(UIViewController *)viewController
                             placement:(CLXSDKConfigPlacement *)placement
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXBannerDelegate>)delegate
                             bannerType:(CLXBannerType)bannerType
                   waterfallMaxBackOffTime:(NSTimeInterval)waterfallMaxBackOffTime
                                  impModel:(CLXConfigImpressionModel *)impModel
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
        _adFactories = [adFactories copy];
        _viewController = viewController;
        _refreshSeconds = (placement.bannerRefreshRateMs ?: 10000) / 1000.0;
        _placementID = [placement.id copy];
        _dealID = [placement.dealId copy];
        _reportingService = reportingService;
        _impModel = impModel;
        _placement = placement;
        _placementSuffix = [placement.firstImpressionPlacementSuffix ?: @"" copy];
        _impressionIndexStart = placement.firstImpressionLoopIndexStart ?: 0;
        _impressionIndexEnd = placement.firstImpressionLoopIndexEnd ?: 0;
        _isReady = NO;
        _isLoading = NO;
        _isDestroyed = NO;
        _forceStop = NO;
        _successWin = NO;
        _autoRefreshEnabled = YES; // Auto-refresh is enabled by default
        _loadBannerTimesCount = 0;
        // Initialize Rill tracking service
        _rillTrackingService = [[CLXRillTrackingService alloc] initWithReportingService:reportingService];
        
        _logger = [[CLXLogger alloc] initWithCategory:@"CloudXBanner"];
        
        // Initialize waterfall backoff algorithm
        // Initialize visibility and prefetch properties
        _isVisible = YES;
        _hasPendingRefresh = NO;
        _prefetchedBanner = nil;
        
        // Initialize timer service
        _timerService = [[CLXBannerTimerService alloc] init];
        
        // Initialize app session service (singleton)
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreBannerAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreBannerSessionIDKey] ?: @"";
        _appSessionService = [[CLXAppSessionServiceImplementation alloc] initWithSessionID:sessionID
                                                                                  appKey:appKey
                                                                                     url:@"https://ads.cloudx.io/metrics?a=test"];
        
        // Initialize bid ad source
        BOOL hasCloseButton = placement.hasCloseButton ?: NO;
        NSInteger adType = (bannerType == CLXBannerTypeW320H50) ? CLXAdTypeBanner : CLXAdTypeMrec;
        
        __weak typeof(self) weakSelf = self;
        _bidAdSource = [[CLXBidAdSource alloc] initWithUserID:userID
                                               placementID:_placementID
                                                    dealID:_dealID
                                             hasCloseButton:hasCloseButton
                                               publisherID:publisherID
                                                    adType:adType
                                            bidTokenSources:bidTokenSources
                                     nativeAdRequirements:nil
                                                      tmax:tmax
                                           reportingService:_reportingService
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
        
        [_logger debug:[NSString stringWithFormat:@"Initialized PublisherBanner for placement: %@", _placementID]];
    }
    return self;
}

#pragma mark - CloudXBanner Protocol

- (void)load {
    [self.logger info:[NSString stringWithFormat:@"🚀 [PublisherBanner] load() called for placement: %@", self.placementID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Current isLoading state: %d", self.isLoading]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Current forceStop state: %d", self.forceStop]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Current bannerOnScreen: %@", self.bannerOnScreen]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Current currentLoadingBanner: %@", self.currentLoadingBanner]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] CLXBidAdSource exists: %d", self.bidAdSource != nil]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] AdFactories count: %lu", (unsigned long)self.adFactories.count]];
    
    if (self.isLoading) {
        [self.logger debug:[NSString stringWithFormat:@"⚠️ [PublisherBanner] Banner load already in progress for placement: %@", self.placementID]];
        return;
    }
    
    if (self.forceStop) {
        [self.logger debug:[NSString stringWithFormat:@"⚠️ [PublisherBanner] Banner load stopped due to forceStop flag for placement: %@", self.placementID]];
        return;
    }
    
    if (!self.bidAdSource) {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherBanner] No CLXBidAdSource available for placement: %@", self.placementID]];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Starting banner load process for placement: %@", self.placementID]];
    self.isLoading = YES;
    self.adLoadStartTime = [NSDate date];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Ad load start time set: %@", self.adLoadStartTime]];
    
    // Implement async banner update request
    [self requestBannerUpdate];
}

#pragma mark - Private Methods

- (void)requestBannerUpdate {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherBanner] requestBannerUpdate() called for placement: %@", self.placementID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] forceStop state: %d", self.forceStop]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] isLoading state: %d", self.isLoading]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] loadBannerTimesCount: %ld", (long)self.loadBannerTimesCount]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] successWin state: %d", self.successWin]];
    
    if (self.forceStop) {
        [self.logger debug:@"⚠️ [PublisherBanner] Request stopped due to forceStop flag"];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Requesting banner update for placement: %@", self.placementID]];
    
    // Implement async bid request logic
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Sending loop-index: %ld for adId: %@", (long)self.loadBannerTimesCount, self.placementID]];
    
    // Update bid request with loop index
    [self updateBidRequestWithLoopIndex];
    
    // Use placement ID directly as stored impression ID
    NSString *storedImpressionId = self.placementID;
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Using placement ID as stored impression ID: %@", storedImpressionId]];
    
    // Request bid from bid ad source
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherBanner] Calling bidAdSource requestBidWithAdUnitID: %@", self.placementID]];
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.placementID
                           storedImpressionId:storedImpressionId
                                    impModel:self.impModel
                                   successWin:self.successWin
                                   completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [self.logger error:@"❌ [PublisherBanner] Self reference lost in bid completion block"];
            return;
        }
        
        [self.logger debug:@"📥 [PublisherBanner] Bid request completion called"];
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Response: %@", response]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error: %@", error]];
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [PublisherBanner] Bid request failed with error: %@", error.localizedDescription]];
            [self.logger error:[NSString stringWithFormat:@"📊 [PublisherBanner] Error domain: %@", error.domain]];
            [self.logger error:[NSString stringWithFormat:@"📊 [PublisherBanner] Error code: %ld", (long)error.code]];
            [self.logger error:[NSString stringWithFormat:@"📊 [PublisherBanner] Error user info: %@", error.userInfo]];
            
            // Continue with waterfall - let continueBannerChain handle the error
            [strongSelf continueBannerChain];
            return;
        }
        
        if (!response) {
            [self.logger error:@"❌ [PublisherBanner] Bid request returned nil response"];
            
            // Continue with waterfall - let continueBannerChain handle the nil response
            [strongSelf continueBannerChain];
            return;
        }
        
        [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Bid response received - Network: %@, BidID: %@, Price: %.2f, CreateBidAd: %d", response.networkName, response.bidID, response.price, response.createBidAd != nil]];
        
        strongSelf.lastBidResponse = response;
        
        // Store the full bid response for LURL firing by getting it from bidAdSource
        strongSelf.currentBidResponse = [strongSelf.bidAdSource getCurrentBidResponse];
        
        // Set up Rill tracking data
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
    
        // Increment load counter
        strongSelf.loadBannerTimesCount += 1;
        
        // Continue banner chain
        [strongSelf continueBannerChain];
    }];
}

- (void)continueBannerChain {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [PublisherBanner] continueBannerChain() called for placement: %@", self.placementID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] forceStop state: %d", self.forceStop]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] isLoading state: %d", self.isLoading]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] lastBidResponse exists: %d", self.lastBidResponse != nil]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] createBidAd function exists: %d", self.lastBidResponse.createBidAd != nil]];
    
    if (self.forceStop) {
        [self.logger debug:@"⚠️ [PublisherBanner] Banner chain stopped due to forceStop flag"];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Continuing banner chain for placement: %@", self.placementID]];
    
    // Implement actual banner creation from bid response
    if (self.lastBidResponse && self.lastBidResponse.createBidAd) {
        [self.logger debug:@"🔧 [PublisherBanner] Calling createBidAd function..."];
        id bidItem = self.lastBidResponse.createBidAd();
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] createBidAd returned: %@", bidItem]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Bid item class: %@", NSStringFromClass([bidItem class])]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Bid item conforms to CLXAdapterBanner: %d", [bidItem conformsToProtocol:@protocol(CLXAdapterBanner)]]];
        
        if ([bidItem conformsToProtocol:@protocol(CLXAdapterBanner)]) {
            id<CLXAdapterBanner> banner = (id<CLXAdapterBanner>)bidItem;
            [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Successfully created banner from bid for placement: %@", self.placementID]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner object: %@", banner]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner class: %@", NSStringFromClass([(NSObject *)banner class])]];
            [self loadAdItem:banner];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [PublisherBanner] Bid item creation failed - Item: %@, ConformsToProtocol: %d", bidItem, bidItem ? [bidItem conformsToProtocol:@protocol(CLXAdapterBanner)] : NO]];
            
            // Treat as technical error - create appropriate error and handle per spec
            NSError *technicalError = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                                   description:@"Banner adapter creation failed"];
            
            [self failToLoadBanner:nil error:technicalError];
        }
    } else {
        [self.logger error:[NSString stringWithFormat:@"❌ [PublisherBanner] Waterfall exhausted - lastBidResponse: %@, createBidAd: %@", self.lastBidResponse, self.lastBidResponse.createBidAd]];
        
        // Waterfall exhausted - create NO_FILL error and handle per spec
        NSError *noFillError = [CLXError errorWithCode:CLXErrorCodeNoFill 
                                           description:@"No ad available - waterfall exhausted"];
        
        [self failToLoadBanner:nil error:noFillError];
    }
}

- (nullable id<CLXAdapterBanner>)createBannerInstanceWithAdId:(NSString *)adId
                                                           bidId:(NSString *)bidId
                                                              adm:(NSString *)adm
                                                    adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                                             burl:(nullable NSString *)burl
                                                   hasClosedButton:(BOOL)hasClosedButton
                                                           network:(NSString *)network {
    [self.logger debug:[NSString stringWithFormat:@"Creating banner instance - AdID: %@, BidID: %@, Network: %@", adId, bidId, network]];
    
    id<CLXAdapterBannerFactory> factory = self.adFactories[network];
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
    [self.logger debug:@"⏰ [PublisherBanner] Timer reached end"];
    
    if (!self.autoRefreshEnabled) {
        [self.logger debug:@"🚫 [PublisherBanner] Auto-refresh is disabled - skipping refresh"];
        return;
    }
    
    if (self.isVisible) {
        [self.logger debug:@"📱 [PublisherBanner] Banner is visible - requesting update"];
        self.previousBanner = self.currentLoadingBanner;
        [self requestBannerUpdate];
    } else {
        [self.logger debug:@"👁️ [PublisherBanner] Banner is hidden - queuing refresh for when visible"];
        self.hasPendingRefresh = YES;
    }
}

- (void)updateBidRequestWithLoopIndex {
    NSDictionary<NSString *, NSString *> *existingUserDict = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreBannerUserKeyValueKey];
    NSMutableDictionary<NSString *, NSString *> *userDict = existingUserDict ? [existingUserDict mutableCopy] : [NSMutableDictionary dictionary];
    userDict[@"loop-index"] = [NSString stringWithFormat:@"%ld", (long)self.loadBannerTimesCount];
    [[NSUserDefaults standardUserDefaults] setObject:userDict forKey:kCLXCoreBannerUserKeyValueKey];
    [self.logger debug:[NSString stringWithFormat:@"updated auction api call with loop-index: %ld", (long)self.loadBannerTimesCount]];
}

- (void)loadAdItem:(id<CLXAdapterBanner>)item {
    [self.logger info:[NSString stringWithFormat:@"🔧 [PublisherBanner] Loading %@ for placement %@", NSStringFromClass([(NSObject *)item class]), self.placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        item.timeout = NO;
        self.currentLoadingBanner = item;
        self.adLoadStartTime = [NSDate date];
        [self.logger debug:@"📊 [PublisherBanner] Calling item.load()"];
        [item load];
        [self.logger info:@"✅ [PublisherBanner] load() called successfully on AdapterBanner"];
    });
}

#pragma mark - CloudXAdapterBannerDelegate

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] didLoadBanner delegate called for placement: %@", self.placementID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner object: %@", banner]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner class: %@", NSStringFromClass([(NSObject *)banner class])]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner timeout: %d", banner.timeout]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner bannerView: %@", banner.bannerView]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner sdkVersion: %@", banner.sdkVersion]];

    if (banner.timeout) {
        [self.logger debug:@"⚠️ [PublisherBanner] Banner had timeout=true, destroying banner"];
        [banner destroy];
        return;
    }

    NSTimeInterval latency = 0;
    if (self.adLoadStartTime) {
        latency = [[NSDate date] timeIntervalSinceDate:self.adLoadStartTime] * 1000;
    }
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Ad loaded with latency: %f ms", latency]];
    [self.appSessionService adLoadedWithPlacementID:self.placementID latency:latency];
    
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

    [self.logger debug:@"🔧 [PublisherBanner] Cleaning up previous banner..."];
    if (self.previousBanner) {
        [self.logger debug:@"📊 [PublisherBanner] Previous banner exists, cleaning up"];
        self.previousBanner.delegate = nil;
        [self.previousBanner destroy];
        [self.previousBanner.bannerView removeFromSuperview];
    } else {
        [self.logger debug:@"📊 [PublisherBanner] No previous banner to clean up"];
    }

    [self.logger debug:@"🔧 [PublisherBanner] Setting banner states..."];
    self.successWin = YES;
    self.isReady = YES;
    self.isLoading = NO;
    
    // Handle visibility-aware display and prefetching
    if (self.isVisible) {
        [self.logger debug:@"📱 [PublisherBanner] Banner is visible - displaying immediately"];
        self.bannerOnScreen = self.currentLoadingBanner;
    } else {
        [self.logger debug:@"👁️ [PublisherBanner] Banner is hidden - prefetching for later display"];
        self.prefetchedBanner = self.currentLoadingBanner;
    }
    
    [self.logger debug:@"📊 [PublisherBanner] States updated:"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] - bannerOnScreen: %@", self.bannerOnScreen]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] - prefetchedBanner: %@", self.prefetchedBanner]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] - successWin: %d", self.successWin]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] - isReady: %d", self.isReady]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] - isLoading: %d", self.isLoading]];

    [self.logger info:@"✅ [PublisherBanner] Banner did load successfully"];

    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Reporting win for bidID=%@", self.lastBidResponse.bidID]];
        [self.reportingService winWithBidID:self.lastBidResponse.bidID];
        
        // Revenue tracking moved to impression callback - don't fire NURL on load
    } else {
        [self.logger debug:@"⚠️ [PublisherBanner] No lastBidResponse to report win"];
    }

    // Call the publisher delegate immediately upon successful load (industry standard)
    // This follows Google AdMob, AppLovin MAX, IronSource pattern
    if ([self.delegate respondsToSelector:@selector(didLoadWithAd:)]) {
        [self.delegate didLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID]];
    }

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
        [self.logger debug:@"🔧 [PublisherBanner] Starting timer service for next auto-refresh cycle..."];
        [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
            [self.logger debug:@"⏰ [PublisherBanner] Timer reached end, calling timerDidReachEnd"];
            [self timerDidReachEnd];
        }];
    } else {
        [self.logger debug:@"⏸️ [PublisherBanner] Auto-refresh disabled - not starting timer"];
    }
    
    [self.logger info:@"✅ [PublisherBanner] didLoadBanner delegate method completed successfully"];
}

- (void)fireLosingBidLurls {
    if (!self.currentBidResponse || !self.lastBidResponse) {
        [self.logger debug:@"📊 [PublisherBanner] No bid response available for lurl firing"];
        return;
    }
    
    NSArray<CLXBidResponseBid *> *allBids = [self.currentBidResponse getAllBidsForWaterfall];
    NSString *winnerBidId = self.lastBidResponse.bidID;
    
    [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherBanner] Firing lurls for losing bids (winner: %@)", winnerBidId]];
    
    for (CLXBidResponseBid *bid in allBids) {
        // Skip the winner
        if ([bid.id isEqualToString:winnerBidId]) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Skipping lurl for winner bid rank=%ld, id=%@", (long)bid.ext.cloudx.rank, bid.id]];
            continue;
        }
        
        // Fire lurl for losing bid
        if (bid.lurl && bid.lurl.length > 0) {
            [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherBanner] Firing lurl for losing bid rank=%ld, reason=LostToHigherBid", (long)bid.ext.cloudx.rank]];
            [self.reportingService fireLurlWithUrl:bid.lurl reason:CLXLossReasonLostToHigherBid];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] No lurl to fire for losing bid rank=%ld", (long)bid.ext.cloudx.rank]];
        }
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [PublisherBanner] Completed firing lurls for losing bids"]];
}


- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ [PublisherBanner] failToLoadBanner delegate called for placement: %@", self.placementID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner object: %@", banner]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Banner class: %@", banner ? NSStringFromClass([(NSObject *)banner class]) : @"nil"]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error: %@", error]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error domain: %@", error.domain]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error code: %ld", (long)error.code]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error description: %@", error.localizedDescription]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Error user info: %@", error.userInfo]];
    
    [self.appSessionService adFailedToLoadWithPlacementID:self.placementID];

    // Destroy the failed banner
    [self.logger debug:@"🔧 [PublisherBanner] Cleaning up failed banner..."];
    [banner destroy];
    
    // Fire LURL for technical errors
    if (self.lastBidResponse && self.lastBidResponse.bid.lurl && self.lastBidResponse.bid.lurl.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [PublisherBanner] Firing lurl for failed winner rank=%ld, reason=TechnicalError", (long)self.lastBidResponse.bid.ext.cloudx.rank]];
        [self.reportingService fireLurlWithUrl:self.lastBidResponse.bid.lurl reason:CLXLossReasonTechnicalError];
    }
    
    // Reset state for next interval
    [self.logger debug:@"📊 [PublisherBanner] Resetting state for next interval"];
    self.lastBidResponse = nil;
    self.currentBidResponse = nil;
    self.successWin = NO;
    self.isReady = NO;
    self.isLoading = NO;
    
    // Convert bid source errors to appropriate CLXError codes for publisher delegate
    NSError *delegateError = error;
    if (error && [error.domain isEqualToString:@"CLXBidAdSource"]) {
        if (error.code == CLXBidAdSourceErrorNoBid) {
            // Convert waterfall exhaustion to NO_FILL error
            delegateError = [CLXError errorWithCode:CLXErrorCodeNoFill 
                                         description:@"No ad available - waterfall exhausted"];
            [self.logger debug:@"🔄 [PublisherBanner] Converted CLXBidAdSource error to CLXErrorCodeNoFill"];
        } else {
            // Convert other bid source errors to generic load failed
            delegateError = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                         description:error.localizedDescription ?: @"Ad failed to load"];
            [self.logger debug:@"🔄 [PublisherBanner] Converted CLXBidAdSource error to CLXErrorCodeLoadFailed"];
        }
    }
    
    // Start timer for next refresh interval (no banner-level retry)
    [self.logger debug:@"🔧 [PublisherBanner] Starting timer for next refresh interval..."];
    [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
        [self.logger debug:@"⏰ [PublisherBanner] Timer reached end, calling timerDidReachEnd"];
        [self timerDidReachEnd];
    }];
    
    // Emit error to delegate
    [self.logger debug:@"🔧 [PublisherBanner] Calling delegate failToLoadWithAd..."];
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        [self.logger info:@"✅ [PublisherBanner] Delegate responds to failToLoadWithAd:error:, calling..."];
        [self.delegate failToLoadWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID] error:delegateError];
    } else {
        [self.logger debug:@"⚠️ [PublisherBanner] Delegate does not respond to failToLoadWithAd:error:"];
    }
    
    [self.logger info:@"✅ [PublisherBanner] failToLoadBanner delegate method completed"];
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
        [self.delegate didShowWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID]];
    }
}

- (void)impressionBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] impression delegate called for placement: %@", self.placementID]];
    if (self.lastBidResponse) {
        [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] Reporting impression for bidID=%@", self.lastBidResponse.bidID]];
        [self.appSessionService addImpressionWithPlacementID:self.placementID];
        [self.appSessionService addSpendWithPlacementID:self.placementID spend:self.lastBidResponse.price];
        [self.reportingService impressionWithBidID:self.lastBidResponse.bidID];
        
        // Fire NURL for revenue tracking on impression (industry standard)
        if (self.lastBidResponse.nurl && self.lastBidResponse.nurl.length > 0) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] Firing NURL on impression for bidID=%@", self.lastBidResponse.bidID]];
            __weak typeof(self) weakSelf = self;
            [self.reportingService fireNurlForRevenueWithPrice:self.lastBidResponse.price nUrl:self.lastBidResponse.nurl completion:^(BOOL success, CLXAd * _Nullable ad) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                if (success) {
                    CLXAd *adObject = [CLXAd adFromBid:strongSelf.lastBidResponse.bid placementId:strongSelf.placementID];
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(revenuePaid:)]) {
                        [strongSelf.delegate revenuePaid:adObject];
                    }
                }
            }];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"📊 [PublisherBanner] No NURL to fire on impression for bidID=%@", self.lastBidResponse.bidID]];
        }
        
        // Send Rill tracking impression event
        [self.rillTrackingService sendImpressionEvent];
    }
    if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
        [self.delegate impressionOn:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID]];
    }
}

- (void)clickBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] click delegate called for placement: %@", self.placementID]];
    [self.appSessionService addClickWithPlacementID:self.placementID];
    // Send Rill tracking click event
    [self.rillTrackingService sendClickEvent];
    if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
        [self.delegate didClickWithAd:[CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID]];
    }
}

- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] closedByUserAction delegate called for placement: %@", self.placementID]];
    [self.appSessionService addCloseWithPlacementID:self.placementID latency:1.0];
    self.loadBannerTimesCount = 0;
    if ([self.delegate respondsToSelector:@selector(closedByUserActionWithAd:)]) {
        CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID];
        [self.delegate closedByUserActionWithAd:adObject];
    }
}

- (void)didExpandBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] didExpandBanner delegate called for placement: %@", self.placementID]];
    if ([self.delegate respondsToSelector:@selector(didExpandAd:)]) {
        CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID];
        [self.delegate didExpandAd:adObject];
    }
}

- (void)didCollapseBanner:(id<CLXAdapterBanner>)banner {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] didCollapseBanner delegate called for placement: %@", self.placementID]];
    if ([self.delegate respondsToSelector:@selector(didCollapseAd:)]) {
        CLXAd *adObject = [CLXAd adFromBid:self.lastBidResponse.bid placementId:self.placementID];
        [self.delegate didCollapseAd:adObject];
    }
}

#pragma mark - CLXAdLifecycle

- (void)destroy {
    [self.logger debug:[NSString stringWithFormat:@"[CloudX][Banner] Destroying banner for placement: %@", self.placementID]];
    
    self.isDestroyed = YES;
    self.isLoading = NO;
    self.isReady = NO;
    
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
    
    // Clear pending refresh flag
    self.hasPendingRefresh = NO;
    
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
        [self.logger debug:[NSString stringWithFormat:@"📱 [PublisherBanner] Visibility changed to: %@", visible ? @"visible" : @"hidden"]];
        
        if (visible) {
            // Banner became visible - execute any pending refresh
            if (self.hasPendingRefresh && self.autoRefreshEnabled) {
                self.hasPendingRefresh = NO;
                [self.logger debug:@"🔄 [PublisherBanner] Executing pending refresh after becoming visible"];
                [self load];
            }
            
            // Display any prefetched banner
            if (self.prefetchedBanner) {
                [self.logger debug:@"📦 [PublisherBanner] Displaying prefetched banner"];
                self.bannerOnScreen = self.prefetchedBanner;
                self.prefetchedBanner = nil;
                // Note: didLoadWithAd was already called when banner loaded successfully
                // Industry standard: don't call delegate again when displaying prefetched banner
            }
        } else {
            // Banner became hidden - no immediate action needed
            [self.logger debug:@"🙈 [PublisherBanner] Banner is now hidden"];
        }
    }
}

- (void)startAutoRefresh {
    [self.logger debug:@"▶️ [PublisherBanner] Starting auto-refresh"];
    self.autoRefreshEnabled = YES;
    
    // Check for rate limiting (minimum 30 seconds between manual refreshes)
    NSTimeInterval minRefreshInterval = 30.0; // Industry standard: 30-60 seconds
    NSDate *now = [NSDate date];
    
    BOOL shouldRefreshImmediately = YES;
    if (self.lastManualRefreshTime) {
        NSTimeInterval timeSinceLastRefresh = [now timeIntervalSinceDate:self.lastManualRefreshTime];
        if (timeSinceLastRefresh < minRefreshInterval) {
            shouldRefreshImmediately = NO;
            [self.logger debug:[NSString stringWithFormat:@"🛡️ [PublisherBanner] Rate limiting: %.1f seconds since last manual refresh (min: %.1f)", 
                                              timeSinceLastRefresh, minRefreshInterval]];
        }
    }
    
    // If there's a pending refresh and banner is visible, execute it now
    if (self.hasPendingRefresh && self.isVisible) {
        self.hasPendingRefresh = NO;
        [self.logger debug:@"🔄 [PublisherBanner] Executing pending refresh after enabling auto-refresh"];
        [self load];
        self.lastManualRefreshTime = now;
    }
    // Industry standard: Immediate refresh when auto-refresh is started (with rate limiting)
    else if (self.bannerOnScreen && self.isVisible && shouldRefreshImmediately) {
        [self.logger debug:@"🚀 [PublisherBanner] Immediate refresh on auto-refresh start (industry standard)"];
        [self load];
        self.lastManualRefreshTime = now;
    }
    // Start timer for next refresh cycle
    else if (self.bannerOnScreen && self.isVisible) {
        [self.logger debug:@"🔧 [PublisherBanner] Starting timer service for next auto-refresh cycle..."];
        [self.timerService startCountDownWithDeadline:self.refreshSeconds completion:^{
            [self.logger debug:@"⏰ [PublisherBanner] Timer reached end, calling timerDidReachEnd"];
            [self timerDidReachEnd];
        }];
    }
}

- (void)stopAutoRefresh {
    [self.logger debug:@"⏹️ [PublisherBanner] Stopping auto-refresh"];
    self.autoRefreshEnabled = NO;
    
    // Stop the current timer
    [self.logger debug:@"🔧 [PublisherBanner] Stopping timer service..."];
    [self.timerService stop];
}


@end

NS_ASSUME_NONNULL_END 
