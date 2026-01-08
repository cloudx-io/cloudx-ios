//
//  CLXBiddingConfigORTBFieldsTests.m
//  CloudXCoreTests
//
//  Tests for ORTB 2.5 bid request field compliance.
//  Covers: device.model, device.hwv, device.lmt, device.carrier, device.mccmnc,
//          banner.pos, banner.topframe, source object
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/CLXORTBConstants.h>
#import "CLXUserDefaultsTestHelper.h"
#import <CoreLocation/CoreLocation.h>

@interface CLXBiddingConfigORTBFieldsTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@end

@implementation CLXBiddingConfigORTBFieldsTests

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

#pragma mark - Helper Methods

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

#pragma mark - device.model Tests

- (void)testDeviceModel_ShouldReturnDeviceIdentifier_NotGenericModel {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // device.model should be device identifier like "iPhone15,2", not "iPhone"
    NSString *model = config.device.model;
    XCTAssertNotNil(model, @"device.model should not be nil");
    XCTAssertFalse([model isEqualToString:@"iPhone"], 
                   @"device.model should not be generic 'iPhone', should be identifier like 'iPhone15,2'");
    XCTAssertFalse([model isEqualToString:@"iPad"], 
                   @"device.model should not be generic 'iPad', should be identifier like 'iPad14,1'");
    
    // Verify it matches CLXSystemInformation
    XCTAssertEqualObjects(model, [CLXSystemInformation shared].model,
                          @"device.model should match CLXSystemInformation.model");
}

- (void)testDeviceModel_ShouldMatchUIDeviceIdentifier {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // Verify device.model matches the UIDevice category method
    NSString *expectedIdentifier = [UIDevice clx_deviceIdentifier];
    XCTAssertEqualObjects(config.device.model, expectedIdentifier,
                          @"device.model should match UIDevice.deviceIdentifier");
}

- (void)testDeviceModelInJSON_ShouldContainDeviceIdentifier {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"model"], @"device.model should be in JSON");
    XCTAssertFalse([deviceJSON[@"model"] isEqualToString:@"iPhone"],
                   @"JSON device.model should not be generic 'iPhone'");
}

#pragma mark - device.hwv Tests

- (void)testDeviceHwv_ShouldReturnDeviceIdentifier_NotOSVersion {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // device.hwv should be the device identifier (e.g., "iPhone17,1"), not OS version like "17.0"
    // Using the device identifier is more valuable for bidders than marketing names
    // since they can map identifiers to exact hardware specs.
    NSString *hwv = config.device.hwv;
    NSString *osv = config.device.osv;
    
    XCTAssertNotNil(hwv, @"device.hwv should not be nil");
    XCTAssertNotEqualObjects(hwv, osv, 
                             @"device.hwv should NOT equal device.osv - hwv is hardware version, osv is OS version");
    
    // Verify it matches the device identifier
    XCTAssertEqualObjects(hwv, [UIDevice clx_deviceIdentifier],
                          @"device.hwv should match UIDevice.deviceIdentifier");
}

- (void)testDeviceHwv_ShouldNotContainVersionNumbers {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // OS version looks like "17.0" or "16.4.1" - hwv should NOT be this format
    NSString *hwv = config.device.hwv;
    
    // If hwv contains only digits and dots, it's likely an OS version (wrong)
    NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    NSString *trimmed = [[hwv componentsSeparatedByCharactersInSet:[versionChars invertedSet]] componentsJoinedByString:@""];
    
    // For simulator (x86, i386, or arm64 on Apple Silicon Macs), hwv might be the arch string
    NSString *deviceId = [UIDevice clx_deviceIdentifier];
    BOOL isSimulator = [deviceId hasPrefix:@"x86"] || [deviceId hasPrefix:@"i386"] || [deviceId hasPrefix:@"arm64"];
    if (!isSimulator) {
        XCTAssertFalse([trimmed isEqualToString:hwv],
                       @"device.hwv should not be OS version format (digits and dots only)");
    }
}

