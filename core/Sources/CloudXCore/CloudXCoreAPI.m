#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXGPPProvider.h>
#import <CloudXCore/CLXErrorReporter.h>
@class CLXAppSessionService;
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAdapterFactoryResolver.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CLXCoreDataManager.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidderConfig.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

// Adapter Protocols
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>
#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXBidTokenSource.h>

// Publisher Ads
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBanner.h>
#import <CloudXCore/CLXBannerAdView.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXInterstitial.h>
#import <CloudXCore/CLXInterstitialDelegate.h>
#import <CloudXCore/CLXRewardedInterstitial.h>
#import <CloudXCore/CLXRewardedDelegate.h>
#import <CloudXCore/CLXFullscreenAd.h>
#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeAdView.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXNativeDelegate.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXPublisherFullscreenAd.h>

@interface CloudXCore ()
@property (nonatomic, strong) id<CLXInitService> initService;
@property (nonatomic, strong) CLXSDKConfigResponse *sdkConfig;
@property (nonatomic, assign) BOOL isInitialised;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, strong) NSDictionary<NSString *, id> *adNetworkConfigs;
@property (nonatomic, strong) NSDictionary<NSString *, id> *adPlacements;
@property (nonatomic, strong) id adFactory;
@property (nonatomic, strong) id reportingService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) double abTestValue;
@property (nonatomic, copy) NSString *abTestName;
@property (nonatomic, copy) NSString *defaultAuctionURL;
@property (nonatomic, strong) CLXMetricsTracker *metricsTracker;
@property (nonatomic, strong) CLXCoreDataManager *coreDataManager;
@property (nonatomic, strong) CLXGeoLocationService *geoLocationService;
@property (nonatomic, strong) CLXAppSessionService *appSessionService;
@property (nonatomic, strong) CLXBidNetworkServiceClass *bidNetworkService;
@property (nonatomic, strong) CLXAdNetworkFactories *adNetworkFactories;
@end

static CloudXCore *_sharedInstance = nil;

@implementation CloudXCore

+ (CloudXCore *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[CloudXCore alloc] init];
    });
    return _sharedInstance;
}

/**
 * Ensures DI container is properly set up with core dependencies
 * This method is idempotent and safe to call multiple times
 * Critical for tests that bypass +shared singleton pattern
 */
- (void)ensureDIContainerSetup {
    CLXDIContainer *container = [CLXDIContainer shared];
    
    // Thread-safe registration using @synchronized
    // This prevents race conditions during concurrent CloudXCore initialization
    @synchronized([CLXDIContainer class]) {
        // Register core dependencies that other services depend on
        // Check-then-register pattern is now thread-safe within the synchronized block
        if (![container resolveType:ServiceTypeSingleton class:[CLXMetricsTracker class]]) {
            [container registerType:[CLXMetricsTracker class] instance:[[CLXMetricsTracker alloc] init]];
        }
        
        if (![container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]]) {
            [container registerType:[CLXLiveInitService class] instance:[[CLXLiveInitService alloc] init]];
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Ensure DI container is always properly initialized, regardless of how CloudXCore is instantiated
        // This is critical for tests that create new instances instead of using +shared
        [self ensureDIContainerSetup];
        
        _logger = [[CLXLogger alloc] initWithCategory:@"CloudXCoreAPI.m"];
        [self.logger debug:@"🔧 [CloudXCore] Initializing CloudXCore instance"];
        _isInitialised = NO;
        _abTestValue = (double)arc4random() / UINT32_MAX;
        _abTestName = @"RandomTest";
        // Default auction URL now comes from SDK response only
        _defaultAuctionURL = @"";
        _logsData = [NSDictionary dictionary];
        
        [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] Instance initialized - AB Test: %@ (%.3f), Default URL: %@", _abTestName, _abTestValue, _defaultAuctionURL]];
    }
    return self;
}

+ (void)logCloudXMessage {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXCore"];
    [logger info:@"Hello from CloudXCore!"];
}

- (NSString *)sdkVersion {
    return [CLXSystemInformation shared].sdkVersion;
}

- (BOOL)isInitialised {
    return _isInitialised;
}

- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [CloudXCore] initSDKWithAppKey called with appKey: %@", appKey]];
    
    // Thread-safe initialization check and setup
    @synchronized(self) {
        if (!appKey || appKey.length == 0) {
            [self.logger error:@"❌ [CloudXCore] AppKey is nil or empty"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized]);
            }
            return;
        }
        
        if (_isInitialised) {
            [self.logger debug:@"⚠️ [CloudXCore] SDK already initialized, returning early"];
            if (completion) {
                completion(YES, nil);
            }
            return;
        }
        
        // Reset metrics dictionary at start of initialization
        NSDictionary *dict = @{};
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kCLXCoreMetricsDictKey];
    }
    
    [self.logger debug:@"🔧 [CloudXCore] Starting SDK initialization process"];
    _appKey = [appKey copy];
    
    // Get init service from DI container
    CLXDIContainer *container = [CLXDIContainer shared];
    [self.logger debug:@"🔧 [CloudXCore] Attempting to resolve CLXLiveInitService from DI container"];
    _initService = [container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]];
    
    if (!_initService) {
        [self.logger error:@"❌ [CloudXCore] Failed to resolve InitService from DI container"];
        // Try to register it again as a fallback
        [self ensureDIContainerSetup];
        _initService = [container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]];
        if (!_initService) {
            [self.logger error:@"❌ [CloudXCore] Still failed to resolve InitService after re-registration"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized]);
            }
            return;
        } else {
            [self.logger debug:@"✅ [CloudXCore] InitService resolved after re-registration"];
        }
    } else {
        [self.logger debug:@"✅ [CloudXCore] InitService resolved successfully"];
    }
    
    [self.logger info:@"✅ [CloudXCore] InitService resolved, calling initSDKWithAppKey"];
    
    [_initService initSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] InitService failed with error: %@", error]];
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        if (!config) {
            [self.logger error:@"❌ [CloudXCore] InitService returned nil config"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized]);
            }
            return;
        }
        
        NSString *sessionID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:kCLXCoreSessionIDKey];
        
        NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
        NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
        if ([metricsDict.allKeys containsObject:@"method_sdk_init"]) {
            NSString *value = metricsDict[@"method_sdk_init"];
            int number = [value intValue];
            int new = number + 1;
            metricsDict[@"method_sdk_init"] = [NSString stringWithFormat:@"%d", new];
        } else {
            metricsDict[@"method_sdk_init"] = @"1";
        }
        [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];

        // Use SDK response URLs exclusively - no fallbacks
        if (!config.eventTrackingURL) {
            [self.logger error:@"❌ [CloudXCore] SDK init missing eventTrackingURL - reporting service will not work"];
        }
        _reportingService = [[CLXAdEventReporter alloc] initWithEndpoint:config.eventTrackingURL];
        
        NSMutableDictionary *geoHeaders = [NSMutableDictionary dictionary];
        if (config.geoHeaders) {
            for (CLXSDKConfigGeoBid *geoBid in config.geoHeaders) {
                geoHeaders[geoBid.source] = geoBid.target;
            }
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] geoHeaders Dictionary: %@", geoHeaders]];
            [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
        }
        
        // Generate unique auction ID for this impression
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:config
                                                                                      auctionID:auctionID
                                                                                  testGroupName:_abTestName];
        
        if (config.geoDataEndpointURL) { // @"https://geoip.cloudx.io"
            [self.reportingService geoTrackingWithURLString:config.geoDataEndpointURL extras:geoHeaders];
            NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
            NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
            if ([metricsDict.allKeys containsObject:@"network_call_geo_req"]) {
                NSString *value = metricsDict[@"network_call_geo_req"];
                int number = [value intValue];
                int new = number + 1;
                metricsDict[@"network_call_geo_req"] = [NSString stringWithFormat:@"%d", new];
            } else {
                metricsDict[@"network_call_geo_req"] = @"1";
            }
            [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
        }
        
        CLXRillImpressionModel *model = [[CLXRillImpressionModel alloc] initWithLastBidResponse:nil impModel:impModel adapterName:@"" loadBannerTimesCount:0 placementID:@""];
        
        NSString* encodedString = [CLXRillImpressionInitService createDataStringWithRillImpressionModel:model];
        
        [self.logger info:@"✅ [CloudXCore] InitService returned config, processing"];
        [self processSDKConfig:config completion:completion];
        
        NSString *accountId = impModel.accountID;
        NSString *payload = encodedString;
        
        [[NSUserDefaults standardUserDefaults] setObject:encodedString forKey:kCLXCoreEncodedStringKey];
        
        NSData *secret = [CLXXorEncryption generateXorSecret: accountId];
        NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64: accountId];
        
        NSString *encrypted = [CLXXorEncryption encrypt: payload secret: secret];
        
        NSString *safeEncrypted = [encrypted urlQueryEncodedString];
        
        NSString *safeCampaignId = [campaignId urlQueryEncodedString];
        
        if (encodedString.length > 0) {
            [self.reportingService rillTrackingWithActionString:@"sdkinitenc" campaignId: safeCampaignId encodedString: safeEncrypted];
        }
    }];
}

