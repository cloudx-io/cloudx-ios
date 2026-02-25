/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyService.h
 * @brief Privacy service for handling CCPA and personal data protection
 * @details This service provides privacy compliance functionality for CCPA.
 *          GDPR support is temporarily internal as server-side support is not yet implemented.
 */

#import <Foundation/Foundation.h>

@class CLXConsentProvider;
@class CLXGeoLocationService;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXPrivacyService
 * @brief Service for handling privacy compliance and personal data protection
 * @discussion This service manages privacy settings for CCPA compliance and
 * determines when personal data should be cleared. GDPR support is temporarily internal
 * until server-side implementation is complete.
 */
@interface CLXPrivacyService : NSObject

/**
 * @brief Shared instance of the privacy service
 * @return The singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief The consent provider used by this privacy service
 */
@property (nonatomic, strong, readonly) CLXConsentProvider *consentProvider;

/**
 * @brief Initializes the privacy service with required dependencies
 * @param userDefaults The UserDefaults instance to use for storing privacy-related data
 * @param consentProvider The consent provider used to manage privacy consent state
 * @param geoLocationService The geo location service used for geography-based privacy checks
 * @return An initialized CLXPrivacyService instance
 */
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
                     consentProvider:(CLXConsentProvider *)consentProvider
                  geoLocationService:(CLXGeoLocationService *)geoLocationService;

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
 * @brief Gets the hashed geo IP for privacy-safe tracking
 * @return The hashed geo IP if available, nil otherwise
 */
- (nullable NSString *)hashedGeoIp;

/**
 * @brief Sets the hashed geo IP
 * @param hashedGeoIp The hashed geo IP to store
 */
- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp;

#pragma mark - GPP Methods

/**
 * @brief Gets the GPP consent string
 * @return The GPP string if available, nil otherwise
 * @discussion GPP (Global Privacy Platform) compliance string
 */
- (nullable NSString *)gppString;

/**
 * @brief Gets the GPP section IDs
 * @return Array of GPP section IDs if available, nil otherwise
 * @discussion GPP section identifiers for applicable privacy frameworks
 */
- (nullable NSArray<NSNumber *> *)gppSid;

/**
 * @brief Sets the GPP string for privacy compliance
 * @param gppString The GPP consent string
 * @discussion Publisher API to set GPP consent data
 */
- (void)setGppString:(nullable NSString *)gppString;

/**
 * @brief Sets the GPP section IDs
 * @param gppSid Array of GPP section IDs
 * @discussion Publisher API to set GPP section identifiers
 */
- (void)setGppSid:(nullable NSArray<NSNumber *> *)gppSid;

@end

NS_ASSUME_NONNULL_END
