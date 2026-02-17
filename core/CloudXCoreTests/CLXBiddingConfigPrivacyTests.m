//
//  CLXBiddingConfigRequestPrivacyTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-08-30.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CoreLocation/CoreLocation.h>

// Test category to expose internal methods for testing
// GDPR methods are internal because server support is not yet implemented.
@interface CLXPrivacyService (Testing)
- (nullable NSString *)gdprConsentString; // Internal - server not supported
- (nullable NSNumber *)gdprApplies; // Internal - server not supported
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
                privacyService:(CLXPrivacyService *)privacyService;
@end

@interface CLXBiddingConfigRequestPrivacyTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXBiddingConfigRequestPrivacyTests

- (void)setUp {
    [super setUp];
    
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
    CLXGeoLocationService *isolatedGeoService = [[CLXGeoLocationService alloc] initWithUserDefaults:self.testDefaults];
    self.privacyService = [[CLXPrivacyService alloc] initWithUserDefaults:self.testDefaults
                                                         consentProvider:self.gppProvider
                                                      geoLocationService:isolatedGeoService];
    
    // Create mock SDK config with appID for tests
    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = @"test-app-id-from-sdk";
    self.mockSDKConfig.accountID = @"test-account";
    self.mockSDKConfig.sessionID = @"test-session";
    
    // Create mock impression model
    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction"
                                                              testGroupName:@"test-group"];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

- (void)clearPrivacySettings {
    [self.testDefaults removeObjectForKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults removeObjectForKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults removeObjectForKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults synchronize];
}

// Test that GDPR consent string is properly included in bidding config
- (void)testGDPRConsentString_ShouldBeIncludedInBiddingConfig {
    [self clearPrivacySettings];
    
    NSString *testConsentString = @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    [self.testDefaults setObject:testConsentString forKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults setInteger:1 forKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults synchronize];
    
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
            privacyService:self.privacyService];
    
    // GDPR is now supported in bid requests
    XCTAssertNotNil(config.regulations.ext.iab.tcString, @"TC string should be included in bid request");
    XCTAssertEqualObjects(config.regulations.ext.iab.tcString, testConsentString, @"TC string should match set value");
    XCTAssertNotNil(config.regulations.ext.iab.gdprApplies, @"GDPR applies should be included in bid request");
    XCTAssertEqualObjects(config.regulations.ext.iab.gdprApplies, @YES, @"GDPR applies should be YES");
}

// Test that CCPA privacy string is properly included in bidding config
- (void)testCCPAPrivacyString_ShouldBeIncludedInBiddingConfig {
    [self clearPrivacySettings]; // Ensure clean state
    
    NSString *testCCPAString = @"1YNN";
    [self.testDefaults setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    // Verify the data was stored
    NSString *storedCCPA = [self.testDefaults stringForKey:kCLXPrivacyCCPAPrivacyKey];
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService]; // ← SOLID: Dependency injection!
    
    XCTAssertNotNil(config.regulations, @"Regulations should be present when CCPA is configured");
    XCTAssertNotNil(config.regulations.ext, @"Regulations ext should be present");
    XCTAssertNotNil(config.regulations.ext.iab, @"IAB ext should be present");
    XCTAssertEqualObjects(config.regulations.ext.iab.usPrivacyString, testCCPAString, @"US privacy string should match CCPA string");
}

