/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXGPPProvider.h
 * @brief GPP (Global Privacy Platform) provider service
 * @details Handles reading, parsing, and decoding GPP consent strings according to IAB specifications
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXGppConsent.h>

@class CLXErrorReporter;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief IAB GPP UserDefaults keys
 * @discussion Standard IAB keys for GPP framework integration
 */
extern NSString * const kIABGPP_GppString;
extern NSString * const kIABGPP_GppSID;

/**
 * @class CLXGPPProvider
 * @brief Service for GPP consent string parsing and management
 * @discussion Provides GPP framework integration with support for US-CA and US-National sections
 */
@interface CLXGPPProvider : NSObject

/**
 * @brief Shared instance of the GPP provider
 * @return The singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief Initializes GPP provider with dependency injection for error reporting
 * @param errorReporter Optional error reporter for exception tracking
 * @return An initialized CLXGPPProvider instance
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
- (nullable CLXGppConsent *)decodeGppForTarget:(nullable NSNumber *)target;

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

@end

NS_ASSUME_NONNULL_END
