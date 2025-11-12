/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsConfig.h
 * @brief Metrics configuration matching Android's MetricsConfig exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetricsConfigNetworkSubConfig : NSObject

@property (nonatomic, strong) NSNumber *enabled;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface CLXMetricsConfigNetworkCalls : NSObject

@property (nonatomic, strong) NSNumber *enabled;
@property (nonatomic, strong) CLXMetricsConfigNetworkSubConfig *bidReq;
@property (nonatomic, strong) CLXMetricsConfigNetworkSubConfig *sdkInitRequest; // renamed from initSdkReq
@property (nonatomic, strong) CLXMetricsConfigNetworkSubConfig *geoReq;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface CLXMetricsConfigSDKAPICalls : NSObject

@property (nonatomic, strong) NSNumber *enabled;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface CLXMetricsConfig : NSObject

@property (nonatomic, assign) NSInteger sendIntervalSeconds;
@property (nonatomic, strong) CLXMetricsConfigSDKAPICalls *sdkAPICalls;
@property (nonatomic, strong) CLXMetricsConfigNetworkCalls *networkCalls;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)fromDictionary:(NSDictionary *)dictionary;

/**
 * Convenience methods
 */
- (BOOL)isSdkApiCallsEnabled;
- (BOOL)isNetworkCallsEnabled;
- (BOOL)isBidRequestNetworkCallsEnabled;
- (BOOL)isSdkInitNetworkCallsEnabled;
- (BOOL)isGeoNetworkCallsEnabled;

@end

NS_ASSUME_NONNULL_END
