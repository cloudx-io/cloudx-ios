#import <CloudXCore/CLXBidNetworkServiceImplementation.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXSKAdNetworkService.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/URLSession+CLX.h>
#import <UIKit/UIKit.h>

@interface CLXBidNetworkServiceImplementation () <CLXBidNetworkService>
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXGeoLocationService *locationService;
@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, copy) NSString *cdpEndpoint;
@property (nonatomic, copy) NSString *userAgent;
@end

@implementation CLXBidNetworkServiceImplementation

@synthesize isCDPEndpointEmpty = _isCDPEndpointEmpty;

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"BidNetworkService"];
        self.isCDPEndpointEmpty = YES;
        _userAgent = [self generateUserAgent];
    }
    return self;
}

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                           cdpEndpointUrl:(NSString *)cdpEndpointUrl {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"BidNetworkService"];
        _endpoint = [auctionEndpointUrl copy];
        _cdpEndpoint = [cdpEndpointUrl copy];
        self.isCDPEndpointEmpty = cdpEndpointUrl.length == 0;
        _userAgent = [self generateUserAgent];
        
        // Initialize base network service
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"auction"];
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:auctionEndpointUrl urlSession:urlSession];
        
        // Initialize location service
        _locationService = [[CLXGeoLocationService alloc] init];
        
        [_logger debug:[NSString stringWithFormat:@"Initialized BidNetworkService with auction endpoint: %@, CDP endpoint: %@", auctionEndpointUrl, cdpEndpointUrl]];
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
                           completion:(void (^)(id _Nullable bidRequest, NSError * _Nullable error))completion {
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Creating bid request - adUnit:%@, type:%ld", adUnitID, (long)adType]];
    
    [_logger debug:[NSString stringWithFormat:@"Creating bid request for ad unit: %@", adUnitID]];
    
    // Get screen dimensions
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    NSInteger screenWidth = (NSInteger)screenRect.size.width;
    NSInteger screenHeight = (NSInteger)screenRect.size.height;
    
    // Adjust dimensions based on ad type
    if (adType == 1) { // MREC
        screenWidth = 300;
        screenHeight = 250;
    } else if (adType == 0) { // Banner
        screenWidth = 320;
        screenHeight = 50;
    }
    // For interstitial (2), rewarded (3), native (4) - use full screen dimensions
    
    // Create device information (matching Swift implementation)
    NSMutableDictionary *device = [NSMutableDictionary dictionary];
    device[@"ua"] = @"ua";
    device[@"make"] = @"Apple";
    device[@"model"] = [CLXSystemInformation shared].model;
    device[@"os"] = @"ios";
    device[@"osv"] = [CLXSystemInformation shared].systemVersion;
    device[@"hwv"] = [CLXSystemInformation shared].hardwareVersion;
    device[@"language"] = [[NSLocale currentLocale] languageCode];
    device[@"ifa"] = [CLXSystemInformation shared].idfa ?: @"B8417CDB-9456-4266-8EA2-B10F88F0E7F4";
    device[@"dnt"] = @([CLXSystemInformation shared].dnt);
    device[@"devicetype"] = @([CLXSystemInformation shared].deviceType);
    device[@"h"] = @(screenHeight);
    device[@"w"] = @(screenWidth);
    device[@"ppi"] = @(489); // UIDevice.ppi equivalent
    device[@"connectiontype"] = @(0); // Default connection type
    device[@"pxratio"] = @(3.0); // Default pixel ratio
    
    // Add device geo information
    NSDictionary *geo = @{
        @"type": @(1),
        @"utcoffset": @(120) // Default timezone offset
    };
    device[@"geo"] = geo;
    
    // Add device ext with ifv
    NSDictionary *deviceExt = @{
        @"ifv": [CLXSystemInformation shared].idfv ?: @"00000-00000-00000-000000"
    };
    device[@"ext"] = deviceExt;
    
    // Create app information (matching Swift implementation)
    NSMutableDictionary *app = [NSMutableDictionary dictionary];
    app[@"id"] = @"5646234";
    app[@"bundle"] = [CLXSystemInformation shared].appBundleIdentifier;
    app[@"ver"] = [CLXSystemInformation shared].appVersion;
    
    if (impModel.appKeyValues) {
        NSDictionary *value = @{
        @"appKey1": @"appValue1",
        @"appKey2": @"appValue2",
        @"appKey3": @"appValue3"};

        NSArray *components = [impModel.appKeyValues componentsSeparatedByString:@"."];
        NSMutableArray *mutableComponents = [components mutableCopy];
        if (mutableComponents.count > 0) {
            [mutableComponents removeObjectAtIndex:0];
        }
        NSMutableDictionary *result = [NSMutableDictionary dictionary];

        // Build nested structure from bottom up
        NSMutableDictionary *current = result;
        for (NSInteger i = 0; i < mutableComponents.count - 1; i++) {
            NSString *key = mutableComponents[i];
            current[key] = [NSMutableDictionary dictionary];
            current = current[key];
        }

        // Set the final value
        current[mutableComponents.lastObject] = value;

        [self.logger debug:[NSString stringWithFormat:@"Result: %@", result]];
        
        [app addEntriesFromDictionary:result];
    }
    
    // Add publisher information
    NSString *parentAccount = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey] ?: @"";
    NSDictionary *publisher = @{
        @"id": publisherID ?: @"",
        @"ext": @{
            @"prebid": @{
                @"parentAccount": parentAccount
            }
        }
    };
    app[@"publisher"] = publisher;
    
    // Create impression array (matching Swift implementation)
    NSMutableDictionary *imp = [NSMutableDictionary dictionary];
    // Generate unique impression ID per request (OpenRTB compliance)
    imp[@"id"] = [[NSUUID UUID] UUIDString];
    imp[@"tagid"] = adUnitID;
    imp[@"bidfloor"] = @(bidFloor);
    imp[@"instl"] = @((adType == 2 || adType == 3) ? 1 : 0); // 1 for fullscreen ads
    imp[@"secure"] = @1; // Add secure field to match Swift SDK
    
    [self.logger debug:[NSString stringWithFormat:@"✅ [BidNetworkService] Impression created - id:%@, tagid:%@, instl:%@, bidFloor:%.2f", imp[@"id"], imp[@"tagid"], imp[@"instl"], bidFloor]];

    // Add banner format for non-native ads
    if (adType != 4) { // Not native
        NSArray *format = @[
            @{@"w": @(screenWidth), @"h": @(screenHeight)},
            @{@"w": @(screenWidth), @"h": @(screenHeight)}
        ];
        NSDictionary *banner = @{@"format": format};
        imp[@"banner"] = banner;
    }

    // Add video for interstitial/rewarded ads
    if (adType == 2 || adType == 3) { // Interstitial or Rewarded
        NSDictionary *video = @{
            @"w": @(screenWidth),
            @"h": @(screenHeight)
        };
        imp[@"video"] = video;
    }

    // Add native for native ads
    if (adType == 4 && nativeAdRequirements) { // Native
        imp[@"native"] = nativeAdRequirements;
    }
    
    // Add impression ext with prebid stored impression and bidder
    NSMutableDictionary *impExt = @{
        @"prebid": @{
            @"storedimpression": @{
                @"adservertargeting": @[],
                @"storedimpression": @{
                    @"id": storedImpressionId
                }
            },
            @"bidder": @{
                @"adservertargeting": @[]
            }
        }
    };
    
    // Add deal ID if provided
    if (dealID) {
        imp[@"dealid"] = dealID;
    }
    
    if (impModel.placementLoopIndex) {
        NSDictionary<NSString *, NSString *> *existingUserDict = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreUserKeyValueKey];
        NSMutableDictionary<NSString *, NSString *> *userDict = existingUserDict ? [existingUserDict mutableCopy] : [NSMutableDictionary dictionary];
        //NSString *value = [NSString stringWithFormat:@"%@", userDict[@"loop-index"]];
        
        NSArray *components = [impModel.appKeyValues componentsSeparatedByString:@"."];
        NSMutableArray *mutableComponents = [components mutableCopy];
        if (mutableComponents.count > 0) {
            [mutableComponents removeObjectAtIndex:0];
        }
        if (mutableComponents.count > 0) {
            [mutableComponents removeObjectAtIndex:0];
        }
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *current = result;
        for (NSInteger i = 0; i < mutableComponents.count - 1; i++) {
            NSString *key = mutableComponents[i];
            current[key] = [NSMutableDictionary dictionary];
            current = current[key];
        }

        // Set the final value
        current[mutableComponents.lastObject] = userDict[@"loop-index"];

        [self.logger debug:[NSString stringWithFormat:@"Result: %@", result]];
        
        [impExt addEntriesFromDictionary:result];
    }
    
    imp[@"ext"] = impExt;
    
    // Create user information
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    if ([CLXSystemInformation shared].idfa) {
        user[@"ifa"] = [CLXSystemInformation shared].idfa;
    }
    if ([CLXSystemInformation shared].idfv) {
        user[@"idfv"] = [CLXSystemInformation shared].idfv;
    }
    user[@"dnt"] = @([CLXSystemInformation shared].dnt);
    user[@"lat"] = @([CLXSystemInformation shared].lat);
    
    // Add buyeruid from adapter info - adapter-agnostic approach
    user[@"buyeruid"] = [CLXSystemInformation extractBuyeruidFromAdapterInfo:adapterInfo logger:self.logger];
    [self.logger info:[NSString stringWithFormat:@"📊 [BidNetworkService] Final user buyeruid: %@", user[@"buyeruid"]]];
    
    NSMutableDictionary *impUsr = @{
          @"data": @{
            @"userKey1": @"userValue1",
            @"userKey2": @"userValue2",
            @"userKey3": @"userValue3"
          },
          @"eids": @[
            @{
              @"source": @"io.cloudx.demo.demoapp",
              @"uids": @[
                @{
                  @"id": @"29060c8606954ec90fbcde825b2783b0b9261585793db9dfcbe6b870a05a9ee3",
                  @"atype": @3
                }
              ]
            }
          ]
    };
    
    user[@"ext"] = impUsr;
    
    if (2<1) {//(impModel.userKeyValues) {
        NSString *value = @"some_value";

        NSArray *components = [impModel.userKeyValues componentsSeparatedByString:@"."];
        NSMutableArray *mutableComponents = [components mutableCopy];
        if (mutableComponents.count > 0) {
            [mutableComponents removeObjectAtIndex:0];
        }
        NSMutableDictionary *result = [NSMutableDictionary dictionary];

        // Build nested structure from bottom up
        NSMutableDictionary *current = result;
        for (NSInteger i = 0; i < mutableComponents.count - 1; i++) {
            NSString *key = mutableComponents[i];
            current[key] = [NSMutableDictionary dictionary];
            current = current[key];
        }

        // Set the final value
        current[mutableComponents.lastObject] = value;

        [self.logger debug:[NSString stringWithFormat:@"Result: %@", result]];
        
        [user addEntriesFromDictionary:result];
    }
    
    // Create regulations information (matching Swift implementation)
    NSMutableDictionary *regs = [NSMutableDictionary dictionary];
    // Add basic regulations - these might be required by the server
    regs[@"coppa"] = @(0); // Default to not COPPA restricted
    
    // Create regulations ext with IAB information
    NSMutableDictionary *regsExt = [NSMutableDictionary dictionary];
    NSMutableDictionary *iab = [NSMutableDictionary dictionary];
    iab[@"gdpr_tcfv2_gdpr_applies"] = @(0); // Default to GDPR not applicable
    iab[@"gdpr_tcfv2_tc_string"] = @""; // Empty TC string
    iab[@"ccpa_us_privacy_string"] = @""; // Empty US privacy string
    regsExt[@"iab"] = iab;
    regsExt[@"gdpr_consent"] = @(0); // Default to no GDPR consent
    regsExt[@"ccpa_do_not_sell"] = @(0); // Default to no CCPA do not sell
    regs[@"ext"] = regsExt;
    
    // Create the bid request
    NSMutableDictionary *bidRequest = [NSMutableDictionary dictionary];
    bidRequest[@"id"] = [[NSUUID UUID] UUIDString];
    
    // Debug logging for imp object
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BidNetworkService] Adding impression to bid request (%lu fields)", (unsigned long)imp.count]];
    
    bidRequest[@"imp"] = @[imp];
    bidRequest[@"device"] = device;
    bidRequest[@"app"] = app;
    bidRequest[@"user"] = user;
    bidRequest[@"regs"] = regs;
    
    // Add tmax if provided
    if (tmax) {
        bidRequest[@"tmax"] = tmax;
    }
    
    // Add adapter info
    if (adapterInfo) {
        bidRequest[@"ext"] = @{@"adapter_extras": adapterInfo};
    }
    
    [self.logger debug:[NSString stringWithFormat:@"✅ [BidNetworkService] Bid request created - ID:%@, impressions:%lu", bidRequest[@"id"], (unsigned long)[bidRequest[@"imp"] count]]];
    
    [_logger debug:[NSString stringWithFormat:@"Created bid request: %@", bidRequest]];
    
    if (completion) {
        completion(bidRequest, nil);
    }
}

