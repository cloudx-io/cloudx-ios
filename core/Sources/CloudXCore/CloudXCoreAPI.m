#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXSdkConfiguration.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXVersion.h>
#import <CloudXCore/CLXDebugOverlayManager.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXPayloadBuilder.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXErrorReporter.h>
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
#import <CloudXCore/CLXSessionTracker.h>
#import <CloudXCore/CLXSessionNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXIlrdTracker.h>
#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXAlIlrd.h>
#import <CloudXCore/CLXIlrdProvider.h>
#import <CloudXCore/CLXAdUnitValidator.h>

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
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXPublisherFullscreenAdBase.h>

// Private category to expose deferred initialization properties for CLXPublisherBanner
// These properties are declared in CLXPublisherBanner.m's class extension
@interface CLXPublisherBanner (DeferredInit)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy, nullable) NSString *adUnitId;
@end

// Private category to expose deferred initialization properties for fullscreen ads
// These properties are declared in CLXPublisherFullscreenAdBase.m's class extension
@interface CLXPublisherFullscreenAdBase (DeferredInit)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy, nullable) NSString *adUnitId;
@end

// Private category to expose deferred initialization properties for native ads
// These properties are declared in CLXPublisherNative.m's class extension
@interface CLXPublisherNative (DeferredInit)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy, nullable) NSString *adUnitId;
@end

// Internal access to the VC stored by deprecated createBanner/MRECWithAdUnitId:viewController: APIs.
// The property is declared in CLXBannerAdView.m's class extension (not on the public header).
@interface CLXBannerAdView (DeprecatedVCAccess)
@property (nonatomic, weak, nullable) UIViewController *viewController;
@end

// Internal notification name for SDK initialization completion (exported in header)
NSString * const CLXSDKInitializedNotification = @"CLXSDKInitializedNotification";

@interface CloudXCore ()
@property (nonatomic, strong) id<CLXInitService> initService;
@property (nonatomic, strong) CLXSDKConfigResponse *sdkConfig;
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy, nullable) NSString *pluginVersion;
@property (nonatomic, strong) NSDictionary<NSString *, id> *adNetworkConfigs;
@property (nonatomic, strong) NSDictionary<NSString *, CLXSDKConfigAdUnit *> *adUnits;
@property (nonatomic, strong) id adFactory;
@property (nonatomic, strong) id reportingService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXGeoLocationService *geoLocationService;
@property (nonatomic, strong) CLXBidNetworkServiceClass *bidNetworkService;
@property (nonatomic, strong) CLXAdNetworkFactories *adNetworkFactories;
@property (nonatomic, strong) NSMutableSet<NSString *> *readyAdapters;
@property (nonatomic, strong, nullable) CLXIlrdTracker *ilrdTracker;
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
        
        // NOTE: CLXMetricsTrackerImpl is NOT registered here (matching Android architecture)
        // It's created and registered in _handleInitResponse: AFTER we have all config
        // (accountId, metricsConfig, payloadBuilder, etc.)
        // This prevents the issue where an unconfigured tracker silently drops metrics.
        
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
        _readyAdapters = [NSMutableSet set];

        // Resolve adapters immediately so banners created before SDK init have token sources
        [self resolveAdapters];
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
                                                      auctionID:auctionID];
}

- (void)initializeWithConfiguration:(CLXInitializationConfiguration *)configuration
                         completion:(void (^)(CLXSdkConfiguration * _Nullable, CLXError * _Nullable))completion {
    _pluginVersion = [configuration.pluginVersion copy];

    // Store pluginVersion in UserDefaults for access by bid request builder
    if (configuration.pluginVersion) {
        [[NSUserDefaults standardUserDefaults] setObject:configuration.pluginVersion forKey:kCLXCorePluginVersionKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCorePluginVersionKey];
    }

    [self _initializeWithAppKey:configuration.appKey completion:completion];
}

#pragma mark - Private Initialization

