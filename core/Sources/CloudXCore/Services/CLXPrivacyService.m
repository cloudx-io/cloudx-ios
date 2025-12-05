/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyService.m
 * @brief Implementation of privacy service for CCPA and personal data protection
 * @discussion GDPR methods are temporarily internal until server support is added.
 */

#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXGeoLocationService.h>

// Private category for internal methods (not exposed in public header)
// GDPR methods are temporarily private because server-side support for GDPR is not implemented
@interface CLXPrivacyService ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

// Internal methods category - these are NOT in the public header
// ⚠️ Server does not support GDPR in bid requests yet
@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
- (BOOL)shouldClearPersonalDataIgnoringATT;
@end

@implementation CLXPrivacyService

+ (instancetype)sharedInstance {
    static CLXPrivacyService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXPrivacyService"];
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (BOOL)shouldClearPersonalData {
    // iOS ATT is the primary privacy control - platform-first approach
    if (![CLXAdTrackingService isIDFAAccessAllowed]) {
        [self.logger debug:@"iOS ATT not authorized - clearing personal data"];
        return YES;
    }
    
    // If ATT allows, check additional compliance requirements
    return [self shouldClearPersonalDataForCompliance];
}

- (BOOL)shouldClearPersonalDataForCompliance {
    CLXGeoLocationService *geoService = [CLXGeoLocationService shared];
    
    // EU users: Check GDPR consent
    if ([geoService isEUUser]) {
        return [self shouldClearPersonalDataForGDPR];
    }
    
    // US users: GPP consent evaluation based on geography
    if ([geoService isUSUser]) {
        CLXConsentProvider *gppProvider = [CLXConsentProvider sharedInstance];
        NSNumber *targetSid = [geoService isCaliforniaUser] ? @(CLXGppTargetUSCA) : @(CLXGppTargetUSNational);
        
        CLXPrivacyConsent *gppConsent = [gppProvider decodeGppForTarget:targetSid];
        if (gppConsent && [gppConsent requiresPiiRemoval]) {
            [self.logger debug:[NSString stringWithFormat:@"GPP consent (SID %@) requires PII removal - clearing personal data", targetSid]];
            return YES;
        }
        
        // Legacy CCPA string check for backward compatibility
        // IAB US Privacy String format: Position 3 (0-indexed: 2) is the opt-out flag
        // 1YYN = opted out (Y at position 2), 1YNN = not opted out (N at position 2)
        NSString *ccpaString = [self ccpaPrivacyString];
        if (ccpaString.length >= 3 && [ccpaString characterAtIndex:2] == 'Y') {
            [self.logger debug:@"Legacy CCPA opt-out detected (position 3 = Y) - clearing personal data"];
            return YES;
        }
    }
    
    [self.logger verbose:@"Personal data can be used (all compliance checks passed)"];
    return NO;
}

- (BOOL)shouldClearPersonalDataForGDPR {
    CLXConsentProvider *gppProvider = [CLXConsentProvider sharedInstance];
    
    // Priority 1: Check GPP Section 2 (EU TCF via GPP - new IAB standard)
    NSArray<NSNumber *> *gppSid = [gppProvider gppSid];
    if (gppSid && [gppSid containsObject:@(CLXGppTargetEUTCF)]) {
        CLXPrivacyConsent *tcfConsent = [gppProvider decodeGppForTarget:@(CLXGppTargetEUTCF)];
        if (tcfConsent) {
            BOOL requiresPiiRemoval = [tcfConsent requiresPiiRemoval];
            [self.logger debug:[NSString stringWithFormat:@"GPP EU TCF (SID 2) consent: requiresPiiRemoval=%@", @(requiresPiiRemoval)]];
            return requiresPiiRemoval;
        }
    }
    
    // Priority 2: Legacy TCF flow - for CMPs that don't support GPP yet
    NSNumber *gdprApplies = [gppProvider gdprApplies];
    
    // If GDPR doesn't apply, no restrictions
    if (!gdprApplies || ![gdprApplies boolValue]) {
        [self.logger debug:@"GDPR does not apply (legacy TCF) - no restrictions"];
        return NO;
    }
    
    // GDPR applies - decode the TC string
    NSString *tcString = [gppProvider tcString];
    if (!tcString || tcString.length == 0) {
        [self.logger debug:@"GDPR applies but no TC string - clearing personal data"];
        return YES;
    }
    
    // Decode TC string to check purpose and vendor consents
    CLXPrivacyConsent *tcfConsent = [gppProvider decodeTcString:tcString];
    if (!tcfConsent) {
        [self.logger debug:@"Failed to decode TC string - clearing personal data"];
        return YES;
    }
    
    BOOL requiresPiiRemoval = [tcfConsent requiresPiiRemoval];
    [self.logger debug:[NSString stringWithFormat:@"Legacy TCF consent: requiresPiiRemoval=%@", @(requiresPiiRemoval)]];
    return requiresPiiRemoval;
}

- (BOOL)shouldClearPersonalDataIgnoringATT {
    // INTERNAL METHOD: This method includes GDPR checks that are not yet supported by server in bid requests
    // Internal method includes comprehensive privacy checks - should not be exposed to publishers
    
    // Check GDPR consent (INTERNAL - server not supported yet)
    NSString *gdprConsent = [self gdprConsentString];
    NSNumber *gdprApplies = [self gdprApplies];
    
    if (gdprApplies && [gdprApplies boolValue]) {
        if (!gdprConsent || gdprConsent.length == 0) {
            [self.logger debug:@"GDPR applies but no consent string - clearing personal data"];
            return YES;
        }
        
        // Basic GDPR consent validation - in a real implementation, you'd parse the TC string
        if ([gdprConsent hasPrefix:@"0"] || [gdprConsent containsString:@"reject"]) {
            [self.logger debug:@"GDPR consent indicates rejection - clearing personal data"];
            return YES;
        }
    }
    
    // Check CCPA opt-out (PUBLIC - server supported)
    // IAB US Privacy String format: Position 3 (0-indexed: 2) is the opt-out flag
    NSString *ccpaString = [self ccpaPrivacyString];
    if (ccpaString.length >= 3 && [ccpaString characterAtIndex:2] == 'Y') {
        [self.logger debug:@"CCPA opt-out detected (position 3 = Y) - clearing personal data"];
        return YES;
    }
    
    [self.logger verbose:@"Personal data can be used (ignoring ATT)"];
    return NO;
}

#pragma mark - Public CCPA Methods (Server Supported)

- (nullable NSString *)ccpaPrivacyString {
    NSString *ccpa = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyCCPAPrivacyKey];
    [self.logger verbose:[NSString stringWithFormat:@"CCPA privacy: %@", ccpa ?: @"(none)"]];
    return ccpa;
}