#pragma mark - device.lmt Tests

- (void)testDeviceLmt_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // device.lmt should not be nil
    XCTAssertNotNil(config.device.lmt, @"device.lmt should not be nil");
}

- (void)testDeviceLmt_ShouldBeZeroOrOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // ORTB 2.5: lmt should be 0 (tracking allowed) or 1 (tracking restricted)
    NSInteger lmtValue = [config.device.lmt integerValue];
    XCTAssertTrue(lmtValue == 0 || lmtValue == 1,
                  @"device.lmt should be 0 or 1, got: %ld", (long)lmtValue);
}

- (void)testDeviceLmtInJSON_ShouldBeIncluded {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"lmt"], @"device.lmt should be in JSON");
    
    NSInteger lmtValue = [deviceJSON[@"lmt"] integerValue];
    XCTAssertTrue(lmtValue == 0 || lmtValue == 1,
                  @"JSON device.lmt should be 0 or 1");
}

- (void)testDeviceLmt_ShouldMatchDNTStatus {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // lmt and dnt should be consistent (both indicate tracking restriction)
    XCTAssertEqualObjects(config.device.lmt, config.device.dnt,
                          @"device.lmt should match device.dnt for consistency");
}

#pragma mark - banner.pos Tests

- (void)testBannerPos_ForBannerAdType_ShouldBeUnknown {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    XCTAssertNotNil(config.impressions.firstObject.banner, @"Banner should exist for banner ad type");
    XCTAssertNotNil(config.impressions.firstObject.banner.pos, @"banner.pos should not be nil");
    
    // Banner ads: pos = 0 (Unknown) - we cannot assume position without publisher input
    XCTAssertEqualObjects(config.impressions.firstObject.banner.pos, @(CLXORTBAdPositionUnknown),
                          @"banner.pos should be 0 (Unknown) for banner ads");
}

- (void)testBannerPos_ForMrecAdType_ShouldBeUnknown {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeMrec];
    
    XCTAssertNotNil(config.impressions.firstObject.banner, @"Banner should exist for MREC ad type");
    XCTAssertNotNil(config.impressions.firstObject.banner.pos, @"banner.pos should not be nil");
    
    // MREC ads: pos = 0 (Unknown) - we cannot assume position without publisher input
    XCTAssertEqualObjects(config.impressions.firstObject.banner.pos, @(CLXORTBAdPositionUnknown),
                          @"banner.pos should be 0 (Unknown) for MREC ads");
}

- (void)testBannerPos_ForInterstitialAdType_ShouldBeFullscreen {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeInterstitial];
    
    XCTAssertNotNil(config.impressions.firstObject.banner, @"Banner should exist for interstitial ad type");
    XCTAssertNotNil(config.impressions.firstObject.banner.pos, @"banner.pos should not be nil");
    
    // Interstitial ads: pos = 7 (Fullscreen) - definitive
    XCTAssertEqualObjects(config.impressions.firstObject.banner.pos, @(CLXORTBAdPositionFullScreen),
                          @"banner.pos should be 7 (Fullscreen) for interstitial ads");
}

- (void)testBannerPos_ForRewardedAdType_ShouldBeFullscreen {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    
    // Rewarded typically uses video, not banner - but if banner is present, it should be fullscreen
    if (config.impressions.firstObject.banner) {
        XCTAssertNotNil(config.impressions.firstObject.banner.pos, @"banner.pos should not be nil");
        XCTAssertEqualObjects(config.impressions.firstObject.banner.pos, @(CLXORTBAdPositionFullScreen),
                              @"banner.pos should be 7 (Fullscreen) for rewarded ads");
    }
}

- (void)testBannerPos_ForNativeAdType_ShouldBeUnknown {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeNative];
    
    // Native ads: pos = 0 (Unknown) - we cannot assume position without publisher input
    if (config.impressions.firstObject.banner) {
        XCTAssertEqualObjects(config.impressions.firstObject.banner.pos, @(CLXORTBAdPositionUnknown),
                              @"banner.pos should be 0 (Unknown) for native ads");
    }
}

