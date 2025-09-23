/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsType.h"

// Network call metrics types - matching Android exactly
NSString * const CLXMetricsTypeNetworkSdkInit = @"network_call_sdk_init_req";
NSString * const CLXMetricsTypeNetworkGeoApi = @"network_call_geo_req";
NSString * const CLXMetricsTypeNetworkBidRequest = @"network_call_bid_req";

// Method call metrics types - matching Android exactly
NSString * const CLXMetricsTypeMethodSdkInit = @"method_sdk_init";
NSString * const CLXMetricsTypeMethodCreateBanner = @"method_create_banner";
NSString * const CLXMetricsTypeMethodCreateInterstitial = @"method_create_interstitial";
NSString * const CLXMetricsTypeMethodCreateRewarded = @"method_create_rewarded";
NSString * const CLXMetricsTypeMethodCreateMrec = @"method_create_mrec";
NSString * const CLXMetricsTypeMethodCreateNative = @"method_create_native";
NSString * const CLXMetricsTypeMethodSetHashedUserId = @"method_set_hashed_user_id";
NSString * const CLXMetricsTypeMethodSetUserKeyValues = @"method_set_user_key_values";
NSString * const CLXMetricsTypeMethodSetAppKeyValues = @"method_set_app_key_values";
NSString * const CLXMetricsTypeMethodBannerRefresh = @"method_banner_refresh";

@implementation CLXMetricsType

+ (BOOL)isNetworkCallType:(NSString *)metricType {
    return [[self allNetworkCallTypes] containsObject:metricType];
}

+ (BOOL)isMethodCallType:(NSString *)metricType {
    return [[self allMethodCallTypes] containsObject:metricType];
}

+ (NSArray<NSString *> *)allNetworkCallTypes {
    static NSArray<NSString *> *networkTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkTypes = @[
            CLXMetricsTypeNetworkSdkInit,
            CLXMetricsTypeNetworkGeoApi,
            CLXMetricsTypeNetworkBidRequest
        ];
    });
    return networkTypes;
}

+ (NSArray<NSString *> *)allMethodCallTypes {
    static NSArray<NSString *> *methodTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        methodTypes = @[
            CLXMetricsTypeMethodSdkInit,
            CLXMetricsTypeMethodCreateBanner,
            CLXMetricsTypeMethodCreateInterstitial,
            CLXMetricsTypeMethodCreateRewarded,
            CLXMetricsTypeMethodCreateMrec,
            CLXMetricsTypeMethodCreateNative,
            CLXMetricsTypeMethodSetHashedUserId,
            CLXMetricsTypeMethodSetUserKeyValues,
            CLXMetricsTypeMethodSetAppKeyValues,
            CLXMetricsTypeMethodBannerRefresh
        ];
    });
    return methodTypes;
}

+ (BOOL)isValidMetricType:(NSString *)metricType {
    return [self isNetworkCallType:metricType] || [self isMethodCallType:metricType];
}

@end