- (nullable NSNumber *)ccpaApplies {
    // Check if CCPA privacy string indicates opt-out
    // IAB US Privacy String format: Position 3 (0-indexed: 2) is the opt-out flag
    NSString *ccpaString = [self ccpaPrivacyString];
    if (ccpaString.length >= 3 && [ccpaString characterAtIndex:2] == 'Y') {
        [self.logger debug:@"CCPA applies: YES (opt-out at position 3)"];
        return @YES;
    }
    [self.logger debug:@"CCPA applies: NO"];
    return @NO;
}

#pragma mark - Internal Privacy Methods (GDPR - Server Not Supported)

- (nullable NSString *)gdprConsentString {
    // INTERNAL ONLY: GDPR support not yet implemented on server
    // Including GDPR data in bid requests will cause 502 errors
    NSString *consent = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyGDPRConsentKey];
    [self.logger debug:[NSString stringWithFormat:@"GDPR consent (INTERNAL): %@", consent ?: @"(none)"]];
    return consent;
}

- (nullable NSNumber *)gdprApplies {
    // INTERNAL ONLY: GDPR support not yet implemented on server
    // Including GDPR data in bid requests will cause 502 errors
    NSUserDefaults *defaults = self.userDefaults;
    if ([defaults objectForKey:kCLXPrivacyGDPRAppliesKey]) {
        // IAB TCF spec requires integer: 0 = does not apply, 1 = applies
        NSInteger gdprValue = [defaults integerForKey:kCLXPrivacyGDPRAppliesKey];
        if (gdprValue == 0 || gdprValue == 1) {
            NSNumber *applies = @(gdprValue);
            [self.logger debug:[NSString stringWithFormat:@"GDPR applies (INTERNAL): %@", applies]];
            return applies;
        }
        [self.logger warn:[NSString stringWithFormat:@"GDPR applies has invalid value: %ld (expected 0 or 1)", (long)gdprValue]];
    }
    [self.logger debug:@"GDPR applies (INTERNAL): (unknown)"];
    return nil;
}

- (nullable NSString *)hashedUserId {
    NSString *hashedId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyHashedUserIdKey];
    [self.logger debug:[NSString stringWithFormat:@"Hashed user ID: %@", hashedId ? @"(present)" : @"(none)"]];
    return hashedId;
}

