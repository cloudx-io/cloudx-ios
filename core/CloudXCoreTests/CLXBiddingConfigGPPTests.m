//
//  CLXBiddingConfigGPPTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CoreLocation/CoreLocation.h>

// Test category for CLXBiddingConfigRequest to enable dependency injection
@interface CLXBiddingConfigRequest (GPPTesting)
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

@interface CLXBiddingConfigGPPTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXBiddingConfigGPPTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
    CLXGeoLocationService *isolatedGeoService = [[CLXGeoLocationService alloc] initWithUserDefaults:self.testDefaults];
    self.privacyService = [[CLXPrivacyService alloc] initWithUserDefaults:self.testDefaults
                                                         consentProvider:self.gppProvider
                                                      geoLocationService:isolatedGeoService];
    
    // Explicitly clear GPP state for each test
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
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
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

#pragma mark - GPP Data in Bid Requests

// Test GPP string is included in bid request regulations
- (void)testGPPStringIncludedInBidRequest {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    [self.gppProvider setGppString:testGppString];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSString *gppInRequest = json[@"regs"][@"ext"][@"gpp"];
    XCTAssertEqualObjects(gppInRequest, testGppString, @"GPP string should be included in bid request");
}

// Test GPP SID is NOT included without GPP string (per OpenRTB 2.6 spec)
// gpp_sid is intended to be used in conjunction with gpp - including gpp_sid
// without a corresponding gpp string does not align with the specification.
- (void)testGPPSidNotIncludedWithoutGPPString {
    NSArray *testGppSid = @[@7, @8];
    [self.gppProvider setGppSid:testGppSid];
    // Note: NOT setting GPP string
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    // Per OpenRTB 2.6 spec, gpp_sid should NOT be included without gpp string
    NSArray *gppSidInRequest = json[@"regs"][@"ext"][@"gpp_sid"];
    XCTAssertNil(gppSidInRequest, @"GPP SID should NOT be included without GPP string (per OpenRTB 2.6 spec)");
}

// Test both GPP string and SID are included together
- (void)testGPPStringAndSidIncludedTogether {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *testGppSid = @[@7, @8];
    
    [self.gppProvider setGppString:testGppString];
    [self.gppProvider setGppSid:testGppSid];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *regsExt = json[@"regs"][@"ext"];
    XCTAssertEqualObjects(regsExt[@"gpp"], testGppString, @"GPP string should be included");
    XCTAssertEqualObjects(regsExt[@"gpp_sid"], testGppSid, @"GPP SID should be included");
}

#pragma mark - Personal Data Clearing in Bid Requests

// Test IFA is cleared when privacy requires it
- (void)testIFAClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (CCPA opt-out)
    [self setupUSUser];
    // Set CCPA opt-out via IAB standard UserDefaults key
    [self.testDefaults setObject:@"1YYN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config json];
    
    NSString *ifa = json[@"device"][@"ifa"];
    XCTAssertEqualObjects(ifa, @"00000000-0000-0000-0000-000000000000", @"IFA should be set to zero IDFA when privacy requires data clearing (unified privacy architecture)");
}

// Test geo coordinates are cleared when privacy requires it
- (void)testGeoCoordinatesClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (CCPA opt-out)
    [self setupUSUser];
    // Set CCPA opt-out via IAB standard UserDefaults key
    [self.testDefaults setObject:@"1YYN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    
    CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithLocation:testLocation];
    NSDictionary *json = [config json];
    
    NSDictionary *geo = json[@"device"][@"geo"];
    XCTAssertNil(geo[@"lat"], @"Latitude should be cleared when privacy requires it");
    XCTAssertNil(geo[@"lon"], @"Longitude should be cleared when privacy requires it");
    XCTAssertNotNil(geo[@"utcoffset"], @"UTC offset should remain when geo coordinates are cleared");
}