- (void)_initializeWithAppKey:(NSString *)appKey completion:(void (^)(CLXSdkConfiguration * _Nullable, CLXError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"[CloudXCore] initializeWithConfiguration called with appKey: %@", appKey]];
    
    // Note: Test mode is now server-controlled via deviceConfig
    // The test mode value will be set after receiving the server response
    
    // NOTE: SDK init method tracking moved to _handleInitResponse: AFTER metrics tracker is configured
    // (Matching Android architecture - metrics tracker doesn't exist until SDK init succeeds)
    
    // Thread-safe initialization check and setup
    @synchronized(self) {
        if (!appKey || appKey.length == 0) {
            [self.logger error:@"AppKey is nil or empty"];
            if (completion) {
                completion(nil, [CLXError errorWithCode:CLXErrorCodeInvalidAppKey 
                                          description:@"App key cannot be nil or empty. Please provide a valid app key."]);
            }
            return;
        }
        
        if (_isInitialized) {
            [self.logger debug:@"[CloudXCore] SDK already initialized, returning early"];
            if (completion) {
                completion([[CLXSdkConfiguration alloc] init], nil);
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
                completion(nil, [CLXError errorWithCode:CLXErrorCodeNotInitialized 
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
                completion(nil, clxError);
            }
            return;
        }
        
        if (!config) {
            [self.logger error:@"InitService returned nil config"];
            if (completion) {
                completion(nil, [CLXError errorWithCode:CLXErrorCodeNotInitialized 
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

        // Initialize ILRD tracking if endpoint is configured
        if (config.ilrdEndpointURL.length > 0) {
            CLXAlIlrd *provider = [[CLXAlIlrd alloc] initWithAccountName:config.accountName];
            NSDictionary *providers = @{ @(CLXIlrdPlatformAl): provider };
            CLXIlrdService *service = [[CLXIlrdService alloc] initWithProviders:providers];
            _ilrdTracker = [[CLXIlrdTracker alloc] initWithAppKey:_appKey
                                                     endpointUrl:config.ilrdEndpointURL
                                                     ilrdService:service];
            [_ilrdTracker start];
        }

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
                                                                                      auctionID:auctionID];
        
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
        
        CLXRillImpressionModel *model = [[CLXRillImpressionModel alloc] initWithLastBidResponse:nil impModel:impModel adapterName:@"" loadBannerTimesCount:0 adUnitId:@""];
        
        NSString* encodedString = [CLXRillImpressionInitService createDataStringWithRillImpressionModel:model];
        
        // Store encodedString BEFORE processSDKConfig so metrics tracker can use it as basePayload
        // This is the server-driven tracking payload that contains all fields ClickHouse expects
        [[NSUserDefaults standardUserDefaults] setObject:encodedString forKey:kCLXCoreEncodedStringKey];
        
        [self.logger info:@"InitService returned config, processing"];
        [self processSDKConfig:config completion:completion];
        
        NSString *accountId = impModel.accountID;
        NSString *payload = encodedString;
        
        NSData *secret = [CLXXorEncryption generateXorSecret: accountId];
        NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64: accountId];
        
        NSString *encrypted = [CLXXorEncryption encrypt: payload secret: secret];
        
        NSString *safeEncrypted = [encrypted clx_urlQueryEncodedString];
        
        NSString *safeCampaignId = [campaignId clx_urlQueryEncodedString];
        
        if (encodedString.length > 0) {
            [self.reportingService rillTrackingWithActionString:@"sdkinitenc" campaignId: safeCampaignId encodedString: safeEncrypted];
        }

        // Send session init event if session endpoint is configured
        if (config.sessionEndpointURL.length > 0) {
            CLXBaseNetworkService *baseService = [[CLXBaseNetworkService alloc]
                initWithBaseURL:config.sessionEndpointURL
                     urlSession:[NSURLSession sharedSession]];
            CLXSessionNetworkService *networkService = [[CLXSessionNetworkService alloc]
                initWithBaseNetworkService:baseService];
            CLXSessionTracker *sessionTracker = [[CLXSessionTracker alloc]
                initWithNetworkService:networkService];
            [sessionTracker sendInitEventWithAppKey:self->_appKey config:config];
        }
    }];
}

- (void)processSDKConfig:(CLXSDKConfigResponse *)config completion:(void (^)(CLXSdkConfiguration * _Nullable, CLXError * _Nullable))completion {
    [self.logger debug:[NSString stringWithFormat:@"Processing SDK config - Session: %@, Account: %@, Bidders: %lu", config.sessionID, config.accountID, (unsigned long)config.bidders.count]];
    
    _sdkConfig = config;
    
    // Apply server-controlled test mode and debug logging from deviceConfig
    CLXSDKConfigDeviceConfig *deviceConfig = config.deviceConfig;
    
    // Start with server-provided values (or defaults)
    NSInteger testModeValue = deviceConfig ? deviceConfig.test : 0;
    BOOL debugEnabled = deviceConfig ? deviceConfig.debug : NO;
    
    // Apply debug logging if server says so
    if (debugEnabled) {
        [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
        [self.logger debug:@"Debug logging enabled via deviceConfig"];
    }
    
#if TARGET_IPHONE_SIMULATOR
    // Always enable test mode on simulator - ads won't fill in production mode anyway
    // and there's no real device IFA to whitelist on the dashboard
    if (testModeValue == 0) {
        testModeValue = 1;
        [self.logger info:@"Test mode automatically enabled for iOS Simulator"];
    }
#endif

    // Compute test mode enabled flag
    BOOL testModeEnabled = (testModeValue != 0);
    if (testModeEnabled) {
        [self.logger info:[NSString stringWithFormat:@"Test mode enabled (test=%ld)", (long)testModeValue]];
    }
    
    // Store test mode for bid requests (as integer value for OpenRTB)
    [[NSUserDefaults standardUserDefaults] setInteger:testModeValue forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Set the tracking configuration for Analytics
    [[CLXTrackingFieldResolver shared] setConfig:config];
    
    // Note: Adapters are now resolved in init, not here
    // This ensures banners created before SDK init have token sources
    
    // Filter config (like Swift SDK does)
    [self filterConfig];
    
    [self.logger debug:[NSString stringWithFormat:@"Adapter resolution complete - Banners: %lu, Tokens: %lu, AdUnits: %lu", (unsigned long)_adNetworkFactories.banners.count, (unsigned long)_adNetworkFactories.bidTokenSources.count, (unsigned long)_adUnits.count]];
    
    // Check if any networks are configured (skip in test mode)
    BOOL isTestMode = NSClassFromString(@"XCTestCase") != nil;
    if ((!config.bidders || config.bidders.count == 0) && !isTestMode) {
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeNoNetworksConfigured];
        [self.logger error:[NSString stringWithFormat:@"SDK initialization failed: %@", error.localizedDescription]];
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Processing %lu bidders", (unsigned long)config.bidders.count]];
    
    // Initialize network bidder adapters - BLOCKING until all complete
    NSDictionary *adNetworkInitializers = _adNetworkFactories.initializers;
    [self.logger debug:[NSString stringWithFormat:@"Initializing adapters - Available: %@", [adNetworkInitializers allKeys]]];
    
    // testModeEnabled was already computed above (includes simulator detection)
    
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
            
            [initializer initializeWithConfig:bidderConfig testMode:testModeEnabled completion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self.logger info:[NSString stringWithFormat:@"Successfully initialized network: %@", mappedNetworkName]];
                    [self markAdapterReady:mappedNetworkName];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"Failed to initialize network: %@ - %@", mappedNetworkName, error.localizedDescription]];
                    
                    // Send error event when adapter fails to initialize (matching Android behavior)
                    [self trackAdapterInitializationErrorForNetwork:mappedNetworkName originalError:error];
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
    
    // Store impression tracker URL for metrics and analytics tracking
    if (config.impressionTrackerURL) {
        [[NSUserDefaults standardUserDefaults] setValue:config.impressionTrackerURL forKey:kCLXCoreMetricsUrlKey];
        [[NSUserDefaults standardUserDefaults] setValue:config.impressionTrackerURL forKey:kCLXCoreImpressionTrackerUrlKey];
    }
    
    // Initialize and start metrics tracker with PayloadBuilder (matching Android architecture)
    // PayloadBuilder centralizes payload construction with {eventId} placeholder replacement
    
    // Set session constant data BEFORE creating PayloadBuilder so appBundle is included in payload
    NSString *appBundle = [CLXSystemInformation shared].effectiveAppBundleIdentifier;
    NSString *pluginVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCorePluginVersionKey];
    DeviceType deviceType = [CLXSystemInformation shared].deviceType;
    [[CLXTrackingFieldResolver shared] setSessionConstData:config.sessionID ?: @""
                                                sdkVersion:CLXSDKVersion
                                             pluginVersion:pluginVersion
                                            deviceTypeName:DeviceTypeToString(deviceType)
                                            deviceTypeCode:(NSInteger)deviceType
                                               abTestGroup:@""
                                                 appBundle:appBundle];
    
    CLXPayloadBuilder *payloadBuilder = [CLXPayloadBuilder createWithAccountId:config.accountID ?: @""
                                                         trackingFieldResolver:[CLXTrackingFieldResolver shared]];
    
    CLXMetricsTrackerImpl *metricsTracker = [[CLXMetricsTrackerImpl alloc] initWithPayloadBuilder:payloadBuilder];
    
    // Register the metrics tracker in DI container for other components to access
    [[CLXDIContainer shared] registerType:[CLXMetricsTrackerImpl class] instance:metricsTracker];
    
    // Create SDK config for metrics tracker
    CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
    sdkConfig.impressionTrackerURL = config.impressionTrackerURL;
    sdkConfig.metricsConfig = config.metricsConfig;
    
    [metricsTracker startWithConfig:sdkConfig];
    [self.logger info:@"Metrics tracker initialized with PayloadBuilder"];
    
    // Track SDK init method call NOW that the tracker is configured (matching Android)
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    
    // Track SDK init network call latency
    // The latency was measured in CLXSDKInitNetworkService and stored in the config response
    if (config.sdkInitLatencyMs > 0) {
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkSdkInit latency:config.sdkInitLatencyMs];
        [self.logger debug:[NSString stringWithFormat:@"Tracked SDK init network latency: %ldms", (long)config.sdkInitLatencyMs]];
    }
    
    // Track geo API network call latency
    // The latency was stored in UserDefaults by CLXAdReportingNetworkService
    // Note: We check objectForKey: first because integerForKey: returns 0 both when
    // the key doesn't exist AND when the actual value is 0ms (simulator geo lookup)
    NSNumber *storedGeoLatency = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreGeoLatencyMsKey];
    if (storedGeoLatency != nil) {
        NSInteger geoLatencyMs = [storedGeoLatency integerValue];
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkGeoApi latency:geoLatencyMs];
        [self.logger debug:[NSString stringWithFormat:@"Tracked deferred geo API latency: %ldms", (long)geoLatencyMs]];
        // Clear the stored value so it's not tracked again on subsequent SDK inits
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreGeoLatencyMsKey];
    }
    
    // NEW: Reset session metrics on SDK initialization (iOS feature parity with Android)
    [[CLXSessionMetricsTracker sharedInstance] resetAll];
    [self.logger info:@"Session metrics tracker reset on SDK init"];
    
    NSString *auctionEndpointUrl = config.auctionEndpointURL ?: @"";

    // Validate endpoints (Android parity: missing auctionEndpointURL fails init via JSONException in JsonToConfig.kt)
    if (auctionEndpointUrl.length == 0) {
        [self.logger error:@"SDK init missing required auctionEndpointURL"];
        if (completion) {
            completion(nil, [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:@"SDK config missing required auctionEndpointURL"]);
        }
        return;
    } else {
        [self.logger info:[NSString stringWithFormat:@"Auction endpoint resolved: %@", auctionEndpointUrl]];
    }
    
    // Metrics use impressionTrackerURL with /bulk suffix
    if (!config.impressionTrackerURL) {
        [self.logger debug:@"[CloudXCore] No impressionTrackerURL available - SDK performance metrics will be stored locally only"];
    }
    
    // Register services in DI container
    CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXBidNetworkServiceClass class] instance:[[CLXBidNetworkServiceClass alloc] initWithAuctionEndpointUrl:auctionEndpointUrl errorReporter:[CLXErrorReporter shared]]];
    
    // Check if adapters are empty (skip in test mode - isTestMode already defined above)
    if (_adNetworkFactories.isEmpty && !isTestMode) {
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound];
        [self.logger error:[NSString stringWithFormat:@"SDK initialization failed: %@", error.localizedDescription]];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    if (isTestMode && _adNetworkFactories.isEmpty) {
        [self.logger debug:@"[CloudXCore] Test mode detected - skipping adapter validation"];
    }
    
    // Mark as initialized
    _isInitialized = YES;
    
    // Record SDK initialization timestamp for time-to-first-ad tracking
    [[CLXSessionMetricsTracker sharedInstance] recordSDKInitialization];
    
    // Configure callback to send time-to-first-ad metric when first impression occurs
    // This connects the SessionMetricsTracker to the MetricsTrackerImpl without tight coupling
    id<CLXMetricsTrackerProtocol> ttfaMetricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [[CLXSessionMetricsTracker sharedInstance] setTimeToFirstAdCallback:^(NSInteger timeToFirstAdMs) {
        // Nil-safe like Android's optional chaining
        if (ttfaMetricsTracker) {
            [ttfaMetricsTracker trackNetworkCall:CLXMetricsTypeNetworkTimeToFirstAd latency:timeToFirstAdMs];
        }
    }];
    
    // Post internal notification for ad objects to resume queued operations
    [[NSNotificationCenter defaultCenter] postNotificationName:CLXSDKInitializedNotification object:nil];
    
    // Visual debugging overlay is NOT auto-enabled - use setVisualDebuggingEnabled: to toggle
    // This allows debugging of production ads without testMode polluting ad content
    
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
    
    // Show visual debugging overlay if enabled (testMode OR visualDebugging flag)
    // This must be called after SDK init because the overlay manager is lazy-loaded
    // and won't have received the NSUserDefaultsDidChangeNotification from earlier
    [[CLXDebugOverlayManager shared] showIfEnabled];
    
    if (completion) {
        completion([[CLXSdkConfiguration alloc] init], nil);
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
 * Look up ad unit configuration by ID
 * @param adUnitId The ad unit ID (e.g., "um9Ek08ScJBWuzSMTyW3b")
 * @return Ad unit configuration or nil if not found
 */
- (CLXSDKConfigAdUnit *)adUnitConfigForId:(NSString *)adUnitId {
    return _adUnits[adUnitId];
}

/**
 * Get all available ad unit IDs from the SDK configuration
 * @return Array of ad unit IDs, or empty array if SDK not initialized or no ad units configured
 */
- (NSArray<NSString *> *)availableAdUnitIds {
    if (!_adUnits || _adUnits.count == 0) {
        return @[];
    }
    return [[_adUnits allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)setHashedUserID:(NSString *)hashedUserID {
    // Track hashed user ID method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetHashedUserId];
    }
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

    // Store in state system for bid request injection
    [[CLXKeyValueState shared] setHashedUserId:hashedUserID];
    
    [self.logger info:@"Hashed user ID stored successfully"];
}

- (void)setUserKeyValue:(NSString *)key value:(NSString *)value {
    if (!key || !value) {
        [self.logger warn:@"[CloudXCore] Attempted to set user key-value with nil key or value"];
        return;
    }
    
    // Nil-safe like Android's optional chaining
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetUserKeyValues];
    }
    
    [[CLXKeyValueState shared] setUserKeyValue:key value:value];
    [self.logger info:[NSString stringWithFormat:@"User key-value pair set: %@ = %@", key, value]];
}