- (void)startAuctionWithBidRequest:(NSDictionary *)bidRequest
                            appKey:(NSString *)appKey
                        completion:(void (^)(CLXBidResponse * _Nullable response, NSError * _Nullable error))completion {
    [self.logger info:@"🚀 [BidNetworkService] startAuctionWithBidRequest called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] AppKey: %@", appKey]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Base URL: %@", self.baseNetworkService.baseURL]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] Endpoint: %@", [self.baseNetworkService.baseURL stringByAppendingString:self.endpoint]]];
    
    // Convert bidRequest to JSON data
    NSError *jsonError;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Failed to serialize bid request: %@", jsonError]];
        if (completion) {
            completion(nil, jsonError);
        }
        return;
    }
    
    // Set up headers with authorization
    NSDictionary *headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent": self.userAgent ?: @"",
        @"Authorization": [NSString stringWithFormat:@"Bearer %@", appKey]
    };
    
    // Use BaseNetworkService to execute the request
    [self.baseNetworkService executeRequestWithEndpoint:self.endpoint
                                         urlParameters:nil
                                          requestBody:requestBody
                                              headers:headers
                                           maxRetries:0
                                               delay:0
                                          completion:^(id _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Auction request failed: %@", error]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error domain: %@", error.domain]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error code: %ld", (long)error.code]];
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Error user info: %@", error.userInfo]];
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        [self.logger info:@"✅ [BidNetworkService] Auction response received successfully"];
        
        // Parse the response into BidResponse object
        if ([response isKindOfClass:[NSDictionary class]]) {
            [self.logger debug:@"🔧 [BidNetworkService] Creating BidResponse from dictionary..."];
            CLXBidResponse *bidResponse = [CLXBidResponse parseBidResponseFromDictionary:response];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidResponse created: %@", bidResponse]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidResponse ID: %@", bidResponse.id]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BidNetworkService] BidResponse seatbid count: %lu", (unsigned long)bidResponse.seatbid.count]];
            
            if (completion) {
                completion(bidResponse, nil);
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [BidNetworkService] Response is not a dictionary: %@", response]];
            NSError *parseError = [NSError errorWithDomain:@"BidNetworkService" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response format"}];
            if (completion) {
                completion(nil, parseError);
            }
        }
    }];
}

