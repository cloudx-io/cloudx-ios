/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXManualPrivacyState.h
 * @brief In-memory holder for publisher-set manual privacy consent values
 * @details Stores nullable boxed BOOLs for hasUserConsent and doNotSell,
 *          allowing publishers to override CMP-derived consent via the public API.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXManualPrivacyState
 * @brief Singleton holding manual privacy consent values set by the publisher
 * @discussion Publishers call CloudXCore.setHasUserConsent / setDoNotSell to set these.
 *             Tri-state: nil = not set (defer to CMP), @YES / @NO = explicit publisher override.
 */
@interface CLXManualPrivacyState : NSObject

/**
 * @brief Shared singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief Publisher-set GDPR consent override
 * @discussion nil = not set (use CMP), @YES = user consented, @NO = user did not consent
 */
@property (atomic, strong, nullable) NSNumber *hasUserConsent;

/**
 * @brief Publisher-set do-not-sell override (CCPA)
 * @discussion nil = not set (use CMP), @YES = do not sell, @NO = sale allowed
 */
@property (atomic, strong, nullable) NSNumber *doNotSell;

/**
 * @brief Clears all manual privacy state (called on SDK shutdown)
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
