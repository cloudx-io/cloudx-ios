/*
 * CloudX Ad Reporting Network Service
 * 
 * This service manages multiple tracking systems:
 * 
 * 1. SDK PERFORMANCE METRICS:
 *    - metricsEndpointURL: Tracks SDK performance and session data
 *    - Method: metricsTrackingWithActionString
 *    - Status: Active, separate from Rill analytics
 *    - Data: Encrypted SDK metrics, session info
 *
 * 2. RILL ANALYTICS (CURRENT):
 *    - impressionTrackerURL: Modern analytics system
 *    - Method: rillTrackingWithActionString
 *    - Status: Active, primary tracking system
 *    - Data: Ad events, impressions, clicks, SDK initialization
 *
 * 3. WIN/LOSS TRACKING:
 *    - Server-side win/loss notifications via CLXWinLossTracker
 *    - Replaces legacy client-side NURL/LURL firing
 *    - Status: Use CLXWinLossNetworkService for structured payloads
 */

#import <CloudXCore/CLXAdReportingNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXURLProvider.h>

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



// Legacy trackNUrlWithPrice and trackLUrlWithLUrl methods removed
// Use CLXWinLossNetworkService for server-side win/loss tracking instead

- (void)geoHeadersWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras
{
    // Track geo API network call latency
    NSDate *geoRequestStartTime = [NSDate date];
    
    // Convert params to query string
    NSURL *url = [NSURL URLWithString:fullURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Track geo API network call latency
        NSTimeInterval geoRequestLatency = [[NSDate date] timeIntervalSinceDate:geoRequestStartTime] * 1000; // Convert to milliseconds
        id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
        [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkGeoApi latency:(NSInteger)geoRequestLatency];
        
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
    // Use metrics URL from SDK response (stored in user defaults)
    NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey];
    if (!metricsURL) {
        [self.logger debug:@"🔧 [CloudXCore] No metrics URL available - SDK performance metrics tracking disabled"];
        // Don't treat this as an error since it's handled with fallback in CloudXCoreAPI
        return;
    }
    NSMutableString *urlString = [NSMutableString stringWithString:metricsURL];
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
    [self.logger debug:[NSString stringWithFormat:@"🔍 [RillTracking] Environment: %@, Action: %@, Campaign: %@, EncodedLength: %lu", [CLXURLProvider environmentName], actionString ?: @"(nil)", campaignId ?: @"(nil)", (unsigned long)(encodedString.length)]];
    
    // Use impression tracker URL from SDK response for Rill tracking
    NSString *trackingString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreImpressionTrackerUrlKey];
    
    if (!trackingString) {
        [self.logger error:@"⚠️ [CloudXCore] No tracking URL available - Rill analytics disabled"];
        if (error) {
            *error = [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No Rill tracking URL configured"}];
        }
        return;
    }
    NSMutableString *urlString = [NSMutableString stringWithString:trackingString];
    // Ensure trailing slash for proper path construction (server gives us "/t" but we need "/t/")
    if (![urlString hasSuffix:@"/"]) {
        [urlString appendString:@"/"];
    }
    [urlString appendString:actionString];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self.logger error:[NSString stringWithFormat:@"❌ [RillTracking] Invalid URL constructed: %@", urlString]];
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
