/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBaseNetworkService;

/**
 * Protocol for ILRD network operations - enables testing.
 */
@protocol CLXIlrdNetworkServiceProtocol <NSObject>

/**
 * Send an ILRD event payload to the backend.
 */
- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

/**
 * Network service for sending ILRD events.
 * Fire-and-forget with no retries, matching Android's RetryStrategy.None.
 */
@interface CLXIlrdNetworkService : NSObject <CLXIlrdNetworkServiceProtocol>

- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession;
- (instancetype)initWithBaseNetworkService:(CLXBaseNetworkService *)baseNetworkService;

@end

NS_ASSUME_NONNULL_END