- (void)setHashedUserId:(nullable NSString *)hashedUserId {
    [self.logger debug:[NSString stringWithFormat:@"Setting hashed user ID: %@", hashedUserId ? @"(present)" : @"(none)"]];
    if (hashedUserId) {
        [[NSUserDefaults standardUserDefaults] setObject:hashedUserId forKey:kCLXPrivacyHashedUserIdKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedUserIdKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSString *)hashedGeoIp {
    NSString *hashedGeoIp = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyHashedGeoIpKey];
    [self.logger debug:[NSString stringWithFormat:@"Hashed geo IP: %@", hashedGeoIp ? @"(present)" : @"(none)"]];
    return hashedGeoIp;
}

- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp {
    [self.logger debug:[NSString stringWithFormat:@"Setting hashed geo IP: %@", hashedGeoIp ? @"(present)" : @"(none)"]];
    if (hashedGeoIp) {
        [[NSUserDefaults standardUserDefaults] setObject:hashedGeoIp forKey:kCLXPrivacyHashedGeoIpKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Public Privacy Setters

- (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString {
    [self.logger debug:[NSString stringWithFormat:@"Setting CCPA privacy string: %@", ccpaPrivacyString ?: @"(cleared)"]];
    if (ccpaPrivacyString) {
        [[NSUserDefaults standardUserDefaults] setObject:ccpaPrivacyString forKey:kCLXPrivacyCCPAPrivacyKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setHasUserConsent:(nullable NSNumber *)hasUserConsent {
    [self.logger debug:[NSString stringWithFormat:@"Setting GDPR consent: %@", hasUserConsent ? (hasUserConsent.boolValue ? @"YES" : @"NO") : @"(cleared)"]];
    if (hasUserConsent) {
        // IAB TCF spec requires integer: 0 = does not apply, 1 = applies
        NSInteger gdprValue = [hasUserConsent boolValue] ? 1 : 0;
        [[NSUserDefaults standardUserDefaults] setInteger:gdprValue forKey:kCLXPrivacyGDPRAppliesKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDoNotSell:(nullable NSNumber *)doNotSell {
    // Convert boolean to CCPA string format
    // IAB US Privacy String: "1" + Notice + OptOut + LSPA
    // Position 1: Version (always 1)
    // Position 2: Notice given (Y = yes, N = no)
    // Position 3: Opt-out of sale (Y = opted out, N = did not opt out)
    // Position 4: LSPA covered (N = no)
    NSString *ccpaString = nil;
    if (doNotSell) {
        // 1YYN = Notice given, user OPTED OUT of sale
        // 1YNN = Notice given, user did NOT opt out
        ccpaString = doNotSell.boolValue ? @"1YYN" : @"1YNN";
    }
    [self.logger debug:[NSString stringWithFormat:@"Setting do not sell: %@ (CCPA: %@)", doNotSell ? (doNotSell.boolValue ? @"YES" : @"NO") : @"(cleared)", ccpaString ?: @"(cleared)"]];
    [self setCCPAPrivacyString:ccpaString];
}

#pragma mark - GPP Methods

- (nullable NSString *)gppString {
    NSString *gppString = [[CLXConsentProvider sharedInstance] gppString];
    [self.logger verbose:[NSString stringWithFormat:@"GPP string: %@", gppString ?: @"(none)"]];
    return gppString;
}

- (nullable NSArray<NSNumber *> *)gppSid {
    NSArray<NSNumber *> *gppSid = [[CLXConsentProvider sharedInstance] gppSid];
    [self.logger debug:[NSString stringWithFormat:@"GPP SID: %@", gppSid ?: @"(none)"]];
    return gppSid;
}

#pragma mark - Publisher GPP API

- (void)setGppString:(NSString *)gppString {
    [[CLXConsentProvider sharedInstance] setGppString:gppString];
    if (gppString) {
        [self.logger info:[NSString stringWithFormat:@"GPP string set: %@", gppString]];
    } else {
        [self.logger info:@"GPP string cleared"];
    }
}

- (void)setGppSid:(NSArray<NSNumber *> *)gppSid {
    [[CLXConsentProvider sharedInstance] setGppSid:gppSid];
    if (gppSid && gppSid.count > 0) {
        [self.logger info:[NSString stringWithFormat:@"GPP SID set: %@", gppSid]];
    } else {
        [self.logger info:@"GPP SID cleared"];
    }
}

@end
