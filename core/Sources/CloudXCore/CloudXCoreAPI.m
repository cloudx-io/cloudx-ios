#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAdapterFactoryResolver.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidderConfig.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXEndpointResolver.h>

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
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXRewardedDelegate.h>
#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeAdView.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXNativeDelegate.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>

// Internal notification name for SDK initialization completion (exported in header)
NSString * const CLXSDKInitializedNotification = @"CLXSDKInitializedNotification";

@interface CloudXCore ()
@property (nonatomic, strong) id<CLXInitService> initService;
@property (nonatomic, strong) CLXSDKConfigResponse *sdkConfig;
@property (nonatomic, assign) BOOL isInitialized;
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
@property (nonatomic, strong) CLXGeoLocationService *geoLocationService;
@property (nonatomic, strong) CLXAppSessionService *appSessionService;
@property (nonatomic, strong) CLXBidNetworkServiceClass *bidNetworkService;
@property (nonatomic, strong) CLXAdNetworkFactories *adNetworkFactories;
@property (nonatomic, strong) NSMutableSet<NSString *> *readyAdapters;
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
        
        // Register new MetricsTrackerImpl for proper metrics tracking
        if (![container resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]]) {
            [container registerType:[CLXMetricsTrackerImpl class] instance:[[CLXMetricsTrackerImpl alloc] init]];
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
        [self.logger debug:@"Initializing CloudXCore instance"];
        _isInitialized = NO;
        _abTestValue = (double)arc4random() / UINT32_MAX;
        _abTestName = @"RandomTest";
        // Default auction URL now comes from SDK response only
        _defaultAuctionURL = @"";
        _readyAdapters = [NSMutableSet set];
        
        // Resolve adapters immediately so banners created before SDK init have token sources
        [self resolveAdapters];
        
        [self.logger info:[NSString stringWithFormat:@"Instance initialized - AB Test: %@ (%.3f), Default URL: %@", _abTestName, _abTestValue, _defaultAuctionURL]];
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

- (BOOL)isInitialized {
    return _isInitialized;
}

// Internal method (not in public API) - used by ad publishers to create impression models
- (nullable CLXConfigImpressionModel *)createImpModelWithAuctionID:(NSString *)auctionID {
    if (!_sdkConfig) {
        [self.logger error:@"Cannot create impression model - SDK not initialized"];
        return nil;
    }
    return [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                      auctionID:auctionID
                                                  testGroupName:_abTestName];
}

- (void)initializeSDKWithAppKey:(NSString *)appKey testMode:(BOOL)testMode completion:(void (^)(BOOL, CLXError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"[CloudXCore] initializeSDKWithAppKey called with appKey: %@, testMode: %@", appKey, testMode ? @"YES" : @"NO"]];
    
    // Store test mode setting immediately (before any adapter initialization)
    // This allows adapters to read the setting during their initialization
    [[NSUserDefaults standardUserDefaults] setBool:testMode forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Track SDK initialization method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    
    // Thread-safe initialization check and setup
    @synchronized(self) {
        if (!appKey || appKey.length == 0) {
            [self.logger error:@"AppKey is nil or empty"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeInvalidAppKey 
                                          description:@"App key cannot be nil or empty. Please provide a valid app key."]);
            }
            return;
        }
        
        if (_isInitialized) {
            [self.logger debug:@"[CloudXCore] SDK already initialized, returning early"];
            if (completion) {
                completion(YES, nil);
            }
            return;
        }
        
        // Reset metrics dictionary at start of initialization
        NSDictionary *dict = @{};
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kCLXCoreMetricsDictKey];
    }
    
    [self.logger debug:@"Starting SDK initialization process"];
    _appKey = [appKey copy];
    
    // Get init service from DI container
    CLXDIContainer *container = [CLXDIContainer shared];
    [self.logger debug:@"Attempting to resolve CLXLiveInitService from DI container"];
    _initService = [container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]];
    
    if (!_initService) {

        [self.logger debug:@"InitService not found in DI container, using fallback registration"];
        // Try to register it again as a fallback
        [self ensureDIContainerSetup];
        _initService = [container resolveType:ServiceTypeSingleton class:[CLXLiveInitService class]];
        if (!_initService) {
            [self.logger error:@"Failed to resolve InitService after fallback registration"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized 
                                          description:@"SDK initialization failed: Unable to initialize required services. Please try again or contact support."]);
            }
            return;
        } else {
            [self.logger debug:@"InitService resolved via fallback registration"];
        }
    } else {
        [self.logger debug:@"InitService resolved successfully"];
    }
    
    [self.logger info:@"InitService resolved, calling initializeSDKWithAppKey"];
    
    [_initService initializeSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"InitService failed with error: %@", error]];
            [self.logger error:[NSString stringWithFormat:@"Error domain: %@, code: %ld, description: %@", error.domain, (long)error.code, error.localizedDescription]];
            [self.logger error:[NSString stringWithFormat:@"Error class: %@", NSStringFromClass([error class])]];
            if (completion) {
                // Ensure we pass a CLXError to the completion handler
                CLXError *clxError = [error isKindOfClass:[CLXError class]] ? (CLXError *)error : [CLXError errorWithCode:CLXErrorCodeNotInitialized description:error.localizedDescription underlyingError:error];
                completion(NO, clxError);
            }
            return;
        }
        
        if (!config) {
            [self.logger error:@"InitService returned nil config"];
            if (completion) {
                completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized 
                                          description:@"SDK initialization failed: No configuration received from server. Please check your app key and network connection."]);
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

        // Initialize reporting service (no longer uses legacy eventTrackingURL)
        _reportingService = [[CLXAdEventReporter alloc] initWithEndpoint:nil];
        
        // Initialize win/loss tracking with server configuration
        [[CLXWinLossTracker shared] setAppKey:_appKey];
        [[CLXWinLossTracker shared] setEndpoint:config.winLossNotificationURL];
        [[CLXWinLossTracker shared] setConfig:config];
        
        // Retry any cached win/loss events from previous sessions
        [[CLXWinLossTracker shared] trySendingPendingWinLossEvents];
        
        NSMutableDictionary *geoHeaders = [NSMutableDictionary dictionary];
        if (config.geoHeaders) {
            for (CLXSDKConfigGeoBid *geoBid in config.geoHeaders) {
                geoHeaders[geoBid.source] = geoBid.target;
            }
            [self.logger debug:[NSString stringWithFormat:@"geoHeaders Dictionary: %@", geoHeaders]];
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
        
        // Create bid request for SDK init tracking to populate bidRequest.* fields
        NSDictionary *sdkInitBidRequest = [self createSDKInitBidRequestWithAuctionId:auctionID impModel:impModel];
        [[CLXTrackingFieldResolver shared] setRequestData:auctionID bidRequestJSON:sdkInitBidRequest];
        [self.logger debug:[NSString stringWithFormat:@"Created bid request for SDK init tracking - Auction ID: %@", auctionID]];
        
        CLXRillImpressionModel *model = [[CLXRillImpressionModel alloc] initWithLastBidResponse:nil impModel:impModel adapterName:@"" loadBannerTimesCount:0 placementID:@""];
        
        NSString* encodedString = [CLXRillImpressionInitService createDataStringWithRillImpressionModel:model];
        
        [self.logger info:@"InitService returned config, processing"];
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

- (void)processSDKConfig:(CLXSDKConfigResponse *)config completion:(void (^)(BOOL, CLXError * _Nullable))completion {
    [self.logger debug:[NSString stringWithFormat:@"Processing SDK config - Session: %@, Account: %@, Bidders: %lu", config.sessionID, config.accountID, (unsigned long)config.bidders.count]];
    
    _sdkConfig = config;
    
    // Store key-value paths configuration
    if (config.keyValuePaths) {
        [[CLXKeyValueState shared] setKeyValuePaths:config.keyValuePaths];
        [self.logger info:@"Key-value paths configuration stored"];
    } else {
        [self.logger debug:@"[CloudXCore] No key-value paths configuration found in server response"];
    }
    
    // Set the tracking configuration for Analytics
    [[CLXTrackingFieldResolver shared] setConfig:config];
    
    // Note: Adapters are now resolved in init, not here
    // This ensures banners created before SDK init have token sources
    
    // Filter config (like Swift SDK does)
    [self filterConfig];
    
    [self.logger debug:[NSString stringWithFormat:@"Adapter resolution complete - Banners: %lu, Tokens: %lu, Placements: %lu", (unsigned long)_adNetworkFactories.banners.count, (unsigned long)_adNetworkFactories.bidTokenSources.count, (unsigned long)_adPlacements.count]];
    
    // Process bidders
    if (config.bidders && config.bidders.count > 0) {
        [self.logger debug:[NSString stringWithFormat:@"Processing %lu bidders", (unsigned long)config.bidders.count]];
    } else {
        [self.logger debug:@"[CloudXCore] No bidders found in config"];
    }
    
    // Initialize network bidder adapters - BLOCKING until all complete
    NSDictionary *adNetworkInitializers = _adNetworkFactories.initializers;
    [self.logger debug:[NSString stringWithFormat:@"Initializing adapters - Available: %@", [adNetworkInitializers allKeys]]];
    
    if (adNetworkInitializers && adNetworkInitializers.count > 0) {
        // Create dispatch group to block until ALL adapters initialize
        dispatch_group_t adapterInitGroup = dispatch_group_create();
        
        for (CLXSDKConfigBidder *adNetworkConfig in config.bidders) {
            NSString *mappedNetworkName = adNetworkConfig.networkNameMapped;
            
            id<CLXAdNetworkInitializer> initializer = adNetworkInitializers[mappedNetworkName];
            if (!initializer) {
                [self.logger info:[NSString stringWithFormat:@"[CloudXCore] Adapter not configured for network: %@ (mapped from %@)", mappedNetworkName, adNetworkConfig.networkName]];
                continue;
            }
            
            // Enter group before starting adapter initialization
            dispatch_group_enter(adapterInitGroup);
            
            // Convert SDKConfigBidder to CloudXBidderConfig 
            CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:adNetworkConfig.bidderInitData networkName:adNetworkConfig.networkName];
            
            [initializer initializeWithConfig:bidderConfig completion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self.logger info:[NSString stringWithFormat:@"Successfully initialized network: %@", mappedNetworkName]];
                    [self markAdapterReady:mappedNetworkName];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"Failed to initialize network: %@ - %@", mappedNetworkName, error.localizedDescription]];
                }
                // Leave group after adapter initialization completes (success or failure)
                dispatch_group_leave(adapterInitGroup);
            }];
        }
        
        // BLOCK until ALL adapters finish initializing - ensures full adapter coverage on first ad request
        [self.logger info:@"Waiting for all adapters to initialize before marking SDK ready..."];
        dispatch_group_wait(adapterInitGroup, DISPATCH_TIME_FOREVER);
        [self.logger success:[NSString stringWithFormat:@"All adapters initialized (%lu ready) - SDK now fully ready", (unsigned long)self.readyAdapters.count]];
    } else {
        [self.logger debug:@"[CloudXCore] No ad network initializers found"];
    }
    
    // Store app key, account ID, and URLs from SDK response
    [[NSUserDefaults standardUserDefaults] setValue:_appKey forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:config.accountID forKey:kCLXCoreAccountIDKey];
    [[NSUserDefaults standardUserDefaults] setValue:config.metricsEndpointURL forKey:kCLXCoreMetricsUrlKey];
    
    // Store impression tracker URL for Analytics tracking
    if (config.impressionTrackerURL) {
        [[NSUserDefaults standardUserDefaults] setValue:config.impressionTrackerURL forKey:kCLXCoreImpressionTrackerUrlKey];
    }
    
    // Initialize and start metrics tracker with proper configuration
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        // Create SDK config for metrics tracker
        CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
        sdkConfig.impressionTrackerURL = config.impressionTrackerURL;
        sdkConfig.metricsEndpointURL = config.metricsEndpointURL;
        sdkConfig.metricsConfig = config.metricsConfig;
        
        [metricsTracker startWithConfig:sdkConfig];
        [metricsTracker setBasicDataWithSessionId:config.sessionID ?: [[NSUUID UUID] UUIDString]
                                        accountId:config.accountID ?: @""
                                      basePayload:@"ios_sdk"];
        
        [self.logger info:@"Metrics tracker initialized and started"];
    } else {
        [self.logger error:@"Failed to resolve metrics tracker from DI container"];
    }
    
    // NEW: Reset session metrics on SDK initialization (iOS feature parity with Android)
    [[CLXSessionMetricsTracker sharedInstance] resetAll];
    [self.logger info:@"Session metrics tracker reset on SDK init"];
    
    // Resolve endpoints with A/B testing support
    CLXEndpointResolver *endpointResolver = [[CLXEndpointResolver alloc] init];
    [endpointResolver resolveFromConfig:config];
    
    NSString *auctionEndpointUrl = endpointResolver.auctionEndpoint;
    NSString *metricsEndpointURL = config.metricsEndpointURL ?: @"";
    
    // Validate endpoints
    if (auctionEndpointUrl.length == 0) {
        [self.logger error:@"SDK init missing auctionEndpointURL - auction requests will fail"];
    } else {
        [self.logger info:[NSString stringWithFormat:@"Auction endpoint resolved: %@", auctionEndpointUrl]];
    }
    
    if (!config.metricsEndpointURL) {
        [self.logger debug:@"[CloudXCore] SDK init missing metricsEndpointURL - SDK performance metrics disabled"];
    }
    
    if (endpointResolver.testGroupName.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"[CloudXCore] A/B Test Group: %@", endpointResolver.testGroupName]];
    }
    
    // Register services in DI container 
        CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXAppSessionService class] instance:[[CLXAppSessionService alloc] initWithSessionID:config.sessionID ?: @"" appKey:_appKey url:metricsEndpointURL]];
    [container registerType:[CLXBidNetworkServiceClass class] instance:[[CLXBidNetworkServiceClass alloc] initWithAuctionEndpointUrl:auctionEndpointUrl errorReporter:[CLXErrorReporter shared]]];
    [container resolveType:ServiceTypeSingleton class:[CLXAppSessionService class]];
    
    // Check if adapters are empty (skip in test mode)
    BOOL isTestMode = NSClassFromString(@"XCTestCase") != nil;
    if (_adNetworkFactories.isEmpty && !isTestMode) {
        [self.logger error:@"SDK initialization failed: No adapters were registered. At least one adapter is required to show ads."];
        if (completion) {
            completion(NO, [CLXError errorWithCode:CLXErrorCodeNotInitialized 
                                      description:@"SDK initialization failed: No adapters were registered. At least one adapter framework (e.g., CloudXMetaAdapter etc) must be included in your project to show ads. Please ensure adapter frameworks are properly linked and loaded."]);
        }
        return;
    }
    
    if (isTestMode && _adNetworkFactories.isEmpty) {
        [self.logger debug:@"[CloudXCore] Test mode detected - skipping adapter validation"];
    }
    
    // Mark as initialized
    _isInitialized = YES;
    
    // Post internal notification for ad objects to resume queued operations
    [[NSNotificationCenter defaultCenter] postNotificationName:CLXSDKInitializedNotification object:nil];
    
    // Track initialization metrics
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary* metricsDict = [metricsDictionary mutableCopy];
    BOOL isFirstInit = NO;
    if ([metricsDict.allKeys containsObject:@"network_call_sdk_init_req"]) {
        NSString *value = metricsDict[@"network_call_sdk_init_req"];
        int number = [value intValue];
        int new = number + 1;
        metricsDict[@"network_call_sdk_init_req"] = [NSString stringWithFormat:@"%d", new];
    } else {
        metricsDict[@"network_call_sdk_init_req"] = @"1";
        isFirstInit = YES;
    }
    [[NSUserDefaults standardUserDefaults] setObject:metricsDict forKey:kCLXCoreMetricsDictKey];
    
    // Log initialization success
    if (isFirstInit) {
        [self.logger event:@"SDK initialized for the first time"];
    } else {
        [self.logger success:@"SDK initialization completed successfully"];
    }
    
    [self startTimer];
    
    if (completion) {
        completion(YES, nil);
    }
}

