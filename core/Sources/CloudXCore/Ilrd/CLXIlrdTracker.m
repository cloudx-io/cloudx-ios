/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXIlrdTracker.h>
#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXIlrdNetworkService.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXIlrdTracker ()
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *endpointUrl;
@property (nonatomic, strong) CLXIlrdService *ilrdService;
@property (nonatomic, strong) id<CLXIlrdNetworkServiceProtocol> networkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) dispatch_queue_t sendQueue;
@property (nonatomic, assign) BOOL started;
@end

@implementation CLXIlrdTracker

- (instancetype)initWithAppKey:(NSString *)appKey
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService
                networkService:(id<CLXIlrdNetworkServiceProtocol>)networkService {
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _endpointUrl = [endpointUrl copy];
        _ilrdService = ilrdService;
        _networkService = networkService;
        _logger = [[CLXLogger alloc] initWithCategory:@"IlrdTracker"];
        _sendQueue = dispatch_queue_create("io.cloudx.ilrd.send", DISPATCH_QUEUE_SERIAL);
        _started = NO;
    }
    return self;
}

- (instancetype)initWithAppKey:(NSString *)appKey
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService {
    CLXIlrdNetworkService *networkService = [[CLXIlrdNetworkService alloc]
        initWithBaseURL:endpointUrl
             urlSession:[NSURLSession sharedSession]];
    return [self initWithAppKey:appKey
                    endpointUrl:endpointUrl
                    ilrdService:ilrdService
                 networkService:networkService];
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    if (_started) {
        [self.logger debug:@"ILRD tracker already started"];
        return;
    }

    _started = YES;

    NSError *error = nil;
    if (![_ilrdService subscribeWithError:&error]) {
        _started = NO;
        [self.logger error:[NSString stringWithFormat:@"Failed to start ILRD tracker: %@", error.localizedDescription]];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [_ilrdService setEventCallback:^(NSDictionary<NSString *, id> *event) {
        [weakSelf sendEvent:event];
    }];

    [self.logger debug:@"ILRD tracker started"];
}

- (void)stop {
    if (!_started) {
        return;
    }

    [_ilrdService setEventCallback:nil];
    [_ilrdService unsubscribe];
    _started = NO;

    [self.logger debug:@"ILRD tracker stopped"];
}

#pragma mark - Private

- (void)sendEvent:(NSDictionary<NSString *, id> *)event {
    dispatch_async(_sendQueue, ^{
        [self.networkService sendWithAppKey:self.appKey
                                   payload:event
                                completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self.logger debug:@"ILRD event sent successfully"];
            } else {
                [self.logger error:[NSString stringWithFormat:@"ILRD event send failed: %@", error.localizedDescription]];
            }
        }];
    });
}

@end