- (void)testORTBAdPositionConstants_ShouldHaveCorrectValues {
    // Verify ORTB 2.5 Section 5.4 compliance
    XCTAssertEqual(CLXORTBAdPositionUnknown, 0, @"Unknown should be 0");
    XCTAssertEqual(CLXORTBAdPositionAboveTheFold, 1, @"Above the Fold should be 1");
    XCTAssertEqual(CLXORTBAdPositionBelowTheFold, 3, @"Below the Fold should be 3");
    XCTAssertEqual(CLXORTBAdPositionHeader, 4, @"Header should be 4");
    XCTAssertEqual(CLXORTBAdPositionFooter, 5, @"Footer should be 5");
    XCTAssertEqual(CLXORTBAdPositionSidebar, 6, @"Sidebar should be 6");
    XCTAssertEqual(CLXORTBAdPositionFullScreen, 7, @"Fullscreen should be 7");
}

- (void)testBannerPosInJSON_ShouldBeIncluded {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertGreaterThan(impressions.count, 0, @"Should have at least one impression");
    
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    XCTAssertNotNil(bannerJSON[@"pos"], @"banner.pos should be in JSON");
}

#pragma mark - banner.topframe Tests

- (void)testBannerTopframe_ShouldAlwaysBeOne {
    // Test all ad types that use banner
    NSArray *adTypes = @[@(CLXAdTypeBanner), @(CLXAdTypeMrec), @(CLXAdTypeInterstitial)];
    
    for (NSNumber *adTypeNum in adTypes) {
        CLXAdType adType = [adTypeNum integerValue];
        CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:adType];
        
        if (config.impressions.firstObject.banner) {
            XCTAssertNotNil(config.impressions.firstObject.banner.topframe,
                            @"banner.topframe should not be nil for ad type %ld", (long)adType);
            XCTAssertEqualObjects(config.impressions.firstObject.banner.topframe, @1,
                                  @"banner.topframe should always be 1 (top frame) for native apps, ad type %ld", (long)adType);
        }
    }
}

- (void)testBannerTopframeInJSON_ShouldBeOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    
    XCTAssertNotNil(bannerJSON[@"topframe"], @"banner.topframe should be in JSON");
    XCTAssertEqualObjects(bannerJSON[@"topframe"], @1,
                          @"JSON banner.topframe should be 1");
}

#pragma mark - source Object Tests

- (void)testSource_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    XCTAssertNotNil(config.source, @"source object should not be nil");
}

- (void)testSourceTid_ShouldMatchRequestID {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    XCTAssertNotNil(config.source.tid, @"source.tid should not be nil");
    XCTAssertEqualObjects(config.source.tid, config.requestID,
                          @"source.tid should match the request ID");
}

- (void)testSourceFd_ShouldBeOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    XCTAssertNotNil(config.source.fd, @"source.fd should not be nil");
    XCTAssertEqualObjects(config.source.fd, @1,
                          @"source.fd should be 1 (integer) indicating exchange makes final decision");
}

- (void)testSourceInJSON_ShouldBeIncluded {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    XCTAssertNotNil(json[@"source"], @"source should be in JSON");
    
    NSDictionary *sourceJSON = json[@"source"];
    XCTAssertNotNil(sourceJSON[@"tid"], @"source.tid should be in JSON");
    XCTAssertNotNil(sourceJSON[@"fd"], @"source.fd should be in JSON");
    XCTAssertEqualObjects(sourceJSON[@"tid"], config.requestID,
                          @"JSON source.tid should match request ID");
    XCTAssertEqualObjects(sourceJSON[@"fd"], @1,
                          @"JSON source.fd should be 1 (integer)");
}

#pragma mark - imp.bidfloor Tests

