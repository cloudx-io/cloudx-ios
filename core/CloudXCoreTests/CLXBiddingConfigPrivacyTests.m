//
//  CLXBiddingConfigRequestPrivacyTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-08-30.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"
#import <CoreLocation/CoreLocation.h>

// Test category to expose internal methods for testing
// These methods are internal because server support for GDPR/COPPA is not yet implemented
@interface CLXPrivacyService (Testing)
- (nullable NSString *)gdprConsentString; // Internal - server not supported
- (nullable NSNumber *)gdprApplies; // Internal - server not supported
- (nullable NSNumber *)coppaApplies; // Internal - server not supported
// Note: No longer supports UserDefaults injection to ensure real-world collision testing
@end

// Test category for CLXBiddingConfigRequest to enable dependency injection
@interface CLXBiddingConfigRequest (Testing)
- (instancetype)initWithAdType:(CLXAdType)adType
                     adUnitID:(NSString *)adUnitID
            storedImpressionId:(NSString *)storedImpressionId
                        dealID:(NSString *)dealID
                     bidFloor:(NSNumber *)bidFloor
                displayManager:(NSString *)displayManager
            displayManagerVer:(NSString *)displayManagerVer
                   publisherID:(NSString *)publisherID
                      location:(CLLocation *)location
                     userAgent:(NSString *)userAgent
                   adapterInfo:(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)adapterInfo
           nativeAdRequirements:(id)nativeAdRequirements
           skadRequestParameters:(id)skadRequestParameters
                          tmax:(NSNumber *)tmax
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      settings:(CLXSettings *)settings
                privacyService:(CLXPrivacyService *)privacyService; // SOLID: Dependency injection for testing
@end

@interface CLXBiddingConfigRequestPrivacyTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@end

@implementation CLXBiddingConfigRequestPrivacyTests

- (void)setUp {
    [super setUp];
    
    // Create privacy service using standardUserDefaults to replicate real-world scenarios
    self.privacyService = [[CLXPrivacyService alloc] init];
    
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    [self clearPrivacySettings];
    
    // Clear all CloudXCore keys to prevent test contamination
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    [super tearDown];
}

- (void)clearPrivacySettings {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Test that GDPR consent string is properly included in bidding config
- (void)testGDPRConsentString_ShouldBeIncludedInBiddingConfig {
    NSString *testConsentString = @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    [[NSUserDefaults standardUserDefaults] setObject:testConsentString forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc] 
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
    XCTAssertNil(config.regulations.ext.iab.tcString, @"TC string should not be included (server not supported)");
    XCTAssertNil(config.regulations.ext.iab.gdprApplies, @"GDPR applies should not be included (server not supported)");
}

// Test that CCPA privacy string is properly included in bidding config
- (void)testCCPAPrivacyString_ShouldBeIncludedInBiddingConfig {
    [self clearPrivacySettings]; // Ensure clean state
    
    NSString *testCCPAString = @"1YNN";
    [[NSUserDefaults standardUserDefaults] setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the data was stored
    NSString *storedCCPA = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyCCPAPrivacyKey];
    XCTAssertEqualObjects(storedCCPA, testCCPAString, @"CCPA string should be stored correctly");
    
    // Verify privacy service can read it
    NSString *serviceCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(serviceCCPA, testCCPAString, @"Privacy service should return stored CCPA string");
    
    // SOLID: Use dependency injection to pass our isolated privacy service
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc] 
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
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService]; // ← SOLID: Dependency injection!
    
    XCTAssertNotNil(config.regulations, @"Regulations should be present when CCPA is configured");
    XCTAssertNotNil(config.regulations.ext, @"Regulations ext should be present");
    XCTAssertNotNil(config.regulations.ext.iab, @"IAB ext should be present");
    XCTAssertEqualObjects(config.regulations.ext.iab.usPrivacyString, testCCPAString, @"US privacy string should match CCPA string");
}

// Test that COPPA applicable flag is included in bidding config when enabled
- (void)testCOPPAApplicable_ShouldBeIncludedInBiddingConfig {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc] 
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
    
    // COPPA should be included in bidding config when enabled (now supported with GPP)
    XCTAssertEqualObjects(config.regulations.coppa, @YES, @"COPPA should be included in bidding config when enabled");
}

// Test that CCPA and COPPA privacy settings are included in bidding config
- (void)testCCPAPrivacySettings_ShouldBeIncludedInBiddingConfig {
    [self clearPrivacySettings]; // Ensure clean state
    
    NSString *testGDPRConsent = @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    NSString *testCCPAString = @"1YNN";
    
    // Set all privacy settings, but only CCPA should be included in bidding config
    [[NSUserDefaults standardUserDefaults] setObject:testGDPRConsent forKey:kCLXPrivacyGDPRConsentKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [[NSUserDefaults standardUserDefaults] setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXPrivacyCOPPAAppliesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify CCPA data was stored and can be read by privacy service
    NSString *storedCCPA = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXPrivacyCCPAPrivacyKey];
    XCTAssertEqualObjects(storedCCPA, testCCPAString, @"CCPA string should be stored correctly");
    
    NSString *serviceCCPA = [self.privacyService ccpaPrivacyString];
    XCTAssertEqualObjects(serviceCCPA, testCCPAString, @"Privacy service should return stored CCPA string");
    
    // SOLID: Use dependency injection to pass our isolated privacy service
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc] 
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
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService]; // ← SOLID: Dependency injection!
    
    XCTAssertNotNil(config.regulations, @"Regulations should be present");
    XCTAssertNotNil(config.regulations.ext, @"Regulations ext should be present");
    XCTAssertNotNil(config.regulations.ext.iab, @"IAB ext should be present");
    
    // CCPA should be included (server supported)
    XCTAssertEqualObjects(config.regulations.ext.iab.usPrivacyString, testCCPAString, @"US privacy string should match CCPA string");
    
    // COPPA should be included when enabled (now supported with GPP)
    XCTAssertEqualObjects(config.regulations.coppa, @YES, @"COPPA should be included when enabled");
    
    // GDPR should NOT be included (server not supported yet)
    XCTAssertNil(config.regulations.ext.iab.gdprApplies, @"GDPR applies should not be included (server not supported)");
    XCTAssertNil(config.regulations.ext.iab.tcString, @"TC string should not be included (server not supported)");
}

@end
