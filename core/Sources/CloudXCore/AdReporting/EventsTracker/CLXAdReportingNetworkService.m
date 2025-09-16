#import <CloudXCore/CLXAdReportingNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXEnvironmentConfig.h>

@interface CLXAdReportingNetworkService ()
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAdReportingNetworkService

- (instancetype)initWithBaseURL:(NSURL *)baseURL urlSession:(NSURLSession *)urlSession {
    self = [super init];
    if (self) {
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:baseURL.absoluteString urlSession:urlSession];
        _logger = [[CLXLogger alloc] initWithCategory:@"AdReporting"];
    }
    return self;
}

- (void)trackImpressionWithBidID:(NSString *)bidID error:(NSError **)error {
    // Temporarily disable impression tracking to prevent 404 errors and crashes
    [self.logger debug:[NSString stringWithFormat:@"🔧 [AdReporting] Impression tracking disabled for bidID: %@", bidID]];
    
    // TODO: Re-enable once server endpoint is properly configured
    /*
    NSDictionary *urlParameters = @{
        @"b": bidID,
        @"t": @"imp"
    };
    
    __block NSError * __autoreleasing *blockError = error;
    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:urlParameters
                                          requestBody:nil
                                              headers:nil
                                           maxRetries:3
                                               delay:1
                                          completion:^(id _Nullable response, NSError * _Nullable networkError) {
        if (networkError && blockError) {
            *blockError = networkError;
        }
    }];
    */
}

- (void)trackWinWithBidID:(NSString *)bidID error:(NSError **)error {
    // Temporarily disable win tracking to prevent 404 errors and crashes
    [self.logger debug:[NSString stringWithFormat:@"🔧 [AdReporting] Win tracking disabled for bidID: %@", bidID]];
    
    // TODO: Re-enable once server endpoint is properly configured
    /*
    NSDictionary *urlParameters = @{
        @"t": @"win",
        @"b": bidID
    };
    
    __block NSError * __autoreleasing *blockError = error;
    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:urlParameters
                                          requestBody:nil
                                              headers:nil
                                           maxRetries:3
                                               delay:1
                                          completion:^(id _Nullable response, NSError * _Nullable networkError) {
        if (networkError && blockError) {
            *blockError = networkError;
        }
    }];
    */
}


- (void)trackNUrlWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    // Network service for NURL tracking with completion callback for revenue reporting
    if (!nUrl || nUrl.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"CLXAdReportingNetworkService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"NURL is nil or empty"}]);
        }
        return;
    }
    
    NSURL *url = [NSURL URLWithString:nUrl];
    if (!url) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"CLXAdReportingNetworkService" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Invalid NURL format"}]);
        }
        return;
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable networkError) {
        BOOL success = NO;
        if (!networkError) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300);
            } else {
                success = YES; // Non-HTTP response, assume success
            }
        }
        
        if (completion) {
            completion(success, networkError);
        }
    }];
    [task resume];
}

- (void)trackLUrlWithLUrl:(nullable NSString *)lUrl {
    // Fire and forget implementation matching CloudX Android behavior
    if (lUrl && lUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:lUrl];
        if (url) {
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                // Fire and forget - ignore errors like CloudX Android implementation
            }];
            [task resume];
        }
    }
}

- (void)geoHeadersWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras
{
    // Convert params to query string
    NSURL *url = [NSURL URLWithString:fullURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"CloudX: geoHeaders error: %@", error]];
            //completion(nil, error);
        } else {
            [self.logger debug:[NSString stringWithFormat:@"CloudX: geoHeaders: %@", fullURL]];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            NSMutableDictionary *finalArray = [NSMutableDictionary dictionary];
            for (NSString *key in extras) {
                NSString *dictValue = extras[key];
                NSString *httpValue = [httpResponse valueForHTTPHeaderField:key];
                if (httpValue && dictValue) {
                    finalArray[httpValue] = dictValue;
                }
            }
            [self.logger debug:[NSString stringWithFormat:@"CloudX: geoHeaders response status code: %ld", (long)[httpResponse statusCode]]];
            [self.logger debug:[NSString stringWithFormat:@"CloudX: geoHeaders response: %@", finalArray]];
            //completion(finalArray, nil);
        }
    }];
    [task resume];
}

- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error {
    CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
    NSMutableString *urlString = [NSMutableString stringWithString:env.trackerBulkEndpointURL];
    NSURL *fullURL = [NSURL URLWithString:urlString];
    if (!fullURL) {
        [self.logger error:[NSString stringWithFormat:@"CloudX: can't parse metricsTracking to URL: %@", urlString]];
        [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];
    request.HTTPMethod = @"POST";
    
    NSDictionary *metricsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *encodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *items = [NSMutableArray array];
    
    NSString *accountId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
   
    NSData *secret = [CLXXorEncryption generateXorSecret: accountId];
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64: accountId];
    
    NSString *safeCampaignId = [campaignId urlQueryEncodedString];
    
    for (NSString *key in metricsDictionary.allKeys) {
        NSString *methodPayload = [encodedString stringByAppendingString:key];
        NSString *methodFinalPayload = [methodPayload stringByAppendingString:@";"];
        NSString *valuePayload = [methodFinalPayload stringByAppendingString:metricsDictionary[key]];
        NSString *finalPayload = [valuePayload stringByAppendingString:@";"];
        NSString *encrypted = [CLXXorEncryption encrypt: finalPayload secret: secret];
        
        NSString *safeEncrypted = [encrypted urlQueryEncodedString];
        NSDictionary *dict = @{
            @"eventName": key,
            @"campaignId": safeCampaignId,
            @"eventValue": metricsDictionary[key],
            @"type": key,
            @"impression": safeEncrypted
        };
        [items addObject: dict];
    }

    [self.logger debug:[NSString stringWithFormat:@"CloudX: METRICS data: %@", items]];
    
    // Prepare JSON data
    NSDictionary *bodyDict = @{@"items": items};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];
    
    __block NSError * __autoreleasing *blockError = error;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"CloudX: metricsTracking error: %@", error]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"CloudX: metricsTracking: %@", fullURL]];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            [self.logger debug:[NSString stringWithFormat:@"CloudX: Tracking response status code: %ld", (long)[httpResponse statusCode]]];
        }
        if (error && blockError) {
            *blockError = error;
        }
    }];
    [task resume];
}

- (void)rillTrackingWithActionString:(NSString *)actionString
                    campaignId:(NSString *)campaignId
                    encodedString:(NSString *)encodedString
                            error:(NSError **)error
{
    // Debug logging for Rill tracking parameters
    CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
    [self.logger debug:[NSString stringWithFormat:@"🔍 [RillTracking] Environment: %@, Action: %@, Campaign: %@, EncodedLength: %lu", env.environmentName, actionString ?: @"(nil)", campaignId ?: @"(nil)", (unsigned long)(encodedString.length)]];
    
    NSString *trackingString = env.trackerRillBaseURL;
    
    // Allow override via user defaults for testing
    if ([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey]) {
        trackingString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey];
    }
    NSMutableString *urlString = [NSMutableString stringWithString:trackingString];
    [urlString appendString:actionString];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self.logger error:[NSString stringWithFormat:@"CloudX: can't parse rillTracking to URL: %@", urlString]];
        [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        return;
    }
    
    NSString *eventName = [actionString stringByReplacingOccurrencesOfString:@"enc" withString:@""];
    
    //eventValue=N%2FA&eventName=event+1&debug=true
    
    NSDictionary *params = @{
        @"impression": encodedString,
        @"campaignId": campaignId,
        @"eventValue": @"N%2FA",
        @"eventName": eventName,
        @"debug": @"true"
    };
    
    // Convert params to query string
    NSMutableArray *queryItems = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [queryItems addObject:[NSString stringWithFormat:@"%@=%@", key, [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    }];
    NSString *queryString = [queryItems componentsJoinedByString:@"&"];
    NSString *fullURLString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
    NSURL *fullURL = [NSURL URLWithString:fullURLString];
    
    // Print the complete request JSON
    NSDictionary *requestJSON = @{
        @"method": @"GET",
        @"url": fullURLString,
        @"parameters": params
    };
    [self.logger debug:[NSString stringWithFormat:@"🔍 [RillTracking] Request JSON: %@", requestJSON]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];
    request.HTTPMethod = @"GET";
    
    __block NSError * __autoreleasing *blockError = error;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Print the complete response JSON
        NSMutableDictionary *responseJSON = [NSMutableDictionary dictionary];
        
        if (error) {
            responseJSON[@"error"] = error.localizedDescription;
            [self.logger error:[NSString stringWithFormat:@"🔍 [RillTracking] ERROR: %@", error]];
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            responseJSON[@"statusCode"] = @(httpResponse.statusCode);
            responseJSON[@"headers"] = httpResponse.allHeaderFields ?: @{};
            
            if (data && data.length > 0) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                responseJSON[@"body"] = responseString ?: @"(could not decode)";
            } else {
                responseJSON[@"body"] = @"(empty)";
            }
        }
        
        [self.logger debug:[NSString stringWithFormat:@"🔍 [RillTracking] Response JSON: %@", responseJSON]];
        
        if (error && blockError) {
            *blockError = error;
        }
    }];
    [task resume];
}

@end 