- (void)setAppKeyValue:(NSString *)key value:(NSString *)value {
    if (!key || !value) {
        [self.logger warn:@"[CloudXCore] Attempted to set app key-value with nil key or value"];
        return;
    }
    
    // Nil-safe like Android's optional chaining
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodSetAppKeyValues];
    }
    
    [[CLXKeyValueState shared] setAppKeyValue:key value:value];
    [self.logger info:[NSString stringWithFormat:@"App key-value pair set: %@ = %@", key, value]];
}

- (void)clearAllKeyValues {
    [[CLXKeyValueState shared] clearAllKeyValues];
    [self.logger info:@"All key-value pairs cleared"];
}

- (CLXBannerAdView *)createBannerWithAdUnitId:(NSString *)adUnitId {
    // Track banner creation method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateBanner];
    }
    [self.logger debug:[NSString stringWithFormat:@"Creating banner for ad unit: %@", adUnitId]];
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    CLXError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get ad unit from config (may be nil if SDK not initialized yet)
    CLXSDKConfigAdUnit *adUnitConfig = nil;
    if (_isInitialized && !deferredError) {
        // SDK is initialized - validate ad unit with detailed error messages
        CLXAdUnitValidationResult *validationResult = [CLXAdUnitValidator validateBannerAdUnit:adUnitId
                                                                                       adUnits:_adUnits];
        if (validationResult.isSuccess) {
            adUnitConfig = validationResult.adUnit;
        } else {
            [self.logger error:[NSString stringWithFormat:@"Ad unit validation failed - error will be deferred to load(): %@", validationResult.error.localizedDescription]];
            deferredError = validationResult.error;
        }
    } else if (!_isInitialized) {
        // SDK not initialized yet - try to get ad unit (may be nil)
        adUnitConfig = [self adUnitConfigForId:adUnitId];
    }
    
    // Defer ad unit config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (adUnitConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID];
    } else if (!adUnitConfig && !_isInitialized) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring banner initialization for ad unit: %@", adUnitId]];
    }
    
    // ALWAYS create banner (errors deferred to load())
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] initWithAdUnit:adUnitConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                   suspendPreloadWhenInvisible:NO
                                                                     delegate:nil
                                                                   bannerType:CLXBannerTypeW320H50
                                                                       impModel:impModel
                                                                    adFactories:_adNetworkFactories.banners
                                                                 bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:adUnitConfig.bidRequestTimeoutSeconds
                                                              reportingService:_reportingService
                                                                      settings:[CLXSettings sharedInstance]
                                                              ];

    // Set deferred error if validation failed (via private category)
    if (deferredError) {
        banner.deferredError = deferredError;
    }
    
    // If SDK not initialized, store the requested ad unit name for deferred lookup
    if (!adUnitConfig) {
        banner.requestedAdUnitId = adUnitId;
        banner.adUnitId = adUnitId;
    }

    // ALWAYS return non-nil
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeW320H50];
}

