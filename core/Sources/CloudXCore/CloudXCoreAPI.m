#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTracker.h>
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
        CLXDIContainer *container = [CLXDIContainer shared];
        [container registerType:[CLXLiveInitService class] instance:[[CLXLiveInitService alloc] init]];
        [container registerType:[CLXMetricsTracker class] instance:[[CLXMetricsTracker alloc] init]];
        _sharedInstance = [[CloudXCore alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CloudXCoreAPI.m"];
        [self.logger debug:@"🔧 [CloudXCore] Initializing CloudXCore instance"];
        _isInitialised = NO;
        _abTestValue = (double)arc4random() / UINT32_MAX;
        _abTestName = @"RandomTest";
        _defaultAuctionURL = @"https://au-dev.cloudx.io/openrtb2/auction";
        _logsData = [NSDictionary dictionary];
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] AB Test Value: %f", _abTestValue]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] AB Test Name: %@", _abTestName]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Default Auction URL: %@", _defaultAuctionURL]];
        [self.logger info:@"✅ [CloudXCore] CloudXCore instance initialized successfully"];
    }
    return self;
}

+ (void)logCloudXMessage {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXCore"];
    [logger info:@"Hello from CloudXCore!"];
}

- (NSString *)sdkVersion {
            NSString *version = [CLXSystemInformation shared].sdkVersion;
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] SDK Version: %@", version]];
    return version;
}

- (BOOL)isInitialised {
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Checking initialization status: %@", _isInitialised ? @"YES" : @"NO"]];
    return _isInitialised;
}

- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [CloudXCore] initSDKWithAppKey called with appKey: %@", appKey]];
    
    NSDictionary *dict = @{};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kCLXCoreMetricsDictKey];
    
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
    
    [self.logger debug:@"🔧 [CloudXCore] Starting SDK initialization process"];
    _appKey = [appKey copy];
    
            // Get init service from DI container
        [self.logger debug:@"🔧 [CloudXCore] Getting InitService from DI container"];
        CLXDIContainer *container = [CLXDIContainer shared];
        _initService = [container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]];
    
    if (!_initService) {
        [self.logger error:@"❌ [CloudXCore] Failed to resolve InitService from DI container"];
        if (completion) {
            completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized]);
        }
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] InitService resolved successfully: %@", NSStringFromClass([_initService class])]];
    
    // Call the init service
    [self.logger debug:@"🔧 [CloudXCore] Calling InitService initSDKWithAppKey"];
    [_initService initSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        [self.logger debug:@"📥 [CloudXCore] InitService completion called"];
        
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

        NSString *metricsEndpointURL = @"https://ads.cloudx.io/metrics?a=test";
        if (config.metricsEndpointURL) {
            metricsEndpointURL = config.metricsEndpointURL;
        }
        _reportingService = [[CLXLiveAdEventReporter alloc] initWithEndpoint:config.eventTrackingURL ?: metricsEndpointURL];
        
        NSMutableDictionary *geoHeaders = [NSMutableDictionary dictionary];
        if (config.geoHeaders) {
            for (CLXSDKConfigGeoBid *geoBid in config.geoHeaders) {
                geoHeaders[geoBid.source] = geoBid.target;
            }
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] geoHeaders Dictionary: %@", geoHeaders]];
            [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
        }
        
        CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:config.sessionID ?: @""
                                                                                  auctionID:config.accountID ?: @""
                                                                      impressionTrackerURL:config.impressionTrackerURL ?: @""
                                                                            organizationID:config.organizationID ?: @""
                                                                                  accountID:config.accountID ?: @""
                                                                                  sdkConfig:config
                                                                              testGroupName:_abTestName ?: @""
                                                                              appKeyValues:config.keyValuePaths.appKeyValues
                                                                                     eids: config.keyValuePaths.eids
                                                                       placementLoopIndex:config.keyValuePaths.placementLoopIndex
                                                                            userKeyValues:config.keyValuePaths.userKeyValues];
        
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
        
        [self.logger info:@"✅ [CloudXCore] InitService returned config successfully"];
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
    [self.logger debug:@"🔧 [CloudXCore] Processing SDK config"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Config App Key: %@", _appKey]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Config Session ID: %@", config.sessionID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Config Account ID: %@", config.accountID]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Config Bidders Count: %lu", (unsigned long)config.bidders.count]];
    
    _sdkConfig = config;
    
    // Set the tracking configuration for Rill analytics
    [[CLXTrackingFieldResolver shared] setConfig:config];
    
    // Resolve adapters (like Swift SDK does)
    [self resolveAdapters];
    
    // Filter config (like Swift SDK does)
    [self filterConfig];
    
    [self.logger debug:@"📊 [CloudXCore] Adapter resolution complete"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Banner factories: %lu", (unsigned long)_adNetworkFactories.banners.count]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Bid token sources: %lu", (unsigned long)_adNetworkFactories.bidTokenSources.count]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Ad placements: %lu", (unsigned long)_adPlacements.count]];
    
    // Process bidders
    [self.logger debug:@"🔧 [CloudXCore] Processing bidders"];
    if (config.bidders && config.bidders.count > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Found %lu bidders", (unsigned long)config.bidders.count]];
        for (CLXSDKConfigBidder *bidder in config.bidders) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Bidder Network Name: %@", bidder.networkName]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Bidder Init Data: %@", bidder.bidderInitData]];
        }
    } else {
        [self.logger debug:@"⚠️ [CloudXCore] No bidders found in config"];
    }
    
    // Initialize network bidder adapters (like Swift SDK)
    [self.logger debug:@"🔧 [CloudXCore] Initializing network bidder adapters"];
    NSDictionary *adNetworkInitializers = _adNetworkFactories.initializers;
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Available initializers: %@", [adNetworkInitializers allKeys]]];
    
    if (adNetworkInitializers && adNetworkInitializers.count > 0) {
        for (CLXSDKConfigBidder *adNetworkConfig in config.bidders) {
            NSString *mappedNetworkName = adNetworkConfig.networkNameMapped;
            [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Processing bidder - Original: %@, Mapped: %@", adNetworkConfig.networkName, mappedNetworkName]];
            
            id<CLXAdNetworkInitializer> initializer = adNetworkInitializers[mappedNetworkName];
            if (!initializer) {
                [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] No initializer found for network: %@ (mapped from %@). Available initializers: %@", mappedNetworkName, adNetworkConfig.networkName, [adNetworkInitializers allKeys]]];
                continue;
            }
            
            [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] Found initializer for network: %@ - %@", mappedNetworkName, initializer]];
            
            // Convert SDKConfigBidder to CloudXBidderConfig (like Swift SDK)
            CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:adNetworkConfig.bidderInitData networkName:adNetworkConfig.networkName];
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Bidder config created with init data: %@", adNetworkConfig.bidderInitData]];
            
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
    
    // Store app key and account ID (like Swift SDK)
    [[NSUserDefaults standardUserDefaults] setValue:_appKey forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:config.accountID forKey:kCLXCoreAccountIDKey];
    
    // Initialize reporting service (like Swift SDK)
    NSString *metricsEndpointURL = @"https://ads.cloudx.io/metrics?a=test";
    if (config.metricsEndpointURL) {
        metricsEndpointURL = config.metricsEndpointURL;
    }
    
    // Select endpoints with A/B testing (like Swift SDK)
    NSString *auctionEndpointUrl = @"https://au-dev.cloudx.io/openrtb2/auction";
    NSString *cdpEndpointUrl = @"";
    
    // Check if auction endpoint is a string or object (like Swift SDK)
    if (config.auctionEndpointURL) {
        id auctionValue = [config.auctionEndpointURL value];
        if ([auctionValue isKindOfClass:[NSString class]]) {
            auctionEndpointUrl = (NSString *)auctionValue;
        } else if ([auctionValue isKindOfClass:[CLXSDKConfigEndpointObject class]]) {
            auctionEndpointUrl = [self chooseEndpointWithObject:auctionValue value:_abTestValue];
        }
    }
    
    // Check if CDP endpoint is an object (like Swift SDK)
    if (config.cdpEndpointURL) {
        cdpEndpointUrl = [self chooseEndpointWithObject:config.cdpEndpointURL value:1.0 - _abTestValue];
    }
    
    [self.logger debug:@"📊 [CloudXCore] ========================="];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] choosenAuctionEndpoint: %@", auctionEndpointUrl]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] choosenCDPEndpoint: %@", cdpEndpointUrl]];
    [self.logger debug:@"📊 [CloudXCore] ========================="];
    
    // Store endpoint data in logs (like Swift SDK)
    NSString *endpointData = [NSString stringWithFormat:@"choosenAuctionEndpoint: %@ ||| choosenCDPEndpoint: %@", auctionEndpointUrl, cdpEndpointUrl];
    _logsData = @{@"endpointData": endpointData};
    
            // Register services in DI container (like Swift SDK)
        CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXAppSessionServiceImplementation class] instance:[[CLXAppSessionServiceImplementation alloc] initWithSessionID:config.sessionID ?: @"" appKey:_appKey url:metricsEndpointURL]];
    [container registerType:[CLXBidNetworkServiceClass class] instance:[[CLXBidNetworkServiceClass alloc] initWithAuctionEndpointUrl:auctionEndpointUrl cdpEndpointUrl:cdpEndpointUrl]];
    [container resolveType:ServiceTypeSingleton class:[CLXAppSessionServiceImplementation class]];
    
    // Check if adapters are empty (like Swift SDK)
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"⚠️ [CloudXCore] WARNING: CloudX SDK was not initialized with any adapters. At least one adapter is required to show ads."];
    } else {
        [self.logger info:@"✅ [CloudXCore] CloudX SDK initialised"];
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
    
    
    if (completion) {
        completion(YES, nil);
    }
}

