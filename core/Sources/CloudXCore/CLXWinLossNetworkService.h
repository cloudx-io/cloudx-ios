/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossNetworkService.h
 * @brief Win/Loss network service matching Android WinLossTrackerApiImpl
 * 
 * Handles server communication for win/loss notifications via POST requests
 * with JSON payloads, exactly matching Android's implementation.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Network service for win/loss notifications
 * Matches Android's WinLossTrackerApiImpl functionality
 */
@interface CLXWinLossNetworkService : NSObject

/**
 * Initializes the service with base URL and session
 * @param baseURL The base URL for network requests
 * @param urlSession The URL session to use
 * @return Initialized service instance
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession;

/**
 * Sends a win/loss notification with dynamic payload
 * Matches Android's send method exactly
 * 
 * @param appKey The app key for authorization
 * @param endpointUrl The endpoint URL to send the request to
 * @param payload Dynamic key-value payload data
 * @param completion Completion handler with success/error result
 */
- (void)sendWithAppKey:(NSString *)appKey
           endpointUrl:(NSString *)endpointUrl
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
