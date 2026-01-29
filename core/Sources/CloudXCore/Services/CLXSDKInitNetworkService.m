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
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXSDKConfigEndpointObject.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

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
    NSString *portString = url.port ? [NSString stringWithFormat:@":%@", url.port] : @"";
    NSString *actualBaseURL = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, portString];
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
                          timeout:0  // Use session default (30s)
                       maxRetries:1
                           delay:0
                          completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
            // Calculate SDK init network latency (will be stored in response for later tracking)
            NSTimeInterval sdkInitLatency = [[NSDate date] timeIntervalSinceDate:sdkInitStartTime] * 1000; // Convert to milliseconds
            
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

                // Parse the response into SDKConfig object with required field validation
                NSError *parseError = nil;
                CLXSDKConfigResponse *config = [self parseSDKConfigFromResponse:response error:&parseError];
                if (!config) {
                    [self.logger error:[NSString stringWithFormat:@"Failed to parse SDK config: %@",
                                        parseError.localizedDescription ?: @"Unknown error"]];
                    if (completion) {
                        completion(nil, parseError ?: [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                                              description:@"Failed to parse server response"]);
                    }
                    return;
                }
                
                // Store SDK init network latency in response for later tracking
                // (tracked in CloudXCoreAPI after MetricsTracker is initialized, matching Android)
                config.sdkInitLatencyMs = (NSInteger)sdkInitLatency;
                [self.logger debug:[NSString stringWithFormat:@"SDK init network latency: %ldms", (long)config.sdkInitLatencyMs]];
                
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
    
    // Log IFA at INFO level for test whitelisting - developers can copy this to whitelist their device
    [self.logger info:[NSString stringWithFormat:@"Device IFA for test whitelisting: %@", idfa]];
    [self.logger debug:[NSString stringWithFormat:@"Device info - Bundle: %@, OS: %@, IDFV: %@", [CLXSystemInformation shared].appBundleIdentifier, [CLXSystemInformation shared].osVersion, idfv]];
    
    CLXSDKConfigRequest *request = [[CLXSDKConfigRequest alloc] init];
    request.bundle = [CLXSystemInformation shared].appBundleIdentifier;
    request.os = @"iOS";
    request.osVersion = [CLXSystemInformation shared].osVersion;
    request.model = [UIDevice clx_deviceIdentifier];
    request.vendor = @"Apple";
    request.ifa = idfa;
    request.ifv = idfv;
    request.sdkVersion = [CLXSystemInformation shared].sdkVersion;
    // Get pluginVersion from UserDefaults (set during CloudXCore.initializeSDK:pluginVersion:completion:)
    request.pluginVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCorePluginVersionKey];
    request.dnt = [CLXSystemInformation shared].dnt;
    request.imp = @[]; // Empty array as in Swift
    request.id = [[NSUUID UUID] UUIDString];
    request.urlParams = @{}; // Empty dictionary as in Swift
    
    [self.logger info:[NSString stringWithFormat:@"Request created successfully - ID: %@", request.id]];
    
    return request;
}

// Helper to get required string field
- (NSString *)requiredString:(NSString *)key from:(NSDictionary *)dict error:(NSError **)outError {
    id value = dict[key];
    if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) {
        return value;
    }
    if (outError) {
        *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                description:[NSString stringWithFormat:@"Required field '%@' is missing or empty", key]];
    }
    return nil;
}

// Helper to get required array field
- (NSArray *)requiredArray:(NSString *)key from:(NSDictionary *)dict error:(NSError **)outError {
    id value = dict[key];
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    if (outError) {
        *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                description:[NSString stringWithFormat:@"Required field '%@' is missing or not an array", key]];
    }
    return nil;
}

// Helper to get required dictionary field
- (NSDictionary *)requiredDictionary:(NSString *)key from:(NSDictionary *)dict error:(NSError **)outError {
    id value = dict[key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    if (outError) {
        *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                description:[NSString stringWithFormat:@"Required field '%@' is missing or not an object", key]];
    }
    return nil;
}

