/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsConfig.h"

@implementation CLXMetricsConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _sendIntervalSeconds = 60; // Default to 60 seconds like Android
        // All other properties default to nil (no explicit enablement)
    }
    return self;
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    CLXMetricsConfig *config = [[CLXMetricsConfig alloc] init];
    
    // Parse send interval
    NSNumber *sendInterval = dictionary[@"send_interval_seconds"];
    if (sendInterval) {
        config.sendIntervalSeconds = sendInterval.integerValue;
    }
    
    // Parse SDK API calls enablement
    if ([dictionary objectForKey:@"sdk_api_calls.enabled"]) {
        config.sdkApiCallsEnabled = dictionary[@"sdk_api_calls.enabled"];
    }
    
    // Parse network calls enablement
    if ([dictionary objectForKey:@"network_calls.enabled"]) {
        config.networkCallsEnabled = dictionary[@"network_calls.enabled"];
    }
    
    // Parse specific network call enablements
    if ([dictionary objectForKey:@"network_calls.bid_req.enabled"]) {
        config.networkCallsBidReqEnabled = dictionary[@"network_calls.bid_req.enabled"];
    }
    
    if ([dictionary objectForKey:@"network_calls.init_sdk_req.enabled"]) {
        config.networkCallsInitSdkReqEnabled = dictionary[@"network_calls.init_sdk_req.enabled"];
    }
    
    if ([dictionary objectForKey:@"network_calls.geo_req.enabled"]) {
        config.networkCallsGeoReqEnabled = dictionary[@"network_calls.geo_req.enabled"];
    }
    
    return config;
}

- (BOOL)isSdkApiCallsEnabled {
    return self.sdkApiCallsEnabled ? self.sdkApiCallsEnabled.boolValue : NO;
}

- (BOOL)isNetworkCallsEnabled {
    return self.networkCallsEnabled ? self.networkCallsEnabled.boolValue : NO;
}

- (BOOL)isBidRequestNetworkCallsEnabled {
    // Must have both global network calls enabled AND specific bid request enabled
    return [self isNetworkCallsEnabled] && 
           (self.networkCallsBidReqEnabled ? self.networkCallsBidReqEnabled.boolValue : NO);
}

- (BOOL)isInitSdkNetworkCallsEnabled {
    // Must have both global network calls enabled AND specific init SDK enabled
    return [self isNetworkCallsEnabled] && 
           (self.networkCallsInitSdkReqEnabled ? self.networkCallsInitSdkReqEnabled.boolValue : NO);
}

- (BOOL)isGeoNetworkCallsEnabled {
    // Must have both global network calls enabled AND specific geo API enabled
    return [self isNetworkCallsEnabled] && 
           (self.networkCallsGeoReqEnabled ? self.networkCallsGeoReqEnabled.boolValue : NO);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CLXMetricsConfig{interval=%ld, sdkApi=%@, network=%@, bidReq=%@, initSdk=%@, geo=%@}",
            (long)self.sendIntervalSeconds,
            self.sdkApiCallsEnabled ?: @"nil",
            self.networkCallsEnabled ?: @"nil",
            self.networkCallsBidReqEnabled ?: @"nil",
            self.networkCallsInitSdkReqEnabled ?: @"nil",
            self.networkCallsGeoReqEnabled ?: @"nil"];
}

@end
