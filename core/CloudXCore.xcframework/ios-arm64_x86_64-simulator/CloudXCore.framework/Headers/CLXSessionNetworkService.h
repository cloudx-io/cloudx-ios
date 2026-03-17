/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSessionNetworkService.h
 * @brief Network service for session event tracking
 *
 * Sends session events (e.g. "init") to the session endpoint via POST with
 * JSON payload and Bearer authorization. Fire-and-forget analytics with 1 retry.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBaseNetworkService;

@interface CLXSessionNetworkService : NSObject

- (instancetype)initWithBaseNetworkService:(CLXBaseNetworkService *)baseNetworkService;

/**
 * Sends a session event payload to the session endpoint.
 * @param appKey The app key for Bearer authorization
 * @param payload Dictionary representing the session event JSON body
 * @param completion Optional completion handler (fire-and-forget: caller may pass nil)
 */
- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