- (void)processSDKConfig:(CLXSDKConfigResponse *)config completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Processing SDK config - Session: %@, Account: %@, Bidders: %lu", config.sessionID, config.accountID, (unsigned long)config.bidders.count]];
    
    _sdkConfig = config;
    
    // Set the tracking configuration for Rill analytics
    [[CLXTrackingFieldResolver shared] setConfig:config];
    
    // Resolve adapters (like Swift SDK does)
    [self resolveAdapters];
    
    // Filter config (like Swift SDK does)
    [self filterConfig];
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Adapter resolution complete - Banners: %lu, Tokens: %lu, Placements: %lu", (unsigned long)_adNetworkFactories.banners.count, (unsigned long)_adNetworkFactories.bidTokenSources.count, (unsigned long)_adPlacements.count]];
    
    // Process bidders
    if (config.bidders && config.bidders.count > 0) {
        [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Processing %lu bidders", (unsigned long)config.bidders.count]];
    } else {
        [self.logger debug:@"⚠️ [CloudXCore] No bidders found in config"];
    }
    
    // Initialize network bidder adapters 
    NSDictionary *adNetworkInitializers = _adNetworkFactories.initializers;
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Initializing adapters - Available: %@", [adNetworkInitializers allKeys]]];
    
    if (adNetworkInitializers && adNetworkInitializers.count > 0) {
        for (CLXSDKConfigBidder *adNetworkConfig in config.bidders) {
            NSString *mappedNetworkName = adNetworkConfig.networkNameMapped;
            
            id<CLXAdNetworkInitializer> initializer = adNetworkInitializers[mappedNetworkName];
            if (!initializer) {
                [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] No initializer found for network: %@ (mapped from %@)", mappedNetworkName, adNetworkConfig.networkName]];
                continue;
            }
            
            // Convert SDKConfigBidder to CloudXBidderConfig 
            CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:adNetworkConfig.bidderInitData networkName:adNetworkConfig.networkName];
            
            [initializer initializeWithConfig:bidderConfig completion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] Successfully initialized network: %@", mappedNetworkName]];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Failed to initialize network: %@ - %@", mappedNetworkName, error.localizedDescription]];
                }
            }];
        }
    } else {
        [self.logger debug:@"⚠️ [CloudXCore] No ad network initializers found"];
    }
    
    // Store app key, account ID, and URLs from SDK response
    [[NSUserDefaults standardUserDefaults] setValue:_appKey forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:config.accountID forKey:kCLXCoreAccountIDKey];
    [[NSUserDefaults standardUserDefaults] setValue:config.metricsEndpointURL forKey:kCLXCoreMetricsUrlKey];
    
    // Store impression tracker URL for Rill tracking (reuse metrics key for now)
    if (config.impressionTrackerURL) {
        // For Rill tracking, use impression tracker URL if available, otherwise use metrics URL
        [[NSUserDefaults standardUserDefaults] setValue:config.impressionTrackerURL forKey:@"CLXCore_impressionTrackerUrl"];
    }
    
    // Use SDK response URLs exclusively - no fallbacks
    NSString *auctionEndpointUrl = @"";
    NSString *cdpEndpointUrl = @"";
    NSString *metricsEndpointURL = config.metricsEndpointURL ?: @"";
    
    // Extract auction endpoint URL from SDK response
    if (config.auctionEndpointURL) {
        id auctionValue = [config.auctionEndpointURL value];
        if ([auctionValue isKindOfClass:[NSString class]]) {
            auctionEndpointUrl = (NSString *)auctionValue;
        } else if ([auctionValue isKindOfClass:[CLXSDKConfigEndpointObject class]]) {
            auctionEndpointUrl = [self chooseEndpointWithObject:auctionValue value:_abTestValue];
        }
    } else {
        [self.logger error:@"❌ [CloudXCore] SDK init missing auctionEndpointURL - auction requests will fail"];
    }
    
    // Extract CDP endpoint URL from SDK response
    if (config.cdpEndpointURL) {
        cdpEndpointUrl = [self chooseEndpointWithObject:config.cdpEndpointURL value:1.0 - _abTestValue];
    }
    
    // Log missing metrics URL
    if (!config.metricsEndpointURL) {
        [self.logger error:@"❌ [CloudXCore] SDK init missing metricsEndpointURL - metrics tracking may not work"];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Endpoints - Auction: %@, CDP: %@", auctionEndpointUrl, cdpEndpointUrl]];
    
    // Store endpoint data in logs 
    NSString *endpointData = [NSString stringWithFormat:@"choosenAuctionEndpoint: %@ ||| choosenCDPEndpoint: %@", auctionEndpointUrl, cdpEndpointUrl];
    _logsData = @{@"endpointData": endpointData};
    
            // Register services in DI container 
        CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXAppSessionServiceImplementation class] instance:[[CLXAppSessionServiceImplementation alloc] initWithSessionID:config.sessionID ?: @"" appKey:_appKey url:metricsEndpointURL]];
    [container registerType:[CLXBidNetworkServiceClass class] instance:[[CLXBidNetworkServiceClass alloc] initWithAuctionEndpointUrl:auctionEndpointUrl cdpEndpointUrl:cdpEndpointUrl errorReporter:[CLXErrorReporter shared]]];
    [container resolveType:ServiceTypeSingleton class:[CLXAppSessionServiceImplementation class]];
    
    // Check if adapters are empty 
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"⚠️ [CloudXCore] WARNING: CloudX SDK was not initialized with any adapters. At least one adapter is required to show ads."];
    }
    
    // Mark as initialized
    _isInitialised = YES;
    [self.logger info:@"✅ [CloudXCore] SDK initialization completed successfully"];
    
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    if ([metricsDict.allKeys containsObject:@"network_call_sdk_init_req"]) {
        NSString *value = metricsDict[@"network_call_sdk_init_req"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"network_call_sdk_init_req"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"network_call_sdk_init_req"] = @"1";
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
    
    
    [self startTimer];
    
    // Mark SDK as successfully initialized
    @synchronized(self) {
        _isInitialised = YES;
    }
    [self.logger info:@"✅ [CloudXCore] SDK initialization completed successfully"];
    
    if (completion) {
        completion(YES, nil);
    }
}

