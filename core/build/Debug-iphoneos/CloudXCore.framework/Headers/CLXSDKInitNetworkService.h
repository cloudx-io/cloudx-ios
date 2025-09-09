/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file SDKInitNetworkService.h
 * @brief Network service for SDK initialization
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXExponentialBackoffStrategy.h>
#import <CloudXCore/CLXSDKConfigRequest.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXSDKInitNetworkService
 * @brief Handles network requests for SDK initialization
 * @discussion This service manages the network communication for initializing the SDK,
 * including retry logic and error handling.
 */
@interface CLXSDKInitNetworkService : CLXBaseNetworkService

/** Logger instance for tracking initialization process */
@property (nonatomic, strong) CLXLogger *logger;

/** Strategy for handling retry attempts with exponential backoff */
@property (nonatomic, strong) CLXExponentialBackoffStrategy *backOffStrategy;

/**
 * @brief Initializes the network service with base URL and session
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @return An initialized instance of SDKInitNetworkService
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession;

/**
 * @brief Initializes the SDK with the provided app key
 * @param appKey The application key for SDK initialization
 * @param completion Completion handler called with the SDK configuration or error
 */
- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 