// Deprecated: the SDK now resolves the presenting VC via topViewController at
// the moment it's needed (JIT). This overload exists solely for backward compat
// with host apps that already pass a VC. The stored VC is used as a first-choice
// fallback in didLoadBanner: before falling back to JIT resolution.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (CLXBannerAdView *)createBannerWithAdUnitId:(NSString *)adUnitId
                               viewController:(UIViewController *)viewController {
    CLXBannerAdView *adView = [self createBannerWithAdUnitId:adUnitId];
    adView.viewController = viewController;
    return adView;
}
#pragma clang diagnostic pop

- (CLXBannerAdView *)createMRECWithAdUnitId:(NSString *)adUnitId {
    // Track MREC creation method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateMrec];
    }
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    CLXError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get ad unit from config (may be nil if SDK not initialized yet)
    CLXSDKConfigAdUnit *adUnitConfig = nil;
    if (_isInitialized && !deferredError) {
        // SDK is initialized - validate ad unit with detailed error messages
        CLXAdUnitValidationResult *validationResult = [CLXAdUnitValidator validateMRECAdUnit:adUnitId
                                                                                     adUnits:_adUnits];
        if (validationResult.isSuccess) {
            adUnitConfig = validationResult.adUnit;
        } else {
            [self.logger error:[NSString stringWithFormat:@"Ad unit validation failed - error will be deferred to load(): %@", validationResult.error.localizedDescription]];
            deferredError = validationResult.error;
        }
    } else if (!_isInitialized) {
        // SDK not initialized yet - try to get ad unit (may be nil)
        adUnitConfig = [self adUnitConfigForId:adUnitId];
    }
    
    // Defer ad unit config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (adUnitConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID];
    } else if (!adUnitConfig && !_isInitialized) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring MREC initialization for ad unit: %@", adUnitId]];
    }
    
    // ALWAYS create banner (errors deferred to load())
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] initWithAdUnit:adUnitConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                    suspendPreloadWhenInvisible:NO
                                                                     delegate:nil
                                                                   bannerType:CLXBannerTypeMREC
                                                                       impModel:impModel
                                                                    adFactories:_adNetworkFactories.banners
                                                                 bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:adUnitConfig.bidRequestTimeoutSeconds
                                                              reportingService:_reportingService
                                                                      settings:[CLXSettings sharedInstance]
                                                              ];

    // Set deferred error if validation failed (via private category)
    if (deferredError) {
        banner.deferredError = deferredError;
    }
    
    // If SDK not initialized, store the requested ad unit name for deferred lookup
    if (!adUnitConfig) {
        banner.requestedAdUnitId = adUnitId;
        banner.adUnitId = adUnitId;
    }

    // ALWAYS return non-nil
    return [[CLXBannerAdView alloc] initWithBanner:banner type:CLXBannerTypeMREC];
}