// Test user data is cleared when privacy requires it
- (void)testUserDataClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (CCPA opt-out)
    [self setupUSUser];
    // Set CCPA opt-out via IAB standard UserDefaults key
    [self.testDefaults setObject:@"1YYN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    
    // Debug: Check what the privacy service is actually returning
    BOOL shouldClear = [self.privacyService shouldClearPersonalData];
    NSLog(@"🔍 DEBUG: shouldClearPersonalData returned: %@", shouldClear ? @"YES" : @"NO");
    
    XCTAssertTrue(shouldClear, @"Privacy service should require data clearing when CCPA opt-out is enabled (unified privacy architecture)");
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config json];
    
    NSDictionary *userExt = json[@"user"][@"ext"];
    XCTAssertNil(userExt[@"data"], @"User data should be cleared when privacy requires it");
    XCTAssertNil(userExt[@"eids"], @"User EIDs should be cleared when privacy requires it");
}

// Test device and geo data behavior when privacy theoretically allows it
- (void)testDataBehaviorWhenPrivacyAllows {
    // Set up scenario that would allow data (non-US user)
    [self setupNonUSUser];
    
    CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithLocation:testLocation];
    NSDictionary *json = [config json];
    
    // Note: In test environment, ATT may not be authorized, so data might still be cleared
    // This test verifies the structure is present, even if values are cleared
    NSString *ifa = json[@"device"][@"ifa"];
    XCTAssertNotNil(ifa, @"IFA field should be present");
    
    // Geo object should be present with UTC offset
    NSDictionary *geo = json[@"device"][@"geo"];
    XCTAssertNotNil(geo, @"Geo object should be present");
    XCTAssertNotNil(geo[@"utcoffset"], @"UTC offset should always be present");
}

#pragma mark - Legacy CCPA Integration

// Test legacy CCPA string is still included alongside GPP
- (void)testLegacyCCPAStringIncludedWithGPP {
    NSString *ccpaString = @"1YNN";
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    
    // Set CCPA string via IAB standard UserDefaults key
    [self.testDefaults setObject:ccpaString forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    [self.gppProvider setGppString:gppString];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config json];
    
    NSDictionary *iab = json[@"regs"][@"ext"][@"iab"];
    XCTAssertEqualObjects(iab[@"ccpa_us_privacy_string"], ccpaString, @"Legacy CCPA string should be included");
    XCTAssertEqualObjects(json[@"regs"][@"ext"][@"gpp"], gppString, @"GPP string should also be included");
}

#pragma mark - Helper Methods

