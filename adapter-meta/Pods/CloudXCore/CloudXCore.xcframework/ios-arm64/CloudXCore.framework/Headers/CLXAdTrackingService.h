/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file AdTrackingService.h
 * @brief Service for handling advertising tracking functionality
 * @details This service provides access to IDFA, DNT, and LAT functionality
 *          following iOS privacy guidelines and App Tracking Transparency framework.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class AdTrackingService
 * @brief Service for handling advertising tracking functionality
 * @discussion This service provides access to IDFA, DNT, and LAT functionality
 * following iOS privacy guidelines and App Tracking Transparency framework.
 */
@interface CLXAdTrackingService : NSObject

/**
 * @brief Checks if IDFA access is allowed
 * @return YES if IDFA access is allowed, NO otherwise
 */
+ (BOOL)isIDFAAccessAllowed;

/**
 * @brief Gets the IDFA (Identifier for Advertisers)
 * @return The IDFA string if available and authorized, nil otherwise
 */
+ (nullable NSString *)idfa;

/**
 * @brief Checks if Do Not Track is enabled
 * @return YES if DNT is enabled, NO otherwise
 */
+ (BOOL)dnt;

@end

NS_ASSUME_NONNULL_END 