// Deprecated: same rationale as createBannerWithAdUnitId:viewController: above.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (CLXBannerAdView *)createMRECWithAdUnitId:(NSString *)adUnitId
                             viewController:(UIViewController *)viewController {
    CLXBannerAdView *adView = [self createMRECWithAdUnitId:adUnitId];
    adView.viewController = viewController;
    return adView;
}
#pragma clang diagnostic pop

- (CLXInterstitial *)createInterstitialWithAdUnitId:(NSString *)adUnitId {
    // Track interstitial creation method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateInterstitial];
    }
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    CLXError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get ad unit from config (may be nil if SDK not initialized yet)
    CLXSDKConfigAdUnit *adUnitConfig = nil;
    if (_isInitialized && !deferredError) {
        // SDK is initialized - validate ad unit with detailed error messages
        CLXAdUnitValidationResult *validationResult = [CLXAdUnitValidator validateInterstitialAdUnit:adUnitId
                                                                                             adUnits:_adUnits];
        if (validationResult.isSuccess) {
            adUnitConfig = validationResult.adUnit;
        } else {
            [self.logger error:[NSString stringWithFormat:@"Ad unit validation failed - error will be deferred to load(): %@", validationResult.error.localizedDescription]];
            deferredError = validationResult.error;
        }
    } else if (!_isInitialized) {
        // SDK not initialized yet - try to get ad unit (may be nil)
        adUnitConfig = [self adUnitConfigForId:adUnitId];
    }
    
    // Defer ad unit config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (adUnitConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID];
    } else if (!adUnitConfig && !_isInitialized) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring interstitial initialization for ad unit: %@", adUnitId]];
    }
    
    // ALWAYS create interstitial (errors deferred to load())
    CLXInterstitial *interstitial = [[CLXInterstitial alloc] initWithAdUnit:adUnitConfig
                                                                     publisherID:@""
                                                                          userID:@""
                                                             rewardedCallbackUrl:nil
                                                                        impModel:impModel
                                                                     adFactories:_adNetworkFactories
                                                                 bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:adUnitConfig.bidRequestTimeoutSeconds
                                                               reportingService:_reportingService
                                                                       settings:[CLXSettings sharedInstance]];
    
    // Set deferred error if validation failed (via private category)
    if (deferredError) {
        interstitial.deferredError = deferredError;
    }
    
    // If SDK not initialized, store the requested ad unit name for deferred lookup
    if (!adUnitConfig) {
        interstitial.requestedAdUnitId = adUnitId;
        interstitial.adUnitId = adUnitId;
    }
    
    // ALWAYS return non-nil
    return interstitial;
}

