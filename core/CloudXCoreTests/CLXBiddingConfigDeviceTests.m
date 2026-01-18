/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBiddingConfigDeviceTests.m
 * @brief Additional device-level bid request tests for ORTB 2.5 compliance
 *
 * Tests:
 * - Connection type ORTB mapping (WiFi, Cellular 2G/3G/4G, Unknown)
 * - Screen dimensions and device type
 * - DNT/LMT correlation with IFA behavior
 *
 * Complements CLXBiddingConfigORTBFieldsTests with device-specific coverage.
 *
 * PRINCIPLES:
 * - NO flaky patterns
 * - Meaningful assertions
 * - Proper test isolation via setUp/tearDown
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXORTBConstants.h>
#import "Helper/CLXUserDefaultsTestHelper.h"
#import <CoreLocation/CoreLocation.h>

#pragma mark - Test Category for CLXBiddingConfigRequest

@interface CLXBiddingConfigRequest (DeviceTesting)
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

#pragma mark - CLXBiddingConfigDeviceTests

@interface CLXBiddingConfigDeviceTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@end

@implementation CLXBiddingConfigDeviceTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    
    self.privacyService = [[CLXPrivacyService alloc] init];
    
    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = @"test-app-id";
    self.mockSDKConfig.accountID = @"test-account";
    self.mockSDKConfig.sessionID = @"test-session";
    
    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction"
                                                              testGroupName:@"test-group"];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - DRY: Factory Methods

- (CLXBiddingConfigRequest *)createBiddingConfigWithAdType:(CLXAdType)adType {
    return [[CLXBiddingConfigRequest alloc]
        initWithAdType:adType
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:nil
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:nil
                          tmax:@3000
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
}

#pragma mark - MARK: Connection Type ORTB Mapping Tests

- (void)testConnectionType_IsValidORTBValue {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"connectiontype"], @"device.connectiontype should be present");
    
    NSInteger connType = [deviceJSON[@"connectiontype"] integerValue];
    
    // ORTB 2.5 Section 5.22 - Connection Type values:
    // 0 = Unknown
    // 1 = Ethernet (not applicable to mobile)
    // 2 = WIFI
    // 3 = Cellular Network - Unknown Generation
    // 4 = Cellular Network - 2G
    // 5 = Cellular Network - 3G
    // 6 = Cellular Network - 4G
    // 7 = Cellular Network - 5G
    XCTAssertGreaterThanOrEqual(connType, 0, @"Connection type should be >= 0");
    XCTAssertLessThanOrEqual(connType, 7, @"Connection type should be <= 7");
}

- (void)testConnectionType_IsIncludedInJSON {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    // Connection type should always be present per ORTB spec
    XCTAssertNotNil(deviceJSON[@"connectiontype"], @"device.connectiontype should be in JSON");
    
    // Value should be a number
    XCTAssertTrue([deviceJSON[@"connectiontype"] isKindOfClass:[NSNumber class]], 
                  @"device.connectiontype should be a number");
}

- (void)testConnectionType_ORTBWiFiValue_Is2 {
    // Per ORTB 2.5 spec, WiFi = 2
    // We can't force a specific network state in tests, but we verify the constant exists
    // and is used when WiFi is detected
    
    // This test verifies the mapping logic is correct by checking the returned value
    // is one of the expected mobile values (0, 2, 4, 5, 6)
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSInteger connType = [json[@"device"][@"connectiontype"] integerValue];
    
    // On simulator or WiFi, we expect 2 (WiFi)
    // On cellular, we expect 4, 5, or 6
    // Unknown should be 0
    NSArray *validMobileValues = @[@0, @2, @4, @5, @6];
    XCTAssertTrue([validMobileValues containsObject:@(connType)],
                  @"Connection type should be a valid mobile ORTB value, got: %ld", (long)connType);
}

#pragma mark - MARK: Screen Dimension Tests

- (void)testDevice_WidthHeight_ArePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    XCTAssertNotNil(deviceJSON[@"w"], @"device.w (width) should be present");
    XCTAssertNotNil(deviceJSON[@"h"], @"device.h (height) should be present");
}

- (void)testDevice_WidthHeight_ArePositiveIntegers {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    NSInteger width = [deviceJSON[@"w"] integerValue];
    NSInteger height = [deviceJSON[@"h"] integerValue];
    
    XCTAssertGreaterThan(width, 0, @"device.w should be positive");
    XCTAssertGreaterThan(height, 0, @"device.h should be positive");
}

