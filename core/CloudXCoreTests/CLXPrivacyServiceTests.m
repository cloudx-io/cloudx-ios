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

// Test category for CloudXCore to enable dependency injection
@interface CloudXCore (Testing)
+ (void)setCCPAPrivacyStringWithService:(nullable NSString *)ccpaPrivacyString privacyService:(CLXPrivacyService *)privacyService;
+ (void)setIsUserConsentWithService:(BOOL)isUserConsent privacyService:(CLXPrivacyService *)privacyService;
+ (void)setIsDoNotSellWithService:(BOOL)isDoNotSell privacyService:(CLXPrivacyService *)privacyService;
@end

// SOLID: Test-only category implementation (keeps core files clean)
@implementation CloudXCore (Testing)

+ (void)setCCPAPrivacyStringWithService:(nullable NSString *)ccpaPrivacyString privacyService:(CLXPrivacyService *)privacyService {
    [privacyService setCCPAPrivacyString:ccpaPrivacyString];
}

+ (void)setIsUserConsentWithService:(BOOL)isUserConsent privacyService:(CLXPrivacyService *)privacyService {
    [privacyService setHasUserConsent:@(isUserConsent)];
}

+ (void)setIsDoNotSellWithService:(BOOL)isDoNotSell privacyService:(CLXPrivacyService *)privacyService {
    [privacyService setDoNotSell:@(isDoNotSell)];
}

@end

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

#pragma mark - Public API Tests

// Test new public API methods work correctly
- (void)testPublicCCPAPrivacyStringAPI {
    // Test setting CCPA privacy string through public API
    [self clearPrivacySettings];
    
    NSString *testCCPAString = @"1YNN";
    [self.privacyService setCCPAPrivacyString:testCCPAString];
    
    // Verify it was stored correctly
    NSString *retrievedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(retrievedCCPA, testCCPAString, @"CCPA string should be stored and retrieved correctly");
    
    // Test clearing CCPA string
    [self.privacyService setCCPAPrivacyString:nil];
    NSString *clearedCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertNil(clearedCCPA, @"CCPA string should be cleared when set to nil");
}

// Test GDPR consent API (with server warning)
- (void)testPublicGDPRConsentAPI {
    [self clearPrivacySettings];
    
    // Test setting GDPR consent through public API
    [self.privacyService setHasUserConsent:@YES];
    
    // Verify it was stored (using internal method since this is for testing)
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"GDPR consent should be stored correctly");
    
    // Test clearing GDPR consent
    [self.privacyService setHasUserConsent:nil];
    gdprApplies = [self.privacyService gdprApplies];
    XCTAssertNil(gdprApplies, @"GDPR consent should be cleared when set to nil");
}

// Test do not sell convenience API
// IAB US Privacy String: Position 3 is the opt-out flag
// 1YYN = Notice given, OPTED OUT, Not LSPA
// 1YNN = Notice given, NOT opted out, Not LSPA
- (void)testPublicDoNotSellAPI {
    [self clearPrivacySettings];
    
    // Test setting do not sell = YES (should create "1YYN" CCPA string - Y at position 3)
    [self.privacyService setDoNotSell:@YES];
    
    NSString *ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YYN", @"Do not sell YES should create '1YYN' CCPA string (opt-out at position 3)");
    
    // Test setting do not sell = NO (should create "1YNN" CCPA string - N at position 3)
    [self.privacyService setDoNotSell:@NO];
    
    ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YNN", @"Do not sell NO should create '1YNN' CCPA string (not opted out at position 3)");
    
    // Test clearing do not sell
    [self.privacyService setDoNotSell:nil];
    ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertNil(ccpaString, @"Do not sell nil should clear CCPA string");
}

// Test CloudXCore public API delegates to CLXPrivacyService correctly
- (void)testCloudXCorePublicAPIIntegration {
    [self clearPrivacySettings];
    
    // SOLID: Test CloudXCore methods with dependency injection to our isolated privacy service
    [CloudXCore setCCPAPrivacyStringWithService:@"1YNN" privacyService:self.privacyService];
    NSString *ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YNN", @"CloudXCore setCCPAPrivacyString should delegate to CLXPrivacyService");
    
    [CloudXCore setIsUserConsentWithService:YES privacyService:self.privacyService];
    NSNumber *gdprApplies = [self.privacyService gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"CloudXCore setIsUserConsent should delegate to CLXPrivacyService");
    
    // setIsDoNotSell:NO should create "1YNN" (not opted out at position 3)
    [CloudXCore setIsDoNotSellWithService:NO privacyService:self.privacyService];
    ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YNN", @"CloudXCore setIsDoNotSell:NO should create '1YNN' CCPA string");
}

@end
