//
//  CLXAppIDIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests to ensure app ID is correctly passed through the entire ad request flow
//  for all ad formats. These tests prevent regression of the impModel:nil bug.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXPublisherFullscreenAd.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXPublisherNative.h>

static NSString * const kTestAppID = @"test-app-id-integration";
static NSString * const kTestAccountID = @"test-account-integration";
static NSString * const kTestSessionID = @"test-session-integration";

@interface CLXAppIDIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@property (nonatomic, strong) CLXSettings *mockSettings;
@property (nonatomic, strong) CLXPrivacyService *mockPrivacyService;
@end

@implementation CLXAppIDIntegrationTests

- (void)setUp {
    [super setUp];
    
    // Create mock SDK config with appID - this simulates successful SDK initialization
    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = kTestAppID;
    self.mockSDKConfig.accountID = kTestAccountID;
    self.mockSDKConfig.sessionID = kTestSessionID;
    
    // Create mock impression model that contains the SDK config
    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction-integration"
                                                              testGroupName:@"test-group"];
    
    // Create required services
    self.mockSettings = [CLXSettings sharedInstance];
    self.mockPrivacyService = [CLXPrivacyService sharedInstance];
    
    // Set up UserDefaults with appKey (different from appID)
    [[NSUserDefaults standardUserDefaults] setObject:@"test-app-key-different" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    // Clean up UserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

#pragma mark - Integration Tests for All Ad Formats

- (void)testBannerBidRequestContainsCorrectAppID {
    // Test that banner ads include the correct app ID from SDK config
    CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:CLXAdTypeBanner];
    NSDictionary *json = [bidRequest json];
    
    [self verifyAppIDInBidRequest:json expectedAppID:kTestAppID adFormat:@"Banner"];
    
    // Verify banner-specific fields
    NSArray *impressions = json[@"imp"];
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @0, @"Banner should have instl=0");
    XCTAssertNotNil(impression[@"banner"], @"Banner impression should have banner object");
}

- (void)testInterstitialBidRequestContainsCorrectAppID {
    // Test that interstitial ads include the correct app ID from SDK config
    CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:CLXAdTypeInterstitial];
    NSDictionary *json = [bidRequest json];
    
    [self verifyAppIDInBidRequest:json expectedAppID:kTestAppID adFormat:@"Interstitial"];
    
    // Verify interstitial-specific fields
    NSArray *impressions = json[@"imp"];
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @1, @"Interstitial should have instl=1");
    XCTAssertNotNil(impression[@"banner"], @"Interstitial impression should have banner object (META quirk)");
}

- (void)testNativeBidRequestContainsCorrectAppID {
    // Test that native ads include the correct app ID from SDK config
    CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:CLXAdTypeNative 
                                                     nativeRequirements:[self createNativeRequirements]];
    NSDictionary *json = [bidRequest json];
    
    [self verifyAppIDInBidRequest:json expectedAppID:kTestAppID adFormat:@"Native"];
    
    // Verify native-specific fields
    NSArray *impressions = json[@"imp"];
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @0, @"Native should have instl=0");
    XCTAssertNotNil(impression[@"native"], @"Native impression should have native object");
}

- (void)testRewardedBidRequestContainsCorrectAppID {
    // Test that rewarded ads include the correct app ID from SDK config
    CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:CLXAdTypeRewarded];
    NSDictionary *json = [bidRequest json];
    
    [self verifyAppIDInBidRequest:json expectedAppID:kTestAppID adFormat:@"Rewarded"];
    
    // Verify rewarded-specific fields
    NSArray *impressions = json[@"imp"];
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @1, @"Rewarded should have instl=1");
    XCTAssertNotNil(impression[@"video"], @"Rewarded impression should have video object");
}

- (void)testMRECBidRequestContainsCorrectAppID {
    // Test that MREC ads include the correct app ID from SDK config
    CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:CLXAdTypeMrec];
    NSDictionary *json = [bidRequest json];
    
    [self verifyAppIDInBidRequest:json expectedAppID:kTestAppID adFormat:@"MREC"];
    
    // Verify MREC-specific fields
    NSArray *impressions = json[@"imp"];
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @0, @"MREC should have instl=0");
    XCTAssertNotNil(impression[@"banner"], @"MREC impression should have banner object");
}

#pragma mark - Regression Tests