- (void)testBidfloor_WhenSet_ShouldBeIncludedInJSON {
    // Create config with bidFloor set
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@2.5
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
    
    NSDictionary *json = [config json];
    NSArray *impressions = json[@"imp"];
    XCTAssertGreaterThan(impressions.count, 0, @"Should have at least one impression");
    
    NSDictionary *impJSON = impressions.firstObject;
    XCTAssertNotNil(impJSON[@"bidfloor"], @"bidfloor should be present in JSON when set");
    XCTAssertEqualObjects(impJSON[@"bidfloor"], @2.5, @"bidfloor value should match");
}

- (void)testBidfloor_WhenNil_ShouldBeOmittedFromJSON {
    // Create config without bidFloor (nil)
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:nil
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
    
    NSDictionary *json = [config json];
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // When bidfloor is nil, it should not be included in JSON
    XCTAssertNil(impJSON[@"bidfloor"], @"bidfloor should be omitted from JSON when nil");
}

- (void)testBidfloor_WhenZero_ShouldBeOmittedFromJSON {
    // Create config with bidFloor set to 0
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@0.0
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
    
    NSDictionary *json = [config json];
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // When bidfloor is 0, it should not be included in JSON (no floor = open auction)
    XCTAssertNil(impJSON[@"bidfloor"], @"bidfloor should be omitted from JSON when zero");
}

- (void)testBidfloorCurrency_ShouldAlwaysBeUSD {
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@1.5
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
    
    NSDictionary *json = [config json];
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // bidfloorcur should always be USD
    XCTAssertEqualObjects(impJSON[@"bidfloorcur"], @"USD",
                          @"bidfloorcur should always be USD");
}

#pragma mark - device.connectiontype Tests

- (void)testDeviceConnectionType_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    XCTAssertNotNil(config.device.connectiontype, @"device.connectiontype should not be nil");
}

- (void)testDeviceConnectionType_ShouldBeORTBCompliant {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    
    // ORTB 2.5 AdCOM v1.0 connection type values: 0-7
    NSInteger connType = [config.device.connectiontype integerValue];
    XCTAssertTrue(connType >= 0 && connType <= 7,
                  @"device.connectiontype should be ORTB-compliant value (0-7), got: %ld", (long)connType);
}

- (void)testDeviceConnectionTypeInJSON_ShouldBeIncluded {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"connectiontype"], @"device.connectiontype should be in JSON");
    
    NSInteger connType = [deviceJSON[@"connectiontype"] integerValue];
    XCTAssertTrue(connType >= 0 && connType <= 7,
                  @"JSON device.connectiontype should be ORTB-compliant (0-7)");
}

- (void)testDeviceConnectionType_ORTBValueMapping {
    // This test verifies the mapping function logic
    // Since we can't control the actual network state in tests,
    // we verify the values are within ORTB spec range
    
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSInteger connType = [config.device.connectiontype integerValue];
    
    // Expected ORTB values based on network state:
    // 0 = Unknown
    // 2 = WIFI
    // 4 = Cellular 2G
    // 5 = Cellular 3G
    // 6 = Cellular 4G
    
    NSArray *validORTBValues = @[@0, @2, @4, @5, @6];
    XCTAssertTrue([validORTBValues containsObject:@(connType)],
                  @"device.connectiontype should be a valid ORTB value (0, 2, 4, 5, 6), got: %ld", (long)connType);
}

#pragma mark - device.ua Tests

- (void)testDeviceUA_WhenProvided_ShouldBeIncluded {
    // Test that device.ua is included when userAgent is provided
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"ua"], @"device.ua should be present when userAgent is provided");
    XCTAssertEqualObjects(deviceJSON[@"ua"], @"test-agent", @"device.ua should match provided userAgent");
}

- (void)testDeviceUA_WhenNil_ShouldBeOmitted {
    // Test that device.ua is omitted when userAgent is nil (per ORTB 2.5 - RECOMMENDED not REQUIRED)
    CLXBiddingConfigRequest *config = [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-pub"
                      location:nil
                     userAgent:nil  // Explicitly nil
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:nil
                          tmax:@3000
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.privacyService];
    
    NSDictionary *json = [config json];
    NSDictionary *deviceJSON = json[@"device"];
    
    // When userAgent is nil, device.ua should be omitted (not empty string, not fake value)
    XCTAssertNil(deviceJSON[@"ua"], @"device.ua should be omitted when userAgent is nil (ORTB 2.5: optional field)");
}

