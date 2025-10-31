/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsConfig.h"

@implementation CLXMetricsConfigNetworkSubConfig

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
    }
    return self;
}

@end

@implementation CLXMetricsConfigNetworkCalls

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
        _bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"bidReq"]];
        _sdkInitRequest = [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"initSdkReq"]];
        _geoReq = [[CLXMetricsConfigNetworkSubConfig alloc] initWithDictionary:dictionary[@"geoReq"]];
    }
    return self;
}

@end

@implementation CLXMetricsConfigSDKAPICalls

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _enabled = dictionary[@"enabled"] ?: @NO;
    }
    return self;
}

@end

@implementation CLXMetricsConfig

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _sendIntervalSeconds = [dictionary[@"sendIntervalSeconds"] integerValue];
        _sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] initWithDictionary:dictionary[@"sdkAPICalls"]];
        _networkCalls = [[CLXMetricsConfigNetworkCalls alloc] initWithDictionary:dictionary[@"networkCalls"]];
    }
    return self;
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary; {
    return [[self alloc] initWithDictionary:dictionary];
}

- (BOOL)isSdkApiCallsEnabled {
    return self.sdkAPICalls.enabled.boolValue;
}

- (BOOL)isNetworkCallsEnabled {
    return self.networkCalls.enabled.boolValue;
}

- (BOOL)isBidRequestNetworkCallsEnabled {
    return self.networkCalls.bidReq.enabled.boolValue;
}

- (BOOL)isSdkInitNetworkCallsEnabled {
    return self.networkCalls.sdkInitRequest.enabled.boolValue;
}

- (BOOL)isGeoNetworkCallsEnabled {
    return self.networkCalls.geoReq.enabled.boolValue;
}

@end
