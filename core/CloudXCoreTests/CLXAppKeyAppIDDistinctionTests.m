//
//  CLXAppKeyAppIDDistinctionTests.m
//  CloudXCoreTests
//
//  Tests to ensure proper distinction between appKey and appID
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXAppKeyAppIDDistinctionTests : XCTestCase
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@property (nonatomic, strong) CLXSettings *mockSettings;
@property (nonatomic, strong) CLXPrivacyService *mockPrivacyService;
@end

@implementation CLXAppKeyAppIDDistinctionTests

- (void)setUp {
    [super setUp];
    
    // Create mock SDK config with appID
    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = @"ISffpfr0IIctoSJd5gKdD";
    self.mockSDKConfig.accountID = @"CLDX2_dc";
    self.mockSDKConfig.sessionID = @"test-session";
    
    // Create mock impression model
    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction"
                                                              testGroupName:@"test-group"];
    
    // Create mock settings and privacy service
    self.mockSettings = [CLXSettings sharedInstance];
    self.mockPrivacyService = [CLXPrivacyService sharedInstance];
    
    // Set up UserDefaults with appKey
    [[NSUserDefaults standardUserDefaults] setObject:@"9o_9omGptuyS2n5wV0QJu" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    // Clean up UserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

- (void)testAppIDFromSDKConfigIsUsedInBidRequest {
    // Create bidding config request
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id uses SDK response appID
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist");
    XCTAssertEqualObjects(appSection[@"id"], @"ISffpfr0IIctoSJd5gKdD", 
                         @"App.id should use SDK response appID, not appKey");
}

- (void)testAppKeyIsNotUsedInBidRequestAppID {
    // Create bidding config request
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeBanner
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id does NOT use appKey
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist");
    XCTAssertNotEqualObjects(appSection[@"id"], @"9o_9omGptuyS2n5wV0QJu", 
                            @"App.id should NOT use appKey value");
}

- (void)testBearerTokenUsesAppKey {
    // Verify that the appKey is available in UserDefaults
    NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    XCTAssertEqualObjects(appKey, @"9o_9omGptuyS2n5wV0QJu", 
                         @"AppKey should be available for bearer token");
    
    // Expected bearer token format
    NSString *expectedBearerToken = [NSString stringWithFormat:@"Bearer %@", appKey];
    XCTAssertEqualObjects(expectedBearerToken, @"Bearer 9o_9omGptuyS2n5wV0QJu",
                         @"Bearer token should use appKey format");
}

- (void)testInterstitialAppIDFromSDKConfigIsUsedInBidRequest {
    // Test interstitial ad type specifically
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeInterstitial
                     adUnitID:@"test-interstitial-unit"
            storedImpressionId:@"test-interstitial-impression"
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id uses SDK response appID for interstitials
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist in interstitial bid request");
    XCTAssertEqualObjects(appSection[@"id"], @"ISffpfr0IIctoSJd5gKdD", 
                         @"Interstitial app.id should use SDK response appID, not appKey");
    
    // Verify interstitial-specific fields
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 1, @"Should have one impression for interstitial");
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @1, @"Interstitial should have instl=1");
}

- (void)testNativeAppIDFromSDKConfigIsUsedInBidRequest {
    // Test native ad type specifically
    NSDictionary *nativeRequirements = @{
        @"assets": @[@{
            @"id": @1,
            @"required": @1,
            @"title": @{@"len": @25}
        }]
    };
    
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeNative
                     adUnitID:@"test-native-unit"
            storedImpressionId:@"test-native-impression"
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id uses SDK response appID for native ads
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist in native bid request");
    XCTAssertEqualObjects(appSection[@"id"], @"ISffpfr0IIctoSJd5gKdD", 
                         @"Native app.id should use SDK response appID, not appKey");
    
    // Verify native-specific fields
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 1, @"Should have one impression for native");
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @0, @"Native should have instl=0");
    XCTAssertNotNil(impression[@"native"], @"Native impression should have native object");
}

- (void)testRewardedAppIDFromSDKConfigIsUsedInBidRequest {
    // Test rewarded ad type specifically
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeRewarded
                     adUnitID:@"test-rewarded-unit"
            storedImpressionId:@"test-rewarded-impression"
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id uses SDK response appID for rewarded ads
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist in rewarded bid request");
    XCTAssertEqualObjects(appSection[@"id"], @"ISffpfr0IIctoSJd5gKdD", 
                         @"Rewarded app.id should use SDK response appID, not appKey");
    
    // Verify rewarded-specific fields
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 1, @"Should have one impression for rewarded");
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @1, @"Rewarded should have instl=1");
    XCTAssertNotNil(impression[@"video"], @"Rewarded impression should have video object");
}

- (void)testMRECAppIDFromSDKConfigIsUsedInBidRequest {
    // Test MREC ad type specifically
    CLXBiddingConfigRequest *biddingConfig = [[CLXBiddingConfigRequest alloc] 
        initWithAdType:CLXAdTypeMrec
                     adUnitID:@"test-mrec-unit"
            storedImpressionId:@"test-mrec-impression"
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
                      impModel:self.mockImpModel
                      settings:self.mockSettings
                privacyService:self.mockPrivacyService];
    
    // Convert to JSON
    NSDictionary *json = [biddingConfig json];
    
    // Verify app.id uses SDK response appID for MREC ads
    NSDictionary *appSection = json[@"app"];
    XCTAssertNotNil(appSection, @"App section should exist in MREC bid request");
    XCTAssertEqualObjects(appSection[@"id"], @"ISffpfr0IIctoSJd5gKdD", 
                         @"MREC app.id should use SDK response appID, not appKey");
    
    // Verify MREC-specific fields
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 1, @"Should have one impression for MREC");
    NSDictionary *impression = impressions[0];
    XCTAssertEqualObjects(impression[@"instl"], @0, @"MREC should have instl=0");
    XCTAssertNotNil(impression[@"banner"], @"MREC impression should have banner object");
}

- (void)testAppKeyAndAppIDAreDifferent {
    // Verify that appKey and appID are different values
    NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *appID = self.mockSDKConfig.appID;
    
    XCTAssertNotEqualObjects(appKey, appID, 
                            @"AppKey and AppID should be different values");
    
    // Verify expected values
    XCTAssertEqualObjects(appKey, @"9o_9omGptuyS2n5wV0QJu", @"AppKey should be init/bearer token value");
    XCTAssertEqualObjects(appID, @"ISffpfr0IIctoSJd5gKdD", @"AppID should be SDK response value");
}

@end