- (void)initSDKWithAppKey:(NSString *)appKey hashedUserID:(NSString *)hashedUserID completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [CloudXCore] initSDKWithAppKey:hashedUserID called - AppKey: %@", appKey]];
    
    // Store hashed user ID
    [self provideUserDetailsWithHashedUserID:hashedUserID];
    
    // Call the main init method
    [self initSDKWithAppKey:appKey completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            self->_adPlacements = [NSMutableDictionary dictionary];
            for (CLXSDKConfigPlacement *placement in self->_sdkConfig.placements) {
                [(NSMutableDictionary *)self->_adPlacements setObject:placement forKey:placement.name];
            }
            [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] Successfully loaded %lu ad placements", (unsigned long)self->_adPlacements.count]];
            completion(YES, nil);
        } else {
            completion(NO, error);
        }
    }];
}

- (void)provideUserDetailsWithHashedUserID:(NSString *)hashedUserID {
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    if ([metricsDict.allKeys containsObject:@"method_set_hashed_user_id"]) {
        NSString *value = metricsDict[@"method_set_hashed_user_id"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"method_set_hashed_user_id"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"method_set_hashed_user_id"] = @"1";
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setValue:hashedUserID forKey:kCLXCoreHashedUserIDKey];
    [self.logger info:@"✅ [CloudXCore] Hashed user ID stored successfully"];
}

- (void)useHashedKeyValueWithKey:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setValue:key forKey:kCLXCoreHashedKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCLXCoreHashedValueKey];
    [self.logger info:@"✅ [CloudXCore] Hashed key-value pair stored successfully"];
}