- (void)testAppIDIsNotEmptyWhenSDKConfigIsPresent {
    // Regression test: Ensure app ID is never empty when SDK config is available
    for (NSNumber *adTypeNum in @[@(CLXAdTypeBanner), @(CLXAdTypeInterstitial), @(CLXAdTypeNative), @(CLXAdTypeRewarded), @(CLXAdTypeMrec)]) {
        CLXAdType adType = adTypeNum.integerValue;
        CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:adType];
        NSDictionary *json = [bidRequest json];
        
        NSDictionary *appSection = json[@"app"];
        NSString *appID = appSection[@"id"];
        XCTAssertNotNil(appID, @"App ID should not be nil for ad type %@", @(adType));
        XCTAssertNotEqualObjects(appID, @"", @"App ID should not be empty string for ad type %@", @(adType));
        XCTAssertEqualObjects(appID, kTestAppID, @"App ID should match SDK config for ad type %@", @(adType));
    }
}

- (void)testAppIDIsNotAppKeyValue {
    // Regression test: Ensure app ID is not confused with app key
    NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    
    for (NSNumber *adTypeNum in @[@(CLXAdTypeBanner), @(CLXAdTypeInterstitial), @(CLXAdTypeNative), @(CLXAdTypeRewarded), @(CLXAdTypeMrec)]) {
        CLXAdType adType = adTypeNum.integerValue;
        CLXBiddingConfigRequest *bidRequest = [self createBidRequestForAdType:adType];
        NSDictionary *json = [bidRequest json];
        
        NSDictionary *appSection = json[@"app"];
        NSString *appID = appSection[@"id"];
        XCTAssertNotEqualObjects(appID, appKey, @"App ID should NOT be app key value for ad type %@", @(adType));
        XCTAssertEqualObjects(appID, kTestAppID, @"App ID should be SDK config value for ad type %@", @(adType));
    }
}

- (void)testNilImpModelResultsInEmptyAppID {
    // Test what happens when impModel is nil (the bug that was fixed)
    CLXBiddingConfigRequest *bidRequest = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeInterstitial
                     adUnitID:@"test-ad-unit"
            storedImpressionId:@"test-impression"
                        dealID:nil
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-publisher"
                      location:nil
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nil
           skadRequestParameters:nil
                          tmax:@3.0
                      impModel:nil  // This simulates the bug
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    NSDictionary *json = [bidRequest json];
    NSDictionary *appSection = json[@"app"];
    NSString *appID = appSection[@"id"];
    
    // When impModel is nil, app ID should be empty (this is the bug behavior)
    XCTAssertEqualObjects(appID, @"", @"When impModel is nil, app ID should be empty string (bug behavior)");
}

#pragma mark - Helper Methods

- (CLXBiddingConfigRequest *)createBidRequestForAdType:(CLXAdType)adType {
    return [self createBidRequestForAdType:adType nativeRequirements:nil];
}

- (CLXBiddingConfigRequest *)createBidRequestForAdType:(CLXAdType)adType nativeRequirements:(id)nativeRequirements {
    return [[CLXBiddingConfigRequest alloc] 
        initWithAdType:adType
                     adUnitID:[NSString stringWithFormat:@"test-ad-unit-%@", @(adType)]
            storedImpressionId:[NSString stringWithFormat:@"test-impression-%@", @(adType)]
                        dealID:nil
                     bidFloor:@1.0
                displayManager:@"test-manager"
            displayManagerVer:@"1.0"
                   publisherID:@"test-publisher"
                      location:nil
                     userAgent:@"test-agent"
                   adapterInfo:@{}
           nativeAdRequirements:nativeRequirements
           skadRequestParameters:nil
                          tmax:@3.0
                      impModel:self.mockImpModel  // This ensures app ID is included
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
}

- (NSDictionary *)createNativeRequirements {
    return @{
        @"assets": @[@{
            @"id": @1,
            @"required": @1,
            @"title": @{@"len": @25}
        }, @{
            @"id": @2,
            @"required": @1,
            @"img": @{@"w": @300, @"h": @250}
        }]
    };
}

- (void)verifyAppIDInBidRequest:(NSDictionary *)json expectedAppID:(NSString *)expectedAppID adFormat:(NSString *)adFormat {
    // Verify basic structure
    XCTAssertNotNil(json, @"%@ bid request JSON should not be nil", adFormat);
    
    // Verify app section exists
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"%@ bid request should have app section", adFormat);
    
    // Verify app.id is correct
    NSString *appID = appSection[@"id"];
    XCTAssertNotNil(appID, @"%@ app.id should not be nil", adFormat);
    XCTAssertEqualObjects(appID, expectedAppID, @"%@ app.id should match expected value", adFormat);
    
    // Verify app.id is not empty
    XCTAssertNotEqualObjects(appID, @"", @"%@ app.id should not be empty string", adFormat);
    
    // Verify other app fields
    XCTAssertNotNil(appSection[@"bundle"], @"%@ app.bundle should exist", adFormat);
    XCTAssertNotNil(appSection[@"ver"], @"%@ app.ver should exist", adFormat);
    XCTAssertNotNil(appSection[@"publisher"], @"%@ app.publisher should exist", adFormat);
}

@end