#pragma mark - Adapter Readiness Tracking

/**
 * Check if a specific adapter has reported ready status
 * @param adapterName The name of the adapter (e.g., "meta", "vungle")
 * @return YES if the adapter is ready, NO otherwise
 */
- (BOOL)isAdapterReady:(NSString *)adapterName {
    @synchronized(self.readyAdapters) {
        return [self.readyAdapters containsObject:adapterName];
    }
}

/**
 * Mark an adapter as ready for use
 * @param adapterName The name of the adapter (e.g., "meta", "vungle")
 */
- (void)markAdapterReady:(NSString *)adapterName {
    @synchronized(self.readyAdapters) {
        if (![self.readyAdapters containsObject:adapterName]) {
            [self.readyAdapters addObject:adapterName];
            [self.logger debug:[NSString stringWithFormat:@"[AdapterReadiness] %@ is now ready (%lu/%lu adapters ready)", 
                adapterName, 
                (unsigned long)self.readyAdapters.count,
                (unsigned long)_adNetworkFactories.bidTokenSources.count]];
        }
    }
}

/**
 * Get the names of all adapters that are ready
 * @return Set of ready adapter names
 */
- (NSSet<NSString *> *)getReadyAdapters {
    @synchronized(self.readyAdapters) {
        return [self.readyAdapters copy];
    }
}

