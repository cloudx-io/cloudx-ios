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
    // ==================================================================================
    // SIMULATOR-ONLY GEO FALLBACK
    // ==================================================================================
    // Purpose: Provide geo data when running on iOS Simulator for testing.
    //
    // Why: The CloudFront geo endpoint (geoip.cloudx.io) returns 403 Forbidden when
    //      accessed from iOS Simulator because CloudFront blocks simulator IPs.
    //      Without geo data, SDK cannot determine user country for ad targeting.
    //
    // Solution: Use device's actual locale/region settings to detect country.
    //           This matches the real location of the developer running the simulator.
    //
    // Safety: This code is ONLY compiled for simulator builds via TARGET_IPHONE_SIMULATOR.
    //         Real iOS devices will ALWAYS use actual CloudFront geo data from headers.
    //         This code is completely stripped from production builds at compile time.
    // ==================================================================================
    #if TARGET_IPHONE_SIMULATOR
    [self.logger debug:@"[Simulator] CloudFront blocks simulator IPs - using device locale for geo data"];
    
    // Get actual country from device's locale settings
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode]; // e.g., "CH", "US", "GB"
    
    // Convert ISO2 (CH) to ISO3 (CHE) format for CloudFront compatibility
    NSLocale *enUSLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSString *countryISO3 = [enUSLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
    
    // Map common ISO2 codes to ISO3 (fallback if displayName doesn't work)
    NSDictionary *iso2ToISO3 = @{
        @"US": @"USA", @"GB": @"GBR", @"DE": @"DEU", @"FR": @"FRA", @"IT": @"ITA",
        @"ES": @"ESP", @"CH": @"CHE", @"AT": @"AUT", @"BE": @"BEL", @"NL": @"NLD",
        @"SE": @"SWE", @"NO": @"NOR", @"DK": @"DNK", @"FI": @"FIN", @"PL": @"POL",
        @"PT": @"PRT", @"GR": @"GRC", @"IE": @"IRL", @"CZ": @"CZE", @"HU": @"HUN",
        @"RO": @"ROU", @"BG": @"BGR", @"HR": @"HRV", @"SK": @"SVK", @"SI": @"SVN",
        @"LT": @"LTU", @"LV": @"LVA", @"EE": @"EST", @"CY": @"CYP", @"MT": @"MLT",
        @"LU": @"LUX", @"IS": @"ISL", @"LI": @"LIE", @"MC": @"MCO", @"AD": @"AND",
        @"SM": @"SMR", @"VA": @"VAT", @"UA": @"UKR", @"BY": @"BLR", @"MD": @"MDA",
        @"RU": @"RUS", @"RS": @"SRB", @"ME": @"MNE", @"MK": @"MKD", @"BA": @"BIH",
        @"AL": @"ALB", @"XK": @"XKX"
    };
    
    NSString *finalCountryISO3 = iso2ToISO3[countryCode] ?: @"USA"; // Default to USA if unknown
    
    // Get region/state from locale (may be nil)
    NSString *regionCode = [[NSTimeZone localTimeZone] abbreviation] ?: @"";
    
    [self.logger debug:[NSString stringWithFormat:@"[Simulator] Detected country from device locale: %@ (%@)", countryCode, finalCountryISO3]];
    
    // Mock CloudFront headers using detected country
    NSDictionary *mockRawHeaders = @{
        @"cloudfront-viewer-country-iso3": finalCountryISO3,
        @"cloudfront-viewer-country-region": regionCode
    };
    
    // Mock processed geo data for bid requests (OpenRTB format)
    NSDictionary *mockProcessedData = @{
        @"region": regionCode
    };
    
    // Store mock data in UserDefaults (same as production flow)
    [[NSUserDefaults standardUserDefaults] setObject:mockRawHeaders forKey:kCLXCoreRawGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] setObject:mockProcessedData forKey:kCLXCoreProcessedGeoDataKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.logger debug:[NSString stringWithFormat:@"[Simulator] Geo data set from locale: %@ - Region: %@", finalCountryISO3, regionCode]];
    
    // Skip network call for simulator
    return;
    #endif
    // ==================================================================================
    // END SIMULATOR-ONLY CODE
    // ==================================================================================
    
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
            NSMutableDictionary *processedGeoData = [NSMutableDictionary dictionary];
            NSMutableDictionary *rawGeoHeaders = [NSMutableDictionary dictionary];
            
            // Store all raw CloudFront headers for privacy checks
            NSDictionary *allHeaders = [httpResponse allHeaderFields];
            for (NSString *headerKey in allHeaders) {
                if ([headerKey hasPrefix:@"cloudfront-"] || [headerKey hasPrefix:@"CloudFront-"]) {
                    NSString *lowerKey = [headerKey lowercaseString];
                    rawGeoHeaders[lowerKey] = allHeaders[headerKey];
                }
            }
            
            // Process geo headers mapping (source -> target) where:
            // source = CloudFront header name (e.g. "cloudfront-viewer-city")
            // target = OpenRTB field name (e.g. "city")
            for (NSString *sourceHeader in extras) {
                NSString *targetField = extras[sourceHeader];
                NSString *headerValue = [httpResponse valueForHTTPHeaderField:sourceHeader];
                if (headerValue && targetField) {
                    processedGeoData[targetField] = headerValue;
                }
            }
            
            // Fallback: Extract common CloudFront headers if not provided by server config
            // This ensures parity with Android which gets all fields
            if (!processedGeoData[@"region"]) {
                NSString *region = [httpResponse valueForHTTPHeaderField:@"cloudfront-viewer-country-region"];
                if (region) processedGeoData[@"region"] = region;
            }
            if (!processedGeoData[@"zip"]) {
                NSString *zip = [httpResponse valueForHTTPHeaderField:@"cloudfront-viewer-postal-code"];
                if (zip) processedGeoData[@"zip"] = zip;
            }
            if (!processedGeoData[@"metro"]) {
                NSString *metro = [httpResponse valueForHTTPHeaderField:@"cloudfront-viewer-metro-code"];
                if (metro) processedGeoData[@"metro"] = metro;
            }
            
            [self.logger debug:[NSString stringWithFormat:@"CloudX: geoHeaders response status code: %ld", (long)[httpResponse statusCode]]];
            [self.logger debug:[NSString stringWithFormat:@"CloudX: processed geo data (for bid request): %@", processedGeoData]];
            [self.logger debug:[NSString stringWithFormat:@"CloudX: raw geo headers (for privacy): %@", rawGeoHeaders]];
            
            // Store both processed data and raw headers
            [[NSUserDefaults standardUserDefaults] setObject:processedGeoData forKey:kCLXCoreProcessedGeoDataKey];
            [[NSUserDefaults standardUserDefaults] setObject:rawGeoHeaders forKey:kCLXCoreRawGeoHeadersKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
    [task resume];
}

- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error {
    // Use metrics URL from SDK response (stored in user defaults)
    NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey];
    if (!metricsURL) {
        [self.logger debug:@"No metrics URL available - SDK performance metrics tracking disabled"];
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
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
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
    NSString *trackingString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreImpressionTrackerUrlKey];
    
    if (!trackingString) {
        [self.logger warn:@"[CloudXCore] No tracking URL available - Rill analytics disabled"];
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
        [self.logger error:[NSString stringWithFormat:@"Invalid URL constructed: %@", urlString]];
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
