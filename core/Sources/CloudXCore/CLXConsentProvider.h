/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXConsentProvider.h
 * @brief GPP (Global Privacy Platform) provider service
 * @details Handles reading, parsing, and decoding GPP consent strings according to IAB specifications
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXPrivacyConsent.h>

@class CLXErrorReporter;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief IAB GPP UserDefaults keys
 * @discussion Standard IAB keys for GPP framework integration
 */
extern NSString * const kIABGPP_GppString;
extern NSString * const kIABGPP_GppSID;

/**
 * @class CLXConsentProvider
 * @brief Service for GPP consent string parsing and management
 * @discussion Provides GPP framework integration with support for US-CA and US-National sections
 */
@interface CLXConsentProvider : NSObject

/**
 * @brief Shared instance of the GPP provider
 * @return The singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief Initializes GPP provider with dependency injection for error reporting
 * @param errorReporter Optional error reporter for exception tracking
 * @return An initialized CLXConsentProvider instance
 */
- (instancetype)initWithErrorReporter:(nullable CLXErrorReporter *)errorReporter;

/**
 * @brief Gets the GPP consent string from UserDefaults
 * @return The GPP string if available, nil otherwise
 * @discussion Reads from standard IAB key IABGPP_HDR_GppString
 */
- (nullable NSString *)gppString;

/**
 * @brief Gets the GPP section IDs from UserDefaults
 * @return Array of section IDs if available, nil otherwise
 * @discussion Parses IABGPP_GppSID with support for flexible delimiters (_ and ,)
 */
- (nullable NSArray<NSNumber *> *)gppSid;

/**
 * @brief Decodes GPP consent for specified target or best available
 * @param target Specific GPP target to decode, or nil for automatic selection
 * @return Decoded consent object if available, nil otherwise
 * @discussion When target is nil, prioritizes consent requiring PII removal, then first available
 */
- (nullable CLXPrivacyConsent *)decodeGppForTarget:(nullable NSNumber *)target;

/**
 * @brief Sets the GPP consent string for privacy compliance
 * @param gppString The GPP string to store
 * @discussion Stores to standard IAB UserDefaults key
 */
- (void)setGppString:(nullable NSString *)gppString;

/**
 * @brief Sets the GPP section IDs for privacy compliance
 * @param gppSid Array of section IDs to store
 * @discussion Stores to standard IAB UserDefaults key with underscore delimiter
 */
- (void)setGppSid:(nullable NSArray<NSNumber *> *)gppSid;

#pragma mark - TCF (GDPR) Methods

/**
 * @brief Gets the TCF consent string from UserDefaults
 * @return The TCF string if available, nil otherwise
 * @discussion Reads from standard IAB key IABTCF_TCString
 */
- (nullable NSString *)tcString;

/**
 * @brief Gets the GDPR applies flag from UserDefaults
 * @return @YES if GDPR applies, @NO if not, nil if unknown
 * @discussion Reads from standard IAB key IABTCF_gdprApplies (integer: 0 or 1)
 */
- (nullable NSNumber *)gdprApplies;

/**
 * @brief Decodes a TCF consent string to extract purpose and vendor consent
 * @param tcString The base64url encoded TCF v2 consent string
 * @return Decoded consent object with purpose and vendor consent, nil on failure
 * @discussion Parses purposes 1-4 and vendor consent for CloudX vendor ID
 */
- (nullable CLXPrivacyConsent *)decodeTcString:(NSString *)tcString;

/**
 * @brief Extracts the TCF string from GPP when Section 2 is present
 * @return The TCF string if GPP contains Section 2, nil otherwise
 * @discussion Use for DSP compatibility - sends TCF in legacy format
 */
- (nullable NSString *)extractTcStringFromGpp;

#pragma mark - GPP Resolution Methods (Legacy Fallback)

/**
 * @brief Resolves GDPR applies status from available consent signals
 * @return @YES if GDPR applies, @NO if not, nil if unknown
 * @discussion Resolution order: 1) GPP SID contains 2, 2) Legacy IABTCF_gdprApplies
 */
- (nullable NSNumber *)resolveGdprApplies;

/**
 * @brief Resolves GPP string for bid requests, constructing from legacy TCF if needed
 * @return GPP string from CMP or constructed from legacy TCF, nil if neither available
 * @discussion For CMPs that don't support GPP, constructs "DBABMA~[tcString]"
 */
- (nullable NSString *)resolveGppString;

/**
 * @brief Resolves GPP SID for bid requests, constructing from legacy TCF if needed
 * @return GPP SID array from CMP or [2] when constructing from legacy TCF
 * @discussion Returns [2] when GPP is constructed from legacy TCF (EU TCF section only)
 */
- (nullable NSArray<NSNumber *> *)resolveGppSid;

@end

/**
 * @brief GPP header for constructing GPP string from legacy TCF only
 * @discussion "DBABMA" indicates only Section 2 (TCF EU v2) is present
 */
extern NSString * const kGPPHeaderTcfEuOnly;

/**
 * @brief GPP Section ID for EU TCF v2 (GDPR)
 */
extern NSInteger const kGPPSidEuTcf;

NS_ASSUME_NONNULL_END
