/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockCLXSessionNetworkService.h"

@implementation MockCLXSessionNetworkService

- (instancetype)init {
    // Call super with nil — we override sendWithAppKey: so baseNetworkService is never used
    self = [super initWithBaseNetworkService:nil];
    if (self) {
        _shouldSucceed = YES;
        _sendCallCount = 0;
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion {
    _sendCallCount++;
    _lastAppKey = [appKey copy];
    _lastPayload = [payload copy];

    if (_shouldSucceed) {
        if (completion) {
            completion(YES, nil);
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCLXSessionNetworkService"
                                             code:500
                                         userInfo:@{NSLocalizedDescriptionKey: @"Mock send failure"}];
        if (completion) {
            completion(NO, error);
        }
    }
}

@end