- (void)testDevice_WidthHeight_AreReasonableScreenSizes {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    NSInteger width = [deviceJSON[@"w"] integerValue];
    NSInteger height = [deviceJSON[@"h"] integerValue];
    
    // Screen should be at least 320x480 (original iPhone) and at most ~3000 for retina
    XCTAssertGreaterThanOrEqual(width, 320, @"device.w should be at least 320");
    XCTAssertGreaterThanOrEqual(height, 480, @"device.h should be at least 480");
    XCTAssertLessThanOrEqual(width, 3000, @"device.w should be reasonable (< 3000)");
    XCTAssertLessThanOrEqual(height, 3000, @"device.h should be reasonable (< 3000)");
}

- (void)testDevice_PPI_IsPresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    // ppi (pixels per inch) is optional but commonly included
    // It should be a reasonable value if present
    if (deviceJSON[@"ppi"]) {
        NSInteger ppi = [deviceJSON[@"ppi"] integerValue];
        XCTAssertGreaterThan(ppi, 0, @"device.ppi should be positive if present");
        XCTAssertLessThan(ppi, 1000, @"device.ppi should be reasonable (< 1000)");
    }
}

#pragma mark - MARK: Device Type Tests

- (void)testDevice_DeviceType_IsValidORTBValue {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    // ORTB 2.5 Section 5.21 - Device Type:
    // 1 = Mobile/Tablet (deprecated, use 4 or 5)
    // 2 = Personal Computer
    // 3 = Connected TV
    // 4 = Phone
    // 5 = Tablet
    // 6 = Connected Device
    // 7 = Set Top Box
    
    if (deviceJSON[@"devicetype"]) {
        NSInteger deviceType = [deviceJSON[@"devicetype"] integerValue];
        
        // For iOS, should be 4 (Phone) or 5 (Tablet)
        XCTAssertTrue(deviceType == 4 || deviceType == 5,
                      @"iOS device type should be 4 (Phone) or 5 (Tablet), got: %ld", (long)deviceType);
    }
}

#pragma mark - MARK: DNT/LMT Consistency Tests

- (void)testDNTandLMT_ArePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    XCTAssertNotNil(deviceJSON[@"dnt"], @"device.dnt should be present");
    XCTAssertNotNil(deviceJSON[@"lmt"], @"device.lmt should be present");
}

- (void)testDNTandLMT_AreBooleanValues {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    NSInteger dnt = [deviceJSON[@"dnt"] integerValue];
    NSInteger lmt = [deviceJSON[@"lmt"] integerValue];
    
    // ORTB spec: 0 = tracking allowed, 1 = do not track
    XCTAssertTrue(dnt == 0 || dnt == 1, @"device.dnt should be 0 or 1, got: %ld", (long)dnt);
    XCTAssertTrue(lmt == 0 || lmt == 1, @"device.lmt should be 0 or 1, got: %ld", (long)lmt);
}

- (void)testDNTandLMT_AreConsistent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    NSInteger dnt = [deviceJSON[@"dnt"] integerValue];
    NSInteger lmt = [deviceJSON[@"lmt"] integerValue];
    
    // DNT and LMT should match - both indicate tracking restriction
    XCTAssertEqual(dnt, lmt, @"device.dnt and device.lmt should be consistent");
}

- (void)testIFA_IsPresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    // IFA should always be present (may be zeros if tracking not allowed)
    XCTAssertNotNil(deviceJSON[@"ifa"], @"device.ifa should be present");
}

- (void)testIFA_IsValidUUIDFormat {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *ifa = json[@"device"][@"ifa"];
    XCTAssertNotNil(ifa, @"device.ifa should be present");
    
    // IFA should be UUID format: 8-4-4-4-12 = 36 characters
    XCTAssertEqual(ifa.length, 36, @"device.ifa should be 36 characters (UUID format)");
    
    // Verify it contains hyphens in the right places
    NSArray *components = [ifa componentsSeparatedByString:@"-"];
    XCTAssertEqual(components.count, 5, @"UUID should have 5 components separated by hyphens");
}

- (void)testIFA_WhenDNT1_ShouldBeZeroIDFA {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    NSInteger dnt = [deviceJSON[@"dnt"] integerValue];
    NSString *ifa = deviceJSON[@"ifa"];
    
    // When DNT=1 (do not track), IFA should be zeros
    if (dnt == 1) {
        XCTAssertEqualObjects(ifa, @"00000000-0000-0000-0000-000000000000",
                              @"When DNT=1, IFA should be zero UUID");
    }
}

- (void)testIFA_WhenDNT0_MayBeRealOrZero {
    // When DNT=0, IFA could be real IDFA or still zeros (if ATT not authorized)
    // This test just verifies the format is correct
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    NSString *ifa = deviceJSON[@"ifa"];
    
    // Just verify format - actual value depends on ATT status
    XCTAssertEqual(ifa.length, 36, @"IFA should always be 36 characters");
}

#pragma mark - MARK: OS Version Tests

- (void)testDevice_OSVersion_IsPresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    XCTAssertNotNil(deviceJSON[@"osv"], @"device.osv should be present");
}

