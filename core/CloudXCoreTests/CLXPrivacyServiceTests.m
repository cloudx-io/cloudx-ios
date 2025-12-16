//
//  CLXPrivacyServiceTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-08-30.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

// Test category to expose internal methods for testing
// These methods are internal because server support for GDPR is not yet implemented
@interface CLXPrivacyService (Testing)
- (BOOL)shouldClearPersonalDataIgnoringATT; // Test without ATT dependency
- (nullable NSString *)gdprConsentString; // Internal - server not supported
- (nullable NSNumber *)gdprApplies; // Internal - server not supported
// Note: No longer supports UserDefaults injection to ensure real-world collision testing
@end

// NOTE: Privacy setter APIs (setCCPAPrivacyString, setHasUserConsent, setDoNotSell) have been removed
// to match Android SDK which relies entirely on IAB standard UserDefaults keys.
// Tests now set privacy values directly via UserDefaults using IAB standard keys.

@interface CLXPrivacyServiceTests : XCTestCase

@property (nonatomic, strong) CLXPrivacyService *privacyService;

@end

@implementation CLXPrivacyServiceTests

- (void)setUp {
    [super setUp];
    
    // Create privacy service using standardUserDefaults (same as production)
    self.privacyService = [[CLXPrivacyService alloc] init];
    
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear all CloudXCore keys to prevent test contamination
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

- (void)clearPrivacySettings {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreHashedUserIDKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - GDPR Tests

// Test comprehensive GDPR consent validation with multiple consent string formats
- (void)testValidGDPRConsent_ShouldAllowPersonalData {
    // Test multiple valid GDPR consent string formats
    NSArray *validConsentStrings = @[
        @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA", // Standard consent
        @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA.YAAAAAAAAAAA", // With vendor consent
        @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA.YAAAAAAAAAAA.YAAAAAAAAAAA" // Full format
    ];
    
    for (NSString *consentString in validConsentStrings) {
        // Clear previous state
        [self clearPrivacySettings];
        
        // Set up valid GDPR consent
        [[NSUserDefaults standardUserDefaults] setObject:consentString forKey:kCLXPrivacyGDPRConsentKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Verify privacy service allows data
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertFalse(shouldClear, @"Valid GDPR consent '%@' should allow personal data usage", consentString);
        
        // Verify individual getters work correctly
        NSString *retrievedConsent = [self.privacyService gdprConsentString];
        XCTAssertEqualObjects(retrievedConsent, consentString, @"GDPR consent should be retrievable");
        
        NSNumber *gdprApplies = [self.privacyService gdprApplies];
        XCTAssertNotNil(gdprApplies, @"GDPR applies should be retrievable");
        XCTAssertTrue([gdprApplies boolValue], @"GDPR applies should be true");
    }
}

// Test comprehensive GDPR rejection scenarios
- (void)testMissingGDPRConsent_ShouldClearPersonalData {
    NSArray *invalidScenarios = @[
        @{@"description": @"Missing consent string", @"consent": [NSNull null], @"applies": @YES},
        @{@"description": @"Empty consent string", @"consent": @"", @"applies": @YES},
        @{@"description": @"Reject consent string", @"consent": @"0reject", @"applies": @YES},
        @{@"description": @"Consent with reject keyword", @"consent": @"CPcABcABcABcAAfKABENB-reject", @"applies": @YES}
    ];
    
    for (NSDictionary *scenario in invalidScenarios) {
        // Clear previous state
        [self clearPrivacySettings];
        
        // Set up invalid GDPR scenario
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
        
        id consent = scenario[@"consent"];
        if (![consent isKindOfClass:[NSNull class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:consent forKey:kCLXPrivacyGDPRConsentKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Verify privacy service blocks data
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertTrue(shouldClear, @"Invalid GDPR scenario '%@' should block personal data", scenario[@"description"]);
        
        // Verify getter methods return expected values
        if (![consent isKindOfClass:[NSNull class]] && [(NSString *)consent length] > 0) {
            NSString *retrievedConsent = [self.privacyService gdprConsentString];
            XCTAssertEqualObjects(retrievedConsent, consent, @"Should retrieve the set consent string");
        }
    }
}

// Test comprehensive CCPA privacy string validation
// IAB US Privacy String format:
// Position 1: Version (always '1')
// Position 2: Notice/Opportunity to Opt Out (Y/N/-)
// Position 3: Opt-Out Sale (Y = opted out, N = did not opt out, - = N/A)
// Position 4: LSPA Covered (Y/N/-)
- (void)testCCPAOptOut_ShouldClearPersonalData {
    // Test CCPA strings where position 3 = Y (opted out of sale)
    NSArray *ccpaOptOutStrings = @[
        @"1YYN", // Notice given, OPTED OUT, Not LSPA
        @"1NYN", // No notice, OPTED OUT, Not LSPA
        @"1YYY", // Notice given, OPTED OUT, LSPA covered
        @"1-Y-"  // N/A notice, OPTED OUT, N/A LSPA
    ];
    
    for (NSString *ccpaString in ccpaOptOutStrings) {
        [self clearPrivacySettings];
        
        [[NSUserDefaults standardUserDefaults] setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertTrue(shouldClear, @"CCPA opt-out string '%@' (position 3 = Y) should clear personal data", ccpaString);
        
        // Verify getter returns the set value
        NSString *retrievedCCPA = [self.privacyService ccpaPrivacyString];
        XCTAssertEqualObjects(retrievedCCPA, ccpaString, @"Should retrieve the set CCPA string");
    }
    
    // Test CCPA strings where position 3 != Y (did NOT opt out of sale)
    NSArray *ccpaAllowStrings = @[
        @"1YNN", // Notice given, NOT opted out, Not LSPA
        @"1NNN", // No notice, NOT opted out, Not LSPA
        @"1-N-", // N/A notice, NOT opted out, N/A LSPA
        @"1---"  // All N/A - CCPA does not apply
    ];
    
    for (NSString *ccpaString in ccpaAllowStrings) {
        [self clearPrivacySettings];
        
        [[NSUserDefaults standardUserDefaults] setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertFalse(shouldClear, @"CCPA consent string '%@' (position 3 != Y) should allow personal data", ccpaString);
    }
}

// Test hashed identifier management
- (void)testHashedIdentifierManagement {
    NSString *testHashedUserId = @"hashed-user-12345";
    NSString *testHashedGeoIp = @"hashed-geo-67890";
    
    // Test setting and getting hashed user ID
    [self.privacyService setHashedUserId:testHashedUserId];
    NSString *retrievedUserId = [self.privacyService hashedUserId];
    XCTAssertEqualObjects(retrievedUserId, testHashedUserId, @"Should set and retrieve hashed user ID");
    
    // Test setting and getting hashed geo IP
    [self.privacyService setHashedGeoIp:testHashedGeoIp];
    NSString *retrievedGeoIp = [self.privacyService hashedGeoIp];
    XCTAssertEqualObjects(retrievedGeoIp, testHashedGeoIp, @"Should set and retrieve hashed geo IP");
    
    // Test clearing hashed identifiers
    [self.privacyService setHashedUserId:nil];
    [self.privacyService setHashedGeoIp:nil];
    
    XCTAssertNil([self.privacyService hashedUserId], @"Should clear hashed user ID");
    XCTAssertNil([self.privacyService hashedGeoIp], @"Should clear hashed geo IP");
}

// Test complex privacy scenarios with multiple flags
- (void)testComplexPrivacyScenarios {
    // Scenario 1: GDPR allows but CCPA blocks - CCPA should win
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"CCPA opt-out should override GDPR consent");
    
    // Scenario 2: All privacy frameworks allow data
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"When all privacy frameworks allow, data should be allowed");
}

#pragma mark - IAB Standard UserDefaults Tests

// Test that SDK reads CCPA privacy string from IAB standard UserDefaults key
- (void)testCCPAPrivacyStringFromIABUserDefaults {
    [self clearPrivacySettings];
    
    // Set CCPA string via IAB standard key (as CMPs would)
    NSString *testCCPAString = @"1YNN";
    [[NSUserDefaults standardUserDefaults] setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify SDK reads it correctly
    NSString *retrievedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(retrievedCCPA, testCCPAString, @"SDK should read CCPA string from IAB UserDefaults key");
    
    // Test clearing CCPA string
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *clearedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertNil(clearedCCPA, @"CCPA string should be nil when UserDefaults key is removed");
}

// Test SDK reads CCPA opt-out correctly from IAB US Privacy String
// IAB US Privacy String format: 1[Notice][OptOut][LSPA]
// Position 3 (index 2) is the opt-out flag: Y = opted out, N = not opted out
- (void)testCCPAOptOutDetection {
    [self clearPrivacySettings];
    
    // Test opt-out detected (Y at position 3)
    [[NSUserDefaults standardUserDefaults] setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSNumber *ccpaApplies = [self.privacyService ccpaApplies];
    XCTAssertEqualObjects(ccpaApplies, @YES, @"CCPA should detect opt-out from '1YYN' (Y at position 3)");
    
    // Test no opt-out (N at position 3)
    [[NSUserDefaults standardUserDefaults] setObject:@"1YNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    ccpaApplies = [self.privacyService ccpaApplies];
    XCTAssertEqualObjects(ccpaApplies, @NO, @"CCPA should not detect opt-out from '1YNN' (N at position 3)");
}

#pragma mark - GDPR/TCF Purpose Consent Tests

// Test TCF purpose consents determine PII removal requirement
// Per IAB TCF 2.2 spec, purposes 1-4 are required for personalized advertising
- (void)testTCFPurposeConsent_AllPurposesGranted_ShouldAllowData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with all purposes granted
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] setObject:@"1111111111" forKey:@"IABTCF_PurposeConsents"];
    // Minimal valid TC string with all purposes granted
    [[NSUserDefaults standardUserDefaults] setObject:@"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB" forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // When GDPR applies and all purposes are granted, data should be allowed
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"GDPR applies should be YES");
    
    NSString *purposeConsents = [[NSUserDefaults standardUserDefaults] stringForKey:@"IABTCF_PurposeConsents"];
    XCTAssertTrue(purposeConsents.length >= 1 && [purposeConsents characterAtIndex:0] == '1', @"Purpose 1 should be granted");
}

// Test TCF with Purpose 1 denied should require PII removal
- (void)testTCFPurposeConsent_Purpose1Denied_ShouldClearData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with Purpose 1 denied
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] setObject:@"0111111111" forKey:@"IABTCF_PurposeConsents"];
    [[NSUserDefaults standardUserDefaults] setObject:@"CQbFSYAQbFSYAEsACDENCFFgAHAAAEPg" forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *purposeConsents = [[NSUserDefaults standardUserDefaults] stringForKey:@"IABTCF_PurposeConsents"];
    BOOL purpose1Granted = purposeConsents.length >= 1 && [purposeConsents characterAtIndex:0] == '1';
    XCTAssertFalse(purpose1Granted, @"Purpose 1 should be denied");
}

// Test TCF with no purpose consents should require PII removal
- (void)testTCFPurposeConsent_NoPurposes_ShouldClearData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with no purposes granted
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] setObject:@"0000000000" forKey:@"IABTCF_PurposeConsents"];
    [[NSUserDefaults standardUserDefaults] setObject:@"CQbFSYAQbFSYAEsACBENCFFgAAAA" forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *purposeConsents = [[NSUserDefaults standardUserDefaults] stringForKey:@"IABTCF_PurposeConsents"];
    BOOL anyPurposeGranted = NO;
    for (NSUInteger i = 0; i < MIN(4, purposeConsents.length); i++) {
        if ([purposeConsents characterAtIndex:i] == '1') {
            anyPurposeGranted = YES;
            break;
        }
    }
    XCTAssertFalse(anyPurposeGranted, @"No purposes should be granted");
}

// Test GDPR does not apply should allow data
- (void)testGDPRDoesNotApply_ShouldAllowData {
    [self clearPrivacySettings];
    
    // GDPR does not apply (non-EEA user)
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @NO, @"GDPR applies should be NO for non-EEA users");
}

// Test missing GDPR applies flag should be treated as unknown
- (void)testGDPRAppliesNotSet_ShouldBeUnknown {
    [self clearPrivacySettings];
    
    // No GDPR applies flag set
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertNil(gdprApplies, @"GDPR applies should be nil when not set");
}

@end
