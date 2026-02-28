/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXIlrdService ()
@property (nonatomic, strong) NSDictionary<NSNumber *, id<CLXIlrdProvider>> *providers;
@property (nonatomic, copy, nullable) CLXIlrdEventCallback eventCallback;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXIlrdService

- (instancetype)initWithProviders:(NSDictionary<NSNumber *, id<CLXIlrdProvider>> *)providers {
    self = [super init];
    if (self) {
        _providers = [providers copy];
        _logger = [[CLXLogger alloc] initWithCategory:@"IlrdService"];
    }
    return self;
}

- (BOOL)subscribeWithError:(NSError **)outError {
    if (_providers.count == 0) {
        [self.logger error:@"No ILRD providers configured"];
        if (outError) {
            *outError = [NSError errorWithDomain:@"CLXIlrdService"
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"No ILRD providers configured"}];
        }
        return NO;
    }

    BOOL anySuccess = NO;
    NSError *lastError = nil;

    for (NSNumber *key in _providers) {
        id<CLXIlrdProvider> provider = _providers[key];
        NSError *providerError = nil;

        if ([provider subscribeWithError:&providerError]) {
            anySuccess = YES;

            __weak typeof(self) weakSelf = self;
            [provider setEventCallback:^(NSDictionary<NSString *, id> *event) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                CLXIlrdEventCallback callback;
                @synchronized (strongSelf) {
                    callback = strongSelf->_eventCallback;
                }
                if (callback) {
                    callback(event);
                }
            }];

            [self.logger debug:[NSString stringWithFormat:@"ILRD provider subscribed: platform=%@", key]];
        } else {
            lastError = providerError;
            [self.logger error:[NSString stringWithFormat:@"ILRD provider failed to subscribe: platform=%@, error=%@",
                                key, providerError.localizedDescription]];
        }
    }

    if (!anySuccess && outError && lastError) {
        *outError = lastError;
    }

    return anySuccess;
}

- (void)unsubscribe {
    for (NSNumber *key in _providers) {
        id<CLXIlrdProvider> provider = _providers[key];
        [provider setEventCallback:nil];
        NSError *error = nil;
        [provider unsubscribeWithError:&error];
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Failed to unsubscribe ILRD provider: platform=%@, error=%@",
                                key, error.localizedDescription]];
        }
    }
}

- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback {
    @synchronized (self) {
        _eventCallback = [callback copy];
    }
}

@end
