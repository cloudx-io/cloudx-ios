/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXIlrdTracker.h>
#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXIlrdNetworkService.h>
#import <CloudXCore/CLXAuctionResult.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXIlrdTracker ()
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *endpointUrl;
@property (nonatomic, strong) CLXIlrdService *ilrdService;
@property (nonatomic, strong) id<CLXIlrdNetworkServiceProtocol> networkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) dispatch_queue_t sendQueue;
@property (nonatomic, assign) BOOL started;
/*
 * Stores the latest no-fill auction result per ad format.
 * Consumed (one-shot) when an ILRD impression arrives for the same format.
 * Keyed by @(CLXAdType), value is NSDictionary with auctionId + adUnitId.
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDictionary *> *noFillAuctions;
@property (nonatomic, strong) dispatch_queue_t noFillQueue;
@end

@implementation CLXIlrdTracker

- (instancetype)initWithAppKey:(NSString *)appKey
                     accountId:(NSString *)accountId
                     sessionId:(NSString *)sessionId
                    sdkVersion:(NSString *)sdkVersion
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService
                networkService:(id<CLXIlrdNetworkServiceProtocol>)networkService {
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _accountId = [accountId copy];
        _sessionId = [sessionId copy];
        _sdkVersion = [sdkVersion copy];
        _endpointUrl = [endpointUrl copy];
        _ilrdService = ilrdService;
        _networkService = networkService;
        _logger = [[CLXLogger alloc] initWithCategory:@"IlrdTracker"];
        _sendQueue = dispatch_queue_create("io.cloudx.ilrd.send", DISPATCH_QUEUE_SERIAL);
        _noFillQueue = dispatch_queue_create("io.cloudx.ilrd.nofill", DISPATCH_QUEUE_SERIAL);
        _started = NO;
        _noFillAuctions = [NSMutableDictionary dictionary];
    }
    return self;
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAuctionResult:)
                                                 name:CLXAuctionResultNotification
                                               object:nil];

    [self.logger debug:@"ILRD tracker started"];
}

- (void)stop {
    if (!_started) {
        return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CLXAuctionResultNotification
                                                  object:nil];

    [_ilrdService setEventCallback:nil];
    [_ilrdService unsubscribe];
    _started = NO;

    [self.logger debug:@"ILRD tracker stopped"];
}

#pragma mark - Auction Result Observation

- (void)handleAuctionResult:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *adType = userInfo[CLXAuctionResultAdTypeKey];
    NSString *auctionId = userInfo[CLXAuctionResultAuctionIdKey];
    NSString *adUnitId = userInfo[CLXAuctionResultAdUnitIdKey];
    BOOL filled = [userInfo[CLXAuctionResultFilledKey] boolValue];

    if (!adType || !auctionId || !adUnitId) {
        [self.logger error:[NSString stringWithFormat:@"Malformed auction result notification: adType=%@, auctionId=%@, adUnitId=%@", adType, auctionId, adUnitId]];
        return;
    }

    dispatch_sync(_noFillQueue, ^{
        if (!filled) {
            self->_noFillAuctions[adType] = @{
                @"auctionId": auctionId,
                @"adUnitId": adUnitId,
            };
        } else {
            [self->_noFillAuctions removeObjectForKey:adType];
        }
    });
}

#pragma mark - Private

- (nullable NSDictionary *)popAuctionResultForAdFormat:(nullable NSString *)adFormat {
    if (!adFormat) return nil;

    NSNumber *key = [self adTypeKeyForFormat:adFormat];
    if (!key) return nil;

    __block NSDictionary *result;
    dispatch_sync(_noFillQueue, ^{
        result = self->_noFillAuctions[key];
        [self->_noFillAuctions removeObjectForKey:key];
    });
    return result;
}

- (nullable NSNumber *)adTypeKeyForFormat:(NSString *)format {
    if ([format isEqualToString:@"interstitial"]) return @(CLXAdTypeInterstitial);
    if ([format isEqualToString:@"rewarded"]) return @(CLXAdTypeRewarded);
    if ([format isEqualToString:@"banner"]) return @(CLXAdTypeBanner);
    if ([format isEqualToString:@"mrec"]) return @(CLXAdTypeMrec);
    return nil;
}

- (void)sendEvent:(NSDictionary<NSString *, id> *)providerEvent {
    dispatch_async(_sendQueue, ^{
        NSDictionary *auctionResult = [self popAuctionResultForAdFormat:providerEvent[@"adFormat"]];

        static NSSet *sdkKeys;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sdkKeys = [NSSet setWithObjects:@"accountId", @"sessionId", @"os", @"sdkVersion", @"cxAuctionId", @"cxAdUnitId", nil];
        });

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];

        /* Provider event fields first */
        for (NSString *key in providerEvent) {
            if ([sdkKeys containsObject:key]) {
                [self.logger error:[NSString stringWithFormat:@"Provider event contains reserved SDK key '%@' -- will be overwritten", key]];
                continue;
            }
            payload[key] = providerEvent[key];
        }

        /* SDK identity last -- cannot be overwritten by provider */
        payload[@"accountId"] = self.accountId;
        payload[@"sessionId"] = self.sessionId;
        payload[@"os"] = @"ios";
        payload[@"sdkVersion"] = self.sdkVersion;

        /* CX auction correlation (optional) */
        if (auctionResult) {
            payload[@"cxAuctionId"] = auctionResult[@"auctionId"];
            payload[@"cxAdUnitId"] = auctionResult[@"adUnitId"];
        }

        [self.logger debug:[NSString stringWithFormat:@"ILRD event: %@", payload]];

        __weak typeof(self) weakSelf = self;
        [self.networkService sendWithAppKey:self.appKey
                                   payload:payload
                                completion:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                [weakSelf.logger error:[NSString stringWithFormat:@"ILRD event send failed: %@", error.localizedDescription ?: @"unknown error"]];
            }
        }];
    });
}

@end
