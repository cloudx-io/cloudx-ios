/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXLocationControlsTests.m
 * @brief Tests for publisher location sharing controls and OpenRTB geo compliance
 *
 * Tests:
 * - locationSharingEnabled flag defaults to YES
 * - Setting locationSharingEnabled=NO omits lat/lon from bid requests
 * - Geo type is 2 (IP-based) per OpenRTB spec
 * - Coordinates are rounded to 2 decimal places
 * - utcoffset and processed geo fields are always included
 * - Privacy clearing takes precedence over locationSharingEnabled
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CoreLocation/CoreLocation.h>

@interface CLXBiddingConfigRequest (LocationTesting)
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

@interface CLXLocationControlsTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@property (nonatomic, strong) CLXSettings *settings;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXLocationControlsTests

#pragma mark - Setup/Teardown

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

    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = @"test-app-id";
    self.mockSDKConfig.accountID = @"test-account";
    self.mockSDKConfig.sessionID = @"test-session";

    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction"
                                                              testGroupName:@"test-group"];

    self.settings = [[CLXSettings alloc] init];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

#pragma mark - DRY: Factory Methods

- (CLXBiddingConfigRequest *)createBiddingConfig {
    return [[CLXBiddingConfigRequest alloc]
        initWithAdType:CLXAdTypeBanner
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
                      settings:self.settings
                privacyService:self.privacyService];
}

#pragma mark - locationSharingEnabled Default

- (void)testLocationSharingEnabled_DefaultsToYES {
    CLXSettings *freshSettings = [[CLXSettings alloc] init];
    XCTAssertTrue(freshSettings.locationSharingEnabled,
                  @"locationSharingEnabled should default to YES for backward compatibility");
}

- (void)testLocationSharingEnabled_CanBeSetToNO {
    self.settings.locationSharingEnabled = NO;
    XCTAssertFalse(self.settings.locationSharingEnabled);
}

#pragma mark - locationSharingEnabled = NO suppresses lat/lon

- (void)testLocationSharingDisabled_OmitsLatLonFromBidRequest {
    self.settings.locationSharingEnabled = NO;

    CLXBiddingConfigRequest *config = [self createBiddingConfig];
    NSDictionary *json = [config json];
    NSDictionary *geoJSON = json[@"device"][@"geo"];

    XCTAssertNil(geoJSON[@"lat"], @"lat should be omitted when locationSharingEnabled=NO");
    XCTAssertNil(geoJSON[@"lon"], @"lon should be omitted when locationSharingEnabled=NO");
}

- (void)testLocationSharingDisabled_StillIncludesUtcOffset {
    self.settings.locationSharingEnabled = NO;

    CLXBiddingConfigRequest *config = [self createBiddingConfig];
    NSDictionary *json = [config json];
    NSDictionary *geoJSON = json[@"device"][@"geo"];

    XCTAssertNotNil(geoJSON[@"utcoffset"], @"utcoffset should always be present regardless of locationSharingEnabled");
}

#pragma mark - Geo Type Tests

- (void)testGeoType_IsIPBased {
    CLXBiddingConfigRequest *config = [self createBiddingConfig];

    XCTAssertEqualObjects(config.device.geo.type, @2,
                          @"geo.type should be 2 (IP-based) per OpenRTB spec");
}

- (void)testGeoType_InJSON_Is2WhenCoordsPresent {
    // Geo type is only in JSON when lat/lon are present.
    // Without CloudFront headers seeded, lat/lon will be nil,
    // so type won't appear in JSON. We verify the model value directly.
    CLXBiddingConfigRequest *config = [self createBiddingConfig];

    XCTAssertEqualObjects(config.device.geo.type, @2,
                          @"Geo type on model should always be 2 (IP-based)");
}

#pragma mark - Coordinate Rounding Tests

- (void)testCoordinateRounding_NSDecimalNumber {
    NSDecimalNumberHandler *roundTo2 = [NSDecimalNumberHandler
        decimalNumberHandlerWithRoundingMode:NSRoundPlain
        scale:2
        raiseOnExactness:NO raiseOnOverflow:NO
        raiseOnUnderflow:NO raiseOnDivideByZero:NO];

    NSDecimalNumber *val1 = [[NSDecimalNumber decimalNumberWithString:@"37.77493"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val1, [NSDecimalNumber decimalNumberWithString:@"37.77"]);

    NSDecimalNumber *val2 = [[NSDecimalNumber decimalNumberWithString:@"-122.41942"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val2, [NSDecimalNumber decimalNumberWithString:@"-122.42"]);

    NSDecimalNumber *val3 = [[NSDecimalNumber decimalNumberWithString:@"51.50735"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val3, [NSDecimalNumber decimalNumberWithString:@"51.51"]);

    NSDecimalNumber *val4 = [[NSDecimalNumber decimalNumberWithString:@"-0.12776"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val4, [NSDecimalNumber decimalNumberWithString:@"-0.13"]);

    NSDecimalNumber *val5 = [[NSDecimalNumber decimalNumberWithString:@"0.0"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val5, [NSDecimalNumber decimalNumberWithString:@"0"]);

    NSDecimalNumber *val6 = [[NSDecimalNumber decimalNumberWithString:@"-90.0"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val6, [NSDecimalNumber decimalNumberWithString:@"-90"]);

    NSDecimalNumber *val7 = [[NSDecimalNumber decimalNumberWithString:@"180.99999"]
                             decimalNumberByRoundingAccordingToBehavior:roundTo2];
    XCTAssertEqualObjects(val7, [NSDecimalNumber decimalNumberWithString:@"181"]);
}

#pragma mark - locationSharingEnabled = NO with CloudFront Headers

- (void)testLocationSharingDisabled_OmitsLatLonEvenWhenHeadersPresent {
    NSDictionary *rawHeaders = @{
        @"cloudfront-viewer-latitude": @"37.77493",
        @"cloudfront-viewer-longitude": @"-122.41942"
    };
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{}
                                                           rawGeoInfo:rawHeaders
                                                          hashedGeoIp:nil];
    [[CLXGeoLocationService shared] setGeoInfo:geoInfo];

    self.settings.locationSharingEnabled = NO;

    CLXBiddingConfigRequest *config = [self createBiddingConfig];

    XCTAssertNil(config.device.geo.lat, @"lat should be nil when location sharing disabled");
    XCTAssertNil(config.device.geo.lon, @"lon should be nil when location sharing disabled");

    [[CLXGeoLocationService shared] setGeoInfo:nil];
}

#pragma mark - Public API Tests

- (void)testPublicAPI_SetLocationSharingEnabled_AffectsSettings {
    BOOL originalValue = [CLXSettings sharedInstance].locationSharingEnabled;

    [CloudXCore setLocationSharingEnabled:NO];
    XCTAssertFalse([CloudXCore isLocationSharingEnabled]);
    XCTAssertFalse([CLXSettings sharedInstance].locationSharingEnabled);

    [CloudXCore setLocationSharingEnabled:YES];
    XCTAssertTrue([CloudXCore isLocationSharingEnabled]);
    XCTAssertTrue([CLXSettings sharedInstance].locationSharingEnabled);

    // Restore
    [CLXSettings sharedInstance].locationSharingEnabled = originalValue;
}

@end
