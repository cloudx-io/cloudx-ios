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
    [self executeRequestWithEndpoint:endpoint
                      urlParameters:urlParameters
                        requestBody:requestBody
                            headers:headers
                         maxRetries:maxRetries
                             delay:delay
                      currentAttempt:0
                         completion:completion];
}

/**
 * @brief Executes HTTP request with retry logic and kill switch detection
 * 
 * This method handles the complete request lifecycle:
 * 1. URL construction with parameters
 * 2. HTTP request execution 
 * 3. Retry logic for network/server errors
 * 4. Kill switch detection via X-CloudX-Status header
 * 5. Response parsing and error handling
 * 
 * @param endpoint The API endpoint to call
 * @param urlParameters Dictionary of URL parameters
 * @param requestBody The request body data
 * @param headers Dictionary of request headers
 * @param maxRetries Maximum number of retry attempts
 * @param delay Delay between retry attempts in seconds
 * @param currentAttempt Current attempt number (0 = initial request)
 * @param completion Completion handler called with the response or error
 */
- (void)executeRequestWithEndpoint:(NSString *)endpoint
                    urlParameters:(nullable NSDictionary *)urlParameters
                     requestBody:(nullable NSData *)requestBody
                         headers:(nullable NSDictionary *)headers
                      maxRetries:(NSInteger)maxRetries
                          delay:(NSTimeInterval)delay
                    currentAttempt:(NSInteger)currentAttempt
                     completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled))completion {
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [BaseNetworkService] executeRequestWithEndpoint - Endpoint: %@, Retries: %ld", endpoint, (long)maxRetries]];
    
    // Build complete URL with query parameters
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:[self.baseURL stringByAppendingString:endpoint]];
    
    // Preserve existing query items from base URL
    NSMutableArray *queryItems = [NSMutableArray array];
    if (components.queryItems) {
        [queryItems addObjectsFromArray:components.queryItems];
    }
    
    // Append new URL parameters
    if (urlParameters) {
        [urlParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:[value description]]];
        }];
    }
    
    // Apply all query parameters to URL
    if (queryItems.count > 0) {
        components.queryItems = queryItems;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] Final URL: %@", components.URL]];
    
    // Configure HTTP request with method, body, and headers
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:components.URL];
    request.HTTPMethod = requestBody ? @"POST" : @"GET";
    request.HTTPBody = requestBody;
    
    NSMutableDictionary *requestHeaders = [[self headers] mutableCopy];
    [requestHeaders addEntriesFromDictionary:headers ?: @{}];
    request.allHTTPHeaderFields = requestHeaders;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] HTTP %@ request prepared", request.HTTPMethod]];
    
    // Execute network request with completion handling
    [self.logger debug:@"🔧 [BaseNetworkService] Creating URLSessionDataTask..."];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self.logger debug:[NSString stringWithFormat:@"🔧 [BaseNetworkService] Request completed - Data: %@, Error: %@", data ? @"YES" : @"NO", error ? error.localizedDescription : @"None"]];
        
        // Initialize kill switch detection flag
        BOOL isKillSwitchEnabled = NO;
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Log response status for debugging
        if (httpResponse) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] HTTP response - Status: %ld", (long)httpResponse.statusCode]];
        } else {
            [self.logger debug:@"📊 [BaseNetworkService] No HTTP response (network/timeout error)"];
        }
        
        // Determine if request should be retried based on error type
        BOOL shouldRetry = NO;
        NSTimeInterval retryDelay = delay;
        
        // Check for network/timeout errors that warrant retry
        BOOL isNetworkOrTimeoutError = (error != nil && (!httpResponse || [self isNetworkTimeoutError:error]));
        if (isNetworkOrTimeoutError) {
            [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] Network/timeout error - Error: %@, Attempt: %ld/%ld", error.localizedDescription, (long)(currentAttempt + 1), (long)(maxRetries + 1)]];
            shouldRetry = YES;
            retryDelay = 1.0; // V1 spec: 1-second delay for network errors
        } else if (httpResponse && ((httpResponse.statusCode >= 500 && httpResponse.statusCode < 600) || httpResponse.statusCode == 429)) {
            // Check for server errors (5xx) or rate limiting (429) that warrant retry
            [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] Server error %ld - Attempt: %ld/%ld", (long)httpResponse.statusCode, (long)(currentAttempt + 1), (long)(maxRetries + 1)]];
            shouldRetry = YES;
            
            if (httpResponse.statusCode == 429) {
                // Parse Retry-After header for rate limiting
                NSString *retryAfterHeader = httpResponse.allHeaderFields[@"Retry-After"];
                NSTimeInterval parsedDelay = [self parseRetryAfterHeader:retryAfterHeader];
                retryDelay = parsedDelay > 0 ? parsedDelay : 1.0; // V1 spec: default 1s if missing
            } else {
                retryDelay = 1.0; // V1 spec: 1-second delay for 5xx errors
            }
        }
        
        // Execute retry if conditions are met and attempts remain
        if (shouldRetry && currentAttempt < maxRetries) {
            NSInteger nextAttempt = currentAttempt + 1;
            [self.logger debug:[NSString stringWithFormat:@"🔄 [BaseNetworkService] Retrying request (attempt %ld) after %.1fs delay", (long)(nextAttempt + 1), retryDelay]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDelay * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                [self executeRequestWithEndpoint:endpoint
                                   urlParameters:urlParameters
                                     requestBody:requestBody
                                         headers:headers
                                      maxRetries:maxRetries
                                           delay:delay
                                   currentAttempt:nextAttempt
                                      completion:completion];
            });
            return;
        }
        
        // Log when max retries are exhausted
        if (shouldRetry) {
            [self.logger error:@"❌ [BaseNetworkService] Max retries reached, calling completion with error"];
        }
        
        // Handle request errors by returning early
        if (error) {
            if (completion) {
                completion(nil, error, isKillSwitchEnabled);
            }
            return;
        }
        
        // Log response data for debugging
        if (data) {
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self.logger debug:[NSString stringWithFormat:@"📊 [BaseNetworkService] Response body length: %lu", (unsigned long)responseBody.length]];
        } else {
            [self.logger debug:@"📊 [BaseNetworkService] No response data received"];
        }
    
        // Process successful HTTP responses (2xx status codes)
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            // KILL SWITCH DETECTION: Check for server-controlled disable commands in HTTP 204 responses
            // Server sends X-CloudX-Status header with "ADS_DISABLED" or "SDK_DISABLED" to remotely disable functionality
            BOOL isNoContentResponse = (httpResponse.statusCode == 204);
            NSString *cloudXStatus = [httpResponse.allHeaderFields objectForKey:@"X-CloudX-Status"];
            BOOL isKillSwitchActive = ([cloudXStatus isEqual:@"ADS_DISABLED"] || [cloudXStatus isEqual:@"SDK_DISABLED"]);
            isKillSwitchEnabled = isNoContentResponse && isKillSwitchActive;
            
            [self.logger info:@"✅ [BaseNetworkService] HTTP status code indicates success"];
            // Parse JSON response data if present and non-empty
            if (data && data.length > 0) {
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
                // No data or empty data to parse, return success with nil response
                [self.logger debug:@"📊 [BaseNetworkService] No data or empty data to parse, calling completion with nil"];
                if (completion) {
                    completion(nil, nil, isKillSwitchEnabled);
                }
            }
        } else {
            // Handle HTTP error status codes (non-2xx)
            [self.logger error:[NSString stringWithFormat:@"❌ [BaseNetworkService] HTTP status code indicates error: %ld", (long)httpResponse.statusCode]];
            if (completion) {
                completion(nil, [CLXError errorWithCode:CLXErrorCodeLoadFailed], false);
            }
        }
    }];
    
    // Start the network request
    [self.logger debug:@"🔧 [BaseNetworkService] Starting URLSessionDataTask..."];
    [task resume];
    [self.logger info:@"✅ [BaseNetworkService] URLSessionDataTask started"];
}

