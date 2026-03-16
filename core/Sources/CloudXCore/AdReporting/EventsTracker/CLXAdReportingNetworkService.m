/*
 * CloudX Ad Reporting Network Service
 * 
 * This service manages multiple tracking systems:
 * 
 * 1. SDK PERFORMANCE METRICS:
 *    - impressionTrackerURL with /bulk suffix: Tracks SDK performance and session data
 *    - Method: CLXMetricsTrackerImpl (sends bulk metrics)
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
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXURLProvider.h>

@interface CLXAdReportingNetworkService ()
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

@implementation CLXAdReportingNetworkService



#pragma mark - Initialization

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     urlSession:(NSURLSession *)urlSession
                   userDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:baseURL.absoluteString urlSession:urlSession];
        _logger = [[CLXLogger alloc] initWithCategory:@"AdReporting"];
        _userDefaults = userDefaults;
    }
    return self;
}



// Legacy trackNUrlWithPrice and trackLUrlWithLUrl methods removed
// Use CLXWinLossNetworkService for server-side win/loss tracking instead



- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error {
    // Use metrics URL from SDK response (stored in user defaults)
    NSString *metricsURL = [self.userDefaults stringForKey:kCLXCoreMetricsUrlKey];
    if (!metricsURL) {
        [self.logger debug:@"No metrics URL available - SDK performance metrics tracking disabled"];
        // Don't treat this as an error since it's handled with fallback in CloudXCoreAPI
        return;
    }
    NSMutableString *urlString = [NSMutableString stringWithString:metricsURL];
    NSURL *fullURL = [NSURL URLWithString:urlString];
    if (!fullURL) {
        [self.logger error:[NSString stringWithFormat:@"CloudX: can't parse metricsTracking to URL: %@", urlString]];
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];
    request.HTTPMethod = @"POST";
    
    NSDictionary *metricsDictionary = [self.userDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *encodedString = [self.userDefaults stringForKey:kCLXCoreEncodedStringKey];
    
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *items = [NSMutableArray array];
    
    NSString *accountId = [self.userDefaults stringForKey:kCLXCoreAccountIDKey];
   
    NSData *secret = [CLXXorEncryption generateXorSecret: accountId];
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64: accountId];
    
    NSString *safeCampaignId = [campaignId clx_urlQueryEncodedString];
    
    for (NSString *key in metricsDictionary.allKeys) {
        NSString *methodPayload = [encodedString stringByAppendingString:key];
        NSString *methodFinalPayload = [methodPayload stringByAppendingString:@";"];
        NSString *valuePayload = [methodFinalPayload stringByAppendingString:metricsDictionary[key]];
        NSString *finalPayload = [valuePayload stringByAppendingString:@";"];
        NSString *encrypted = [CLXXorEncryption encrypt: finalPayload secret: secret];
        
        NSString *safeEncrypted = [encrypted clx_urlQueryEncodedString];
        NSDictionary *dict = @{
            @"eventName": key,
            @"campaignId": safeCampaignId,
            @"eventValue": metricsDictionary[key],
            @"type": key,
            @"impression": safeEncrypted
        };
        [items addObject: dict];
    }

    // Prepare JSON data
    NSDictionary *bodyDict = @{@"items": items};
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"JSON serialization failed: %@", jsonError]];
        return;
    }
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        if (networkError) {
            [self.logger error:[NSString stringWithFormat:@"CloudX: metricsTracking error: %@", networkError]];
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
    [self.logger debug:[NSString stringWithFormat:@"Environment: %@, Action: %@, Campaign: %@, EncodedLength: %lu", [CLXURLProvider environmentName], actionString ?: @"(nil)", campaignId ?: @"(nil)", (unsigned long)(encodedString.length)]];
    
    // Use impression tracker URL from SDK response for Rill tracking
    NSString *trackingString = [self.userDefaults stringForKey:kCLXCoreImpressionTrackerUrlKey];
    
    if (!trackingString) {
        [self.logger warn:@"[CloudXCore] No tracking URL available - Rill analytics disabled"];
        if (error) {
            *error = [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No Rill tracking URL configured"}];
        }
        return;
    }
    
    // Use NSURLComponents for proper URL construction
    // This handles cases where the base URL may already contain query parameters
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:trackingString];
    if (!urlComponents) {
        [self.logger error:[NSString stringWithFormat:@"Invalid tracking URL: %@", trackingString]];
        if (error) {
            *error = [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        }
        return;
    }
    
    // Append action to the path (ensure trailing slash first)
    NSString *path = urlComponents.path ?: @"";
    if (![path hasSuffix:@"/"]) {
        path = [path stringByAppendingString:@"/"];
    }
    urlComponents.path = [path stringByAppendingString:actionString];
    
    NSString *eventName = [actionString stringByReplacingOccurrencesOfString:@"enc" withString:@""];
    
    // Build query items, preserving any existing ones from the base URL
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems ?: @[]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"impression" value:encodedString]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"campaignId" value:campaignId]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"eventValue" value:@"N%2FA"]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"eventName" value:eventName]];
    urlComponents.queryItems = queryItems;
    
    NSURL *fullURL = urlComponents.URL;
    if (!fullURL) {
        [self.logger error:[NSString stringWithFormat:@"Failed to construct URL from components: %@", urlComponents]];
        if (error) {
            *error = [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];
    request.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        if (networkError) {
            [self.logger error:[NSString stringWithFormat:@"Ad reporting request failed: %@", networkError.localizedDescription]];
        }
    }];
    [task resume];
}

@end 