- (void)initSDKWithAppKey:(NSString *)appKey hashedUserID:(NSString *)hashedUserID completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self.logger info:@"🚀 [CloudXCore] initSDKWithAppKey:hashedUserID called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] AppKey: %@", appKey]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] HashedUserID: %@", hashedUserID]];
    
    // Store hashed user ID
    [self provideUserDetailsWithHashedUserID:hashedUserID];
    
    // Call the main init method
    [self initSDKWithAppKey:appKey completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            self->_adPlacements = [NSMutableDictionary dictionary];
            for (CLXSDKConfigPlacement *placement in self->_sdkConfig.placements) {
                [(NSMutableDictionary *)self->_adPlacements setObject:placement forKey:placement.name];
            }
            [self.logger info:[NSString stringWithFormat:@"✅ [CloudXCore] LOG: Successfully loaded %lu ad placements:", (unsigned long)self->_adPlacements.count]];
            for (NSString *placementID in self->_adPlacements) {
                [self.logger debug:[NSString stringWithFormat:@"   -> LOG: Loaded Placement ID: '%@'", placementID]];
            }
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
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Storing hashed user ID: %@", hashedUserID]];
    [[NSUserDefaults standardUserDefaults] setValue:hashedUserID forKey:kCLXCoreHashedUserIDKey];
    [self.logger info:@"✅ [CloudXCore] Hashed user ID stored successfully"];
}

- (void)useHashedKeyValueWithKey:(NSString *)key value:(NSString *)value {
    [self.logger debug:@"🔧 [CloudXCore] Storing hashed key-value pair"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Key: %@", key]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Value: %@", value]];
    [[NSUserDefaults standardUserDefaults] setValue:key forKey:kCLXCoreHashedKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCLXCoreHashedValueKey];
    [self.logger info:@"✅ [CloudXCore] Hashed key-value pair stored successfully"];
}

