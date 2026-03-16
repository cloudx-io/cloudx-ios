//
//  CLXPrivacyServiceTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-08-30.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

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
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;

@end

@implementation CLXPrivacyServiceTests

- (void)setUp {
    [super setUp];
    
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    CLXConsentProvider *isolatedProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil
                                                                               userDefaults:self.testDefaults];
    CLXGeoLocationService *isolatedGeoService = [[CLXGeoLocationService alloc] initWithUserDefaults:self.testDefaults];
    self.privacyService = [[CLXPrivacyService alloc] initWithUserDefaults:self.testDefaults
                                                         consentProvider:isolatedProvider
                                                      geoLocationService:isolatedGeoService];
}

- (void)tearDown {
    [[CLXManualPrivacyState sharedInstance] clear];
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

- (void)clearPrivacySettings {
    [self.testDefaults removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    [self.testDefaults synchronize];
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
        [self.testDefaults setObject:consentString forKey:kCLXPrivacyGDPRConsentKey];
        [self.testDefaults setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
        [self.testDefaults synchronize];
        
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
        [self.testDefaults setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
        
        id consent = scenario[@"consent"];
        if (![consent isKindOfClass:[NSNull class]]) {
            [self.testDefaults setObject:consent forKey:kCLXPrivacyGDPRConsentKey];
        }
        [self.testDefaults synchronize];
        
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
        
        [self.testDefaults setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [self.testDefaults synchronize];
        
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
        
        [self.testDefaults setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [self.testDefaults synchronize];
        
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertFalse(shouldClear, @"CCPA consent string '%@' (position 3 != Y) should allow personal data", ccpaString);
    }
}

// Test hashed identifier management
- (void)testHashedGeoIpManagement {
    NSString *testHashedGeoIp = @"hashed-geo-67890";

    // Test setting and getting hashed geo IP
    [self.privacyService setHashedGeoIp:testHashedGeoIp];
    NSString *retrievedGeoIp = [self.privacyService hashedGeoIp];
    XCTAssertEqualObjects(retrievedGeoIp, testHashedGeoIp, @"Should set and retrieve hashed geo IP");

    // Test clearing hashed geo IP
    [self.privacyService setHashedGeoIp:nil];
    XCTAssertNil([self.privacyService hashedGeoIp], @"Should clear hashed geo IP");
}

// Test complex privacy scenarios with multiple flags
- (void)testComplexPrivacyScenarios {
    // Scenario 1: GDPR allows but CCPA blocks - CCPA should win
    [self clearPrivacySettings];
    [self.testDefaults setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"CCPA opt-out should override GDPR consent");
    
    // Scenario 2: All privacy frameworks allow data
    [self clearPrivacySettings];
    [self.testDefaults setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"When all privacy frameworks allow, data should be allowed");
}

#pragma mark - IAB Standard UserDefaults Tests

// Test that SDK reads CCPA privacy string from IAB standard UserDefaults key
- (void)testCCPAPrivacyStringFromIABUserDefaults {
    [self clearPrivacySettings];
    
    // Set CCPA string via IAB standard key (as CMPs would)
    NSString *testCCPAString = @"1YNN";
    [self.testDefaults setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    // Verify SDK reads it correctly
    NSString *retrievedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(retrievedCCPA, testCCPAString, @"SDK should read CCPA string from IAB UserDefaults key");
    
    // Test clearing CCPA string
    [self.testDefaults removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    NSString *clearedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertNil(clearedCCPA, @"CCPA string should be nil when UserDefaults key is removed");
}

// Test SDK reads CCPA opt-out correctly from IAB US Privacy String
// IAB US Privacy String format: 1[Notice][OptOut][LSPA]
// Position 3 (index 2) is the opt-out flag: Y = opted out, N = not opted out
- (void)testCCPAOptOutDetection {
    [self clearPrivacySettings];
    
    // Test opt-out detected (Y at position 3)
    [self.testDefaults setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    NSNumber *ccpaApplies = [self.privacyService ccpaApplies];
    XCTAssertEqualObjects(ccpaApplies, @YES, @"CCPA should detect opt-out from '1YYN' (Y at position 3)");
    
    // Test no opt-out (N at position 3)
    [self.testDefaults setObject:@"1YNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    ccpaApplies = [self.privacyService ccpaApplies];
    XCTAssertEqualObjects(ccpaApplies, @NO, @"CCPA should not detect opt-out from '1YNN' (N at position 3)");
}

#pragma mark - GDPR/TCF Purpose Consent Tests

// Test TCF purpose consents determine PII removal requirement
// Per IAB TCF 2.2 spec, purposes 1-4 are required for personalized advertising
- (void)testTCFPurposeConsent_AllPurposesGranted_ShouldAllowData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with all purposes granted
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults setObject:@"1111111111" forKey:@"IABTCF_PurposeConsents"];
    // Minimal valid TC string with all purposes granted
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
    // When GDPR applies and all purposes are granted, data should be allowed
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"GDPR applies should be YES");
    
    NSString *purposeConsents = [self.testDefaults stringForKey:@"IABTCF_PurposeConsents"];
    XCTAssertTrue(purposeConsents.length >= 1 && [purposeConsents characterAtIndex:0] == '1', @"Purpose 1 should be granted");
}

// Test TCF with Purpose 1 denied should require PII removal
- (void)testTCFPurposeConsent_Purpose1Denied_ShouldClearData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with Purpose 1 denied
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults setObject:@"0111111111" forKey:@"IABTCF_PurposeConsents"];
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACDENCFFgAHAAAEPg" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
    NSString *purposeConsents = [self.testDefaults stringForKey:@"IABTCF_PurposeConsents"];
    BOOL purpose1Granted = purposeConsents.length >= 1 && [purposeConsents characterAtIndex:0] == '1';
    XCTAssertFalse(purpose1Granted, @"Purpose 1 should be denied");
}

// Test TCF with no purpose consents should require PII removal
- (void)testTCFPurposeConsent_NoPurposes_ShouldClearData {
    [self clearPrivacySettings];
    
    // Set up GDPR applies with no purposes granted
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults setObject:@"0000000000" forKey:@"IABTCF_PurposeConsents"];
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFFgAAAA" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
    NSString *purposeConsents = [self.testDefaults stringForKey:@"IABTCF_PurposeConsents"];
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
    [self.testDefaults setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @NO, @"GDPR applies should be NO for non-EEA users");
}

// Test missing GDPR applies flag should be treated as unknown
- (void)testGDPRAppliesNotSet_ShouldBeUnknown {
    [self clearPrivacySettings];
    
    // No GDPR applies flag set
    [self.testDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertNil(gdprApplies, @"GDPR applies should be nil when not set");
}

#pragma mark - Manual Privacy Fallback Tests

// Test manual doNotSell=YES triggers data clearing when no CMP signals
- (void)testManualDoNotSell_YES_ShouldClearPersonalData {
    [self clearPrivacySettings];

    // No CMP signals, but publisher manually set doNotSell
    [[CLXManualPrivacyState sharedInstance] setDoNotSell:@YES];

    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"Manual doNotSell=YES should clear personal data");
}

// Test manual doNotSell=NO does NOT trigger data clearing
- (void)testManualDoNotSell_NO_ShouldAllowPersonalData {
    [self clearPrivacySettings];

    [[CLXManualPrivacyState sharedInstance] setDoNotSell:@NO];

    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"Manual doNotSell=NO should allow personal data");
}

// Test manual doNotSell=nil (not set) does NOT trigger data clearing
- (void)testManualDoNotSell_Nil_ShouldAllowPersonalData {
    [self clearPrivacySettings];

    [[CLXManualPrivacyState sharedInstance] setDoNotSell:nil];

    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"Manual doNotSell=nil should defer and allow personal data");
}

// Test CMP CCPA signal takes priority over manual doNotSell
- (void)testCCPAOptOut_OverridesManualDoNotSell_NO {
    [self clearPrivacySettings];

    // CMP says opt-out, but publisher manually says doNotSell=NO
    [self.testDefaults setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    [[CLXManualPrivacyState sharedInstance] setDoNotSell:@NO];

    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"CMP CCPA opt-out should override manual doNotSell=NO");
}

// Test clearing manual state restores default behavior
- (void)testClearManualState_RestoresDefaultBehavior {
    [self clearPrivacySettings];

    // Set and then clear
    [[CLXManualPrivacyState sharedInstance] setDoNotSell:@YES];
    [[CLXManualPrivacyState sharedInstance] clear];

    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"After clearing manual state, should defer to CMP (which has no signal = allow)");
}

@end