#pragma mark - Parsing: Main Entry Point

- (nullable CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response
                                                        error:(NSError **)outError {
    if (!response || ![response isKindOfClass:[NSDictionary class]]) {
        [self.logger error:@"Invalid response format"];
        if (outError) {
            *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                    description:@"Response is not a valid dictionary"];
        }
        return nil;
    }

    [self.logger debug:@"Parsing SDK config from response"];
    [self.logger info:[NSString stringWithFormat:@"[SDK_INIT_RESPONSE] Full response: %@", response]];

    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. Identity
    // ═══════════════════════════════════════════════════════════════════════════
    config.accountID = [self requiredString:@"accountID" from:response error:outError];
    if (!config.accountID) return nil;

    config.sessionID = [self requiredString:@"sessionID" from:response error:outError];
    if (!config.sessionID) return nil;

    config.appID = [self requiredString:@"appID" from:response error:outError];
    if (!config.appID) return nil;

    config.organizationID = response[@"organizationID"];  // optional

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. Endpoints
    // ═══════════════════════════════════════════════════════════════════════════
    config.auctionEndpointURL = [self parseEndpointURLFromValue:response[@"auctionEndpointURL"]
                                                          field:@"auctionEndpointURL"
                                                          error:outError];
    if (!config.auctionEndpointURL) return nil;

    config.impressionTrackerURL = [self requiredString:@"impressionTrackerURL" from:response error:outError];
    if (!config.impressionTrackerURL) return nil;

    config.winLossNotificationURL = [self requiredString:@"winLossNotificationURL" from:response error:outError];
    if (!config.winLossNotificationURL) return nil;

    config.geoDataEndpointURL = [self requiredString:@"geoDataEndpointURL" from:response error:outError];
    if (!config.geoDataEndpointURL) return nil;

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. Core Config
    // ═══════════════════════════════════════════════════════════════════════════
    NSArray *biddersArray = [self requiredArray:@"bidders" from:response error:outError];
    if (!biddersArray) return nil;
    config.bidders = [self parseBiddersFromArray:biddersArray error:outError];
    if (!config.bidders) return nil;

    NSArray *placementsArray = [self requiredArray:@"placements" from:response error:outError];
    if (!placementsArray) return nil;
    config.placements = [self parsePlacementsFromArray:placementsArray error:outError];
    if (!config.placements) return nil;

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. Tracking & Geo
    // ═══════════════════════════════════════════════════════════════════════════
    NSArray *trackingArray = [self requiredArray:@"tracking" from:response error:outError];
    if (!trackingArray) return nil;
    config.tracking = [trackingArray copy];

    NSArray *geoHeadersArray = [self requiredArray:@"geoHeaders" from:response error:outError];
    if (!geoHeadersArray) return nil;
    config.geoHeaders = [self parseGeoHeadersFromArray:geoHeadersArray];

    NSDictionary *winLossPayloadConfig = [self requiredDictionary:@"winLossNotificationPayloadConfig" from:response error:outError];
    if (!winLossPayloadConfig) return nil;
    config.winLossNotificationPayloadConfig = [self parseStringMapFromDictionary:winLossPayloadConfig];

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. Optional Config
    // ═══════════════════════════════════════════════════════════════════════════
    config.metricsConfig = [self parseMetricsConfigFromArray:response[@"metrics"]];
    config.deviceConfig = [self parseDeviceConfigFromDictionary:response[@"deviceConfig"]];

    [self.logger info:[NSString stringWithFormat:@"SDK config parsed - Account: %@, Session: %@, Bidders: %lu, Placements: %lu",
                      config.accountID, config.sessionID, (unsigned long)config.bidders.count, (unsigned long)config.placements.count]];
    return config;
}

#pragma mark - Parsing: Bidders (matches Android toBidders)

