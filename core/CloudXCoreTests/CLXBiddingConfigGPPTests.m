//
//  CLXBiddingConfigGPPTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"
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
@property (nonatomic, strong) CLXGPPProvider *gppProvider;
@end

@implementation CLXBiddingConfigGPPTests

- (void)setUp {
    [super setUp];
    self.privacyService = [[CLXPrivacyService alloc] init];
    self.gppProvider = [CLXGPPProvider sharedInstance];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - GPP Data in Bid Requests

// Test GPP string is included in bid request regulations
- (void)testGPPStringIncludedInBidRequest {
    NSString *testGppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    [self.gppProvider setGppString:testGppString];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config toJSON];
    
    NSString *gppInRequest = json[@"regs"][@"ext"][@"gpp"];
    XCTAssertEqualObjects(gppInRequest, testGppString, @"GPP string should be included in bid request");
}

// Test GPP SID array is included in bid request regulations
- (void)testGPPSidIncludedInBidRequest {
    NSArray *testGppSid = @[@7, @8];
    [self.gppProvider setGppSid:testGppSid];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config toJSON];
    
    NSArray *gppSidInRequest = json[@"regs"][@"ext"][@"gpp_sid"];
    XCTAssertEqualObjects(gppSidInRequest, testGppSid, @"GPP SID array should be included in bid request");
}

// Test both GPP string and SID are included together
- (void)testGPPStringAndSidIncludedTogether {
    NSString *testGppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    NSArray *testGppSid = @[@7, @8];
    
    [self.gppProvider setGppString:testGppString];
    [self.gppProvider setGppSid:testGppSid];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config toJSON];
    
    NSDictionary *regsExt = json[@"regs"][@"ext"];
    XCTAssertEqualObjects(regsExt[@"gpp"], testGppString, @"GPP string should be included");
    XCTAssertEqualObjects(regsExt[@"gpp_sid"], testGppSid, @"GPP SID should be included");
}

// Test COPPA flag is included in bid request when enabled
- (void)testCOPPAFlagIncludedWhenEnabled {
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config toJSON];
    
    NSNumber *coppaFlag = json[@"regs"][@"coppa"];
    XCTAssertEqualObjects(coppaFlag, @1, @"COPPA flag should be included when enabled");
}

// Test COPPA flag is not included when disabled
- (void)testCOPPAFlagNotIncludedWhenDisabled {
    [self.privacyService setIsAgeRestrictedUser:@NO];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config toJSON];
    
    NSNumber *coppaFlag = json[@"regs"][@"coppa"];
    XCTAssertNil(coppaFlag, @"COPPA flag should not be included when disabled");
}

#pragma mark - Personal Data Clearing in Bid Requests

// Test IFA is cleared when privacy requires it
- (void)testIFAClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (COPPA enabled)
    [self setupUSUser];
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config toJSON];
    
    NSString *ifa = json[@"device"][@"ifa"];
    XCTAssertEqualObjects(ifa, @"", @"IFA should be cleared when privacy requires it");
}

// Test geo coordinates are cleared when privacy requires it
- (void)testGeoCoordinatesClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (COPPA enabled)
    [self setupUSUser];
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithLocation:testLocation];
    NSDictionary *json = [config toJSON];
    
    NSDictionary *geo = json[@"device"][@"geo"];
    XCTAssertNil(geo[@"lat"], @"Latitude should be cleared when privacy requires it");
    XCTAssertNil(geo[@"lon"], @"Longitude should be cleared when privacy requires it");
    XCTAssertNotNil(geo[@"utcoffset"], @"UTC offset should remain when geo coordinates are cleared");
}

// Test user data is cleared when privacy requires it
- (void)testUserDataClearedWhenPrivacyRequires {
    // Set up scenario that requires data clearing (COPPA enabled)
    [self setupUSUser];
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config toJSON];
    
    NSDictionary *userExt = json[@"user"][@"ext"];
    XCTAssertNil(userExt[@"data"], @"User data should be cleared when privacy requires it");
    XCTAssertNil(userExt[@"eids"], @"User EIDs should be cleared when privacy requires it");
}

// Test device and geo data is preserved when privacy allows it
- (void)testDataPreservedWhenPrivacyAllows {
    // Set up scenario that allows data (non-US user)
    [self setupNonUSUser];
    [self.privacyService setIsAgeRestrictedUser:@NO];
    
    CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithLocation:testLocation];
    NSDictionary *json = [config toJSON];
    
    // IFA should be present (not empty)
    NSString *ifa = json[@"device"][@"ifa"];
    XCTAssertNotEqualObjects(ifa, @"", @"IFA should not be cleared when privacy allows");
    
    // Geo coordinates should be present
    NSDictionary *geo = json[@"device"][@"geo"];
    XCTAssertNotNil(geo[@"lat"], @"Latitude should be present when privacy allows");
    XCTAssertNotNil(geo[@"lon"], @"Longitude should be present when privacy allows");
}

#pragma mark - Legacy CCPA Integration

// Test legacy CCPA string is still included alongside GPP
- (void)testLegacyCCPAStringIncludedWithGPP {
    NSString *ccpaString = @"1YNN";
    NSString *gppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    
    [self.privacyService setCCPAPrivacyString:ccpaString];
    [self.gppProvider setGppString:gppString];
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfigWithPrivacyService];
    NSDictionary *json = [config toJSON];
    
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
                      impModel:nil
                      settings:[CLXSettings sharedInstance]];
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
                      impModel:nil
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
                      impModel:nil
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
}

- (void)setupUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"TX"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
}

- (void)setupNonUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"ON"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
}

@end