- (CLXBiddingConfigRequest *)createTestBiddingConfig {
    return [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:@"test-deal"
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:nil
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:@{}
                          tmax:@3.0
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
}

- (CLXBiddingConfigRequest *)createTestBiddingConfigWithPrivacyService {
    return [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:@"test-deal"
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:nil
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:@{}
                          tmax:@3.0
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
}

- (CLXBiddingConfigRequest *)createTestBiddingConfigWithLocation:(CLLocation *)location {
    return [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:@"test-deal"
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:location
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:@{}
                          tmax:@3.0
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
}

- (void)setupUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"TX"
    };
    [self.testDefaults setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

- (void)setupNonUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"ON"
    };
    [self.testDefaults setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

// Test unified privacy architecture - ATT-first behavior
- (void)testUnifiedPrivacyArchitectureATTFirst {
    // Test that unified privacy method respects ATT as primary control
    // Note: In test environment, ATT status may vary
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalData];
    
    // Create config and verify IFA behavior matches privacy decision
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config json];
    NSString *ifa = json[@"device"][@"ifa"];
    
    if (shouldClear) {
        XCTAssertEqualObjects(ifa, @"00000000-0000-0000-0000-000000000000", 
                             @"When privacy clearing required, IFA should be zero IDFA");
    } else {
        XCTAssertNotEqualObjects(ifa, @"00000000-0000-0000-0000-000000000000", 
                                @"When privacy allows data, IFA should not be zero IDFA");
    }
    
    NSLog(@"🔍 Unified Privacy Test - shouldClear: %@, IFA: %@", 
          shouldClear ? @"YES" : @"NO", ifa);
}

#pragma mark - QA Fix Tests (CX-1911, CX-1912, CX-1904)

// CX-1911: GPP SID must be present when GPP string exists (even if empty array)
// Per IAB spec, gpp_sid MUST accompany gpp string, even if empty
- (void)testGPPSidPresentWhenGPPStringExists_EmptyArray {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    
    // Set GPP string but no SID (simulates CMP providing string without SID)
    [self.gppProvider setGppString:testGppString];
    [self.gppProvider setGppSid:nil];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *regsExt = json[@"regs"][@"ext"];
    
    // Verify GPP string is present
    XCTAssertEqualObjects(regsExt[@"gpp"], testGppString, @"GPP string should be present");
    
    // CX-1911 FIX: gpp_sid MUST be present when gpp exists (even if empty)
    XCTAssertNotNil(regsExt[@"gpp_sid"], @"gpp_sid MUST be present when gpp string exists (IAB spec)");
    XCTAssertTrue([regsExt[@"gpp_sid"] isKindOfClass:[NSArray class]], @"gpp_sid must be an array");
    XCTAssertEqual([regsExt[@"gpp_sid"] count], 0, @"gpp_sid should be empty array when no SID provided");
}

// CX-1911: GPP SID included with non-empty array
- (void)testGPPSidPresentWhenGPPStringExists_NonEmptyArray {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *testGppSid = @[@7]; // US National
    
    [self.gppProvider setGppString:testGppString];
    [self.gppProvider setGppSid:testGppSid];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *regsExt = json[@"regs"][@"ext"];
    
    // CX-1911 FIX: gpp_sid present with correct values
    XCTAssertEqualObjects(regsExt[@"gpp_sid"], testGppSid, @"gpp_sid should contain provided SID array");
}

// CX-1911: GPP SID not present when GPP string absent
- (void)testGPPSidAbsentWhenGPPStringAbsent {
    // No GPP string set
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *regsExt = json[@"regs"][@"ext"];
    
    // When no GPP string, gpp_sid should not be present
    XCTAssertNil(regsExt[@"gpp"], @"GPP string should be absent");
    XCTAssertNil(regsExt[@"gpp_sid"], @"gpp_sid should be absent when no GPP string");
}

// CX-1904: DNT field set correctly in device (not hardcoded to 0)
// Note: This test verifies DNT field exists and is a number (0 or 1)
// Actual value depends on ATT authorization status which varies in test environment
- (void)testDNTFieldDynamicallySet {
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    // CX-1904 FIX: DNT should be dynamically set from CLXAdTrackingService
    NSNumber *dntValue = json[@"device"][@"dnt"];
    XCTAssertNotNil(dntValue, @"DNT field must be present in device");
    XCTAssertTrue([dntValue isKindOfClass:[NSNumber class]], @"DNT must be a number");
    
    // DNT should be 0 or 1 (0 = tracking allowed, 1 = do not track)
    XCTAssertTrue([dntValue intValue] == 0 || [dntValue intValue] == 1, 
                  @"DNT value must be 0 (tracking allowed) or 1 (do not track)");
    
    NSLog(@"🔍 DNT Test - Value: %@", dntValue);
}

// CX-1904: Verify DNT correlates with IFA privacy behavior
// When DNT=1, IFA should be zeros; when DNT=0, IFA may be real
- (void)testDNTCorrelatesWithIFAPrivacy {
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config json];
    
    NSNumber *dntValue = json[@"device"][@"dnt"];
    NSString *ifaValue = json[@"device"][@"ifa"];
    
    XCTAssertNotNil(dntValue, @"DNT must be present");
    XCTAssertNotNil(ifaValue, @"IFA must be present");
    
    // CX-1904: When DNT=1 (do not track), IFA should be zeros
    if ([dntValue intValue] == 1) {
        XCTAssertEqualObjects(ifaValue, @"00000000-0000-0000-0000-000000000000",
                             @"When DNT=1, IFA must be zero IDFA for privacy");
    }
    
    NSLog(@"🔍 DNT/IFA Correlation Test - DNT: %@, IFA: %@", dntValue, ifaValue);
}

@end
