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

#pragma mark - CLXDispatchScheduler Implementation

@implementation CLXDispatchScheduler

+ (instancetype)sharedInstance {
    static CLXDispatchScheduler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CLXDispatchScheduler alloc] init];
    });
    return instance;
}

- (void)scheduleAfterDelay:(NSTimeInterval)delay
                   onQueue:(dispatch_queue_t)queue
                     block:(dispatch_block_t)block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), queue, block);
}

@end

#pragma mark - CLXSynchronousScheduler Implementation

@implementation CLXSynchronousScheduler

- (void)scheduleAfterDelay:(NSTimeInterval)delay
                   onQueue:(dispatch_queue_t)queue
                     block:(dispatch_block_t)block {
    // Execute immediately for fast, deterministic tests
    if (block) {
        block();
    }
}

@end

#pragma mark - CLXBaseNetworkService Implementation

@interface CLXBaseNetworkService ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXBaseNetworkService

/**
 * @brief Initializes the network service with base URL and session
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @return An initialized instance of BaseNetworkService
 * @note Uses CLXDispatchScheduler by default for production retry delays
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    return [self initWithBaseURL:baseURL urlSession:urlSession scheduler:[CLXDispatchScheduler sharedInstance]];
}

/**
 * @brief Initializes the network service with base URL, session, and custom scheduler
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @param scheduler The scheduler to use for retry delays (use CLXSynchronousScheduler for tests)
 * @return An initialized instance of BaseNetworkService
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL 
                     urlSession:(NSURLSession *)urlSession
                      scheduler:(id<CLXScheduler>)scheduler {
    self = [super init];
    if (self) {
        _baseURL = [baseURL copy];
        _urlSession = urlSession;
        _scheduler = scheduler;
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
 * @param timeout Request timeout in seconds (0 = use session default of 30s)
 * @param maxRetries Maximum number of retry attempts
 * @param delay Delay between retry attempts in seconds
 * @param completion Completion handler called with the response or error
 */
