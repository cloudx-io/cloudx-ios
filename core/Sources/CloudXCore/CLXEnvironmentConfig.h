#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Centralized environment configuration for CloudX SDK
 * Automatically selects staging for DEBUG builds, production otherwise
 * 
 * All URLs, paths, and environment-specific configuration centralized here
 * to eliminate hardcoded strings throughout the codebase.
 */
@interface CLXEnvironmentConfig : NSObject

/**
 * Returns the singleton instance
 */
+ (instancetype)shared;

// MARK: - Complete Endpoint URLs

/**
 * Complete auction endpoint URL (base + path)
 */
@property (nonatomic, readonly) NSString *auctionEndpointURL;

/**
 * Complete metrics endpoint URL (base + path + default params)
 */
@property (nonatomic, readonly) NSString *metricsEndpointURL;

/**
 * Complete event tracking endpoint URL (base + path + default params)
 */
@property (nonatomic, readonly) NSString *eventTrackingEndpointURL;

/**
 * Complete tracker bulk endpoint URL (base + path + debug params if applicable)
 */
@property (nonatomic, readonly) NSString *trackerBulkEndpointURL;

/**
 * Complete tracker base URL for rill tracking (base + path)
 */
@property (nonatomic, readonly) NSString *trackerRillBaseURL;

/**
 * Complete initialization endpoint URL (base + path)
 */
@property (nonatomic, readonly) NSString *initializationEndpointURL;

/**
 * Complete geo data endpoint URL
 */
@property (nonatomic, readonly) NSString *geoEndpointURL;

// MARK: - Environment Info

/**
 * Whether we're in debug/staging environment
 */
@property (nonatomic, readonly) BOOL isDebugEnvironment;

/**
 * Current environment name (for logging)
 */
@property (nonatomic, readonly) NSString *environmentName;

// MARK: - Debug Environment Selection (DEBUG builds only)

/**
 * Set debug environment preference (dev or staging)
 * Only available in DEBUG builds, ignored in production
 * @param environment Either "dev" or "staging"
 */
+ (void)setDebugEnvironment:(NSString *)environment;

/**
 * Reset to default environment (dev in DEBUG, production in release)
 */
+ (void)resetToDefault;

/**
 * Get list of available debug environments
 * @return Array of environment names, empty in production builds
 */
+ (NSArray<NSString *> *)availableDebugEnvironments;

@end

NS_ASSUME_NONNULL_END
