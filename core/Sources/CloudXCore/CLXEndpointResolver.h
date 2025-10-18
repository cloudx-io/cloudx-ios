/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXEndpointResolver.h
 * @brief Resolver for endpoint URLs with A/B testing support
 *
 * The CLXEndpointResolver handles endpoint URL selection for A/B testing.
 * It uses one random number to choose only one test URL from all endpoints.
 * The test ratios must add up to 1.0, or it uses default URLs.
 * If test data is missing or invalid, it falls back to default URLs.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXEndpointResolver : NSObject

/**
 * @brief Resolved auction endpoint URL
 */
@property (nonatomic, copy, readonly) NSString *auctionEndpoint;

/**
 * @brief Resolved CDP endpoint URL
 */
@property (nonatomic, copy, readonly) NSString *cdpEndpoint;

/**
 * @brief Resolved geo endpoint URL
 */
@property (nonatomic, copy, readonly) NSString *geoEndpoint;

/**
 * @brief Name of the selected A/B test group (empty if no test selected)
 */
@property (nonatomic, copy, readonly) NSString *testGroupName;

/**
 * @brief Resolves endpoints from SDK config response with A/B testing logic
 * @param config The SDK configuration response containing endpoint definitions
 */
- (void)resolveFromConfig:(CLXSDKConfigResponse *)config;

/**
 * @brief Resolves endpoints with custom random value (for testing)
 * @param config The SDK configuration response containing endpoint definitions
 * @param randomValue Random value between 0.0 and 1.0 for A/B test selection
 */
- (void)resolveFromConfig:(CLXSDKConfigResponse *)config randomValue:(double)randomValue;

/**
 * @brief Resets all resolved endpoints to empty strings
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