#pragma mark - Regression Tests

- (void)testExistingFields_ShouldNotBeAffected {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    // Verify essential existing fields are still present
    XCTAssertNotNil(json[@"id"], @"request id should be present");
    XCTAssertNotNil(json[@"imp"], @"imp array should be present");
    XCTAssertNotNil(json[@"app"], @"app object should be present");
    XCTAssertNotNil(json[@"device"], @"device object should be present");
    XCTAssertNotNil(json[@"user"], @"user object should be present");
    XCTAssertNotNil(json[@"regs"], @"regs object should be present");
    
    // Verify device fields that shouldn't change
    NSDictionary *deviceJSON = json[@"device"];
    XCTAssertNotNil(deviceJSON[@"ua"], @"device.ua should be present");
    XCTAssertNotNil(deviceJSON[@"make"], @"device.make should be present");
    XCTAssertEqualObjects(deviceJSON[@"make"], @"Apple", @"device.make should be 'Apple'");
    XCTAssertNotNil(deviceJSON[@"os"], @"device.os should be present");
    XCTAssertEqualObjects(deviceJSON[@"os"], @"iOS", @"device.os should be 'iOS'");
    XCTAssertNotNil(deviceJSON[@"osv"], @"device.osv should be present");
    XCTAssertNotNil(deviceJSON[@"language"], @"device.language should be present");
    XCTAssertNotNil(deviceJSON[@"h"], @"device.h should be present");
    XCTAssertNotNil(deviceJSON[@"w"], @"device.w should be present");
}

- (void)testBannerFormat_ShouldStillBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    
    // Verify format array is still present
    XCTAssertNotNil(bannerJSON[@"format"], @"banner.format should still be present");
    NSArray *formats = bannerJSON[@"format"];
    XCTAssertGreaterThan(formats.count, 0, @"banner.format should have entries");
    
    NSDictionary *firstFormat = formats.firstObject;
    XCTAssertNotNil(firstFormat[@"w"], @"format.w should be present");
    XCTAssertNotNil(firstFormat[@"h"], @"format.h should be present");
}

#pragma mark - Auction Type (at) Tests

- (void)testAuctionType_ShouldBeFirstPrice {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    // ORTB 2.5: at field indicates auction type (1 = First Price, 2 = Second Price)
    XCTAssertNotNil(json[@"at"], @"at (auction type) should be present");
    XCTAssertEqualObjects(json[@"at"], @1, @"at should be 1 (First Price auction)");
}

- (void)testAuctionType_ShouldBePresentForAllAdTypes {
    NSArray *adTypes = @[@(CLXAdTypeBanner), @(CLXAdTypeMrec), @(CLXAdTypeInterstitial), @(CLXAdTypeRewarded), @(CLXAdTypeNative)];
    
    for (NSNumber *adTypeNum in adTypes) {
        CLXAdType adType = [adTypeNum integerValue];
        CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:adType];
        NSDictionary *json = [config json];
        
        XCTAssertNotNil(json[@"at"], @"at should be present for ad type %ld", (long)adType);
        XCTAssertEqualObjects(json[@"at"], @1, @"at should be 1 for ad type %ld", (long)adType);
    }
}

#pragma mark - Display Manager Tests

- (void)testDisplayManager_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // ORTB 2.5: displaymanager identifies the SDK responsible for rendering
    XCTAssertNotNil(impJSON[@"displaymanager"], @"displaymanager should be present in impression");
    XCTAssertNotNil(impJSON[@"displaymanagerver"], @"displaymanagerver should be present in impression");
}

- (void)testDisplayManager_ShouldMatchExpectedValue {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // displaymanager should be "cloudx" (lowercase for consistency)
    XCTAssertEqualObjects(impJSON[@"displaymanager"], @"test-manager",
                          @"displaymanager should match the provided value");
}