/**
 * Look up placement configuration by name
 * @param placementName The placement name
 * @return Placement configuration or nil if not found
 */
- (CLXSDKConfigPlacement *)placementConfigForName:(NSString *)placementName {
    return _adPlacements[placementName];
}

- (void)setHashedUserID:(NSString *)hashedUserID {
    // Track hashed user ID method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetHashedUserId];
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
    
    // Also store in new state system for declarative injection
    [[CLXKeyValueState shared] setHashedUserId:hashedUserID];
    
    [self.logger info:@"Hashed user ID stored successfully"];
}

- (void)setHashedKeyValue:(NSString *)key value:(NSString *)value {
    // Track user key-value method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetUserKeyValues];
    [[NSUserDefaults standardUserDefaults] setValue:key forKey:kCLXCoreHashedKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCLXCoreHashedValueKey];
    [self.logger info:@"Hashed key-value pair stored successfully"];
}

- (void)setKeyValueDictionary:(NSDictionary<NSString *,NSString *> *)userDictionary {
    // Track user key-values method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetUserKeyValues];
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
    
    // Also store in new state system for declarative injection
    for (NSString *key in userDictionary) {
        [[CLXKeyValueState shared] setUserKeyValue:key value:userDictionary[key]];
    }
    
    [self.logger info:@"User dictionary stored successfully"];
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

- (void)setBidderKeyValue:(NSString *)bidder key:(NSString *)key value:(NSString *)value {
    // Track app key-values method call (bidder key-values are app-level)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetAppKeyValues];
    [[NSUserDefaults standardUserDefaults] setValue:bidder forKey:kCLXCoreUserBidderKey];
    [[NSUserDefaults standardUserDefaults] setValue:key forKey:kCLXCoreUserBidderKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCLXCoreUserBidderValueKey];
    [self.logger info:@"Bidder key-value pair stored successfully"];
}

- (void)setUserKeyValue:(NSString *)key value:(NSString *)value {
    if (!key || !value) {
        [self.logger warn:@"[CloudXCore] Attempted to set user key-value with nil key or value"];
        return;
    }
    
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetUserKeyValues];
    
    [[CLXKeyValueState shared] setUserKeyValue:key value:value];
    [self.logger info:[NSString stringWithFormat:@"User key-value pair set: %@ = %@", key, value]];
}

