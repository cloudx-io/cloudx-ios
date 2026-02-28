/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXIlrdNetworkService.h>

NS_ASSUME_NONNULL_BEGIN

@interface MockCLXIlrdNetworkService : NSObject <CLXIlrdNetworkServiceProtocol>

@property (nonatomic, assign) BOOL shouldSucceed;
@property (nonatomic, assign) NSInteger sendCallCount;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *lastPayload;
@property (nonatomic, copy, nullable) NSString *lastAppKey;

@end

NS_ASSUME_NONNULL_END
