/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsType.h
 * @brief Metrics type constants matching Android's sealed classes exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Network call metrics types
 * Matches Android's sealed class Network(typeCode: String) : MetricsType(typeCode)
 */
extern NSString * const CLXMetricsTypeNetworkSdkInit;      // "network_call_sdk_init_req"
extern NSString * const CLXMetricsTypeNetworkGeoApi;       // "network_call_geo_req"
extern NSString * const CLXMetricsTypeNetworkBidRequest;   // "network_call_bid_req"

/**
 * Method call metrics types
 * Matches Android's sealed class Method(typeCode: String) : MetricsType(typeCode)
 */
extern NSString * const CLXMetricsTypeMethodSdkInit;           // "method_sdk_init"
extern NSString * const CLXMetricsTypeMethodCreateBanner;     // "method_create_banner"
extern NSString * const CLXMetricsTypeMethodCreateInterstitial; // "method_create_interstitial"
extern NSString * const CLXMetricsTypeMethodCreateRewarded;   // "method_create_rewarded"
extern NSString * const CLXMetricsTypeMethodCreateMrec;       // "method_create_mrec"
extern NSString * const CLXMetricsTypeMethodCreateNative;     // "method_create_native"
extern NSString * const CLXMetricsTypeMethodSetHashedUserId;  // "method_set_hashed_user_id"
extern NSString * const CLXMetricsTypeMethodSetUserKeyValues; // "method_set_user_key_values"
extern NSString * const CLXMetricsTypeMethodSetAppKeyValues;  // "method_set_app_key_values"
extern NSString * const CLXMetricsTypeMethodBannerRefresh;    // "method_banner_refresh"

/**
 * Utility class for metrics type validation and categorization
 */
@interface CLXMetricsType : NSObject

/**
 * Check if a metric type is a network call type
 */
+ (BOOL)isNetworkCallType:(NSString *)metricType;

/**
 * Check if a metric type is a method call type
 */
+ (BOOL)isMethodCallType:(NSString *)metricType;

/**
 * Get all network call types
 */
+ (NSArray<NSString *> *)allNetworkCallTypes;

/**
 * Get all method call types
 */
+ (NSArray<NSString *> *)allMethodCallTypes;

/**
 * Validate that a metric type is known
 */
+ (BOOL)isValidMetricType:(NSString *)metricType;

@end

NS_ASSUME_NONNULL_END