- (void)setAppKeyValue:(NSString *)key value:(NSString *)value {
    if (!key || !value) {
        [self.logger warn:@"[CloudXCore] Attempted to set app key-value with nil key or value"];
        return;
    }
    
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetAppKeyValues];
    
    [[CLXKeyValueState shared] setAppKeyValue:key value:value];
    [self.logger info:[NSString stringWithFormat:@"App key-value pair set: %@ = %@", key, value]];
}

- (void)clearAllKeyValues {
    [[CLXKeyValueState shared] clearAllKeyValues];
    [self.logger info:@"All key-value pairs cleared"];
}

- (CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                    viewController:(UIViewController *)viewController
                                         delegate:(id<CLXBannerDelegate>)delegate {
    // Track banner creation method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    [self.logger debug:[NSString stringWithFormat:@"Creating banner for placement: %@", placement]];
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    NSError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersRegistered
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get placement from config (may be nil if SDK not initialized yet)
    CLXSDKConfigPlacement *placementConfig = [self placementConfigForName:placement];
    if (!placementConfig && _isInitialized && !deferredError) {
        // SDK is initialized but placement not found - this is an error
        [self.logger error:[NSString stringWithFormat:@"Placement not found - error will be deferred to load(): %@", placement]];
        deferredError = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                    description:[NSString stringWithFormat:@"Placement not found: %@", placement]];
    }
    
    // Defer placement config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (placementConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID
                                                          testGroupName:_abTestName];
    } else if (!placementConfig) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring banner initialization for placement: %@", placement]];
    }
    
    // ALWAYS create banner (errors deferred to load())
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
                                                                          tmax:nil
                                                              ];
    
    // Set deferred error if validation failed (using KVC to access private property)
    if (deferredError) {
        [banner setValue:deferredError forKey:@"deferredError"];
    }
    
    // If SDK not initialized, store the requested placement name for deferred lookup
    if (!placementConfig) {
        [banner setValue:placement forKey:@"requestedPlacementName"];
    }
    
    // ALWAYS return non-nil
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeW320H50 delegate:delegate];
}