// Test that CCPA privacy settings are included in bidding config
- (void)testCCPAPrivacySettings_ShouldBeIncludedInBiddingConfig {
    [self clearPrivacySettings]; // Ensure clean state
    
    NSString *testGDPRConsent = @"CPcABcABcABcAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    NSString *testCCPAString = @"1YNN";
    
    // Set privacy settings - CCPA should be included in bidding config
    [self.testDefaults setObject:testGDPRConsent forKey:kCLXPrivacyGDPRConsentKey];
    [self.testDefaults setBool:YES forKey:kCLXPrivacyGDPRAppliesKey];
    [self.testDefaults setObject:testCCPAString forKey:kCLXPrivacyCCPAPrivacyKey];
    [self.testDefaults synchronize];
    
    // Verify CCPA data was stored and can be read by privacy service
    NSString *storedCCPA = [self.testDefaults stringForKey:kCLXPrivacyCCPAPrivacyKey];
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService]; // ← SOLID: Dependency injection!
    
    XCTAssertNotNil(config.regulations, @"Regulations should be present");
    XCTAssertNotNil(config.regulations.ext, @"Regulations ext should be present");
    XCTAssertNotNil(config.regulations.ext.iab, @"IAB ext should be present");
    
    // CCPA should be included
    XCTAssertEqualObjects(config.regulations.ext.iab.usPrivacyString, testCCPAString, @"US privacy string should match CCPA string");
    
    // GDPR is now supported in bid requests
    XCTAssertNotNil(config.regulations.ext.iab.gdprApplies, @"GDPR applies should be included");
    XCTAssertEqualObjects(config.regulations.ext.iab.gdprApplies, @YES, @"GDPR applies should be YES");
    XCTAssertEqualObjects(config.regulations.ext.iab.tcString, testGDPRConsent, @"TC string should match GDPR consent");
}

#pragma mark - GDPR Bid Request Tests

// Test GDPR applies flag in bid request when set to YES
- (void)testGDPRAppliesYes_ShouldBeIncludedInBidRequest {
    [self clearPrivacySettings];
    
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFF" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
            privacyService:self.privacyService];
    
    XCTAssertNotNil(config.regulations.ext.iab.gdprApplies, @"GDPR applies should be included");
    XCTAssertEqualObjects(config.regulations.ext.iab.gdprApplies, @YES, @"GDPR applies should be YES");
}

// Test GDPR applies flag in bid request when set to NO
- (void)testGDPRAppliesNo_ShouldNotClearData {
    [self clearPrivacySettings];
    
    [self.testDefaults setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
    // When GDPR doesn't apply, bidding config should still function normally
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
            privacyService:self.privacyService];
    
    // When GDPR doesn't apply, gdprApplies should be nil or not set
    // The bid request should still be valid
    XCTAssertNotNil(config, @"Bidding config should be created successfully");
}

// Test GPP resolution in bid request when GPP string available
- (void)testGPPString_ShouldBeIncludedInBidRequest {
    [self clearPrivacySettings];
    
    NSString *testGppString = @"DBABLA~BVVqAAEABBENA.QA";
    [self.testDefaults setObject:testGppString forKey:@"IABGPP_HDR_GppString"];
    [self.testDefaults setObject:@"8" forKey:@"IABGPP_GppSID"];
    [self.testDefaults synchronize];
    
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
            privacyService:self.privacyService];
    
    XCTAssertNotNil(config.regulations.ext.gpp, @"GPP string should be included in bid request");
    XCTAssertNotNil(config.regulations.ext.gppSid, @"GPP SID should be included in bid request");
}

// Test GPP resolution fallback from legacy TCF
- (void)testGPPFallbackFromLegacyTCF_ShouldConstructGPP {
    [self clearPrivacySettings];
    
    // Clear GPP but set legacy TCF
    [self.testDefaults removeObjectForKey:@"IABGPP_HDR_GppString"];
    [self.testDefaults removeObjectForKey:@"IABGPP_GppSID"];
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFF" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
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
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
            privacyService:self.privacyService];
    
    // GPP should be constructed from legacy TCF
    XCTAssertNotNil(config.regulations.ext.gpp, @"GPP should be constructed from legacy TCF");
    XCTAssertTrue([config.regulations.ext.gpp hasPrefix:@"DBABMA~"], @"Constructed GPP should have TCF-only header");
    XCTAssertEqualObjects(config.regulations.ext.gppSid, (@[@2]), @"Constructed GPP SID should be [2]");
}

@end
