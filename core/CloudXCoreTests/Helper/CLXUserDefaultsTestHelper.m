//
//  CLXUserDefaultsTestHelper.m
//  CloudXCoreTests
//
//  Shared utility for User Defaults test isolation
//

#import "CLXUserDefaultsTestHelper.h"
#import <CloudXCore/CLXUserDefaultsKeys.h>

@implementation CLXUserDefaultsTestHelper

+ (void)clearAllCloudXCoreUserDefaultsKeys {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Clear all prefixed keys that CloudXCore now uses
    NSArray<NSString *> *prefixedKeys = [self allPrefixedKeys];
    for (NSString *key in prefixedKeys) {
        [userDefaults removeObjectForKey:key];
    }
    
    // Clear any additional prefixed keys that specific components might use
    [userDefaults removeObjectForKey:kCLXBannerMetricsDictKey];
    [userDefaults removeObjectForKey:kCLXBannerUserKeyValueKey];
    
    // Clear privacy service keys
    [userDefaults removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [userDefaults removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [userDefaults removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [userDefaults removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
    [userDefaults removeObjectForKey:kCLXPrivacyHashedUserIdKey];
    [userDefaults removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    
    // Clear any other keys that might be used in migration tests
    [userDefaults removeObjectForKey:kCLXCoreIfaConfigKey];
    
    [userDefaults synchronize];
}

+ (NSArray<NSString *> *)allPrefixedKeys {
    // These are the ACTUAL keys CloudXCore now uses (from CLXUserDefaultsKeys.h)
    return @[
        kCLXCoreAppKeyKey,
        kCLXCoreSessionIDKey,
        kCLXCoreAccountIDKey,
        kCLXCoreEncodedStringKey,
        kCLXCoreMetricsDictKey,
        kCLXCoreUserKeyValueKey,
        kCLXCoreHashedUserIDKey,
        kCLXCoreHashedKeyKey,
        kCLXCoreHashedValueKey,
        kCLXCoreUserBidderKey,
        kCLXCoreUserBidderKeyKey,
        kCLXCoreUserBidderValueKey,
        kCLXCoreBundleConfigKey,
        kCLXCoreGeoHeadersKey,
        kCLXCoreIFAConfigKey,
        kCLXCoreAIPromptKey,
        kCLXCoreUserKeywordsKey,
        kCLXCoreEnableBannerRetriesKey,
        kCLXCoreEnableInterstitialRetriesKey,
        kCLXCoreEnableRewardedRetriesKey,
        kCLXCoreEnableNativeRetriesKey,
        kCLXCoreBannerAppKeyKey,
        kCLXCoreBannerSessionIDKey,
        kCLXCoreBannerMetricsDictKey,
        kCLXCoreBannerUserKeyValueKey,
        kCLXCoreCloudXInitURLKey
    ];
}

+ (NSArray<NSString *> *)allUnprefixedKeys {
    // These are the OLD keys CloudXCore used to use (for collision testing)
    return @[
        @"appKey",              // Line 342 in CloudXCoreAPI.m
        @"accId_config",        // Line 343 in CloudXCoreAPI.m
        @"sessionIDKey",        // Line 189 in CloudXCoreAPI.m
        @"metricsDict",         // Line 131, 191, 232, etc. in CloudXCoreAPI.m
        @"geoHeaders",          // Line 215 in CloudXCoreAPI.m
        @"encodedString",       // Line 255 in CloudXCoreAPI.m
        @"hashedUserID",        // Line 456 in CloudXCoreAPI.m
        @"hashedKey",           // Line 464 in CloudXCoreAPI.m
        @"hashedValue",         // Line 465 in CloudXCoreAPI.m
        @"userKeyValue",        // Line 483 in CloudXCoreAPI.m
        @"userBidder",          // Line 509 in CloudXCoreAPI.m
        @"userBidderKey",       // Line 510 in CloudXCoreAPI.m
        @"userBidderValue"      // Line 511 in CloudXCoreAPI.m
    ];
}

@end