- (void)startCDPFlowWithBidRequest:(id)bidRequest
                       completion:(void (^)(id _Nullable enrichedBidRequest, NSError * _Nullable error))completion {
    
    if (self.isCDPEndpointEmpty) {
        [_logger debug:@"CDP endpoint is empty, skipping CDP flow"];
        if (completion) {
            completion(bidRequest, nil);
        }
        return;
    }
    
    [_logger debug:@"Starting CDP flow"];
    
    // Convert to JSON
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bidRequest options:0 error:&jsonError];
    if (jsonError) {
        [_logger error:[NSString stringWithFormat:@"Failed to serialize bid request for CDP: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(nil, jsonError);
        }
        return;
    }
    
    // Create URL request
    NSURL *url = [NSURL URLWithString:self.cdpEndpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    
    // Make the request
    NSURLSessionDataTask *task = [self.baseNetworkService.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"CDP request failed: %@", error.localizedDescription]];
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *httpError = [NSError errorWithDomain:@"BidNetworkService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: @"CDP HTTP request failed"}];
            [self.logger error:[NSString stringWithFormat:@"CDP request failed with status: %ld", (long)httpResponse.statusCode]];
            if (completion) {
                completion(nil, httpError);
            }
            return;
        }
        
        // Parse response
        NSError *parseError;
        NSDictionary *enrichedBidRequest = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError) {
            [self.logger error:[NSString stringWithFormat:@"Failed to parse CDP response: %@", parseError.localizedDescription]];
            if (completion) {
                completion(nil, parseError);
            }
            return;
        }
        
        [self.logger debug:@"CDP flow completed successfully"];
        
        if (completion) {
            completion(enrichedBidRequest, nil);
        }
    }];
    
    [task resume];
}

- (NSString *)generateUserAgent {
    // Implement the logic to generate a user agent string based on your requirements
    // This is a placeholder and should be replaced with the actual implementation
    return @"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1";
}

@end 
