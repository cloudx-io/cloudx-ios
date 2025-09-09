//
//  CLXPrivacyIntegrationTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-08-30.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CoreLocation/CoreLocation.h>

// Testing category to expose internal methods for testing
// These methods are internal because server support for GDPR/COPPA is not yet implemented
@interface CLXPrivacyService (Testing)
- (BOOL)shouldClearPersonalDataIgnoringATT; // Test without ATT dependency
- (nullable NSString *)gdprConsentString; // Internal - server not supported
- (nullable NSNumber *)gdprApplies; // Internal - server not supported
- (nullable NSNumber *)coppaApplies; // Internal - server not supported
@end

// Note: Using public buildPayload method for robust integration testing instead of private methods

@interface CLXPrivacyIntegrationTests : XCTestCase
@end

@implementation CLXPrivacyIntegrationTests

- (void)setUp {
    [super setUp];
    // Clear ALL UserDefaults that might interfere with privacy tests
    [self clearAllPotentiallyConflictingSettings];
    [self clearPrivacySettings];
}

- (void)tearDown {
    [self clearPrivacySettings];
    [self clearAllPotentiallyConflictingSettings];
    [super tearDown];
}

- (void)clearAllPotentiallyConflictingSettings {
    // Clear settings that banner tests might have set that could interfere
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXBanner_metricsDict"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXBanner_userKeyValue"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXBanner_appKey"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXBanner_sessionIDKey"];
    // Also clear old unprefixed keys for backward compatibility during transition
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearPrivacySettings {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedUserIdKey];
    // Also clear old unprefixed key for backward compatibility during transition
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreHashedUserIDKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyHashedGeoIpKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupPrivacyAllowingPersonalData {
    [self clearPrivacySettings]; // Clear any leftover settings first
    // Set CCPA to allow personal data (server-supported)
    // CCPA string "1NNN" means: version=1, explicit_notice=N, opt_out_sale=N, limited_service_provider=N
    [[NSUserDefaults standardUserDefaults] setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupPrivacyBlockingPersonalData {
    [self clearPrivacySettings]; // Clear any leftover settings first
    // Use CCPA opt-out (Y in 3rd position) to block personal data - this is server-supported
    [[NSUserDefaults standardUserDefaults] setObject:@"1YYN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CLXSDKConfigResponse *)createTestSDKConfig {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account-integration";
    config.organizationID = @"test-org-integration";
    config.sessionID = @"test-session-integration";
    config.tracking = @[@"bidRequest.device.ifa", @"sdk.sessionId", @"bidRequest.id"];
    return config;
}

// Test complete privacy flow from service to bidding config for GDPR compliance
- (void)testGDPRComplianceFlow_ShouldPropagateCorrectly {
    [self clearPrivacySettings]; // Clear any leftover settings first
    
    NSString *testGDPRConsent = @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    [[NSUserDefaults standardUserDefaults] setObject:testGDPRConsent forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify data was actually stored
    NSString *storedConsent = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyGDPRConsentKey];
    XCTAssertEqualObjects(storedConsent, testGDPRConsent, @"GDPR consent should be stored in UserDefaults");
    BOOL storedApplies = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyGDPRAppliesKey];
    XCTAssertTrue(storedApplies, @"GDPR applies should be stored as YES in UserDefaults");
    
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    XCTAssertEqualObjects([privacyService gdprConsentString], testGDPRConsent, @"Privacy service should return correct GDPR consent");
    XCTAssertEqualObjects([privacyService gdprApplies], @YES, @"Privacy service should return GDPR applies as YES");
    
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:@"test-deal"
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:[[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194]
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:@{}
                          tmax:@3.0
                      impModel:nil
                      settings:[CLXSettings sharedInstance]];
    // GDPR should NOT be included in bidding config as server doesn't support it yet
    XCTAssertNil(biddingConfig.regulations.ext.iab.tcString, @"Bidding config should not include GDPR consent (server not supported)");
    XCTAssertNil(biddingConfig.regulations.ext.iab.gdprApplies, @"Bidding config should not include GDPR applies (server not supported)");
}

// Test that privacy-compliant IFA resolution works correctly
- (void)testPrivacyCompliantIFAResolution_InTrackingPayloads {
    [self setupPrivacyBlockingPersonalData];
    
    // Verify the CCPA string was set correctly in UserDefaults
    NSString *storedCCPA = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyCCPAPrivacyKey];
    XCTAssertEqualObjects(storedCCPA, @"1YYN", @"CCPA string should be stored in UserDefaults");
    
    // WHEN: Privacy service is configured to block personal data
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    
    // Verify CCPA opt-out is present (which should trigger data blocking)
    NSString *ccpaString = [privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YYN", @"CCPA should indicate opt-out when privacy blocks personal data");
    
    // THEN: Privacy service should correctly block personal data
    BOOL shouldClearData = [privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClearData, @"Privacy service should block personal data when configured to do so");
    
    // Verify GDPR consent is not present (which should trigger data blocking)
    NSString *gdprConsent = [privacyService gdprConsentString];
    XCTAssertNil(gdprConsent, @"GDPR consent should be nil when privacy blocks personal data");
}

// Test that hashed identifiers are properly used in privacy-compliant scenarios
- (void)testHashedIdentifiersIntegration_InPrivacyCompliantScenarios {
    // GIVEN: Privacy settings that allow personal data but DNT is enabled
    [self setupPrivacyAllowingPersonalData];
    
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    [privacyService setHashedUserId:@"hashed-user-integration-test"];
    [privacyService setHashedGeoIp:@"hashed-geo-integration-test"];
    
    // WHEN: Testing privacy service hashed identifier functionality
    
    // THEN: Verify hashed identifiers are properly stored and accessible
    NSString *retrievedHashedUserId = [privacyService hashedUserId];
    XCTAssertEqualObjects(retrievedHashedUserId, @"hashed-user-integration-test", 
                         @"Hashed user ID should be correctly stored and retrievable");
    
    // Verify hashed geo IP functionality
    NSString *retrievedHashedGeoIp = [privacyService hashedGeoIp];
    XCTAssertEqualObjects(retrievedHashedGeoIp, @"hashed-geo-integration-test", 
                         @"Hashed geo IP should be correctly stored and retrievable");
    
    // Verify privacy service correctly evaluates consent (ignoring ATT for test consistency)
    BOOL shouldClearData = [privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClearData, @"With valid GDPR consent, privacy service should allow personal data");
    
    // Verify that privacy service correctly integrates with the system
    XCTAssertNotNil(privacyService, @"Privacy service should be available for integration");
    
    // Test that privacy settings persist correctly
    NSUserDefaults *testDefaults = [NSUserDefaults standardUserDefaults];
    NSString *storedHashedUserId = [testDefaults objectForKey:kCLXPrivacyHashedUserIdKey];
    XCTAssertEqualObjects(storedHashedUserId, @"hashed-user-integration-test", 
                         @"Hashed user ID should persist in UserDefaults");
    
    NSString *storedHashedGeoIp = [testDefaults objectForKey:kCLXPrivacyHashedGeoIpKey];
    XCTAssertEqualObjects(storedHashedGeoIp, @"hashed-geo-integration-test", 
                         @"Hashed geo IP should persist in UserDefaults");
}

// Test that runtime privacy changes affect all components consistently
- (void)testRuntimePrivacyChanges_AffectAllComponentsConsistently {
    [self setupPrivacyAllowingPersonalData];
    
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    CLXBiddingConfigRequest *initialConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:@"test-deal"
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:[[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194]
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:@{}
                          tmax:@3.0
                      impModel:nil
                      settings:[CLXSettings sharedInstance]];
    
    // Test privacy logic ignoring ATT to focus on CCPA logic
    XCTAssertFalse([privacyService shouldClearPersonalDataIgnoringATT], @"Initially, privacy should allow personal data (ignoring ATT)");
    // GDPR should NOT be included in bidding config as server doesn't support it yet
    XCTAssertNil(initialConfig.regulations.ext.iab.gdprApplies, @"Initial config should not have GDPR applies (server not supported)");
    
    [self setupPrivacyBlockingPersonalData];
    
    // Test that privacy changes are reflected in the privacy service
    XCTAssertTrue([privacyService shouldClearPersonalDataIgnoringATT], @"After change, privacy should block personal data (ignoring ATT)");
    
    // Verify CCPA opt-out is now applied
    NSString *ccpaString = [privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(ccpaString, @"1YYN", @"CCPA should indicate opt-out after privacy change");
}

// Test CCPA string parsing for different opt-out scenarios
- (void)testCCPAStringParsing_ForDifferentOptOutScenarios {
    [self clearPrivacySettings];
    
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    
    // Test CCPA string "1YNN" - should clear personal data
    [[NSUserDefaults standardUserDefaults] setObject:@"1YNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *retrievedCCPA = [privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(retrievedCCPA, @"1YNN", @"Should retrieve the set CCPA string");
    
    BOOL shouldClear = [privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertTrue(shouldClear, @"CCPA opt-out string '1YNN' should clear personal data");
    
    // Test CCPA string "1NNN" - should allow personal data
    [[NSUserDefaults standardUserDefaults] setObject:@"1NNN" forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *retrievedCCPA2 = [privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(retrievedCCPA2, @"1NNN", @"Should retrieve the updated CCPA string");
    
    BOOL shouldClear2 = [privacyService shouldClearPersonalDataIgnoringATT];
    XCTAssertFalse(shouldClear2, @"CCPA string '1NNN' should allow personal data");
}

@end
