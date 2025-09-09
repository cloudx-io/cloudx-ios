/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyService.h
 * @brief Privacy service for handling COPPA and personal data protection
 * @details This service provides privacy compliance functionality for COPPA.
 *          GDPR and CCPA support are temporarily internal as server-side support
 *          is not yet implemented.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXPrivacyService
 * @brief Service for handling privacy compliance and personal data protection
 * @discussion This service manages privacy settings for COPPA compliance and
 * determines when personal data should be cleared. GDPR and CCPA support are
 * temporarily internal until server-side implementation is complete.
 */
@interface CLXPrivacyService : NSObject

/**
 * @brief Shared instance of the privacy service
 * @return The singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief Determines if personal data should be cleared based on privacy settings
 * @return YES if personal data should be cleared, NO otherwise
 * @discussion This checks COPPA and iOS ATT status to determine data clearing
 */
- (BOOL)shouldClearPersonalData;

/**
 * @brief Checks if COPPA applies to the current user
 * @return YES if COPPA applies, NO otherwise, nil if unknown
 * @discussion COPPA (Children's Online Privacy Protection Act) compliance check
 */
- (nullable NSNumber *)coppaApplies;

/**
 * @brief Gets the hashed user ID for privacy-safe tracking
 * @return The hashed user ID if available, nil otherwise
 */
- (nullable NSString *)hashedUserId;

/**
 * @brief Sets the hashed user ID
 * @param hashedUserId The hashed user ID to store
 */
- (void)setHashedUserId:(nullable NSString *)hashedUserId;

/**
 * @brief Gets the hashed geo IP for privacy-safe tracking
 * @return The hashed geo IP if available, nil otherwise
 */
- (nullable NSString *)hashedGeoIp;

/**
 * @brief Sets the hashed geo IP
 * @param hashedGeoIp The hashed geo IP to store
 */
- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp;

@end

NS_ASSUME_NONNULL_END
