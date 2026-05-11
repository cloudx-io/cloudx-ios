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
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class URLProvider
 * @brief Utility class for providing SDK endpoint URLs
 * @discussion This class provides centralized access to various SDK endpoint URLs
 * and allows for easy configuration of different environments.
 */
CLX_INTERNAL_TESTING
@interface CLXURLProvider : NSObject

/**
 * @brief Returns the initialization API URL
 * @return The URL for SDK initialization
 */
+ (NSURL *)initApiUrl;

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

/**
 * Set custom local initialization URL (used when environment is "local")
 * @param url Full URL to provisioning /sdk endpoint
 */
+ (void)setLocalInitializationURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END 