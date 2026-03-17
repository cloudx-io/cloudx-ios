/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSessionTracker.h
 * @brief Builds and sends session events (e.g., "init") to the session endpoint.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSDKConfigResponse;
@class CLXSessionNetworkService;

@interface CLXSessionTracker : NSObject

/**
 * Designated initializer with injectable network service for testability.
 * @param networkService The session network service to use for sending events
 */
- (instancetype)initWithNetworkService:(CLXSessionNetworkService *)networkService;

/**
 * Sends an "init" session event to the session endpoint.
 * Fires asynchronously on a background queue; errors are logged but not propagated.
 *
 * @param appKey The app key for Bearer authorization
 * @param config The SDK config response containing session/account/device info
 */
- (void)sendInitEventWithAppKey:(NSString *)appKey
                         config:(CLXSDKConfigResponse *)config;

@end

NS_ASSUME_NONNULL_END
