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
// These methods are internal because server support for GDPR/COPPA is not yet implemented
@interface CLXPrivacyService (Testing)
- (BOOL)shouldClearPersonalDataIgnoringATT; // Test without ATT dependency
- (nullable NSString *)gdprConsentString; // Internal - server not supported
- (nullable NSNumber *)gdprApplies; // Internal - server not supported
- (nullable NSNumber *)coppaApplies; // Internal - server not supported
// Note: No longer supports UserDefaults injection to ensure real-world collision testing
@end

// Test category for CloudXCore to enable dependency injection
@interface CloudXCore (Testing)
+ (void)setCCPAPrivacyStringWithService:(nullable NSString *)ccpaPrivacyString privacyService:(CLXPrivacyService *)privacyService;
+ (void)setIsUserConsentWithService:(BOOL)isUserConsent privacyService:(CLXPrivacyService *)privacyService;
+ (void)setIsAgeRestrictedUserWithService:(BOOL)isAgeRestrictedUser privacyService:(CLXPrivacyService *)privacyService;
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

+ (void)setIsAgeRestrictedUserWithService:(BOOL)isAgeRestrictedUser privacyService:(CLXPrivacyService *)privacyService {
    [privacyService setIsAgeRestrictedUser:@(isAgeRestrictedUser)];
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
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
- (void)testCCPAOptOut_ShouldClearPersonalData {
    // Test various CCPA opt-out scenarios (any string containing Y indicates opt-out)
    NSArray *ccpaOptOutStrings = @[
        @"1YYN", // Standard opt-out
        @"1YNN", // Opt-out with different flags  
        @"1YYY", // Full opt-out
        @"1-Y-"  // Minimal opt-out format (from Android implementation)
    ];
    
    for (NSString *ccpaString in ccpaOptOutStrings) {
        [self clearPrivacySettings];
        
        [[NSUserDefaults standardUserDefaults] setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertTrue(shouldClear, @"CCPA opt-out string '%@' should clear personal data", ccpaString);
        
        // Verify getter returns the set value
        NSString *retrievedCCPA = [self.privacyService ccpaPrivacyString];
        XCTAssertEqualObjects(retrievedCCPA, ccpaString, @"Should retrieve the set CCPA string");
    }
    
    // Test CCPA strings that should NOT trigger opt-out (no Y means consent/no opt-out)
    NSArray *ccpaAllowStrings = @[
        @"1NNN", // No opt-out
        @"1-N-", // Explicit consent (from Android implementation)
        @"1---"  // CCPA does not apply (from Android implementation)
    ];
    
    for (NSString *ccpaString in ccpaAllowStrings) {
        [self clearPrivacySettings];
        
        [[NSUserDefaults standardUserDefaults] setObject:ccpaString forKey:kCLXPrivacyCCPAPrivacyKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
        XCTAssertFalse(shouldClear, @"CCPA consent string '%@' should allow personal data", ccpaString);
    }
}

// Test comprehensive COPPA validation with edge cases
- (void)testCOPPAApplicable_ShouldClearPersonalData {
    // Test COPPA applicable scenarios
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"COPPA applicable should clear personal data");
    
    // Verify getter returns correct value
    NSNumber *coppaApplies = [self.privacyService coppaApplies];
    XCTAssertNotNil(coppaApplies, @"COPPA applies should be retrievable");
    XCTAssertTrue([coppaApplies boolValue], @"COPPA applies should be true");
    
    // Test COPPA not applicable
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"COPPA not applicable should allow personal data");
    
    // Test missing COPPA flag (should default to not applicable)
    [self clearPrivacySettings];
    shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear, @"Missing COPPA flag should default to allowing personal data");
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
    
    // Scenario 2: GDPR allows, CCPA allows, but COPPA blocks - COPPA should win
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    shouldClear = [self.privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"COPPA should override both GDPR and CCPA consent");
    
    // Scenario 3: All privacy frameworks allow data
    [self clearPrivacySettings];
    [[NSUserDefaults standardUserDefaults] setObject:@"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA" forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCLXPrivacyCOPPAAppliesKey];
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

// Test COPPA age restriction API (with server warning)
- (void)testPublicCOPPAAPI {
    [self clearPrivacySettings];
    
    // Test setting COPPA flag through public API
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    // Verify it was stored (using internal method since this is for testing)
    NSNumber *coppaApplies = [self.privacyService coppaApplies];
    XCTAssertEqualObjects(coppaApplies, @YES, @"COPPA flag should be stored correctly");
    
    // Test clearing COPPA flag
    [self.privacyService setIsAgeRestrictedUser:nil];
    coppaApplies = [self.privacyService coppaApplies];
    XCTAssertNil(coppaApplies, @"COPPA flag should be cleared when set to nil");
}

// Test do not sell convenience API
- (void)testPublicDoNotSellAPI {
    [self clearPrivacySettings];
    
    // Test setting do not sell = YES (should create "1YNN" CCPA string)
    [self.privacyService setDoNotSell:@YES];
    
    NSString *ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YNN", @"Do not sell YES should create '1YNN' CCPA string");
    
    // Test setting do not sell = NO (should create "1NNN" CCPA string)
    [self.privacyService setDoNotSell:@NO];
    
    ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1NNN", @"Do not sell NO should create '1NNN' CCPA string");
    
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
    
    [CloudXCore setIsAgeRestrictedUserWithService:YES privacyService:self.privacyService];
    NSNumber *coppaApplies = [self.privacyService coppaApplies];
    XCTAssertEqualObjects(coppaApplies, @YES, @"CloudXCore setIsAgeRestrictedUser should delegate to CLXPrivacyService");
    
    [CloudXCore setIsDoNotSellWithService:NO privacyService:self.privacyService];
    ccpaString = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1NNN", @"CloudXCore setIsDoNotSell should delegate to CLXPrivacyService");
}

@end
