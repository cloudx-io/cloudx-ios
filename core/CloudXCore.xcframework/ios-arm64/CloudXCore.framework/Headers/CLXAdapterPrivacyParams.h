/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacyParams.h
 * @brief Model holding resolved privacy params passed to adapter handlers
 */

#import <CloudXCore/CLXAdapterParams.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXAdapterPrivacyParams
 * @brief Immutable snapshot of privacy params for adapter consumption
 * @discussion Privacy values are nullable; nil means the value could not be determined.
 *             Adapters should use the manual fields (manualHasUserConsent / manualDoNotSell)
 *             when their SDK auto-reads IAB strings from NSUserDefaults to avoid double-signaling.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterPrivacyParams : CLXAdapterParams

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

@end

NS_ASSUME_NONNULL_END