- (void)useKeyValuesWithUserDictionary:(NSDictionary<NSString *,NSString *> *)userDictionary {
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    if ([metricsDict.allKeys containsObject:@"method_set_user_key_values"]) {
        NSString *value = metricsDict[@"method_set_user_key_values"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"method_set_user_key_values"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"method_set_user_key_values"] = @"1";
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:userDictionary forKey:kCLXCoreUserKeyValueKey];
    [self.logger info:@"✅ [CloudXCore] User dictionary stored successfully"];
}

- (void)startTimer {
    [NSTimer scheduledTimerWithTimeInterval:10.0   // every 1 second
                                     target:self
                                   selector:@selector(timerFired:)
                                   userInfo:nil
                                    repeats:YES];
}

// Method called by the timer
- (void)timerFired:(NSTimer *)timer {
    [self.logger debug:@"⏰ [CloudXCore] Timer fired - sending analytics"];
    
    //Send Analytics
    [self.reportingService metricsTrackingWithActionString:@"sdkmetricenc"];
    
}

- (void)useBidderKeyValueWithBidder:(NSString *)bidder key:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setValue:bidder forKey:kCLXCoreUserBidderKey];
    [[NSUserDefaults standardUserDefaults] setValue:key forKey:kCLXCoreUserBidderKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCLXCoreUserBidderValueKey];
    [self.logger info:@"✅ [CloudXCore] Bidder key-value pair stored successfully"];
}

- (CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                    viewController:(UIViewController *)viewController
                                         delegate:(id<CLXBannerDelegate>)delegate
                                             tmax:(NSNumber *)tmax {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Creating banner for placement: %@", placement]];
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Generate unique auction ID for this banner impression
    NSString *auctionID = [[NSUUID UUID] UUIDString];
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                                                  auctionID:auctionID
                                                                              testGroupName:_abTestName];
    
    // Create banner using real adNetworkFactories
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] initWithViewController:viewController
                                                                     placement:placementConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                    suspendPreloadWhenInvisible:NO
                                                                     delegate:delegate
                                                                                                                                       bannerType:CLXBannerTypeW320H50
                                                       waterfallMaxBackOffTime:5.0
                                                                       impModel:impModel
                                                                    adFactories:_adNetworkFactories.banners
                                                                bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:3.0
                                                              reportingService:_reportingService
                                                                      settings:[CLXSettings sharedInstance]
                                                                           tmax:tmax
                                                              ];
    
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeW320H50 delegate:delegate];
}

- (CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                 viewController:(UIViewController *)viewController
                                      delegate:(id<CLXBannerDelegate>)delegate {
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Generate unique auction ID for this MREC impression
    NSString *auctionID = [[NSUUID UUID] UUIDString];
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                                                  auctionID:auctionID
                                                                              testGroupName:_abTestName];
    
    // Create banner using real adNetworkFactories
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] initWithViewController:viewController
                                                                     placement:placementConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                    suspendPreloadWhenInvisible:NO
                                                                     delegate:delegate
                                                                                                                                       bannerType:CLXBannerTypeMREC
                                                       waterfallMaxBackOffTime:5.0
                                                                       impModel:impModel
                                                                    adFactories:_adNetworkFactories.banners
                                                                bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:3.0
                                                              reportingService:_reportingService
                                                                      settings:[CLXSettings sharedInstance]
                                                                           tmax:nil
                                                              ];
    
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeMREC delegate:delegate];
}

- (id<CLXInterstitial>)createInterstitialWithPlacement:(NSString *)placement
                                                 delegate:(id<CLXInterstitialDelegate>)delegate {
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Generate unique auction ID for this interstitial impression
    NSString *auctionID = [[NSUUID UUID] UUIDString];
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                                                  auctionID:auctionID
                                                                              testGroupName:_abTestName];
    
    // Create interstitial with simplified state-based management
    CLXPublisherFullscreenAd *interstitial = [[CLXPublisherFullscreenAd alloc] initWithInterstitialDelegate:delegate
        rewardedDelegate:nil
        placement:placementConfig
        publisherID:@""
        userID:@""
        rewardedCallbackUrl:nil
        impModel:impModel
        adFactories:_adNetworkFactories
        waterfallMaxBackOffTime:@10.0
        bidTokenSources:_adNetworkFactories.bidTokenSources
        bidRequestTimeout:3.0
        reportingService:_reportingService
        settings:[CLXSettings sharedInstance]
        adType:CLXAdTypeInterstitial];
    
    return interstitial;
}

