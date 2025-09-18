/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file URLProvider.h
 * @brief Provides URL functionality for the CloudX SDK
 * @details This class is responsible for providing various SDK endpoint URLs,
 *          including initialization API URLs and other service endpoints.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class URLProvider
 * @brief Utility class for providing SDK endpoint URLs
 * @discussion This class provides centralized access to various SDK endpoint URLs
 * and allows for easy configuration of different environments.
 */
@interface CLXURLProvider : NSObject

/**
 * @brief Returns the initialization API URL
 * @return The URL for SDK initialization
 */
+ (NSURL *)initApiUrl;

/**
 * @brief Returns the auction API URL
 * @return The URL string for ad auctions
 */
+ (NSString *)auctionApiUrl;

/**
 * @brief Returns the metrics API URL
 * @return The URL string for metrics reporting
 */
+ (NSString *)metricsApiUrl;

// MARK: - Environment Utilities

/**
 * Get the current environment name (for logging)
 * @return Environment name: "development", "staging", or "production"
 */
+ (NSString *)environmentName;

/**
 * Set debug environment preference (dev, staging, or production)
 * Only available in DEBUG builds, ignored in production
 * @param environment "dev", "staging", or "production"
 */
+ (void)setEnvironment:(NSString *)environment;

@end

NS_ASSUME_NONNULL_END 