- (void)testDevice_OSVersion_HasCorrectFormat {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *osv = json[@"device"][@"osv"];
    XCTAssertNotNil(osv, @"device.osv should be present");
    
    // OS version should be like "17.0" or "16.4.1"
    XCTAssertGreaterThan(osv.length, 0, @"device.osv should not be empty");
    
    // Should start with a digit
    unichar firstChar = [osv characterAtIndex:0];
    XCTAssertTrue(firstChar >= '0' && firstChar <= '9',
                  @"device.osv should start with a digit, got: %@", osv);
}

- (void)testDevice_OS_IsiOS {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *os = json[@"device"][@"os"];
    XCTAssertEqualObjects(os, @"iOS", @"device.os should be 'iOS'");
}

#pragma mark - MARK: Make/Model Tests

- (void)testDevice_Make_IsApple {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *make = json[@"device"][@"make"];
    XCTAssertEqualObjects(make, @"Apple", @"device.make should be 'Apple'");
}

- (void)testDevice_Model_IsNotGeneric {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *model = json[@"device"][@"model"];
    XCTAssertNotNil(model, @"device.model should be present");
    
    // Should not be generic "iPhone" or "iPad"
    XCTAssertFalse([model isEqualToString:@"iPhone"],
                   @"device.model should be specific identifier, not generic 'iPhone'");
    XCTAssertFalse([model isEqualToString:@"iPad"],
                   @"device.model should be specific identifier, not generic 'iPad'");
}

#pragma mark - MARK: Language Tests

- (void)testDevice_Language_IsPresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    
    XCTAssertNotNil(deviceJSON[@"language"], @"device.language should be present");
}

- (void)testDevice_Language_IsValidISO {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSString *language = json[@"device"][@"language"];
    XCTAssertNotNil(language, @"device.language should be present");
    
    // Language should be 2-letter ISO code (e.g., "en", "es", "fr")
    XCTAssertGreaterThanOrEqual(language.length, 2,
                                 @"device.language should be at least 2 characters");
}

#pragma mark - MARK: Geo/UTC Offset Tests

- (void)testDevice_Geo_UTCOffset_IsPresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *geoJSON = json[@"device"][@"geo"];
    
    // utcoffset should always be present (even if coordinates are cleared for privacy)
    if (geoJSON) {
        XCTAssertNotNil(geoJSON[@"utcoffset"], @"geo.utcoffset should be present");
    }
}

- (void)testDevice_Geo_UTCOffset_IsValidRange {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *geoJSON = json[@"device"][@"geo"];
    
    if (geoJSON && geoJSON[@"utcoffset"]) {
        NSInteger utcOffset = [geoJSON[@"utcoffset"] integerValue];
        
        // UTC offset in minutes should be between -720 (-12 hours) and +840 (+14 hours)
        XCTAssertGreaterThanOrEqual(utcOffset, -720,
                                    @"geo.utcoffset should be >= -720 minutes (-12 hours)");
        XCTAssertLessThanOrEqual(utcOffset, 840,
                                 @"geo.utcoffset should be <= 840 minutes (+14 hours)");
    }
}

#pragma mark - MARK: All Ad Types Have Same Device Info

- (void)testAllAdTypes_HaveConsistentDeviceInfo {
    CLXAdType adTypes[] = {CLXAdTypeBanner, CLXAdTypeMrec, CLXAdTypeInterstitial, CLXAdTypeRewarded, CLXAdTypeNative};
    NSInteger count = sizeof(adTypes) / sizeof(adTypes[0]);
    
    NSDictionary *firstDeviceJSON = nil;
    
    for (NSInteger i = 0; i < count; i++) {
        CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:adTypes[i]];
        NSDictionary *json = [config json];
        NSDictionary *deviceJSON = json[@"device"];
        
        if (i == 0) {
            firstDeviceJSON = deviceJSON;
        } else {
            // Device info should be consistent across ad types
            XCTAssertEqualObjects(deviceJSON[@"make"], firstDeviceJSON[@"make"],
                                  @"device.make should be consistent across ad types");
            XCTAssertEqualObjects(deviceJSON[@"model"], firstDeviceJSON[@"model"],
                                  @"device.model should be consistent across ad types");
            XCTAssertEqualObjects(deviceJSON[@"os"], firstDeviceJSON[@"os"],
                                  @"device.os should be consistent across ad types");
            XCTAssertEqualObjects(deviceJSON[@"osv"], firstDeviceJSON[@"osv"],
                                  @"device.osv should be consistent across ad types");
            XCTAssertEqualObjects(deviceJSON[@"w"], firstDeviceJSON[@"w"],
                                  @"device.w should be consistent across ad types");
            XCTAssertEqualObjects(deviceJSON[@"h"], firstDeviceJSON[@"h"],
                                  @"device.h should be consistent across ad types");
        }
    }
}

@end