- (CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                 viewController:(UIViewController *)viewController
                                      delegate:(id<CLXBannerDelegate>)delegate {
    // Track MREC creation method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateMrec];
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    NSError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersRegistered
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get placement from config (may be nil if SDK not initialized yet)
    CLXSDKConfigPlacement *placementConfig = [self placementConfigForName:placement];
    if (!placementConfig && _isInitialized && !deferredError) {
        // SDK is initialized but placement not found - this is an error
        [self.logger error:[NSString stringWithFormat:@"Placement not found - error will be deferred to load(): %@", placement]];
        deferredError = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                    description:[NSString stringWithFormat:@"Placement not found: %@", placement]];
    }
    
    // Defer placement config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (placementConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID
                                                          testGroupName:_abTestName];
    } else if (!placementConfig) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring MREC initialization for placement: %@", placement]];
    }
    
    // ALWAYS create banner (errors deferred to load())
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
    
    // Set deferred error if validation failed (using KVC to access private property)
    if (deferredError) {
        [banner setValue:deferredError forKey:@"deferredError"];
    }
    
    // If SDK not initialized, store the requested placement name for deferred lookup
    if (!placementConfig) {
        [banner setValue:placement forKey:@"requestedPlacementName"];
    }
    
    // ALWAYS return non-nil
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeMREC delegate:delegate];
}

