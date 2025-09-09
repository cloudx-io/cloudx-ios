#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <WebKit/WebKit.h>

@interface CLXBidNetworkServiceClass ()
@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, copy) NSString *cdpEndpoint;
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy) NSString *userAgent;
@end

@implementation CLXBidNetworkServiceClass

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                           cdpEndpointUrl:(NSString *)cdpEndpointUrl {
    self = [super init];
    if (self) {
        _endpoint = [auctionEndpointUrl copy];
        _cdpEndpoint = [cdpEndpointUrl copy];
        _isCDPEndpointEmpty = cdpEndpointUrl.length == 0;
        _logger = [[CLXLogger alloc] initWithCategory:@"BidNetworkService"];
        
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
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Creating bid request for ad unit: %@", adUnitID]];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] AdType numeric: %d", (int)adType]];
    
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
                                                                           settings:[CLXSettings sharedInstance]];
    if (completion) {
        completion([bidRequest json], nil);
    }
}

- (void)startAuctionWithBidRequest:(NSDictionary *)bidRequest
                            appKey:(NSString *)appKey
                        completion:(void (^)(CLXBidResponse * _Nullable response, NSError * _Nullable error))completion {
    [self.logger info:@"🚀 [BidNetworkService] startAuctionWithBidRequest called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] AppKey: %@", appKey]];
    
    // Log the actual bid request JSON
    if (bidRequest) {
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:NSJSONWritingPrettyPrinted error:&jsonError];
        if (jsonData && !jsonError) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidRequest JSON:\n%@", jsonString]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidRequest: %@", bidRequest]];
        }
    } else {
        [self.logger debug:@"📊 [BidNetworkService] BidRequest: (null)"];
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
    NSError *jsonError;
    NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON serialization failed: %@", jsonError]];
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON error domain: %@", jsonError.domain]];
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON error code: %ld", (long)jsonError.code]];
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON error user info: %@", jsonError.userInfo]];
        if (completion) completion(nil, jsonError);
        return;
    }
    
    // Log request body details
    NSString *requestBodyString = [[NSString alloc] initWithData:requestBodyData encoding:NSUTF8StringEncoding];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Request body size: %lu bytes", (unsigned long)requestBodyData.length]];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Request body preview (first 500 chars): %@", [requestBodyString substringToIndex:MIN(500, requestBodyString.length)]]];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Full request body: %@", requestBodyString]];
    
    // Validate JSON structure
    id jsonObject = [NSJSONSerialization JSONObjectWithData:requestBodyData options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] JSON validation failed: %@", jsonError]];
        if (completion) completion(nil, jsonError);
        return;
    }
    [self.logger info:@"✅ [BidNetworkService] JSON validation successful"];
    
    // Use empty endpoint string like Swift version to avoid double URL
    [self.logger debug:@"🔧 [BidNetworkService] Starting network request..."];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Headers: %@", headers]];
    
    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:nil
                                          requestBody:requestBodyData
                                              headers:headers
                                           maxRetries:0
                                               delay:0
                                          completion:^(id _Nullable response, NSError * _Nullable error) {
        [self.logger debug:@"📥 [BidNetworkService] Network request completion called"];
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Network request failed with error: %@", error]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error domain: %@", error.domain]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error code: %ld", (long)error.code]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error user info: %@", error.userInfo]];
            if (completion) completion(nil, error);
            return;
        }
        
        if (!response) {
            NSError *noDataError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse description:@"No response data"];
            [self.logger error:@"❌ [BidNetworkService] No response data received"];
            if (completion) completion(nil, noDataError);
            return;
        }
        
        [self.logger info:@"✅ [BidNetworkService] Auction response received successfully"];
        [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Response type: %@", NSStringFromClass([response class])]];
        [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Response: %@", response]];
        // Parse response dictionary into BidResponse object
        CLXBidResponse *bidResponse = [CLXBidResponse parseBidResponseFromDictionary:response];
        if (completion) completion(bidResponse, nil);
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
    
    [self.baseNetworkService executeRequestWithEndpoint:self.cdpEndpoint
                                         urlParameters:nil
                                          requestBody:jsonData
                                              headers:headers
                                           maxRetries:0
                                               delay:0
                                          completion:^(id _Nullable response, NSError * _Nullable error) {
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
