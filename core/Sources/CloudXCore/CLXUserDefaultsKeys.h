/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXUserDefaultsKeys.h
 * @brief Constants for User Defaults keys to prevent collisions
 * @details Centralized User Defaults key definitions with CLXCore_ prefix
 * to prevent collisions with other SDKs or host applications.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Core SDK User Defaults keys with CLXCore_ prefix
 * @discussion These keys replace the previous unprefixed keys to prevent
 * collisions with other SDKs or host applications.
 */

// Core SDK session and configuration keys
#define kCLXCoreAppKeyKey @"CLXCore_appKey"
#define kCLXCoreSessionIDKey @"CLXCore_sessionIDKey"
#define kCLXCoreAccountIDKey @"CLXCore_accId_config"
#define kCLXCoreEncodedStringKey @"CLXCore_encodedString"

// Metrics and analytics keys
#define kCLXCoreMetricsDictKey @"CLXCore_metricsDict"
#define kCLXCoreMetricsUrlKey @"CLXCore_metricsUrl"
#define kCLXCoreImpressionTrackerUrlKey @"CLXCore_impressionTrackerUrl"

// User data keys
#define kCLXCoreUserKeyValueKey @"CLXCore_userKeyValue"
#define kCLXCoreHashedUserIDKey @"CLXCore_hashedUserID"
#define kCLXCoreHashedKeyKey @"CLXCore_hashedKey"
#define kCLXCoreHashedValueKey @"CLXCore_hashedValue"

// Bidder data keys
#define kCLXCoreUserBidderKey @"CLXCore_userBidder"
#define kCLXCoreUserBidderKeyKey @"CLXCore_userBidderKey"
#define kCLXCoreUserBidderValueKey @"CLXCore_userBidderValue"

// Additional configuration keys
#define kCLXCoreBundleConfigKey @"CLXCore_bundle_config"
#define kCLXCoreGeoHeadersKey @"CLXCore_geoHeaders"
#define kCLXCoreIFAConfigKey @"CLXCore_ifa_config"
#define kCLXCoreAIPromptKey @"CLXCore_aiPrompt"
#define kCLXCoreUserKeywordsKey @"CLXCore_userKeywords"

// Settings keys
#define kCLXCoreEnableBannerRetriesKey @"CLXCore_EnableBannerRetries"
#define kCLXCoreEnableInterstitialRetriesKey @"CLXCore_EnableInterstitialRetries"
#define kCLXCoreEnableRewardedRetriesKey @"CLXCore_EnableRewardedRetries"
#define kCLXCoreEnableNativeRetriesKey @"CLXCore_EnableNativeRetries"

// Banner-specific keys
#define kCLXCoreBannerAppKeyKey @"CLXCore_Banner_appKey"
#define kCLXCoreBannerSessionIDKey @"CLXCore_Banner_sessionIDKey"
#define kCLXCoreBannerMetricsDictKey @"CLXCore_Banner_metricsDict"
#define kCLXCoreBannerUserKeyValueKey @"CLXCore_Banner_userKeyValue"

// Debug/Development keys
#define kCLXCoreCloudXInitURLKey @"CLXCore_CloudXInitURL"

// Test and lifecycle keys
#define kCLXCoreCurrentStateKey @"CLXCore_currentState"
#define kCLXCoreReportingServiceKey @"CLXCore_reportingService"
#define kCLXCoreCampaignIdKey @"CLXCore_campaignId"

// Banner-specific additional keys
#define kCLXBannerMetricsDictKey @"CLXBanner_metricsDict"
#define kCLXBannerUserKeyValueKey @"CLXBanner_userKeyValue"

// Network and tracking keys (UserDefaults keys only)
#define kCLXCoreDeviceKey @"CLXCore_device"
#define kCLXCoreDntKey @"CLXCore_dnt"
#define kCLXCoreUserAgentValueKey @"CLXCore_userAgent"

// Additional configuration keys
#define kCLXCoreIfaConfigKey @"CLXCore_ifa_config"

// Privacy service keys (already properly prefixed)
#define kCLXPrivacyGDPRConsentKey @"CLXPrivacyGDPRConsent"
#define kCLXPrivacyCCPAPrivacyKey @"CLXPrivacyCCPAPrivacy"
#define kCLXPrivacyGDPRAppliesKey @"CLXPrivacyGDPRApplies"
#define kCLXPrivacyCOPPAAppliesKey @"CLXPrivacyCOPPAApplies"
#define kCLXPrivacyHashedUserIdKey @"CLXPrivacy_hashedUserID"
#define kCLXPrivacyHashedGeoIpKey @"CLXPrivacyHashedGeoIp"


NS_ASSUME_NONNULL_END