- (CLXInterstitial *)createInterstitialWithPlacement:(NSString *)placement {
    // Track interstitial creation method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    NSError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersRegistered
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get placement from config (may be nil if SDK not initialized yet)
    CLXSDKConfigPlacement *placementConfig = [self placementConfigForName:placement];
    if (!placementConfig && _isInitialized && !deferredError) {
        // SDK is initialized but placement not found - this is an error
        [self.logger error:[NSString stringWithFormat:@"Placement not found - error will be deferred to load(): %@", placement]];
        deferredError = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                    description:[NSString stringWithFormat:@"Placement not found: %@", placement]];
    }
    
    // Defer placement config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (placementConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID
                                                          testGroupName:_abTestName];
    } else if (!placementConfig) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring interstitial initialization for placement: %@", placement]];
    }
    
    // ALWAYS create interstitial (errors deferred to load())
    CLXInterstitial *interstitial = [[CLXInterstitial alloc] initWithPlacement:placementConfig
                                                                     publisherID:@""
                                                                          userID:@""
                                                             rewardedCallbackUrl:nil
                                                                        impModel:impModel
                                                                     adFactories:_adNetworkFactories
                                                        waterfallMaxBackOffTime:@10.0
                                                                 bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:3.0
                                                               reportingService:_reportingService
                                                                       settings:[CLXSettings sharedInstance]];
    
    // Set deferred error if validation failed (using KVC to access private property)
    if (deferredError) {
        [interstitial setValue:deferredError forKey:@"deferredError"];
    }
    
    // If SDK not initialized, store the requested placement name for deferred lookup
    if (!placementConfig) {
        [interstitial setValue:placement forKey:@"requestedPlacementName"];
    }
    
    // ALWAYS return non-nil
    return interstitial;
}

