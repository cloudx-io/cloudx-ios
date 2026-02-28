/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import "MockCLXIlrdProvider.h"

@implementation MockCLXIlrdProvider

@synthesize platform = _platform;

- (instancetype)init {
    self = [super init];
    if (self) {
        _platform = CLXIlrdPlatformAl;
        _shouldSucceedSubscribe = YES;
        _shouldSucceedUnsubscribe = YES;
        _subscribeCallCount = 0;
        _unsubscribeCallCount = 0;
    }
    return self;
}

- (BOOL)subscribeWithError:(NSError **)outError {
    _subscribeCallCount++;
    if (!_shouldSucceedSubscribe) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"MockCLXIlrdProvider"
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"Mock subscribe failure"}];
        }
        return NO;
    }
    return YES;
}

- (BOOL)unsubscribeWithError:(NSError **)outError {
    _unsubscribeCallCount++;
    if (!_shouldSucceedUnsubscribe) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"MockCLXIlrdProvider"
                                            code:2
                                        userInfo:@{NSLocalizedDescriptionKey: @"Mock unsubscribe failure"}];
        }
        return NO;
    }
    return YES;
}

- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback {
    _eventCallback = [callback copy];
}

- (void)simulateEvent:(NSDictionary<NSString *, id> *)event {
    if (_eventCallback) {
        _eventCallback(event);
    }
}

@end
