/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXSessionTracker.h>
#import <CloudXCore/CLXSessionNetworkService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXVersion.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXSessionTracker {
    CLXLogger *_logger;
    CLXSessionNetworkService *_networkService;
}

- (instancetype)initWithNetworkService:(CLXSessionNetworkService *)networkService {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"SessionTracker"];
        _networkService = networkService;
    }
    return self;
}

- (void)sendInitEventWithAppKey:(NSString *)appKey
                         config:(CLXSDKConfigResponse *)config {

    CLXSystemInformation *sysInfo = [CLXSystemInformation shared];

    // Determine device type string from enum
    NSString *deviceTypeString;
    switch (sysInfo.deviceType) {
        case DeviceTypeTablet:
            deviceTypeString = @"tablet";
            break;
        case DeviceTypePhone:
            deviceTypeString = @"mobile";
            break;
        default:
            deviceTypeString = @"unknown";
            break;
    }

    // Use locale region code as device country (always available, unlike async geo headers)
    NSString *deviceCountry = [[NSLocale currentLocale] regionCode] ?: @"";

    NSDictionary *payload = @{
        @"sessionId": config.sessionID ?: @"",
        @"accountId": config.accountID ?: @"",
        @"eventType": @"init",
        @"appBundle": sysInfo.appBundleIdentifier ?: @"",
        @"deviceOS": @"iOS",
        @"deviceCountry": deviceCountry,
        @"deviceName": sysInfo.model ?: @"",
        @"deviceType": deviceTypeString,
        @"osVersion": sysInfo.osVersion ?: @"",
        @"deviceIFA": sysInfo.idfa ?: @"",
        @"sdkVersion": CLXSDKVersion ?: @"",
        @"test": @(config.deviceConfig ? config.deviceConfig.test : 0),
    };

    // Fire-and-forget on background queue
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self->_networkService sendWithAppKey:appKey
                                     payload:payload
                                  completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self->_logger info:@"Session init event sent"];
            } else {
                [self->_logger warn:[NSString stringWithFormat:@"Failed to send session init event: %@", error.localizedDescription]];
            }
        }];
    });
}

@end