- (CLXRewarded *)createRewardedWithPlacement:(NSString *)placement {
    // Track rewarded creation method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateRewarded];
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    NSError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersRegistered
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get placement from config (may be nil if SDK not initialized yet)
    CLXSDKConfigPlacement *placementConfig = [self placementConfigForName:placement];
    if (!placementConfig && _isInitialized && !deferredError) {
        // SDK is initialized but placement not found - this is an error
        [self.logger error:[NSString stringWithFormat:@"Placement not found - error will be deferred to load(): %@", placement]];
        deferredError = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                    description:[NSString stringWithFormat:@"Placement not found: %@", placement]];
    }
    
    // Defer placement config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (placementConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID
                                                          testGroupName:_abTestName];
    } else if (!placementConfig) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring rewarded initialization for placement: %@", placement]];
    }
    
    // ALWAYS create rewarded (errors deferred to load())
    CLXRewarded *rewarded = [[CLXRewarded alloc] initWithPlacement:placementConfig
                                                         publisherID:@""
                                                              userID:@""
                                                 rewardedCallbackUrl:nil
                                                            impModel:impModel
                                                         adFactories:_adNetworkFactories
                                            waterfallMaxBackOffTime:@5.0
                                                     bidTokenSources:_adNetworkFactories.bidTokenSources
                                                  bidRequestTimeout:3.0
                                                   reportingService:_reportingService
                                                           settings:[CLXSettings sharedInstance]];
    
    // Set deferred error if validation failed (using KVC to access private property)
    if (deferredError) {
        [rewarded setValue:deferredError forKey:@"deferredError"];
    }
    
    // If SDK not initialized, store the requested placement name for deferred lookup
    if (!placementConfig) {
        [rewarded setValue:placement forKey:@"requestedPlacementName"];
    }
    
    // ALWAYS return non-nil
    return rewarded;
}

