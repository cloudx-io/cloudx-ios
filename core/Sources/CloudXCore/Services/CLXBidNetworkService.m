#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <WebKit/WebKit.h>

@interface CLXBidNetworkServiceClass ()
@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, copy) NSString *cdpEndpoint;
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, strong, nullable) CLXErrorReporter *errorReporter;
@end

@interface CLXBidNetworkServiceClass (ErrorReporting)
- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context;
@end

@implementation CLXBidNetworkServiceClass

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                           cdpEndpointUrl:(NSString *)cdpEndpointUrl {
    return [self initWithAuctionEndpointUrl:auctionEndpointUrl cdpEndpointUrl:cdpEndpointUrl errorReporter:nil];
}

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                           cdpEndpointUrl:(NSString *)cdpEndpointUrl
                            errorReporter:(nullable CLXErrorReporter *)errorReporter {
    self = [super init];
    if (self) {
        _endpoint = [auctionEndpointUrl copy];
        _cdpEndpoint = [cdpEndpointUrl copy];
        _isCDPEndpointEmpty = cdpEndpointUrl.length == 0;
        _logger = [[CLXLogger alloc] initWithCategory:@"BidNetworkService"];
        _errorReporter = errorReporter;
        
        // Initialize user agent like Swift SDK
        _userAgent = [self generateUserAgent];
        
        // Initialize base network service with auction endpoint
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"auction"];
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:auctionEndpointUrl urlSession:urlSession];
        
        [self.logger info:[NSString stringWithFormat:@"✅ [BidNetworkService] Initialized with auction endpoint: %@", _endpoint]];
    }
    return self;
}

- (void)createBidRequestWithAdUnitID:(NSString *)adUnitID
                   storedImpressionId:(NSString *)storedImpressionId
                               adType:(CLXAdType)adType
                               dealID:(nullable NSString *)dealID
                             bidFloor:(float)bidFloor
                          publisherID:(NSString *)publisherID
                               userID:(NSString *)userID
                          adapterInfo:(NSDictionary *)adapterInfo
                nativeAdRequirements:(nullable id)nativeAdRequirements
                                 tmax:(nullable NSNumber *)tmax
                            impModel:(nullable CLXConfigImpressionModel *)impModel
                           completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Creating bid request - AdUnit: %@, Type: %d", adUnitID, (int)adType]];
    
    CLXBiddingConfigRequest *bidRequest = [[CLXBiddingConfigRequest alloc] initWithAdType:adType
                                                                             adUnitID:adUnitID
                                                                   storedImpressionId:storedImpressionId
                                                                               dealID:dealID
                                                                             bidFloor:@(bidFloor)
                                                                      displayManager:[CLXSystemInformation shared].displayManager ?: @""
                                                                  displayManagerVer:[CLXSystemInformation shared].sdkVersion ?: @""
                                                                         publisherID:publisherID ?: @""
                                                                            location:nil
                                                                           userAgent:nil
                                                                         adapterInfo:adapterInfo
                                                               nativeAdRequirements:nativeAdRequirements
                                                               skadRequestParameters:nil
                                                                               tmax:tmax
                                                                           impModel:impModel
                                                                           settings:[CLXSettings sharedInstance]
                                                                     privacyService:[CLXPrivacyService sharedInstance]];
    if (completion) {
        completion([bidRequest json], nil);
    }
}