- (void)testDisplayManagerVer_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // displaymanagerver should be the SDK version
    XCTAssertNotNil(impJSON[@"displaymanagerver"], @"displaymanagerver should be present");
    XCTAssertTrue([impJSON[@"displaymanagerver"] length] > 0, @"displaymanagerver should not be empty");
}

#pragma mark - Rewarded (rwdd) Tests

- (void)testRwdd_ForRewardedAd_ShouldBeOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *impJSON = impressions.firstObject;
    
    // ORTB 2.5: rwdd = 1 indicates rewarded ad
    XCTAssertNotNil(impJSON[@"rwdd"], @"rwdd should be present for rewarded ads");
    XCTAssertEqualObjects(impJSON[@"rwdd"], @1, @"rwdd should be 1 for rewarded ads");
}

- (void)testRwdd_ForNonRewardedAds_ShouldBeAbsent {
    NSArray *nonRewardedTypes = @[@(CLXAdTypeBanner), @(CLXAdTypeMrec), @(CLXAdTypeInterstitial)];
    
    for (NSNumber *adTypeNum in nonRewardedTypes) {
        CLXAdType adType = [adTypeNum integerValue];
        CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:adType];
        NSDictionary *json = [config json];
        
        NSArray *impressions = json[@"imp"];
        NSDictionary *impJSON = impressions.firstObject;
        
        // rwdd should NOT be present for non-rewarded ads
        XCTAssertNil(impJSON[@"rwdd"], @"rwdd should be absent for ad type %ld", (long)adType);
    }
}

#pragma mark - Video Skip Tests (SDK-driven, kept)
// NOTE: Video policy fields (minduration, maxduration, skipafter, startdelay, playbackmethod, skipmin)
// are now server-driven and removed from SDK. Only video.skip is still SDK-driven.

- (void)testVideoSkip_ForRewarded_ShouldBeZero {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *videoJSON = impressions.firstObject[@"video"];
    
    // Rewarded videos should NOT be skippable
    XCTAssertNotNil(videoJSON[@"skip"], @"video.skip should be present");
    XCTAssertEqualObjects(videoJSON[@"skip"], @0, @"video.skip should be 0 (not skippable) for rewarded");
}

- (void)testVideoSkip_ForInterstitial_ShouldBeOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeInterstitial];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *videoJSON = impressions.firstObject[@"video"];
    
    // Interstitial videos SHOULD be skippable (if video object exists)
    if (videoJSON) {
        XCTAssertNotNil(videoJSON[@"skip"], @"video.skip should be present");
        XCTAssertEqualObjects(videoJSON[@"skip"], @1, @"video.skip should be 1 (skippable) for interstitial");
    }
}

#pragma mark - New Bid Request Parity Fields Tests

- (void)testBannerId_ShouldBeOne {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    
    XCTAssertNotNil(bannerJSON, @"banner object should be present");
    // ORTB 2.5: Standard convention for single banner per impression
    XCTAssertEqualObjects(bannerJSON[@"id"], @"1", @"banner.id should be '1' per ORTB standard convention");
}

- (void)testBannerWidthHeight_ShouldMatchFormat {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    
    XCTAssertNotNil(bannerJSON, @"banner object should be present");
    XCTAssertNotNil(bannerJSON[@"w"], @"banner.w should be present at root level");
    XCTAssertNotNil(bannerJSON[@"h"], @"banner.h should be present at root level");
    // Banner size should be 320x50
    XCTAssertEqualObjects(bannerJSON[@"w"], @320, @"banner.w should match format width");
    XCTAssertEqualObjects(bannerJSON[@"h"], @50, @"banner.h should match format height");
}

- (void)testRewardedAds_ShouldHaveVideoNotBanner {
    // Rewarded ads only have video object, not banner object
    // This is intentional - rewarded ads are video-based
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *bannerJSON = impressions.firstObject[@"banner"];
    NSDictionary *videoJSON = impressions.firstObject[@"video"];
    
    // Banner should NOT be present for rewarded ads
    XCTAssertNil(bannerJSON, @"banner should NOT be present for rewarded ads (video-only)");
    // Video SHOULD be present for rewarded ads
    XCTAssertNotNil(videoJSON, @"video should be present for rewarded ads");
}