- (CLXRewarded *)createRewardedWithAdUnitId:(NSString *)adUnitId {
    // Track rewarded creation method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateRewarded];
    }
    
    // v1.3.0: Defer validation errors to load() - always return non-nil
    CLXError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }
    
    // Get ad unit from config (may be nil if SDK not initialized yet)
    CLXSDKConfigAdUnit *adUnitConfig = nil;
    if (_isInitialized && !deferredError) {
        // SDK is initialized - validate ad unit with detailed error messages
        CLXAdUnitValidationResult *validationResult = [CLXAdUnitValidator validateRewardedAdUnit:adUnitId
                                                                                         adUnits:_adUnits];
        if (validationResult.isSuccess) {
            adUnitConfig = validationResult.adUnit;
        } else {
            [self.logger error:[NSString stringWithFormat:@"Ad unit validation failed - error will be deferred to load(): %@", validationResult.error.localizedDescription]];
            deferredError = validationResult.error;
        }
    } else if (!_isInitialized) {
        // SDK not initialized yet - try to get ad unit (may be nil)
        adUnitConfig = [self adUnitConfigForId:adUnitId];
    }
    
    // Defer ad unit config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (adUnitConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID];
    } else if (!adUnitConfig && !_isInitialized) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring rewarded initialization for ad unit: %@", adUnitId]];
    }
    
    // ALWAYS create rewarded (errors deferred to load())
    CLXRewarded *rewarded = [[CLXRewarded alloc] initWithAdUnit:adUnitConfig
                                                         publisherID:@""
                                                              userID:@""
                                                 rewardedCallbackUrl:nil
                                                            impModel:impModel
                                                         adFactories:_adNetworkFactories
                                                     bidTokenSources:_adNetworkFactories.bidTokenSources
                                                  bidRequestTimeout:adUnitConfig.bidRequestTimeoutSeconds
                                                   reportingService:_reportingService
                                                           settings:[CLXSettings sharedInstance]];
    
    // Set deferred error if validation failed (via private category)
    if (deferredError) {
        rewarded.deferredError = deferredError;
    }
    
    // If SDK not initialized, store the requested ad unit name for deferred lookup
    if (!adUnitConfig) {
        rewarded.requestedAdUnitId = adUnitId;
        rewarded.adUnitId = adUnitId;
    }
    
    // ALWAYS return non-nil
    return rewarded;
}

