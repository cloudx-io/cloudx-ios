/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsConfig.h
 * @brief Metrics configuration matching Android's MetricsConfig exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Metrics configuration class
 * Matches Android's data class MetricsConfig exactly
 */
@interface CLXMetricsConfig : NSObject

@property (nonatomic, assign) NSInteger sendIntervalSeconds;                    // Default: 60
@property (nonatomic, strong, nullable) NSNumber *sdkApiCallsEnabled;          // Global SDK API calls flag
@property (nonatomic, strong, nullable) NSNumber *networkCallsEnabled;         // Global network calls flag
@property (nonatomic, strong, nullable) NSNumber *networkCallsBidReqEnabled;   // Bid request specific flag
@property (nonatomic, strong, nullable) NSNumber *networkCallsInitSdkReqEnabled; // SDK init specific flag
@property (nonatomic, strong, nullable) NSNumber *networkCallsGeoReqEnabled;   // Geo API specific flag

- (instancetype)init;

/**
 * Create from dictionary (for JSON parsing)
 */
+ (instancetype)fromDictionary:(NSDictionary *)dictionary;

/**
 * Check if SDK API calls are enabled
 */
- (BOOL)isSdkApiCallsEnabled;

/**
 * Check if network calls are globally enabled
 */
- (BOOL)isNetworkCallsEnabled;

/**
 * Check if bid request network calls are enabled
 */
- (BOOL)isBidRequestNetworkCallsEnabled;

/**
 * Check if SDK init network calls are enabled
 */
- (BOOL)isInitSdkNetworkCallsEnabled;

/**
 * Check if geo API network calls are enabled
 */
- (BOOL)isGeoNetworkCallsEnabled;

@end

NS_ASSUME_NONNULL_END