- (void)startAuctionWithBidRequest:(NSDictionary *)bidRequest
                            appKey:(NSString *)appKey
                        completion:(void (^)(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [BidNetworkService] startAuctionWithBidRequest called - AppKey: %@", appKey]];
    
    // Log the actual bid request JSON
    if (bidRequest) {
        @try {
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:NSJSONWritingPrettyPrinted error:&jsonError];
            if (jsonData && !jsonError) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidRequest JSON (%lu chars)", (unsigned long)jsonString.length]];
            }
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Exception in bid_request_json_logging: %@ - %@", 
                               exception.name ?: @"unknown", exception.reason ?: @"no reason"]];
            [self reportException:exception context:@{@"operation": @"bid_request_json_logging"}];
            // Continue execution - debug logging failure should not affect bid request
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Bid request: ID=%@, IMPs=%lu, URL=%@%@", 
                       bidRequest[@"id"], 
                       (unsigned long)[bidRequest[@"imp"] count],
                       self.baseNetworkService.baseURL,
                       self.endpoint]];
    
    // Check for missing required fields
    NSMutableArray *missing = [NSMutableArray array];
    if (!bidRequest[@"imp"]) [missing addObject:@"imp"];
    if (!bidRequest[@"app"]) [missing addObject:@"app"];
    if (!bidRequest[@"device"]) [missing addObject:@"device"];
    if (!bidRequest[@"regs"]) [missing addObject:@"regs"];
    if (missing.count > 0) {
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Missing required fields: %@", [missing componentsJoinedByString:@", "]]];
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    [headers setObject:[NSString stringWithFormat:@"Bearer %@", appKey] forKey:@"Authorization"];
    [headers setObject:self.userAgent ?: @"" forKey:@"User-Agent"];
    
    // Convert bidRequest dictionary to NSData
    // Validate bid request before JSON serialization
    if (!bidRequest) {
        NSError *invalidRequestError = [CLXError errorWithCode:CLXErrorCodeInvalidRequest description:@"Bid request cannot be nil"];
        [self.logger error:@"❌ [BidNetworkService] Bid request is nil"];
        if (completion) completion(nil, nil, invalidRequestError);
        return;
    }
    
    NSError *jsonError;
    NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON serialization failed - %@ (Domain: %@, Code: %ld)", jsonError.localizedDescription, jsonError.domain, (long)jsonError.code]];
        if (completion) completion(nil, nil, jsonError);
        return;
    }
    
    // Use empty endpoint string like Swift version to avoid double URL
    [self.logger debug:@"🔧 [BidNetworkService] Starting auction request with V1 retry policy (maxRetries:1, delay:1.0s)"];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Headers: %@", headers]];
    
    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:nil
                                          requestBody:requestBodyData
                                              headers:headers
                                           maxRetries:1
                                               delay:1.0
                                          completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        [self.logger debug:@"📥 [BidNetworkService] Network request completion called"];
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Network request failed - Domain: %@, Code: %ld, Error: %@", error.domain, (long)error.code, error.localizedDescription]];
            if (completion) completion(nil, nil, error);
            return;
        }
        
        if (!response) {
            NSError *noDataError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse description:@"No response data"];
            [self.logger error:@"❌ [BidNetworkService] No response data received"];
            if (completion) completion(nil, nil, noDataError);
            return;
        }
        
        if (isKillSwitchEnabled) {
            NSError *adsDisabledError = [CLXError errorWithCode:CLXErrorCodeAdsDisabled description:@"No response data"];
            [self.logger error:@"❌ [BidNetworkService] kill switch in on received"];
            if (completion) completion(nil, nil, adsDisabledError);
            return;
        }
        
        [self.logger info:@"✅ [BidNetworkService] Auction response received successfully"];
        [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Response type: %@", NSStringFromClass([response class])]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Response: %@", response]];
        // Parse response dictionary into BidResponse object
        CLXBidResponse *bidResponse = [CLXBidResponse parseBidResponseFromDictionary:response];
        
        // Pass both parsed object and raw JSON to completion handler
        if (completion) {
            completion(bidResponse, [response isKindOfClass:[NSDictionary class]] ? (NSDictionary *)response : nil, nil);
        }
    }];
}

- (void)startCDPFlowWithBidRequest:(id)bidRequest
                       completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Content-Type"] = @"application/json";
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        if (completion) {
            completion(nil, jsonError);
        }
        return;
    }
    
    [self.logger debug:@"🔧 [BidNetworkService] Starting CDP request with V1 retry policy (maxRetries:1, delay:1.0s)"];
    [self.baseNetworkService executeRequestWithEndpoint:self.cdpEndpoint
                                         urlParameters:nil
                                          requestBody:jsonData
                                              headers:headers
                                           maxRetries:1
                                               delay:1.0
                                          completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        if (completion) {
            completion(response, error);
        }
    }];
}

- (NSString *)generateUserAgent {
    // Check if we're on the main thread
    if ([NSThread isMainThread]) {
        // Use WKWebView to get the actual user agent like Swift SDK
        WKWebView *webView = [[WKWebView alloc] init];
        NSString *userAgent = [webView valueForKey:@"userAgent"];
        return userAgent ?: @"Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148";
    } else {
        // If not on main thread, use a fallback user agent
        // This prevents the Main Thread Checker warning
        return @"Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148";
    }
}

@end

#pragma mark - Error Reporting Helper

@implementation CLXBidNetworkServiceClass (ErrorReporting)

- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context {
    // Only report if error reporter was injected
    if (self.errorReporter) {
        [self.errorReporter reportException:exception context:context];
    }
}

@end 