- (id<CLXRewardedInterstitial>)createRewardedWithPlacement:(NSString *)placement
                                                    delegate:(id<CLXRewardedDelegate>)delegate {
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Generate unique auction ID for this rewarded impression
    NSString *auctionID = [[NSUUID UUID] UUIDString];
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                                                  auctionID:auctionID
                                                                              testGroupName:_abTestName];
    
    // Create rewarded with simplified state-based management
    CLXPublisherFullscreenAd *rewarded = [[CLXPublisherFullscreenAd alloc] initWithInterstitialDelegate:nil
        rewardedDelegate:delegate
        placement:placementConfig
        publisherID:@""
        userID:@""
        rewardedCallbackUrl:nil
        impModel:impModel
        adFactories:_adNetworkFactories
        waterfallMaxBackOffTime:@5.0
        bidTokenSources:_adNetworkFactories.bidTokenSources
        bidRequestTimeout:3.0
        reportingService:_reportingService
        settings:[CLXSettings sharedInstance]
        adType:CLXAdTypeRewarded];
    
    return rewarded;
}

- (nullable CLXNativeAdView *)createNativeAdWithPlacement:(NSString *)placement viewController:(UIViewController *)viewController delegate:(id)delegate {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Creating native ad for placement: %@", placement]];

    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Generate unique auction ID for this native impression
    NSString *auctionID = [[NSUUID UUID] UUIDString];
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                                                  auctionID:auctionID
                                                                              testGroupName:_abTestName];
    
    // Create native using real adNetworkFactories
    CLXPublisherNative *native = [[CLXPublisherNative alloc] initWithViewController:viewController
                                                                     placement:placementConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                    suspendPreloadWhenInvisible:NO
                                                                     delegate:delegate
                                                                   nativeType:CLXNativeTemplateDefault
                                                       waterfallMaxBackOffTime:5.0
                                                                    impModel:impModel
                                                                    adFactories:_adNetworkFactories.native
                                                                bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:3.0
                                                              reportingService:_reportingService];
    
    if (!native) {
        [self.logger error:@"❌ [CloudXCore] Failed to create native ad"];
        return nil;
    }
    
    return [[CLXNativeAdView alloc] initWithNative:native type:placementConfig.nativeTemplate delegate:delegate];
}

#pragma mark - Private Helper Methods

- (void)resolveAdapters {
    CLXAdapterFactoryResolver *adapterResolver = [[CLXAdapterFactoryResolver alloc] init];
    NSDictionary *factoriesDict = [adapterResolver resolveAdNetworkFactories];
    _adNetworkFactories = [[CLXAdNetworkFactories alloc] initWithDictionary:factoriesDict];
}

- (void)filterConfig {
    NSMutableDictionary *placementsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.placements && _sdkConfig.placements.count > 0) {
        for (CLXSDKConfigPlacement *placement in _sdkConfig.placements) {
            placementsDict[placement.name] = placement; // Use name as key like Swift SDK
        }
    }
    _adPlacements = [placementsDict copy];
    
    // Also populate ad network configs dictionary
    NSMutableDictionary *configsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.bidders && _sdkConfig.bidders.count > 0) {
        for (CLXSDKConfigBidder *bidder in _sdkConfig.bidders) {
            configsDict[bidder.networkName] = bidder;
        }
    }
    _adNetworkConfigs = [configsDict copy];
}