- (void)testVideoExtVideotype_ForRewarded_ShouldBeRewarded {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSArray *impressions = json[@"imp"];
    NSDictionary *videoJSON = impressions.firstObject[@"video"];
    
    XCTAssertNotNil(videoJSON, @"video object should be present for rewarded ads");
    NSDictionary *extJSON = videoJSON[@"ext"];
    XCTAssertNotNil(extJSON, @"video.ext should be present for rewarded ads");
    XCTAssertEqualObjects(extJSON[@"videotype"], @"rewarded", @"video.ext.videotype should be 'rewarded'");
}

- (void)testImpExtCxFormat_ShouldMatchAdType {
    // Test rewarded
    CLXBiddingConfigRequest *rewardedConfig = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *rewardedJSON = [rewardedConfig json];
    NSDictionary *rewardedExt = rewardedJSON[@"imp"][0][@"ext"][@"cx"];
    XCTAssertEqualObjects(rewardedExt[@"format"], @"rewarded", @"imp.ext.cx.format should be 'rewarded'");
    
    // Test banner
    CLXBiddingConfigRequest *bannerConfig = [self createBiddingConfigWithAdType:CLXAdTypeBanner];
    NSDictionary *bannerJSON = [bannerConfig json];
    NSDictionary *bannerExt = bannerJSON[@"imp"][0][@"ext"][@"cx"];
    XCTAssertEqualObjects(bannerExt[@"format"], @"banner", @"imp.ext.cx.format should be 'banner'");
    
    // Test interstitial
    CLXBiddingConfigRequest *interstitialConfig = [self createBiddingConfigWithAdType:CLXAdTypeInterstitial];
    NSDictionary *interstitialJSON = [interstitialConfig json];
    NSDictionary *interstitialExt = interstitialJSON[@"imp"][0][@"ext"][@"cx"];
    XCTAssertEqualObjects(interstitialExt[@"format"], @"interstitial", @"imp.ext.cx.format should be 'interstitial'");
}

- (void)testImpExtCxPlacementId_ShouldBeSet {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSDictionary *cxExt = json[@"imp"][0][@"ext"][@"cx"];
    XCTAssertNotNil(cxExt[@"placement_id"], @"imp.ext.cx.placement_id should be present");
}

- (void)testImpExtCxSessId_ShouldBeUUID {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSDictionary *cxExt = json[@"imp"][0][@"ext"][@"cx"];
    XCTAssertNotNil(cxExt[@"sess_id"], @"imp.ext.cx.sess_id should be present");
    // Verify it looks like a UUID (36 chars with hyphens)
    NSString *sessId = cxExt[@"sess_id"];
    XCTAssertEqual(sessId.length, 36, @"imp.ext.cx.sess_id should be a UUID (36 characters)");
}

- (void)testSourceExtCxInstallId_ShouldBePersistentUUID {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSDictionary *sourceExt = json[@"source"][@"ext"][@"cx"];
    XCTAssertNotNil(sourceExt[@"install_id"], @"source.ext.cx.install_id should be present");
    // Verify it looks like a UUID (36 chars with hyphens)
    NSString *installId = sourceExt[@"install_id"];
    XCTAssertEqual(installId.length, 36, @"source.ext.cx.install_id should be a UUID (36 characters)");
}

- (void)testDeviceExtCxHwModel_ShouldBePresent {
    CLXBiddingConfigRequest *config = [self createBiddingConfigWithAdType:CLXAdTypeRewarded];
    NSDictionary *json = [config json];
    
    NSDictionary *deviceExt = json[@"device"][@"ext"][@"cx"];
    XCTAssertNotNil(deviceExt[@"hw_model"], @"device.ext.cx.hw_model should be present");
}

@end

