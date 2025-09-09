/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyService.h
 * @brief Privacy service for handling CCPA and personal data protection
 * @details This service provides privacy compliance functionality for CCPA.
 *          GDPR and COPPA support are temporarily internal as server-side support
 *          is not yet implemented.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXPrivacyService
 * @brief Service for handling privacy compliance and personal data protection
 * @discussion This service manages privacy settings for CCPA compliance and
 * determines when personal data should be cleared. GDPR and COPPA support are
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
 * @discussion This checks CCPA and iOS ATT status to determine data clearing
 */
- (BOOL)shouldClearPersonalData;

/**
 * @brief Gets the CCPA privacy string
 * @return The CCPA privacy string if available, nil otherwise
 * @discussion CCPA (California Consumer Privacy Act) compliance string
 */
- (nullable NSString *)ccpaPrivacyString;

/**
 * @brief Checks if CCPA applies to the current user
 * @return YES if CCPA applies, NO otherwise, nil if unknown
 * @discussion CCPA (California Consumer Privacy Act) compliance check
 */
- (nullable NSNumber *)ccpaApplies;

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

/**
 * @brief Sets the CCPA privacy string
 * @param ccpaPrivacyString The CCPA privacy string (e.g., "1YNN")
 * @discussion CCPA (California Consumer Privacy Act) compliance string
 */
- (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString;

/**
 * @brief Sets whether the user has given consent (GDPR)
 * @param hasUserConsent YES if user has given consent, NO otherwise, nil to clear
 * @discussion ⚠️ GDPR is not yet supported by CloudX servers. Please contact CloudX if you need GDPR support. CCPA is fully supported.
 */
- (void)setHasUserConsent:(nullable NSNumber *)hasUserConsent;

/**
 * @brief Sets whether the user is age-restricted (COPPA)
 * @param isAgeRestrictedUser YES if user is age-restricted, NO otherwise, nil to clear
 * @discussion ⚠️ COPPA is not yet supported by CloudX servers. Please contact CloudX if you need COPPA support. CCPA is fully supported.
 */
- (void)setIsAgeRestrictedUser:(nullable NSNumber *)isAgeRestrictedUser;

/**
 * @brief Sets the "do not sell" preference (CCPA)
 * @param doNotSell YES to opt-out of data selling, NO otherwise, nil to clear
 * @discussion CCPA "do not sell my personal information" flag - converts to CCPA privacy string format
 */
- (void)setDoNotSell:(nullable NSNumber *)doNotSell;

@end

NS_ASSUME_NONNULL_END