- (NSString *)chooseEndpointWithObject:(id)object value:(double)value {
    NSString *stringToReturn = _defaultAuctionURL;
    
    // Check if object is a SDKConfigEndpointObject
    if ([object isKindOfClass:[CLXSDKConfigEndpointObject class]]) {
        CLXSDKConfigEndpointObject *endpointObject = (CLXSDKConfigEndpointObject *)object;
        
        // Get the default key
        NSString *defaultKey = endpointObject.defaultKey;
        if (defaultKey) {
            stringToReturn = defaultKey;
        }
        
        // Get the test array (EndpointValue structures)
        NSArray *tests = endpointObject.test;
        if ([tests isKindOfClass:[NSArray class]]) {
            for (CLXSDKConfigEndpointValue *test in tests) {
                if ([test isKindOfClass:[CLXSDKConfigEndpointValue class]]) {
                    double ratio = test.ratio;
                    NSString *testValue = test.value;
                    NSString *testName = test.name;
                    
                    if (testValue) {
                        if (value <= ratio) {
                            // Use default key for this test
                            stringToReturn = defaultKey ?: @"";
                        } else {
                            // Use test value
                            stringToReturn = testValue;
                            if (testName) {
                                _abTestName = testName;
                            }
                        }
                    }
                }
            }
        }
    }
    
    return stringToReturn;
}

#pragma mark - Public Getters

#pragma mark - SDK Error Tracking

+ (void)trackSDKError:(NSError *)error {
    // Get the shared instance to access reporting service
    CloudXCore *sharedInstance = [CloudXCore shared];
    if (!sharedInstance.reportingService) {
        [sharedInstance.logger error:@"❌ [CloudXCore] Cannot track SDK error - reporting service not initialized"];
        return;
    }
    
    // Get stored encoded string and campaign ID from UserDefaults (set during SDK init)
    NSString *encodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    if (!encodedString || encodedString.length == 0) {
        [sharedInstance.logger error:@"❌ [CloudXCore] Cannot track SDK error - no encoded string available"];
        return;
    }
    
    // Create error payload by appending error details to the base payload
    NSString *errorMessage = error.localizedDescription ?: @"Unknown error";
    NSString *errorDetails = [NSString stringWithFormat:@"Domain: %@, Code: %ld, Description: %@", 
                             error.domain, (long)error.code, errorMessage];
    
    // Get campaign ID from the same source as SDK init
    NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
    NSString *accountId = sharedInstance.sdkConfig.accountID;
    
    if (!accountId || accountId.length == 0) {
        [sharedInstance.logger error:@"❌ [CloudXCore] Cannot track SDK error - no account ID available"];
        return;
    }
    
    // Generate campaign ID for tracking
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:accountId];
    NSString *safeCampaignId = [campaignId urlQueryEncodedString];
    
    // Create error-specific encoded string by appending error details
    NSString *errorPayload = [NSString stringWithFormat:@"%@;%@", encodedString, errorDetails];
    NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
    NSString *errorEncrypted = [CLXXorEncryption encrypt:errorPayload secret:secret];
    NSString *safeErrorEncrypted = [errorEncrypted urlQueryEncodedString];
    
    // Send SDK error tracking event
    [sharedInstance.reportingService rillTrackingWithActionString:@"sdkerrorenc" 
                                                       campaignId:safeCampaignId 
                                                    encodedString:safeErrorEncrypted];
    
    [sharedInstance.logger info:@"📤 [CloudXCore] Sent SDK error Rill tracking event"];
}

#pragma mark - Privacy Settings

+ (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString {
    [[CLXPrivacyService sharedInstance] setCCPAPrivacyString:ccpaPrivacyString];
}

+ (void)setIsUserConsent:(BOOL)isUserConsent {
    [[CLXPrivacyService sharedInstance] setHasUserConsent:@(isUserConsent)];
}

+ (void)setIsAgeRestrictedUser:(BOOL)isAgeRestrictedUser {
    [[CLXPrivacyService sharedInstance] setIsAgeRestrictedUser:@(isAgeRestrictedUser)];
}

+ (void)setIsDoNotSell:(BOOL)isDoNotSell {
    [[CLXPrivacyService sharedInstance] setDoNotSell:@(isDoNotSell)];
}

#pragma mark - GPP (Global Privacy Platform) Settings

+ (void)setGPPString:(nullable NSString *)gppString {
    [[CLXGPPProvider sharedInstance] setGppString:gppString];
}

+ (nullable NSString *)getGPPString {
    return [[CLXGPPProvider sharedInstance] gppString];
}

+ (void)setGPPSid:(nullable NSArray<NSNumber *> *)gppSid {
    [[CLXGPPProvider sharedInstance] setGppSid:gppSid];
}

+ (nullable NSArray<NSNumber *> *)getGPPSid {
    return [[CLXGPPProvider sharedInstance] gppSid];
}

@end 
