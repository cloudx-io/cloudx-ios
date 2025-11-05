/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsConfig.h"

@implementation CLXMetricsConfigNetworkSubConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = @NO;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
    }
    return self;
}

@end

@implementation CLXMetricsConfigNetworkCalls

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = @NO;
        _bidReq = nil;
        _sdkInitRequest = nil;
        _geoReq = nil;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
        _bidReq = dictionary[@"bidReq"] ? [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"bidReq"]] : nil;
        _sdkInitRequest = dictionary[@"initSdkReq"] ? [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"initSdkReq"]] : nil;
        _geoReq = dictionary[@"geoReq"] ? [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"geoReq"]] : nil;
    }
    return self;
}

@end

@implementation CLXMetricsConfigSDKAPICalls

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = @NO;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
    }
    return self;
}

@end

@implementation CLXMetricsConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _sendIntervalSeconds = 60; // Default value
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (self) {
        // Support both snake_case (from backend) and camelCase keys
        NSNumber *sendInterval = dictionary[@"send_interval_seconds"] ?: dictionary[@"sendIntervalSeconds"];
        if (sendInterval) {
            _sendIntervalSeconds = [sendInterval integerValue];
        }
        
        // Handle flattened keys (e.g., "sdk_api_calls.enabled") or nested objects
        id sdkAPICallsData = dictionary[@"sdkAPICalls"];
        if (!sdkAPICallsData && dictionary[@"sdk_api_calls.enabled"]) {
            // Build nested structure from flattened keys
            sdkAPICallsData = @{@"enabled": dictionary[@"sdk_api_calls.enabled"]};
        }
        if (sdkAPICallsData) {
            _sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] initWithDictionary:sdkAPICallsData];
        }
        
        // Handle network calls - support both flattened and nested
        id networkCallsData = dictionary[@"networkCalls"];
        if (!networkCallsData) {
            // Check for flattened keys
            NSMutableDictionary *networkDict = [NSMutableDictionary dictionary];
            if (dictionary[@"network_calls.enabled"]) {
                networkDict[@"enabled"] = dictionary[@"network_calls.enabled"];
            }
            
            NSMutableDictionary *bidReqDict = [NSMutableDictionary dictionary];
            if (dictionary[@"network_calls.bid_req.enabled"]) {
                bidReqDict[@"enabled"] = dictionary[@"network_calls.bid_req.enabled"];
                networkDict[@"bidReq"] = bidReqDict;
            }
            
            NSMutableDictionary *initSdkReqDict = [NSMutableDictionary dictionary];
            if (dictionary[@"network_calls.init_sdk_req.enabled"]) {
                initSdkReqDict[@"enabled"] = dictionary[@"network_calls.init_sdk_req.enabled"];
                networkDict[@"initSdkReq"] = initSdkReqDict;
            }
            
            NSMutableDictionary *geoReqDict = [NSMutableDictionary dictionary];
            if (dictionary[@"network_calls.geo_req.enabled"]) {
                geoReqDict[@"enabled"] = dictionary[@"network_calls.geo_req.enabled"];
                networkDict[@"geoReq"] = geoReqDict;
            }
            
            if (networkDict.count > 0) {
                networkCallsData = networkDict;
            }
        }
        if (networkCallsData) {
            _networkCalls = [[CLXMetricsConfigNetworkCalls alloc] initWithDictionary:networkCallsData];
        }
    }
    return self;
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary; {
    return [[self alloc] initWithDictionary:dictionary];
}

- (BOOL)isSdkApiCallsEnabled {
    return self.sdkAPICalls != nil && self.sdkAPICalls.enabled.boolValue;
}

- (BOOL)isNetworkCallsEnabled {
    return self.networkCalls != nil && self.networkCalls.enabled.boolValue;
}

- (BOOL)isBidRequestNetworkCallsEnabled {
    return [self isNetworkCallsEnabled] && self.networkCalls.bidReq != nil && self.networkCalls.bidReq.enabled.boolValue;
}

- (BOOL)isSdkInitNetworkCallsEnabled {
    return [self isNetworkCallsEnabled] && self.networkCalls.sdkInitRequest != nil && self.networkCalls.sdkInitRequest.enabled.boolValue;
}

- (BOOL)isGeoNetworkCallsEnabled {
    return [self isNetworkCallsEnabled] && self.networkCalls.geoReq != nil && self.networkCalls.geoReq.enabled.boolValue;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<CLXMetricsConfig: sendIntervalSeconds=%ld, sdkAPICalls=%@, networkCalls=%@>",
            (long)self.sendIntervalSeconds,
            self.sdkAPICalls ? @"configured" : @"nil",
            self.networkCalls ? @"configured" : @"nil"];
}

@end
