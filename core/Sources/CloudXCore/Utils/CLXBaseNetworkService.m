/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BaseNetworkService.m
 * @brief Implementation of base network service functionality
 */

#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXBaseNetworkService ()
@property (nonatomic, assign) NSInteger currentRetryCount;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXBaseNetworkService

/**
 * @brief Initializes the network service with base URL and session
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @return An initialized instance of BaseNetworkService
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    self = [super init];
    if (self) {
        _baseURL = [baseURL copy];
        _urlSession = urlSession;
        _currentRetryCount = 0;
        _logger = [[CLXLogger alloc] initWithCategory:@"BaseNetworkService"];
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
 * @brief Executes a network request with the given parameters
 * @param endpoint The API endpoint to call
 * @param urlParameters Dictionary of URL parameters
 * @param requestBody The request body data
 * @param headers Dictionary of request headers
 * @param maxRetries Maximum number of retry attempts
 * @param delay Delay between retry attempts in seconds
 * @param completion Completion handler called with the response or error
 */
- (void)executeRequestWithEndpoint:(NSString *)endpoint
                    urlParameters:(nullable NSDictionary *)urlParameters
                     requestBody:(nullable NSData *)requestBody
                         headers:(nullable NSDictionary *)headers
                      maxRetries:(NSInteger)maxRetries
                          delay:(NSTimeInterval)delay
                     completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled))completion {
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BaseNetworkService] executeRequestWithEndpoint - Endpoint: %@, Retries: %ld", endpoint, (long)maxRetries]];
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:[self.baseURL stringByAppendingString:endpoint]];
    
    // Start with existing query items from the base URL
    NSMutableArray *queryItems = [NSMutableArray array];
    if (components.queryItems) {
        [queryItems addObjectsFromArray:components.queryItems];
    }
    
    // Add new URL parameters
    if (urlParameters) {
        [urlParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:[value description]]];
        }];
    }
    
    // Set the combined query items
    if (queryItems.count > 0) {
        components.queryItems = queryItems;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] Final URL: %@", components.URL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:components.URL];
    request.HTTPMethod = requestBody ? @"POST" : @"GET";
    request.HTTPBody = requestBody;
    
    NSMutableDictionary *requestHeaders = [[self headers] mutableCopy];
    [requestHeaders addEntriesFromDictionary:headers ?: @{}];
    request.allHTTPHeaderFields = requestHeaders;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] HTTP %@ request prepared", request.HTTPMethod]];
    
    [self.logger debug:@"🔧 [BaseNetworkService] Creating URLSessionDataTask..."];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self.logger debug:[NSString stringWithFormat:@"🔧 [BaseNetworkService] Request completed - Data: %@, Error: %@", data ? @"YES" : @"NO", error ? error.localizedDescription : @"None"]];
        
        BOOL isKillSwitchEnabled = NO;
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] Network request failed - Error: %@, Retry: %ld/%ld", error.localizedDescription, (long)self.currentRetryCount, (long)maxRetries]];
            
            if (self.currentRetryCount < maxRetries) {
                self.currentRetryCount++;
                [self.logger debug:[NSString stringWithFormat:@"🔄 [BaseNetworkService] Retrying request (attempt %ld)", (long)self.currentRetryCount]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self executeRequestWithEndpoint:endpoint
                                     urlParameters:urlParameters
                                      requestBody:requestBody
                                          headers:headers
                                       maxRetries:maxRetries
                                           delay:delay
                                      completion:completion];
                });
            } else {
                [self.logger error:@"❌ [BaseNetworkService] Max retries reached, calling completion with error"];
                self.currentRetryCount = 0;
                if (completion) {
                    completion(nil, error, isKillSwitchEnabled);
                }
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Log HTTP status code
        [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] HTTP response - Status: %ld", (long)httpResponse.statusCode]];
        
        // Log response body
        if (data) {
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] Response body length: %lu", (unsigned long)responseBody.length]];
        } else {
            [self.logger debug:@"📊 [BaseNetworkService] No response data received"];
        }
        
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            if (httpResponse.statusCode == 204) {
                if ([[httpResponse.allHeaderFields objectForKey:@"X-CloudX-Status"] isEqual:@"ADS_DISABLED"] || [[httpResponse.allHeaderFields objectForKey:@"X-CloudX-Status"] isEqual:@"SDK_DISABLED"]) {
                    isKillSwitchEnabled = YES;
                }
                
            }
            [self.logger info:@"✅ [BaseNetworkService] HTTP status code indicates success"];
            if (data) {
                NSError *jsonError;
                id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (jsonError) {
                    [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] JSON parsing failed: %@", jsonError]];
                    if (completion) {
                        completion(nil, jsonError, isKillSwitchEnabled);
                    }
                } else {
                    [self.logger info:@"✅ [BaseNetworkService] JSON parsing successful, calling completion with response"];
                    if (completion) {
                        completion(jsonResponse, nil, isKillSwitchEnabled);
                    }
                }
            } else {
                [self.logger debug:@"📊 [BaseNetworkService] No data to parse, calling completion with nil"];
                if (completion) {
                    completion(nil, nil, false);
                }
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] HTTP status code indicates error: %ld", (long)httpResponse.statusCode]];
            if (completion) {
                completion(nil, [CLXError errorWithCode:CLXErrorCodeLoadFailed], false);
            }
        }
    }];
    
    [self.logger debug:@"🔧 [BaseNetworkService] Starting URLSessionDataTask..."];
    [task resume];
    [self.logger info:@"✅ [BaseNetworkService] URLSessionDataTask started"];
}

@end 