- (void)executeRequestWithEndpoint:(NSString *)endpoint
                    urlParameters:(nullable NSDictionary *)urlParameters
                     requestBody:(nullable NSData *)requestBody
                         headers:(nullable NSDictionary *)headers
                         timeout:(NSTimeInterval)timeout
                      maxRetries:(NSInteger)maxRetries
                          delay:(NSTimeInterval)delay
                     completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled))completion {
    [self executeRequestWithEndpoint:endpoint
                      urlParameters:urlParameters
                        requestBody:requestBody
                            headers:headers
                            timeout:timeout
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
 * @param timeout Request timeout in seconds (0 = use session default of 30s)
 * @param maxRetries Maximum number of retry attempts
 * @param delay Delay between retry attempts in seconds
 * @param currentAttempt Current attempt number (0 = initial request)
 * @param completion Completion handler called with the response or error
 */
- (void)executeRequestWithEndpoint:(NSString *)endpoint
                    urlParameters:(nullable NSDictionary *)urlParameters
                     requestBody:(nullable NSData *)requestBody
                         headers:(nullable NSDictionary *)headers
                         timeout:(NSTimeInterval)timeout
                      maxRetries:(NSInteger)maxRetries
                          delay:(NSTimeInterval)delay
                    currentAttempt:(NSInteger)currentAttempt
                     completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled))completion {
    
    [self.logger verbose:[NSString stringWithFormat:@"Request endpoint: %@, maxRetries: %ld", endpoint, (long)maxRetries]];
    
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
    
    [self.logger verbose:[NSString stringWithFormat:@"Final URL: %@", components.URL]];
    
    // Configure HTTP request with method, body, headers, and timeout
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:components.URL];
    request.HTTPMethod = requestBody ? @"POST" : @"GET";
    request.HTTPBody = requestBody;

    // Set per-request timeout if specified (0 = use session default of 30s)
    if (timeout > 0) {
        request.timeoutInterval = timeout;
    }

    NSMutableDictionary *requestHeaders = [[self headers] mutableCopy];
    [requestHeaders addEntriesFromDictionary:headers ?: @{}];
    request.allHTTPHeaderFields = requestHeaders;
    
    [self.logger verbose:[NSString stringWithFormat:@"HTTP %@ request prepared", request.HTTPMethod]];
    
    // Execute network request with completion handling
    [self.logger verbose:@"Starting network request"];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self.logger verbose:[NSString stringWithFormat:@"Request completed - hasData: %@, hasError: %@", data ? @"YES" : @"NO", error ? @"YES" : @"NO"]];
        
        // Initialize kill switch detection flag
        BOOL isKillSwitchEnabled = NO;
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Log response status for debugging
        if (httpResponse) {
            [self.logger verbose:[NSString stringWithFormat:@"HTTP response status: %ld", (long)httpResponse.statusCode]];
        } else {
            [self.logger verbose:@"No HTTP response (network/timeout error)"];
        }
        
        // Determine if request should be retried based on error type
        // Aligned with Android: retry on network errors (NOT timeouts), 5xx, 429, 408
        BOOL shouldRetry = NO;
        NSTimeInterval retryDelay = delay;

        // Check for retryable network errors (NOT timeouts - aligned with Android)
        BOOL isRetryableNetwork = (error != nil && [self isRetryableNetworkError:error]);
        if (isRetryableNetwork) {
            [self.logger error:[NSString stringWithFormat:@"Network error - Error: %@, Attempt: %ld/%ld", error.localizedDescription, (long)(currentAttempt + 1), (long)(maxRetries + 1)]];
            shouldRetry = YES;
            retryDelay = [self delayWithJitter:1.0]; // 1s base + jitter (aligned with Android)
        } else if (httpResponse && ((httpResponse.statusCode >= 500 && httpResponse.statusCode < 600) || httpResponse.statusCode == 429 || httpResponse.statusCode == 408)) {
            // Check for server errors (5xx), rate limiting (429), or request timeout (408) that warrant retry
            [self.logger error:[NSString stringWithFormat:@"Server error %ld - Attempt: %ld/%ld", (long)httpResponse.statusCode, (long)(currentAttempt + 1), (long)(maxRetries + 1)]];
            shouldRetry = YES;

            if (httpResponse.statusCode == 429) {
                // Parse Retry-After header for rate limiting - use server-specified delay without jitter
                NSString *retryAfterHeader = httpResponse.allHeaderFields[@"Retry-After"];
                NSTimeInterval parsedDelay = [self parseRetryAfterHeader:retryAfterHeader];
                retryDelay = parsedDelay > 0 ? parsedDelay : [self delayWithJitter:1.0];
            } else {
                retryDelay = [self delayWithJitter:1.0]; // 1s base + jitter (aligned with Android)
            }
        }
        
        // Execute retry if conditions are met and attempts remain
        if (shouldRetry && currentAttempt < maxRetries) {
            NSInteger nextAttempt = currentAttempt + 1;
            [self.logger verbose:[NSString stringWithFormat:@"Retrying request (attempt %ld) after %.1fs delay", (long)(nextAttempt + 1), retryDelay]];
            [self.scheduler scheduleAfterDelay:retryDelay
                                       onQueue:dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
                                         block:^{
                [self executeRequestWithEndpoint:endpoint
                                   urlParameters:urlParameters
                                     requestBody:requestBody
                                         headers:headers
                                         timeout:timeout
                                      maxRetries:maxRetries
                                           delay:delay
                                   currentAttempt:nextAttempt
                                      completion:completion];
            }];
            return;
        }
        
        // Log when max retries are exhausted
        if (shouldRetry) {
            [self.logger error:@"Max retries reached, calling completion with error"];
        }
        
        // Handle request errors by returning early
        if (error) {
            if (completion) {
                // Convert NSURLError to CLXError to match Android SDK behavior
                if ([error.domain isEqualToString:NSURLErrorDomain]) {
                    CLXErrorCode code = (error.code == NSURLErrorTimedOut)
                        ? CLXErrorCodeNetworkTimeout   // 201 - matches Android NETWORK_TIMEOUT
                        : CLXErrorCodeNetworkError;    // 200 - matches Android NETWORK_ERROR
                    CLXError *networkError = [CLXError errorWithCode:code underlyingError:error];
                    completion(nil, networkError, isKillSwitchEnabled);
                } else {
                    completion(nil, error, isKillSwitchEnabled);
                }
            }
            return;
        }
        
        // Log response data for debugging
        if (data) {
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self.logger verbose:[NSString stringWithFormat:@"Response body length: %lu", (unsigned long)responseBody.length]];
        } else {
            [self.logger verbose:@"No response data received"];
        }
    
        // Process successful HTTP responses (2xx status codes)
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            // KILL SWITCH DETECTION: Check for server-controlled disable commands in HTTP 204 responses
            // Server sends X-CloudX-Status header with "ADS_DISABLED" or "SDK_DISABLED" to remotely disable functionality
            BOOL isNoContentResponse = (httpResponse.statusCode == 204);
            NSString *cloudXStatus = [httpResponse.allHeaderFields objectForKey:@"X-CloudX-Status"];
            BOOL isKillSwitchActive = ([cloudXStatus isEqual:@"ADS_DISABLED"] || [cloudXStatus isEqual:@"SDK_DISABLED"]);
            isKillSwitchEnabled = isNoContentResponse && isKillSwitchActive;
            
            [self.logger verbose:[NSString stringWithFormat:@"HTTP status code: %lu", httpResponse.statusCode]];
            
            // Parse JSON response data if present and non-empty
            if (data && data.length > 0) {
                NSError *jsonError;
                id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (jsonError) {
                    [self.logger error:[NSString stringWithFormat:@"JSON parsing failed: %@", jsonError]];
                    if (completion) {
                        completion(nil, jsonError, isKillSwitchEnabled);
                    }
                } else {
                    [self.logger verbose:@"JSON parsing successful"];
                    if (completion) {
                        completion(jsonResponse, nil, isKillSwitchEnabled);
                    }
                }
            } else {
                // No data or empty data to parse, return success with nil response
                [self.logger verbose:@"No data or empty data to parse"];
                if (completion) {
                    completion(nil, nil, isKillSwitchEnabled);
                }
            }
        } else {
            // Handle HTTP error status codes (non-2xx)
            [self.logger verbose:[NSString stringWithFormat:@"HTTP error status code: %ld", (long)httpResponse.statusCode]];
            
            // Extract error response body for debugging and user-facing error messages
            NSString *errorResponseBody = nil;
            if (data && data.length > 0) {
                errorResponseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (errorResponseBody) {
                    [self.logger verbose:[NSString stringWithFormat:@"Error response body: %@", errorResponseBody]];
                } else {
                    [self.logger verbose:@"Error response body could not be decoded as UTF-8"];
                }
            } else {
                [self.logger verbose:@"No error response body available"];
            }
            
            if (completion) {
                // Pass server error message to CLXError for detailed error reporting in demo apps
                completion(nil, [CLXError errorWithHTTPStatusCode:httpResponse.statusCode serverMessage:errorResponseBody], false);
            }
        }
    }];
    
    // Start the network request
    [task resume];
}

#pragma mark - Private Helper Methods

/**
 * @brief Determines if an error is a retryable network error
 * @param error The NSError to check
 * @return YES if this is a retryable network error (NOT including timeouts - aligned with Android)
 */
- (BOOL)isRetryableNetworkError:(NSError *)error {
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        // Don't retry on timeout (aligned with Android which throws immediately)
        if (error.code == NSURLErrorTimedOut) {
            return NO;
        }
        return (error.code == NSURLErrorCannotFindHost ||
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorNetworkConnectionLost ||
                error.code == NSURLErrorNotConnectedToInternet);
    }
    return NO;
}

/**
 * @brief Adds random jitter to a base delay to prevent thundering herd
 * @param baseDelay The base delay in seconds
 * @return Delay with jitter added (baseDelay + random 0-1 second, aligned with Android)
 */
- (NSTimeInterval)delayWithJitter:(NSTimeInterval)baseDelay {
    // Add 0-1 second of random jitter (matches Android's default randomizationMs = 1000)
    NSTimeInterval jitter = (NSTimeInterval)arc4random_uniform(1000) / 1000.0;
    return baseDelay + jitter;
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
