/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file SDKInitNetworkService.m
 * @brief Implementation of network service for SDK initialization
 */

#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXExponentialBackoffStrategy.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXSDKConfigEndpointObject.h>

static NSString *const kAPIRequestKeyAppKey = @"appKey";
static NSString *const kAPIRequestKeyLat = @"lat";
static NSString *const kAPIRequestKeyIfa = @"ifa";

@interface CLXSDKInitNetworkService ()
@property (nonatomic, copy) NSString *endpoint;
@end

@implementation CLXSDKInitNetworkService

/**
 * @brief Initializes the network service with base URL and session
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @return An initialized instance of SDKInitNetworkService
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    [self.logger debug:[NSString stringWithFormat:@"Initializing with baseURL: %@", baseURL]];
    
    // Extract the base URL and endpoint from the full URL
    NSURL *url = [NSURL URLWithString:baseURL];
    NSString *actualBaseURL = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    NSString *endpointPath = url.path;
    
    // Handle empty or nil path
    if (!endpointPath || endpointPath.length == 0) {
        endpointPath = @"/";
    }
    
    [self.logger debug:[NSString stringWithFormat:@"URL parsing - Original: %@, Base: %@, Path: '%@'", baseURL, actualBaseURL, endpointPath]];
    
    
    // Call parent's initWithBaseURL method with the actual base URL
    self = [super initWithBaseURL:actualBaseURL urlSession:urlSession];
    if (self) {
        _endpoint = endpointPath;
        _logger = [[CLXLogger alloc] initWithCategory:@"SDKInitNetworkService"];
        _backOffStrategy = [[CLXExponentialBackoffStrategy alloc] initWithInitialDelay:1 maxDelay:60 maxAttempts:5];
        [self.logger info:[NSString stringWithFormat:@"Initialized - endpoint: %@, baseURL: %@", _endpoint, self.baseURL]];
    }
    return self;
}

/**
 * @brief Returns the headers required for API requests
 * @return Dictionary containing the required headers
 */
- (NSDictionary *)headers {
    return @{
        @"Content-Type": @"application/json"
    };
}

/**
 * @brief Initializes the SDK with the provided app key
 * @param appKey The application key for SDK initialization
 * @param completion Completion handler called with the SDK configuration or error
 */
- (void)initializeSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable, NSError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"[SDKInitNetworkService] initializeSDKWithAppKey called - AppKey: %@, Endpoint: %@", appKey, _endpoint]];
    [self tryInitSDKWithAppKey:appKey completion:completion];
}

/**
 * @brief Attempts to initialize the SDK with retry logic
 * @param appKey The application key for SDK initialization
 * @param completion Completion handler called with the SDK configuration or error
 */