- (nullable CLXNativeAdView *)createNativeAdWithPlacement:(NSString *)placement viewController:(UIViewController *)viewController delegate:(id)delegate {
    // Track native creation method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateNative];
    
    [self.logger debug:[NSString stringWithFormat:@"Creating native ad for placement: %@", placement]];

    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"Cannot create native ad: No adapters registered. At least one adapter framework must be included in your project to show ads."];
        return nil;
    }

    // Get placement from config
    CLXSDKConfigPlacement *placementConfig = _adPlacements[placement];
    if (!placementConfig) {
        [self.logger error:[NSString stringWithFormat:@"Placement not found: %@", placement]];
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
        [self.logger error:@"Failed to create native ad"];
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

// Internal getter for ad network factories - used by banner/fullscreen ads for deferred initialization
- (CLXAdNetworkFactories *)adNetworkFactories {
    return _adNetworkFactories;
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
        [sharedInstance.logger error:@"Cannot track SDK error - reporting service not initialized"];
        return;
    }
    
    // Get stored encoded string and campaign ID from UserDefaults (set during SDK init)
    NSString *encodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    if (!encodedString || encodedString.length == 0) {
        [sharedInstance.logger error:@"Cannot track SDK error - no encoded string available"];
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
        [sharedInstance.logger error:@"Cannot track SDK error - no account ID available"];
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
    
    [sharedInstance.logger info:@"Sent SDK error Analytics tracking event"];
}

#pragma mark - Privacy Settings

+ (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString {
    [[CLXPrivacyService sharedInstance] setCCPAPrivacyString:ccpaPrivacyString];
}

+ (void)setIsUserConsent:(BOOL)isUserConsent {
    [[CLXPrivacyService sharedInstance] setHasUserConsent:@(isUserConsent)];
}

+ (void)setIsDoNotSell:(BOOL)isDoNotSell {
    [[CLXPrivacyService sharedInstance] setDoNotSell:@(isDoNotSell)];
}

#pragma mark - Logging Control

+ (void)setLoggingEnabled:(BOOL)enabled {
    [[CLXLogger shared] setLoggingEnabled:enabled];
}

+ (void)setMinLogLevel:(CLXLogLevel)minLogLevel {
    [[CLXLogger shared] setMinLogLevel:minLogLevel];
}

+ (void)setLoggingEmojisEnabled:(BOOL)enabled {
    [[CLXLogger shared] setEmojisEnabled:enabled];
}

+ (void)setLoggingTimestampsEnabled:(BOOL)enabled {
    [[CLXLogger shared] setTimestampsEnabled:enabled];
}

#pragma mark - SDK Lifecycle

/**
 * Creates a minimal bid request for SDK init tracking
 * This ensures bidRequest.* fields are populated in the tracking payload
 */
- (NSDictionary *)createSDKInitBidRequestWithAuctionId:(NSString *)auctionId impModel:(CLXConfigImpressionModel *)impModel {
    // Create a minimal bid request for SDK init (similar to Android's approach)
    // Use empty/minimal values for ad-specific fields since this is not an actual ad request
    CLXBiddingConfigRequest *bidRequest = [[CLXBiddingConfigRequest alloc] initWithAdType:CLXAdTypeBanner
                                                                                 adUnitID:@""
                                                                       storedImpressionId:@""
                                                                                   dealID:@""
                                                                                 bidFloor:@0
                                                                          displayManager:[CLXSystemInformation shared].displayManager ?: @""
                                                                      displayManagerVer:[CLXSystemInformation shared].sdkVersion ?: @""
                                                                             publisherID:@""
                                                                                location:nil
                                                                               userAgent:nil
                                                                             adapterInfo:@{}
                                                                   nativeAdRequirements:nil
                                                                   skadRequestParameters:nil
                                                                                   tmax:nil
                                                                               impModel:impModel
                                                                               settings:[CLXSettings sharedInstance]
                                                                         privacyService:[CLXPrivacyService sharedInstance]];
    
    // Override the request ID with the auction ID for tracking
    bidRequest.requestID = auctionId;
    
    // Convert to JSON
    NSMutableDictionary *bidRequestJSON = [[bidRequest json] mutableCopy];
    
    // Set empty imp array for SDK init (no actual ad request)
    bidRequestJSON[@"imp"] = @[];
    
    return [bidRequestJSON copy];
}

- (void)deinitialize {
    [self.logger info:@"Deinitializing SDK"];
    
    // Reset initialization state
    _isInitialized = NO;
    _appKey = nil;
    _sdkConfig = nil;
    _adNetworkConfigs = nil;
    _adPlacements = nil;
    _adFactory = nil;
    _reportingService = nil;
    _abTestValue = 0.0;
    _abTestName = nil;
    _defaultAuctionURL = nil;
    _metricsTracker = nil;
    _geoLocationService = nil;
    _appSessionService = nil;
    _bidNetworkService = nil;
    _adNetworkFactories = nil;
    
    [self.logger info:@"SDK deinitialized successfully"];
}

#pragma mark - Testing Support

- (void)resetForTesting {
    // Reset initialization state
    _isInitialized = NO;
    _appKey = nil;
    _sdkConfig = nil;
    _adNetworkConfigs = nil;
    _adPlacements = nil;
    _adFactory = nil;
    _reportingService = nil;
    _abTestValue = (double)arc4random() / UINT32_MAX;
    _abTestName = @"RandomTest";
    _defaultAuctionURL = @"";
    _metricsTracker = nil;
    _geoLocationService = nil;
    _appSessionService = nil;
    _bidNetworkService = nil;
    _adNetworkFactories = nil;
    
    // Note: We don't reset the singleton instance itself or the initService
    // as those are meant to persist across the app lifecycle
}

@end 