- (void)useKeyValuesWithUserDictionary:(NSDictionary<NSString *,NSString *> *)userDictionary {
    [self.logger debug:@"🔧 [CloudXCore] Storing user dictionary"];
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
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Dictionary: %@", userDictionary]];
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
    NSLog(@"Timer fired!");
    
    //Send Analytics
    [self.reportingService metricsTrackingWithActionString:@"sdkmetricenc"];
    
}

- (void)useBidderKeyValueWithBidder:(NSString *)bidder key:(NSString *)key value:(NSString *)value {
    [self.logger debug:@"🔧 [CloudXCore] Storing bidder key-value pair"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Bidder: %@", bidder]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Key: %@", key]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Value: %@", value]];
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
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] ViewController: %@", viewController]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Delegate: %@", delegate]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] TMax: %@", tmax]];
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Create impression model
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:_sdkConfig.sessionID ?: @""
                                                                                  auctionID:_sdkConfig.accountID ?: @""
                                                                      impressionTrackerURL:_sdkConfig.impressionTrackerURL ?: @""
                                                                            organizationID:_sdkConfig.organizationID ?: @""
                                                                                  accountID:_sdkConfig.accountID ?: @""
                                                                                  sdkConfig:_sdkConfig
                                                                              testGroupName:_abTestName ?: @""
                                                                              appKeyValues:_sdkConfig.keyValuePaths.appKeyValues
                                                                                     eids: _sdkConfig.keyValuePaths.eids
                                                                       placementLoopIndex:_sdkConfig.keyValuePaths.placementLoopIndex
                                                                            userKeyValues:_sdkConfig.keyValuePaths.userKeyValues];
    
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
                                                                           tmax:tmax];
    
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeW320H50 delegate:delegate];
}

- (CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                 viewController:(UIViewController *)viewController
                                      delegate:(id<CLXBannerDelegate>)delegate {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Creating MREC for placement: %@", placement]];
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Create impression model
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:_sdkConfig.sessionID ?: @""
                                                                                  auctionID:_sdkConfig.accountID ?: @""
                                                                  impressionTrackerURL:_sdkConfig.impressionTrackerURL ?: @""
                                                                        organizationID:_sdkConfig.organizationID ?: @""
                                                                              accountID:_sdkConfig.accountID ?: @""
                                                                              sdkConfig:_sdkConfig
                                                                          testGroupName:_abTestName ?: @""
                                                                          appKeyValues:_sdkConfig.keyValuePaths.appKeyValues
                                                                                  eids: _sdkConfig.keyValuePaths.eids
                                                                    placementLoopIndex:_sdkConfig.keyValuePaths.placementLoopIndex
                                                                         userKeyValues:_sdkConfig.keyValuePaths.userKeyValues];
    
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
                                                                           tmax:nil];
    
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeMREC delegate:delegate];
}

