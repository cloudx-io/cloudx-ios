/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSessionNetworkService.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mock session network service that captures calls for test verification.
 * Does not make real network requests.
 */
@interface MockCLXSessionNetworkService : CLXSessionNetworkService

@property (nonatomic, assign) BOOL shouldSucceed;
@property (nonatomic, assign) NSInteger sendCallCount;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *lastPayload;
@property (nonatomic, copy, nullable) NSString *lastAppKey;

@end

NS_ASSUME_NONNULL_END
