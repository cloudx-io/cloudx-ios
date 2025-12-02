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
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>

@interface CLXBidNetworkServiceClass ()
@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, strong, nullable) CLXErrorReporter *errorReporter;
@end

@interface CLXBidNetworkServiceClass (ErrorReporting)
- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context;
@end

@implementation CLXBidNetworkServiceClass

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl {
    return [self initWithAuctionEndpointUrl:auctionEndpointUrl errorReporter:nil];
}

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                            errorReporter:(nullable CLXErrorReporter *)errorReporter {
    // Use default URLSession
    NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"auction"];
    return [self initWithAuctionEndpointUrl:auctionEndpointUrl 
                             errorReporter:errorReporter 
                                urlSession:urlSession];
}

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                            errorReporter:(nullable CLXErrorReporter *)errorReporter
                               urlSession:(NSURLSession *)urlSession {
    self = [super init];
    if (self) {
        _endpoint = [auctionEndpointUrl copy];
        _logger = [[CLXLogger alloc] initWithCategory:@"BidNetworkService"];
        _errorReporter = errorReporter;
        
        // Initialize user agent like Swift SDK
        _userAgent = [self generateUserAgent];
        
        // Initialize base network service with provided URLSession
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:auctionEndpointUrl urlSession:urlSession];
        
        [self.logger info:[NSString stringWithFormat:@"Initialized with auction endpoint: %@", _endpoint]];
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
                       correlationId:(NSString *)correlationId
                          completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Creating bid request - AdUnit: %@, Type: %d", correlationId, adUnitID, (int)adType]];
    
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
                      correlationId:(NSString *)correlationId
                        completion:(void (^)(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error))completion {
    [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Starting auction request - AppKey: %@", correlationId, appKey]];
    
    // Log the actual bid request JSON
    if (bidRequest) {
        @try {
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:NSJSONWritingPrettyPrinted error:&jsonError];
            if (jsonData && !jsonError) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] BidRequest JSON (%lu chars)", correlationId, (unsigned long)jsonString.length]];
            }
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] Exception in bid_request_json_logging: %@ - %@", 
                               correlationId, exception.name ?: @"unknown", exception.reason ?: @"no reason"]];
            [self reportException:exception context:@{@"operation": @"bid_request_json_logging", @"correlationId": correlationId}];
            // Continue execution - debug logging failure should not affect bid request
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Bid request: ID=%@, IMPs=%lu", 
                       correlationId,
                       bidRequest[@"id"], 
                       (unsigned long)[bidRequest[@"imp"] count]]];
    
    // Check for missing required fields
    NSMutableArray *missing = [NSMutableArray array];
    if (!bidRequest[@"imp"]) [missing addObject:@"imp"];
    if (!bidRequest[@"app"]) [missing addObject:@"app"];
    if (!bidRequest[@"device"]) [missing addObject:@"device"];
    if (!bidRequest[@"regs"]) [missing addObject:@"regs"];
    if (missing.count > 0) {
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] Missing required fields: %@", correlationId, [missing componentsJoinedByString:@", "]]];
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    // Use appKey (init value) as bearer token
    [headers setObject:[NSString stringWithFormat:@"Bearer %@", appKey] forKey:@"Authorization"];
    [headers setObject:self.userAgent ?: @"" forKey:@"User-Agent"];
    // Add correlation ID for end-to-end request tracing
    [headers setObject:correlationId forKey:@"X-CloudX-Correlation-ID"];
    
    // Convert bidRequest dictionary to NSData
    // Validate bid request before JSON serialization
    if (!bidRequest) {
        NSError *invalidRequestError = [CLXError errorWithCode:CLXErrorCodeInvalidRequest 
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"Bid request cannot be nil",
                                                           @"CLXCorrelationID": correlationId
                                                       }];
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] Bid request is nil", correlationId]];
        if (completion) completion(nil, nil, invalidRequestError);
        return;
    }
    
    NSError *jsonError;
    NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] JSON serialization failed - %@ (Domain: %@, Code: %ld)", correlationId, jsonError.localizedDescription, jsonError.domain, (long)jsonError.code]];
        // Add correlation ID to error
        NSMutableDictionary *errorUserInfo = [jsonError.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
        errorUserInfo[@"CLXCorrelationID"] = correlationId;
        NSError *enrichedError = [NSError errorWithDomain:jsonError.domain code:jsonError.code userInfo:errorUserInfo];
        if (completion) completion(nil, nil, enrichedError);
        return;
    }
    
    // Use empty endpoint string like Swift version to avoid double URL
    [self.logger debug:[NSString stringWithFormat:@"[%@] Starting auction request with V1 retry policy (maxRetries:1, delay:1.0s)", correlationId]];
    [self.logger verbose:[NSString stringWithFormat:@"[%@] Headers: %@", correlationId, headers]];
    
    // Track bid request network call latency
    NSDate *bidRequestStartTime = [NSDate date];
    
    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:nil
                                          requestBody:requestBodyData
                                              headers:headers
                                           maxRetries:1
                                               delay:1.0
                                          completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        // Track bid request latency
        NSTimeInterval bidRequestLatency = [[NSDate date] timeIntervalSinceDate:bidRequestStartTime] * 1000; // Convert to milliseconds
        id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:(NSInteger)bidRequestLatency];
        
        [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Network request completion called (%.0fms)", correlationId, bidRequestLatency]];
        
        if (error) {
            // Error already logged by BaseNetworkService - add correlation ID and propagate
            NSMutableDictionary *errorUserInfo = [error.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
            errorUserInfo[@"CLXCorrelationID"] = correlationId;
            NSError *enrichedError = [NSError errorWithDomain:error.domain code:error.code userInfo:errorUserInfo];
            if (completion) completion(nil, nil, enrichedError);
            return;
        }
        
        // Check kill switch BEFORE checking response data (kill switch responses have no data)
        if (isKillSwitchEnabled) {
            NSError *adsDisabledError = [CLXError errorWithCode:CLXErrorCodeAdsDisabled
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"Ads disabled by kill switch",
                                                           @"CLXCorrelationID": correlationId
                                                       }];
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] Ads disabled by kill switch", correlationId]];
            if (completion) completion(nil, nil, adsDisabledError);
            return;
        }
        
        if (!response) {
            NSError *noDataError = [CLXError errorWithCode:CLXErrorCodeInvalidResponse 
                                                   userInfo:@{
                                                       NSLocalizedDescriptionKey: @"No response data",
                                                       @"CLXCorrelationID": correlationId
                                                   }];
            [self.logger error:[NSString stringWithFormat:@"[%@] ❌ [BidNetworkService] No response data received", correlationId]];
            if (completion) completion(nil, nil, noDataError);
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Auction response received successfully", correlationId]];
        
        // Parse response dictionary into BidResponse object
        CLXBidResponse *bidResponse = [CLXBidResponse parseBidResponseFromDictionary:response];
        
        // Log useful summary instead of massive raw response
        if (bidResponse) {
            NSString *currency = bidResponse.cur ?: @"USD";
            NSInteger seatbidCount = bidResponse.seatbid ? bidResponse.seatbid.count : 0;
            NSString *bidId = bidResponse.bidid ?: @"unknown";
            [self.logger debug:[NSString stringWithFormat:@"[%@] [BidNetworkService] Parsed response - BidID: %@, Currency: %@, SeatBids: %ld", correlationId, bidId, currency, (long)seatbidCount]];
        }
        
        // Pass both parsed object and raw JSON to completion handler
        if (completion) {
            completion(bidResponse, [response isKindOfClass:[NSDictionary class]] ? (NSDictionary *)response : nil, nil);
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