- (void)tryInitSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable, NSError * _Nullable))completion {
    [self.logger debug:@"tryInitSDKWithAppKey called"];
    
    NSError *backoffError;
    NSTimeInterval delay = [self.backOffStrategy nextDelayWithError:&backoffError];
    if (backoffError) {
        [self.logger error:@"Backoff strategy exhausted"];
        [self.backOffStrategy reset];
        if (completion) {
            completion(nil, [CLXError errorWithCode:CLXErrorCodeInitializationTimeout 
                                       description:@"SDK initialization timed out after multiple retry attempts. Please check your network connection and try again."]);
        }
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Attempt to init SDK with delay: %f", delay]];
    
    [self.logger debug:@"Creating request"];
    CLXSDKConfigRequest *request = [self createRequest];
    [self.logger debug:[NSString stringWithFormat:@"Request created: %@", request]];
    
    [self.logger debug:@"Preparing headers"];
    NSMutableDictionary *headers = [[self headers] mutableCopy];
    headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", appKey];
    [self.logger debug:[NSString stringWithFormat:@"Headers: %@", headers]];
    
    [self.logger debug:[NSString stringWithFormat:@"[SDKInitNetworkService] Executing network request - Endpoint: %@", self.endpoint]];
    
    // Serialize the JSON dictionary to NSData
    NSError *jsonError;
    NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:request.json options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"JSON serialization failed: %@", jsonError]];
        if (completion) {
            completion(nil, jsonError);
        }
        return;
    }
    
    // Debug: Print the request payload
    NSString *requestPayloadString = [[NSString alloc] initWithData:requestBodyData encoding:NSUTF8StringEncoding];
    [self.logger debug:[NSString stringWithFormat:@"[SDKInitNetworkService] Request Payload:\n%@", requestPayloadString]];
    
    // Track SDK init network call latency
    NSDate *sdkInitStartTime = [NSDate date];
    
    [self executeRequestWithEndpoint:self.endpoint
                     urlParameters:nil
                      requestBody:requestBodyData
                          headers:headers
                       maxRetries:1
                           delay:delay
                          completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
            // Track SDK init network call latency
            NSTimeInterval sdkInitLatency = [[NSDate date] timeIntervalSinceDate:sdkInitStartTime] * 1000; // Convert to milliseconds
            id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
            [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkSdkInit latency:(NSInteger)sdkInitLatency];
            
            [self.logger debug:@"[SDKInitNetworkService] Network request completion called"];
            
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"Network request failed: %@", error.localizedDescription]];
                if (completion) {
                    completion(nil, error);
                }
                return;
            } else if (isKillSwitchEnabled) {
                NSError *sdkDisabledError = [CLXError errorWithCode:CLXErrorCodeSDKDisabled description:@"No response data"];
                [self.logger error:@"kill switch in on received"];
                if (completion) completion(nil, sdkDisabledError);
                return;
            } else {
                [self.logger info:@"Network request succeeded"];
                
                // Parse the response into SDKConfig object
                CLXSDKConfigResponse *config = [self parseSDKConfigFromResponse:response];
                if (!config) {
                    [self.logger error:@"Failed to parse SDK config from response"];
                    if (completion) {
                        completion(nil, [CLXError errorWithCode:CLXErrorCodeInvalidResponse 
                                               description:@"Invalid server response: Unable to parse SDK configuration. Please try again or contact support."]);
                    }
                    return;
                }
                
                if (completion) {
                    completion(config, nil);
                }
            }
        }];
}

/**
 * @brief Creates a configuration request with system information
 * @return SDKConfigRequest object containing system information
 */
- (CLXSDKConfigRequest *)createRequest {
    [self.logger debug:@"Creating SDK config request"];
    
    // Use IDFV as rid for rollout
    NSString *idfa = [CLXSystemInformation shared].idfa ?: @"00000-00000-00000-000000";
    NSString *idfv = [CLXSystemInformation shared].idfv ?: @"00000-00000-00000-000000";
    
    [self.logger debug:[NSString stringWithFormat:@"Device info - IDFA: %@, Bundle: %@, OS: %@", idfa, [CLXSystemInformation shared].appBundleIdentifier, [CLXSystemInformation shared].osVersion]];
    
    CLXSDKConfigRequest *request = [[CLXSDKConfigRequest alloc] init];
    request.bundle = [CLXSystemInformation shared].appBundleIdentifier;
    request.os = @"iOS";
    request.osVersion = [CLXSystemInformation shared].osVersion;
    request.model = [UIDevice clx_deviceIdentifier];
    request.vendor = @"Apple";
    request.ifa = idfa;
    request.ifv = idfv;
    request.sdkVersion = [CLXSystemInformation shared].sdkVersion;
    request.dnt = [CLXSystemInformation shared].dnt;
    request.imp = @[]; // Empty array as in Swift
    request.id = [[NSUUID UUID] UUIDString];
    request.urlParams = @{}; // Empty dictionary as in Swift
    
    [self.logger info:[NSString stringWithFormat:@"Request created successfully - ID: %@", request.id]];
    
    return request;
}

/**
 * @brief Parses the network response into an SDKConfigResponse object
 * @param response The raw response dictionary from the network request
 * @return SDKConfigResponse object or nil if parsing fails
 */
