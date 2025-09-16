/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyService.m
 * @brief Implementation of privacy service for CCPA and personal data protection
 * @discussion GDPR methods are temporarily internal until server support is added. COPPA data clearing is implemented but not sent to server.
 */

#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXGPPProvider.h>
#import <CloudXCore/CLXGeoLocationService.h>

// Private category for internal methods (not exposed in public header)
// These methods are temporarily private because server-side support for GDPR/CCPA is not implemented
@interface CLXPrivacyService ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

// Internal methods category - these are NOT in the public header
// ⚠️ Server does not support GDPR or COPPA in bid requests yet - COPPA data clearing is implemented
@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
- (nullable NSNumber *)coppaApplies;
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
        [self.logger debug:@"🔒 [CLXPrivacyService] iOS ATT not authorized - clearing personal data"];
        return YES;
    }
    
    // If ATT allows, check additional compliance requirements
    return [self shouldClearPersonalDataForCompliance];
}

- (BOOL)shouldClearPersonalDataForCompliance {
    CLXGeoLocationService *geoService = [CLXGeoLocationService shared];
    
    // Non-US users: no additional restrictions (matching Android)
    if (![geoService isUSUser]) {
        [self.logger debug:@"✅ [CLXPrivacyService] Non-US user - no additional restrictions"];
        return NO;
    }
    
    // US users: COPPA always takes precedence (matching Android)
    if ([self isCoppaEnabled]) {
        [self.logger debug:@"🔒 [CLXPrivacyService] COPPA enabled for US user - clearing personal data"];
        return YES;
    }
    
    // US users: GPP consent evaluation based on geography (matching Android)
    CLXGPPProvider *gppProvider = [CLXGPPProvider sharedInstance];
    NSNumber *targetSid = [geoService isCaliforniaUser] ? @(CLXGppTargetUSCA) : @(CLXGppTargetUSNational);
    
    CLXGppConsent *gppConsent = [gppProvider decodeGppForTarget:targetSid];
    if (gppConsent && [gppConsent requiresPiiRemoval]) {
        [self.logger debug:[NSString stringWithFormat:@"🔒 [CLXPrivacyService] GPP consent (SID %@) requires PII removal - clearing personal data", targetSid]];
        return YES;
    }
    
    // Legacy CCPA string check for backward compatibility
    NSString *ccpaString = [self ccpaPrivacyString];
    if (ccpaString && [ccpaString containsString:@"Y"]) {
        [self.logger debug:@"🔒 [CLXPrivacyService] Legacy CCPA opt-out detected - clearing personal data"];
        return YES;
    }
    
    [self.logger debug:@"✅ [CLXPrivacyService] Personal data can be used (all compliance checks passed)"];
    return NO;
}

- (BOOL)shouldClearPersonalDataIgnoringATT {
    // ⚠️ INTERNAL METHOD: This method includes GDPR/COPPA checks that are not yet supported by server in bid requests
    // Internal method includes comprehensive privacy checks - should not be exposed to publishers
    
    // Check GDPR consent (INTERNAL - server not supported yet)
    NSString *gdprConsent = [self gdprConsentString];
    NSNumber *gdprApplies = [self gdprApplies];
    
    if (gdprApplies && [gdprApplies boolValue]) {
        if (!gdprConsent || gdprConsent.length == 0) {
            [self.logger debug:@"🔒 [CLXPrivacyService] GDPR applies but no consent string - clearing personal data"];
            return YES;
        }
        
        // Basic GDPR consent validation - in a real implementation, you'd parse the TC string
        if ([gdprConsent hasPrefix:@"0"] || [gdprConsent containsString:@"reject"]) {
            [self.logger debug:@"🔒 [CLXPrivacyService] GDPR consent indicates rejection - clearing personal data"];
            return YES;
        }
    }
    
    // Check CCPA opt-out (PUBLIC - server supported)
    NSString *ccpaString = [self ccpaPrivacyString];
    if (ccpaString && [ccpaString containsString:@"Y"]) {
        [self.logger debug:@"🔒 [CLXPrivacyService] CCPA opt-out detected - clearing personal data"];
        return YES;
    }
    
    // Check COPPA (INTERNAL - server not supported yet)
    NSNumber *coppaApplies = [self coppaApplies];
    if (coppaApplies && [coppaApplies boolValue]) {
        [self.logger debug:@"🔒 [CLXPrivacyService] COPPA applies - clearing personal data"];
        return YES;
    }
    
    [self.logger debug:@"✅ [CLXPrivacyService] Personal data can be used (ignoring ATT)"];
    return NO;
}

#pragma mark - Public CCPA Methods (Server Supported)

- (nullable NSString *)ccpaPrivacyString {
    NSString *ccpa = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyCCPAPrivacyKey];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] CCPA privacy: %@", ccpa ?: @"(none)"]];
    return ccpa;
}

- (nullable NSNumber *)ccpaApplies {
    // Check if CCPA privacy string indicates opt-out
    NSString *ccpaString = [self ccpaPrivacyString];
    if (ccpaString && [ccpaString containsString:@"Y"]) {
        [self.logger debug:@"📊 [CLXPrivacyService] CCPA applies: YES (opt-out detected)"];
        return @YES;
    }
    [self.logger debug:@"📊 [CLXPrivacyService] CCPA applies: NO"];
    return @NO;
}

#pragma mark - Internal Privacy Methods (GDPR/COPPA - Server Not Supported)

- (nullable NSString *)gdprConsentString {
    // ⚠️ INTERNAL ONLY: GDPR support not yet implemented on server
    // Including GDPR data in bid requests will cause 502 errors
    NSString *consent = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyGDPRConsentKey];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] GDPR consent (INTERNAL): %@", consent ?: @"(none)"]];
    return consent;
}

