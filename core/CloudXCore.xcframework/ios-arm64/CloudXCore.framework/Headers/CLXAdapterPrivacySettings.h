/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacySettings.h
 * @brief Model holding resolved privacy settings passed to adapter handlers
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXAdapterPrivacySettings
 * @brief Immutable snapshot of privacy settings for adapter consumption
 * @discussion All properties are nullable — nil means the value could not be determined.
 *             Adapters should use the manual fields (manualHasUserConsent / manualDoNotSell)
 *             because most ad SDKs auto-read IAB strings from NSUserDefaults — passing
 *             resolved values would double-signal consent.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterPrivacySettings : NSObject

/**
 * @brief Resolved GDPR user consent (nil = unknown, @YES = consented, @NO = not consented)
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *hasUserConsent;

/**
 * @brief Resolved CCPA do-not-sell (nil = unknown, @YES = do not sell, @NO = sale allowed)
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *doNotSell;

/**
 * @brief Raw publisher-set GDPR consent (nil = not set, @YES = consented, @NO = not consented)
 * @discussion Adapters should prefer this over hasUserConsent to avoid double-signaling.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *manualHasUserConsent;

/**
 * @brief Raw publisher-set CCPA do-not-sell (nil = not set, @YES = do not sell, @NO = sale allowed)
 * @discussion Adapters should prefer this over doNotSell to avoid double-signaling.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *manualDoNotSell;

/**
 * @brief Designated initializer with resolved and manual values
 */
- (instancetype)initWithHasUserConsent:(nullable NSNumber *)hasUserConsent
                             doNotSell:(nullable NSNumber *)doNotSell
                   manualHasUserConsent:(nullable NSNumber *)manualHasUserConsent
                         manualDoNotSell:(nullable NSNumber *)manualDoNotSell;

@end

NS_ASSUME_NONNULL_END