- (CLXNativeAdView *)createNativeAdWithAdUnitId:(NSString *)adUnitId viewController:(UIViewController *)viewController delegate:(id)delegate {
    // Track native creation method call (nil-safe like Android's optional chaining)
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    if (metricsTracker) {
        [metricsTracker trackMethodCall:CLXMetricsTypeMethodCreateNative];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Creating native ad for adUnit: %@", adUnitId]];

    // v1.3.0: Defer validation errors to load() - always return non-nil
    CLXError *deferredError = nil;
    
    // Check if adapters are registered
    if (_adNetworkFactories.isEmpty) {
        [self.logger error:@"No adapters registered - error will be deferred to load()"];
        deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                    description:@"No adapters registered. At least one adapter framework must be included in your project to show ads."];
    }

    // Get ad unit from config (may be nil if SDK not initialized yet)
    CLXSDKConfigAdUnit *adUnitConfig = nil;
    if (_isInitialized && !deferredError) {
        // SDK is initialized - validate ad unit with detailed error messages
        // Note: Native ads don't have a specific type in config, so we only validate existence
        CLXAdUnitValidationResult *validationResult = [CLXAdUnitValidator validateNativeAdUnit:adUnitId
                                                                                       adUnits:_adUnits];
        if (validationResult.isSuccess) {
            adUnitConfig = validationResult.adUnit;
        } else {
            [self.logger error:[NSString stringWithFormat:@"Ad unit validation failed - error will be deferred to load(): %@", validationResult.error.localizedDescription]];
            deferredError = validationResult.error;
        }
    } else if (!_isInitialized) {
        // SDK not initialized yet - try to get ad unit (may be nil)
        adUnitConfig = [self adUnitConfigForId:adUnitId];
    }
    
    // Defer ad unit config and impression model creation if SDK not ready
    CLXConfigImpressionModel *impModel = nil;
    if (adUnitConfig && _sdkConfig) {
        // SDK is initialized - create impression model now
        NSString *auctionID = [[NSUUID UUID] UUIDString];
        impModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:_sdkConfig
                                                              auctionID:auctionID];
    } else if (!adUnitConfig && !_isInitialized) {
        // SDK not initialized yet - defer all initialization to load() time
        [self.logger debug:[NSString stringWithFormat:@"SDK not initialized - deferring native initialization for ad unit: %@", adUnitId]];
    }
    
    // ALWAYS create native (errors deferred to load())
    CLXPublisherNative *native = [[CLXPublisherNative alloc] initWithViewController:viewController
                                                                     adUnit:adUnitConfig
                                                                        userID:@""
                                                                   publisherID:@""
                                                    suspendPreloadWhenInvisible:NO
                                                                     delegate:delegate
                                                                   nativeType:CLXNativeTemplateDefault
                                                                    impModel:impModel
                                                                    adFactories:_adNetworkFactories.native
                                                                bidTokenSources:_adNetworkFactories.bidTokenSources
                                                              bidRequestTimeout:adUnitConfig.bidRequestTimeoutSeconds
                                                              reportingService:_reportingService];
    
    // Set deferred error if validation failed (via private category)
    if (deferredError) {
        native.deferredError = deferredError;
    }
    
    // If SDK not initialized, store the requested ad unit name for deferred lookup
    if (!adUnitConfig) {
        native.requestedAdUnitId = adUnitId;
        native.adUnitId = adUnitId;
    }
    
    // Use default template if adUnitConfig is nil (deferred init case)
    CLXNativeTemplate nativeTemplate = adUnitConfig ? adUnitConfig.nativeTemplate : CLXNativeTemplateDefault;
    
    // ALWAYS return non-nil
    return [[CLXNativeAdView alloc] initWithNative:native type:nativeTemplate delegate:delegate];
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
    NSMutableDictionary *adUnitsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.adUnits && _sdkConfig.adUnits.count > 0) {
        for (CLXSDKConfigAdUnit *adUnit in _sdkConfig.adUnits) {
            adUnitsDict[adUnit.id] = adUnit; // Use id as key to match Android SDK
        }
    }
    _adUnits = [adUnitsDict copy];
    
    // Also populate ad network configs dictionary
    NSMutableDictionary *configsDict = [NSMutableDictionary dictionary];
    if (_sdkConfig.bidders && _sdkConfig.bidders.count > 0) {
        for (CLXSDKConfigBidder *bidder in _sdkConfig.bidders) {
            configsDict[bidder.networkName] = bidder;
        }
    }
    _adNetworkConfigs = [configsDict copy];
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
    NSString *safeCampaignId = [campaignId clx_urlQueryEncodedString];
    
    // Create error-specific encoded string by appending error details
    NSString *errorPayload = [NSString stringWithFormat:@"%@;%@", encodedString, errorDetails];
    NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
    NSString *errorEncrypted = [CLXXorEncryption encrypt:errorPayload secret:secret];
    NSString *safeErrorEncrypted = [errorEncrypted clx_urlQueryEncodedString];
    
    // Send SDK error tracking event
    [sharedInstance.reportingService rillTrackingWithActionString:@"sdkerrorenc" 
                                                       campaignId:safeCampaignId 
                                                    encodedString:safeErrorEncrypted];
    
    [sharedInstance.logger info:@"Sent SDK error Analytics tracking event"];
}

