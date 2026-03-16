/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyConsentResolver.h
 * @brief Shared IAB consent resolution used by both CLXPrivacyService and CLXAdapterPrivacyForwarder.
 * @details Returns nil when no relevant IAB data is available, allowing callers to fall back
 *          to manual flags or defaults as appropriate.
 */

#import <Foundation/Foundation.h>

@class CLXConsentProvider;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXPrivacyConsentResolver
 * @brief Stateless utility that resolves privacy consent from IAB signals only
 */
@interface CLXPrivacyConsentResolver : NSObject

/**
 * @brief Resolves GDPR consent from IAB signals: GPP SID 2 -> legacy TCF.
 * @param provider The consent provider (GPP/TCF)
 * @return @YES if consented, @NO if denied, nil if no IAB GDPR data available
 */
+ (nullable NSNumber *)resolveIabGdprConsent:(CLXConsentProvider *)provider;

/**
 * @brief Resolves do-not-sell from the legacy US Privacy string (IABUSPrivacy_String).
 * @param userDefaults The user defaults to read IABUSPrivacy_String from
 * @return @YES if opted out, @NO if not, nil if no legacy string available
 * @discussion Format: "1[Notice][OptOutSale][LSPA]" — character at index 2 is sale opt-out.
 */
+ (nullable NSNumber *)resolveIabUsPrivacyDoNotSell:(NSUserDefaults *)userDefaults;

@end

NS_ASSUME_NONNULL_END