- (CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response {
    if (!response || ![response isKindOfClass:[NSDictionary class]]) {
        [self.logger error:@"Invalid response format"];
        return nil;
    }
    
    [self.logger debug:@"Parsing SDK config from response"];
    
    // 🔍 DEBUG: Print the full SDK init response to examine tracking configuration
    [self.logger info:[NSString stringWithFormat:@"[SDK_INIT_RESPONSE] Full response: %@", response]];
    
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    // Parse basic fields
    config.accountID = response[@"accountID"];
    config.organizationID = response[@"organizationID"];
    config.sessionID = response[@"sessionID"];
    config.appID = response[@"appID"];
    config.geoDataEndpointURL = response[@"geoDataEndpointURL"];
    
    // Parse tracking array for Analytics
    NSArray *trackingArray = response[@"tracking"];
    if (trackingArray && [trackingArray isKindOfClass:[NSArray class]]) {
        config.tracking = [trackingArray copy];
    } else {
        config.tracking = nil;  // Explicitly set to nil when missing or malformed
        [self.logger error:@"No tracking array found in SDK init response - Analytics tracking may not work properly"];
    }
    
    // Parse auction endpoint URL with A/B test support
    id auctionEndpointValue = response[@"auctionEndpointURL"];
    if (auctionEndpointValue) {
        CLXSDKConfigEndpointQuantumValue *endpointQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
        
        if ([auctionEndpointValue isKindOfClass:[NSString class]]) {
            // Simple string format
            endpointQuantum.endpointString = (NSString *)auctionEndpointValue;
        } else if ([auctionEndpointValue isKindOfClass:[NSDictionary class]]) {
            // Object format with default and test variants
            NSDictionary *auctionDict = (NSDictionary *)auctionEndpointValue;
            CLXSDKConfigEndpointObject *endpointObj = [self parseEndpointObject:auctionDict];
            endpointQuantum.endpointObject = endpointObj;
        }
        
        config.auctionEndpointURL = endpointQuantum;
    }

    // Parse geoHeaders
    NSArray *geoHeaders = response[@"geoHeaders"];
    if (geoHeaders && [geoHeaders isKindOfClass:[NSArray class]]) {
        NSMutableArray *geos = [NSMutableArray array];
        for (NSDictionary *geoHeadersDict in geoHeaders) {
            CLXSDKConfigGeoBid *geoHeader = [[CLXSDKConfigGeoBid alloc] init];
            geoHeader.source = geoHeadersDict[@"source"];
            geoHeader.target = geoHeadersDict[@"target"];
            [geos addObject:geoHeader];
        }
        config.geoHeaders = [geos copy];
    }
    
    // Parse tracking URLs
    config.impressionTrackerURL = response[@"impressionTrackerURL"];
    config.metricsEndpointURL = response[@"metricsEndpointURL"];
    config.winLossNotificationURL = response[@"winLossNotificationURL"];
    
    // Parse metrics configuration from server response
    NSArray<NSDictionary *> *metricsConfigArr = response[@"metrics"];
    if (metricsConfigArr.count > 0) {
        NSDictionary *metricsConfigDict = metricsConfigArr[0];
        config.metricsConfig = [CLXMetricsConfig fromDictionary: metricsConfigDict];
        [self.logger debug:[NSString stringWithFormat:@"Parsed metrics config: %@", config.metricsConfig]];
    } else {
        [self.logger debug:@"[SDKInitNetworkService] No metrics configuration found in server response"];
        // Create default config to enable metrics with impression URL
        CLXMetricsConfig *defaultConfig = [[CLXMetricsConfig alloc] init];
        defaultConfig.sdkAPICalls.enabled = @YES;
        defaultConfig.networkCalls.enabled = @YES;
        defaultConfig.networkCalls.bidReq.enabled = @YES;
        defaultConfig.networkCalls.sdkInitRequest.enabled = @NO; // Keep SDK init disabled by default
        defaultConfig.networkCalls.geoReq.enabled = @YES;
        config.metricsConfig = defaultConfig;
        [self.logger debug:@"Created default metrics config for impression URL usage"];
    }
    
    // Parse win/loss notification payload configuration
    NSDictionary *winLossPayloadConfig = response[@"winLossNotificationPayloadConfig"];
    if (winLossPayloadConfig && [winLossPayloadConfig isKindOfClass:[NSDictionary class]]) {
        config.winLossNotificationPayloadConfig = [winLossPayloadConfig copy];
        [self.logger debug:[NSString stringWithFormat:@"Win/loss payload config parsed with %lu fields", 
                           (unsigned long)config.winLossNotificationPayloadConfig.count]];
    } else {
        config.winLossNotificationPayloadConfig = nil;
        [self.logger debug:@"[SDK_INIT] No win/loss payload config found in response"];
    }
    
    // Parse bidders
    NSArray *biddersArray = response[@"bidders"];
    if (biddersArray && [biddersArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *bidders = [NSMutableArray array];
        for (NSDictionary *bidderDict in biddersArray) {
            CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] init];
            bidder.networkName = bidderDict[@"networkName"];
            bidder.bidderInitData = bidderDict[@"initData"];
            [bidders addObject:bidder];
        }
        config.bidders = [bidders copy];
    }
    
    // Parse placements
    NSArray *placementsArray = response[@"placements"];
    if (placementsArray && [placementsArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *placements = [NSMutableArray array];
        for (NSDictionary *placementDict in placementsArray) {
            CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
            placement.id = placementDict[@"id"];
            placement.name = placementDict[@"name"];
            
            // Convert string type to enum
            NSString *typeString = placementDict[@"type"];
            if ([typeString isEqualToString:@"banner"]) {
                placement.type = SDKConfigAdTypeBanner;
            } else if ([typeString isEqualToString:@"mrec"]) {
                placement.type = SDKConfigAdTypeMrec;
            } else if ([typeString isEqualToString:@"interstitial"]) {
                placement.type = SDKConfigAdTypeInterstitial;
            } else if ([typeString isEqualToString:@"rewarded"]) {
                placement.type = SDKConfigAdTypeRewarded;
            } else {
                placement.type = SDKConfigAdTypeUnknown;
            }
            
            placement.bidResponseTimeoutMs = [placementDict[@"bidResponseTimeoutMs"] integerValue];
            placement.adLoadTimeoutMs = [placementDict[@"adLoadTimeoutMs"] integerValue];
            placement.bannerRefreshRateMs = [placementDict[@"bannerRefreshRateMs"] integerValue];
            
            // Parse reward configuration for rewarded placements
            if (placementDict[@"rewardAmount"]) {
                placement.rewardAmount = [placementDict[@"rewardAmount"] integerValue];
            }
            if (placementDict[@"rewardCurrency"]) {
                placement.rewardCurrency = placementDict[@"rewardCurrency"];
            }
            if (placementDict[@"rewardCallbackUrl"]) {
                placement.rewardCallbackUrl = placementDict[@"rewardCallbackUrl"];
            }
            
            [placements addObject:placement];
        }
        config.placements = [placements copy];
    }
    
    [self.logger info:[NSString stringWithFormat:@"SDK config parsed - Account: %@, Session: %@, Bidders: %lu, Placements: %lu", config.accountID, config.sessionID, (unsigned long)config.bidders.count, (unsigned long)config.placements.count]];
    
    return config;
}

/**
 * @brief Parses endpoint object with default and test variants for A/B testing
 * @param endpointDict Dictionary containing 'default' and optionally 'test' array
 * @return CLXSDKConfigEndpointObject with parsed test variants
 */
- (CLXSDKConfigEndpointObject *)parseEndpointObject:(NSDictionary *)endpointDict {
    NSString *defaultValue = endpointDict[@"default"] ?: @"";
    NSArray *testArray = endpointDict[@"test"];
    NSMutableArray<CLXSDKConfigEndpointValue *> *testVariants = [NSMutableArray array];
    
    if (testArray && [testArray isKindOfClass:[NSArray class]]) {
        for (id testItem in testArray) {
            if ([testItem isKindOfClass:[NSDictionary class]]) {
                NSDictionary *testDict = (NSDictionary *)testItem;
                NSString *name = testDict[@"name"];
                NSString *value = testDict[@"value"];
                NSNumber *ratioNum = testDict[@"ratio"];
                double ratio = ratioNum ? [ratioNum doubleValue] : 0.0;
                
                if (value && [value isKindOfClass:[NSString class]] && value.length > 0) {
                    CLXSDKConfigEndpointValue *variant = [[CLXSDKConfigEndpointValue alloc] initWithName:name 
                                                                                                    value:value 
                                                                                                    ratio:ratio];
                    [testVariants addObject:variant];
                }
            }
        }
    }
    
    return [[CLXSDKConfigEndpointObject alloc] initWithTest:testVariants.count > 0 ? testVariants : nil 
                                                  defaultKey:defaultValue];
}

@end 