/**
 * Tracks an adapter initialization failure error event.
 * Called synchronously within the adapter init completion block (which already runs
 * inside a dispatch_group_wait barrier, so no need to dispatch to background).
 *
 * @param networkName The name of the network whose adapter failed to initialize
 * @param originalError The original error from the adapter initialization attempt (may be nil)
 */
- (void)trackAdapterInitializationErrorForNetwork:(NSString *)networkName originalError:(NSError * _Nullable)originalError {
    NSString *errorDetails = originalError.localizedDescription ?: @"No error details provided";
    NSString *errorDescription = [NSString stringWithFormat:@"Adapter initialization failed: %@ - %@",
                                  networkName, errorDetails];
    
    CLXError *adapterError = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                         description:errorDescription];
    
    [CloudXCore trackSDKError:adapterError];
}

#pragma mark - Visual Debugging

// In-memory only - resets to NO on every app launch for safety
// Prevents accidental release with visual debugging enabled
static BOOL _visualDebuggingEnabled = NO;

+ (void)setVisualDebuggingEnabled:(BOOL)enabled {
    _visualDebuggingEnabled = enabled;
    
    if (enabled) {
        [[CLXDebugOverlayManager shared] showIfEnabled];
    } else {
        [[CLXDebugOverlayManager shared] hide];
    }
}

+ (BOOL)isVisualDebuggingEnabled {
    return _visualDebuggingEnabled;
}

#pragma mark - Logging Control

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

#pragma mark - Testing Support

- (void)resetForTesting {
    // Reset initialization state
    _isInitialized = NO;
    _appKey = nil;
    _sdkConfig = nil;
    _adNetworkConfigs = nil;
    _adUnits = nil;
    _adFactory = nil;
    _reportingService = nil;
    _geoLocationService = nil;
    _bidNetworkService = nil;
    _adNetworkFactories = nil;
    [_readyAdapters removeAllObjects];

    [_ilrdTracker stop];
    _ilrdTracker = nil;

    // Note: We don't reset the singleton instance itself or the initService
    // as those are meant to persist across the app lifecycle
}

@end 