- (nullable NSNumber *)gdprApplies {
    // ⚠️ INTERNAL ONLY: GDPR support not yet implemented on server
    // Including GDPR data in bid requests will cause 502 errors
    NSUserDefaults *defaults = self.userDefaults;
    if ([defaults objectForKey:kCLXPrivacyGDPRAppliesKey]) {
        NSNumber *applies = @([defaults boolForKey:kCLXPrivacyGDPRAppliesKey]);
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] GDPR applies (INTERNAL): %@", applies]];
        return applies;
    }
    [self.logger debug:@"📊 [CLXPrivacyService] GDPR applies (INTERNAL): (unknown)"];
    return nil;
}

- (nullable NSNumber *)coppaApplies {
    // ⚠️ INTERNAL ONLY: COPPA support not yet implemented on server
    // Including COPPA data in bid requests will cause 502 errors
    NSUserDefaults *defaults = self.userDefaults;
    if ([defaults objectForKey:kCLXPrivacyCOPPAAppliesKey]) {
        NSNumber *applies = @([defaults boolForKey:kCLXPrivacyCOPPAAppliesKey]);
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] COPPA applies (INTERNAL): %@", applies]];
        return applies;
    }
    [self.logger debug:@"📊 [CLXPrivacyService] COPPA applies (INTERNAL): (unknown)"];
    return nil;
}

- (nullable NSString *)hashedUserId {
    NSString *hashedId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyHashedUserIdKey];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] Hashed user ID: %@", hashedId ? @"(present)" : @"(none)"]];
    return hashedId;
}

- (void)setHashedUserId:(nullable NSString *)hashedUserId {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting hashed user ID: %@", hashedUserId ? @"(present)" : @"(none)"]];
    if (hashedUserId) {
        [[NSUserDefaults standardUserDefaults] setObject:hashedUserId forKey:kCLXPrivacyHashedUserIdKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedUserIdKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSString *)hashedGeoIp {
    NSString *hashedGeoIp = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyHashedGeoIpKey];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] Hashed geo IP: %@", hashedGeoIp ? @"(present)" : @"(none)"]];
    return hashedGeoIp;
}

- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting hashed geo IP: %@", hashedGeoIp ? @"(present)" : @"(none)"]];
    if (hashedGeoIp) {
        [[NSUserDefaults standardUserDefaults] setObject:hashedGeoIp forKey:kCLXPrivacyHashedGeoIpKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Public Privacy Setters

- (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting CCPA privacy string: %@", ccpaPrivacyString ?: @"(cleared)"]];
    if (ccpaPrivacyString) {
        [[NSUserDefaults standardUserDefaults] setObject:ccpaPrivacyString forKey:kCLXPrivacyCCPAPrivacyKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setHasUserConsent:(nullable NSNumber *)hasUserConsent {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting GDPR consent: %@", hasUserConsent ? (hasUserConsent.boolValue ? @"YES" : @"NO") : @"(cleared)"]];
    if (hasUserConsent) {
        [[NSUserDefaults standardUserDefaults] setBool:[hasUserConsent boolValue] forKey:kCLXPrivacyGDPRAppliesKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIsAgeRestrictedUser:(nullable NSNumber *)isAgeRestrictedUser {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting COPPA flag: %@", isAgeRestrictedUser ? (isAgeRestrictedUser.boolValue ? @"YES" : @"NO") : @"(cleared)"]];
    if (isAgeRestrictedUser) {
        [[NSUserDefaults standardUserDefaults] setBool:[isAgeRestrictedUser boolValue] forKey:kCLXPrivacyCOPPAAppliesKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDoNotSell:(nullable NSNumber *)doNotSell {
    // Convert boolean to CCPA string format
    NSString *ccpaString = nil;
    if (doNotSell) {
        // CCPA string format: "1YNN" = opt-out, "1NNN" = no opt-out
        ccpaString = doNotSell.boolValue ? @"1YNN" : @"1NNN";
    }
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] Setting do not sell: %@ (CCPA: %@)", doNotSell ? (doNotSell.boolValue ? @"YES" : @"NO") : @"(cleared)", ccpaString ?: @"(cleared)"]];
    [self setCCPAPrivacyString:ccpaString];
}

#pragma mark - GPP Methods

- (nullable NSString *)gppString {
    NSString *gppString = [[CLXGPPProvider sharedInstance] gppString];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] GPP string: %@", gppString ?: @"(none)"]];
    return gppString;
}

- (nullable NSArray<NSNumber *> *)gppSid {
    NSArray<NSNumber *> *gppSid = [[CLXGPPProvider sharedInstance] gppSid];
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXPrivacyService] GPP SID: %@", gppSid ?: @"(none)"]];
    return gppSid;
}

#pragma mark - Publisher GPP API

- (void)setGppString:(NSString *)gppString {
    [[CLXGPPProvider sharedInstance] setGppString:gppString];
    if (gppString) {
        [self.logger info:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] GPP string set: %@", gppString]];
    } else {
        [self.logger info:@"🔧 [CLXPrivacyService] GPP string cleared"];
    }
}

- (void)setGppSid:(NSArray<NSNumber *> *)gppSid {
    [[CLXGPPProvider sharedInstance] setGppSid:gppSid];
    if (gppSid && gppSid.count > 0) {
        [self.logger info:[NSString stringWithFormat:@"🔧 [CLXPrivacyService] GPP SID set: %@", gppSid]];
    } else {
        [self.logger info:@"🔧 [CLXPrivacyService] GPP SID cleared"];
    }
}


- (BOOL)isCoppaEnabled {
    NSNumber *coppaApplies = [self coppaApplies];
    return coppaApplies && [coppaApplies boolValue];
}

@end