- (id<CLXInterstitial>)createInterstitialWithPlacement:(NSString *)placement
                                                 delegate:(id<CLXInterstitialDelegate>)delegate {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Creating interstitial for placement: %@", placement]];
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Create impression model
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:_sdkConfig.sessionID ?: @""
                                                                                  auctionID:_sdkConfig.accountID ?: @""
                                                                      impressionTrackerURL:_sdkConfig.impressionTrackerURL ?: @""
                                                                            organizationID:_sdkConfig.organizationID ?: @""
                                                                                  accountID:_sdkConfig.accountID ?: @""
                                                                                  sdkConfig:_sdkConfig
                                                                              testGroupName:_abTestName ?: @""
                                                                              appKeyValues:_sdkConfig.keyValuePaths.appKeyValues
                                                                                     eids: _sdkConfig.keyValuePaths.eids
                                                                       placementLoopIndex:_sdkConfig.keyValuePaths.placementLoopIndex
                                                                            userKeyValues:_sdkConfig.keyValuePaths.userKeyValues];
    
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
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] Creating rewarded for placement: %@", placement]];
    
    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Create impression model
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:_sdkConfig.sessionID ?: @""
                                                                                  auctionID:_sdkConfig.accountID ?: @""
                                                                      impressionTrackerURL:_sdkConfig.impressionTrackerURL ?: @""
                                                                            organizationID:_sdkConfig.organizationID ?: @""
                                                                                  accountID:_sdkConfig.accountID ?: @""
                                                                                  sdkConfig:_sdkConfig
                                                                              testGroupName:_abTestName ?: @""
                                                                              appKeyValues:_sdkConfig.keyValuePaths.appKeyValues
                                                                                     eids: _sdkConfig.keyValuePaths.eids
                                                                       placementLoopIndex:_sdkConfig.keyValuePaths.placementLoopIndex
                                                                            userKeyValues:_sdkConfig.keyValuePaths.userKeyValues];
    
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
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CloudXCore] LOG: Attempting to create native ad for placement: '%@'", placement]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] LOG: Available Placements are: %@", [self->_adPlacements allKeys]]];

    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CloudXCore] Placement not found: %@", placement]];
        return nil;
    }
    
    // Create impression model
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] initWithSessionID:_sdkConfig.sessionID ?: @""
                                                                                  auctionID:_sdkConfig.accountID ?: @""
                                                                  impressionTrackerURL:_sdkConfig.impressionTrackerURL ?: @""
                                                                        organizationID:_sdkConfig.organizationID ?: @""
                                                                              accountID:_sdkConfig.accountID ?: @""
                                                                              sdkConfig:_sdkConfig
                                                                          testGroupName:_abTestName ?: @""
                                                                          appKeyValues:_sdkConfig.keyValuePaths.appKeyValues
                                                                                  eids: _sdkConfig.keyValuePaths.eids
                                                                    placementLoopIndex:_sdkConfig.keyValuePaths.placementLoopIndex
                                                                         userKeyValues:_sdkConfig.keyValuePaths.userKeyValues];
    
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
    [self.logger debug:@"🔧 [CloudXCore] Resolving adapters"];
    CLXAdapterFactoryResolver *adapterResolver = [[CLXAdapterFactoryResolver alloc] init];
    NSDictionary *factoriesDict = [adapterResolver resolveAdNetworkFactories];
    _adNetworkFactories = [[CLXAdNetworkFactories alloc] initWithDictionary:factoriesDict];
}

- (void)filterConfig {
    [self.logger debug:@"🔧 [CloudXCore] Filtering config"];
    NSMutableDictionary *placementsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.placements && _sdkConfig.placements.count > 0) {
        for (CLXSDKConfigPlacement *placement in _sdkConfig.placements) {
            placementsDict[placement.name] = placement; // Use name as key like Swift SDK
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Added placement: %@", placement.name]];
        }
    }
    _adPlacements = [placementsDict copy];
    
    // Also populate ad network configs dictionary
    NSMutableDictionary *configsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.bidders && _sdkConfig.bidders.count > 0) {
        for (CLXSDKConfigBidder *bidder in _sdkConfig.bidders) {
            configsDict[bidder.networkName] = bidder;
            [self.logger debug:[NSString stringWithFormat:@"📊 [CloudXCore] Added bidder config: %@", bidder.networkName]];
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
        NSLog(@"⚠️ [CloudXCore] Cannot track SDK error - reporting service not initialized");
        return;
    }
    
    // Get stored encoded string and campaign ID from UserDefaults (set during SDK init)
    NSString *encodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    if (!encodedString || encodedString.length == 0) {
        NSLog(@"⚠️ [CloudXCore] Cannot track SDK error - no encoded string available");
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
        NSLog(@"⚠️ [CloudXCore] Cannot track SDK error - no account ID available");
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
    
    NSLog(@"📤 [CloudXCore] Sent SDK error Rill tracking event: %@", errorMessage);
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

@end 