- (nullable NSArray<CLXSDKConfigBidder *> *)parseBiddersFromArray:(NSArray *)array error:(NSError **)outError {
    NSMutableArray *bidders = [NSMutableArray array];
    for (NSUInteger i = 0; i < array.count; i++) {
        id item = array[i];
        if (![item isKindOfClass:[NSDictionary class]]) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"bidders[%lu] is not an object", (unsigned long)i]];
            return nil;
        }
        NSDictionary *dict = (NSDictionary *)item;

        NSString *networkName = [self requiredString:@"networkName" from:dict error:outError];
        if (!networkName) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"bidders[%lu].networkName is missing or empty", (unsigned long)i]];
            return nil;
        }

        NSDictionary *initData = [self requiredDictionary:@"initData" from:dict error:outError];
        if (!initData) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"bidders[%lu].initData is missing or not an object", (unsigned long)i]];
            return nil;
        }

        CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] init];
        bidder.networkName = networkName;
        bidder.bidderInitData = initData;
        [bidders addObject:bidder];
    }
    return [bidders copy];
}

#pragma mark - Parsing: Placements (matches Android toAdUnits)

- (nullable NSArray<CLXSDKConfigPlacement *> *)parsePlacementsFromArray:(NSArray *)array error:(NSError **)outError {
    NSMutableArray *placements = [NSMutableArray array];
    for (NSUInteger i = 0; i < array.count; i++) {
        id item = array[i];
        if (![item isKindOfClass:[NSDictionary class]]) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"placements[%lu] is not an object", (unsigned long)i]];
            return nil;
        }
        NSDictionary *dict = (NSDictionary *)item;

        // Required fields
        NSString *placementId = [self requiredString:@"id" from:dict error:outError];
        if (!placementId) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"placements[%lu].id is missing or empty", (unsigned long)i]];
            return nil;
        }
        NSString *name = [self requiredString:@"name" from:dict error:outError];
        if (!name) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"placements[%lu].name is missing or empty", (unsigned long)i]];
            return nil;
        }
        NSString *typeString = [self requiredString:@"type" from:dict error:outError];
        if (!typeString) {
            if (outError) *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"placements[%lu].type is missing or empty", (unsigned long)i]];
            return nil;
        }

        CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
        placement.id = placementId;
        placement.name = name;
        placement.type = [self parseAdTypeFromString:typeString];

        // Optional fields - only override defaults if present (matches Android optInt)
        if (dict[@"bidResponseTimeoutMs"]) {
            placement.bidResponseTimeoutMs = [dict[@"bidResponseTimeoutMs"] integerValue];
        }
        if (dict[@"adLoadTimeoutMs"]) {
            placement.adLoadTimeoutMs = [dict[@"adLoadTimeoutMs"] integerValue];
        }
        if (dict[@"bannerRefreshRateMs"]) {
            placement.bannerRefreshRateMs = [dict[@"bannerRefreshRateMs"] integerValue];
        }
        if (dict[@"hasCloseButton"]) {
            placement.hasCloseButton = [dict[@"hasCloseButton"] boolValue];
        }
        if (dict[@"rewardAmount"]) {
            placement.rewardAmount = [dict[@"rewardAmount"] integerValue];
        }
        if (dict[@"rewardCurrency"]) {
            placement.rewardCurrency = dict[@"rewardCurrency"];
        }
        if (dict[@"rewardCallbackUrl"]) {
            placement.rewardCallbackUrl = dict[@"rewardCallbackUrl"];
        }

        [placements addObject:placement];
    }
    return [placements copy];
}

