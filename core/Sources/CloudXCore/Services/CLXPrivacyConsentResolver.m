/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXPrivacyConsentResolver.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXPrivacyConsent.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXPrivacyConsentResolver

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXPrivacyConsentResolver"];
    });
    return logger;
}

+ (nullable NSNumber *)resolveIabGdprConsent:(CLXConsentProvider *)provider {
    // Priority 1: GPP SID 2 (EU TCF via GPP)
    NSArray<NSNumber *> *gppSid = [provider gppSid];
    if (gppSid && [gppSid containsObject:@(2)]) {
        CLXPrivacyConsent *consent = [provider decodeGppForTarget:@(2)];
        if (consent) {
            BOOL consented = ![consent requiresPiiRemoval];
            [[self logger] debug:[NSString stringWithFormat:@"GDPR consent resolved from GPP SID 2: %@", @(consented)]];
            return @(consented);
        }
    }

    // Priority 2: Legacy TCF consent string
    NSString *tcString = [provider tcString];
    if (tcString.length > 0) {
        NSNumber *gdprApplies = [provider gdprApplies];
        if (gdprApplies && [gdprApplies boolValue]) {
            CLXPrivacyConsent *consent = [provider decodeTcString:tcString];
            if (consent) {
                BOOL consented = ![consent requiresPiiRemoval];
                [[self logger] debug:[NSString stringWithFormat:@"GDPR consent resolved from legacy TCF: %@", @(consented)]];
                return @(consented);
            }
        }
    }

    return nil;
}

+ (nullable NSNumber *)resolveIabUsPrivacyDoNotSell:(NSUserDefaults *)userDefaults {
    NSString *usPrivacy = [userDefaults stringForKey:@"IABUSPrivacy_String"];
    if (usPrivacy.length >= 3) {
        unichar saleOptOut = [usPrivacy characterAtIndex:2];
        if (saleOptOut == 'Y' || saleOptOut == 'y') {
            [[self logger] debug:@"Do-not-sell resolved from legacy CCPA string: YES"];
            return @YES;
        }
        if (saleOptOut == 'N' || saleOptOut == 'n') {
            [[self logger] debug:@"Do-not-sell resolved from legacy CCPA string: NO"];
            return @NO;
        }
    }
    return nil;
}

@end