#pragma mark - Private Helper Methods

/**
 * @brief Determines if an error is a network/timeout error that should be retried
 * @param error The NSError to check
 * @return YES if this is a retryable network/timeout error
 */
- (BOOL)isNetworkTimeoutError:(NSError *)error {
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        return (error.code == NSURLErrorTimedOut ||
                error.code == NSURLErrorCannotFindHost ||
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorNetworkConnectionLost ||
                error.code == NSURLErrorNotConnectedToInternet);
    }
    return NO;
}

/**
 * @brief Parses Retry-After header supporting both seconds and HTTP-date formats
 * @param retryAfterHeader The Retry-After header value
 * @return Parsed delay in seconds, or 0 if invalid/missing
 */
- (NSTimeInterval)parseRetryAfterHeader:(NSString *)retryAfterHeader {
    if (!retryAfterHeader || retryAfterHeader.length == 0) {
        return 0;
    }
    
    // Try parsing as integer seconds first
    NSInteger seconds = [retryAfterHeader integerValue];
    if (seconds > 0) {
        // Clamp to reasonable bounds (V1 spec safety)
        return MIN(seconds, 60); // Max 60 seconds to avoid long UI blocks
    }
    
    // Try parsing as HTTP-date (RFC 7231)
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
    
    NSDate *retryDate = [formatter dateFromString:retryAfterHeader];
    if (retryDate) {
        NSTimeInterval delay = [retryDate timeIntervalSinceNow];
        // Clamp to reasonable bounds and ensure positive
        return MAX(0, MIN(delay, 60));
    }
    
    return 0; // Invalid format
}

@end 
