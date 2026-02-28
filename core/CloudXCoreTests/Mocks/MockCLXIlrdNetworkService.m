/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import "MockCLXIlrdNetworkService.h"

@implementation MockCLXIlrdNetworkService

- (instancetype)init {
    self = [super init];
    if (self) {
        _shouldSucceed = YES;
        _sendCallCount = 0;
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    _sendCallCount++;
    _lastAppKey = [appKey copy];
    _lastPayload = [payload copy];

    if (_shouldSucceed) {
        if (completion) {
            completion(YES, nil);
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCLXIlrdNetworkService"
                                             code:500
                                         userInfo:@{NSLocalizedDescriptionKey: @"Mock send failure"}];
        if (completion) {
            completion(NO, error);
        }
    }
}

@end