- (SDKConfigAdType)parseAdTypeFromString:(NSString *)typeString {
    if ([typeString caseInsensitiveCompare:@"banner"] == NSOrderedSame) {
        return SDKConfigAdTypeBanner;
    } else if ([typeString caseInsensitiveCompare:@"mrec"] == NSOrderedSame) {
        return SDKConfigAdTypeMrec;
    } else if ([typeString caseInsensitiveCompare:@"interstitial"] == NSOrderedSame) {
        return SDKConfigAdTypeInterstitial;
    } else if ([typeString caseInsensitiveCompare:@"rewarded"] == NSOrderedSame) {
        return SDKConfigAdTypeRewarded;
    }
    return SDKConfigAdTypeUnknown;
}

#pragma mark - Parsing: GeoHeaders (matches Android toGeoHeaders)

- (NSArray<CLXSDKConfigGeoBid *> *)parseGeoHeadersFromArray:(NSArray *)array {
    NSMutableArray *headers = [NSMutableArray array];
    for (id item in array) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *dict = (NSDictionary *)item;

        NSString *source = dict[@"source"];
        NSString *target = dict[@"target"];

        // Filter out entries with empty source/target (matches Android behavior)
        if ([source isKindOfClass:[NSString class]] && source.length > 0 &&
            [target isKindOfClass:[NSString class]] && target.length > 0) {
            CLXSDKConfigGeoBid *header = [[CLXSDKConfigGeoBid alloc] init];
            header.source = source;
            header.target = target;
            [headers addObject:header];
        }
    }
    return [headers copy];
}

#pragma mark - Parsing: Endpoint URL (matches Android toEndpointUrl)

- (nullable CLXSDKConfigEndpointQuantumValue *)parseEndpointURLFromValue:(id)value
                                                                   field:(NSString *)field
                                                                   error:(NSError **)outError {
    if (!value) {
        if (outError) {
            *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                    description:[NSString stringWithFormat:@"Required field '%@' is missing", field]];
        }
        return nil;
    }

    CLXSDKConfigEndpointQuantumValue *endpoint = [[CLXSDKConfigEndpointQuantumValue alloc] init];

    if ([value isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)value;
        if (str.length == 0) {
            if (outError) {
                *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"Required field '%@' is empty", field]];
            }
            return nil;
        }
        endpoint.endpointString = str;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)value;
        NSString *defaultURL = dict[@"default"];
        if (!defaultURL || ![defaultURL isKindOfClass:[NSString class]] || defaultURL.length == 0) {
            if (outError) {
                *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                        description:[NSString stringWithFormat:@"Required field '%@.default' is missing or empty", field]];
            }
            return nil;
        }
        endpoint.endpointObject = [self parseEndpointObject:dict];
    } else {
        if (outError) {
            *outError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse
                                    description:[NSString stringWithFormat:@"Required field '%@' has invalid type", field]];
        }
        return nil;
    }

    return endpoint;
}

#pragma mark - Parsing: String Map (matches Android toStringMap)

- (NSDictionary<NSString *, NSString *> *)parseStringMapFromDictionary:(NSDictionary *)dict {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (NSString *key in dict) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) {
            map[key] = value;
        }
    }
    return [map copy];
}

#pragma mark - Parsing: Metrics Config (matches Android toMetricsConfig)

- (nullable CLXMetricsConfig *)parseMetricsConfigFromArray:(NSArray *)array {
    if (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0) {
        return nil;
    }
    NSDictionary *dict = array[0];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [CLXMetricsConfig fromDictionary:dict];
}

#pragma mark - Parsing: Device Config (matches Android toDeviceConfig)

- (CLXSDKConfigDeviceConfig *)parseDeviceConfigFromDictionary:(NSDictionary *)dict {
    CLXSDKConfigDeviceConfig *config = [[CLXSDKConfigDeviceConfig alloc] init];
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return config;  // Return default config
    }

    NSNumber *testValue = dict[@"test"];
    if (testValue && [testValue isKindOfClass:[NSNumber class]]) {
        config.test = [testValue integerValue];
    }

    NSNumber *debugValue = dict[@"debug"];
    if (debugValue && [debugValue isKindOfClass:[NSNumber class]]) {
        config.debug = [debugValue boolValue];
    }

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
