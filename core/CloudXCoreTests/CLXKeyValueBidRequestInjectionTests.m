//
//  CLXKeyValueBidRequestInjectionTests.m
//  CloudXCoreTests
//
//  Tests for key-value injection into bid requests with privacy compliance
//  SOLID Principles: 
//  - Single Responsibility: Tests ONLY KV injection behavior (not general privacy)
//  - Dependency Inversion: Uses mock privacy service via dependency injection
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CoreLocation/CoreLocation.h>

// Test category for dependency injection
@interface CLXBiddingConfigRequest (KVInjectionTesting)
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

// Mock privacy service for testing
@interface MockPrivacyServiceForKV : CLXPrivacyService
@property (nonatomic, assign) BOOL shouldClearPersonalData;
@end

@implementation MockPrivacyServiceForKV
- (BOOL)shouldClearPersonalData {
    return _shouldClearPersonalData;
}
@end

@interface CLXKeyValueBidRequestInjectionTests : XCTestCase
@property (nonatomic, strong) CLXKeyValueState *kvState;
@property (nonatomic, strong) MockPrivacyServiceForKV *mockPrivacyService;
@property (nonatomic, strong) CLXSDKConfigResponse *mockSDKConfig;
@property (nonatomic, strong) CLXConfigImpressionModel *mockImpModel;
@end

@implementation CLXKeyValueBidRequestInjectionTests

- (void)setUp {
    [super setUp];
    
    // SOLID: Dependency Injection - use mock privacy service
    self.mockPrivacyService = [[MockPrivacyServiceForKV alloc] init];
    self.mockPrivacyService.shouldClearPersonalData = NO; // Default: allow personal data
    
    // Set up key-value state
    self.kvState = [CLXKeyValueState shared];
    [self.kvState clearAllKeyValues];
    
    // Configure server paths
    CLXSDKConfigKeyValueObject *paths = [[CLXSDKConfigKeyValueObject alloc] init];
    paths.userKeyValues = @"user.ext.data";
    paths.appKeyValues = @"app.ext.data";
    paths.eids = @"user.ext.eids[*]";
    self.kvState.keyValuePaths = paths;
    
    // Mock SDK config
    self.mockSDKConfig = [[CLXSDKConfigResponse alloc] init];
    self.mockSDKConfig.appID = @"test-app-id";
    self.mockSDKConfig.accountID = @"test-account";
    
    self.mockImpModel = [[CLXConfigImpressionModel alloc] initWithSDKConfig:self.mockSDKConfig
                                                                  auctionID:@"test-auction"
                                                              testGroupName:@"test-group"];
}

- (void)tearDown {
    [self.kvState clearAllKeyValues];
    [super tearDown];
}

#pragma mark - Helper Method

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
           skadRequestParameters:nil
                          tmax:@3.0
                      impModel:self.mockImpModel
                      settings:[CLXSettings sharedInstance]
                privacyService:self.mockPrivacyService]; // SOLID: Dependency injection!
}

#pragma mark - User Key-Values with Privacy Tests

- (void)testUserKeyValues_IncludedWhenPrivacyAllows {
    // SOLID: Single Responsibility - tests ONLY user KV injection with consent
    [self.kvState setUserKeyValue:@"age" value:@"28"];
    [self.kvState setUserKeyValue:@"interest" value:@"gaming"];
    self.mockPrivacyService.shouldClearPersonalData = NO; // Privacy allows
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *userData = json[@"user"][@"ext"][@"data"];
    XCTAssertNotNil(userData, @"User ext.data should exist when privacy allows");
    XCTAssertEqualObjects(userData[@"age"], @"28", @"User KV should be at correct path");
    XCTAssertEqualObjects(userData[@"interest"], @"gaming", @"User KV should be at correct path");
}

- (void)testUserKeyValues_ClearedWhenPrivacyDenies {
    // SOLID: Single Responsibility - tests ONLY user KV removal for privacy
    [self.kvState setUserKeyValue:@"age" value:@"28"];
    [self.kvState setUserKeyValue:@"interest" value:@"gaming"];
    self.mockPrivacyService.shouldClearPersonalData = YES; // Privacy blocks
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *userExt = json[@"user"][@"ext"];
    XCTAssertTrue([userExt count] == 0 || userExt[@"data"] == nil, 
                  @"User KVs should be cleared when privacy denies");
}

#pragma mark - App Key-Values Independent of Privacy

- (void)testAppKeyValues_AlwaysIncluded_EvenWithPrivacyDenial {
    // SOLID: Single Responsibility - tests app KVs are NOT affected by privacy
    [self.kvState setAppKeyValue:@"version" value:@"1.2.3"];
    [self.kvState setAppKeyValue:@"platform" value:@"ios"];
    self.mockPrivacyService.shouldClearPersonalData = YES; // Privacy blocks user data
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *appData = json[@"app"][@"ext"][@"data"];
    XCTAssertNotNil(appData, @"App ext.data should exist regardless of privacy");
    XCTAssertEqualObjects(appData[@"version"], @"1.2.3", @"App KV should be at correct path");
    XCTAssertEqualObjects(appData[@"platform"], @"ios", @"App KV should be at correct path");
}

- (void)testAppKeyValues_IncludedWhenPrivacyAllows {
    [self.kvState setAppKeyValue:@"version" value:@"1.2.3"];
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSDictionary *appData = json[@"app"][@"ext"][@"data"];
    XCTAssertEqualObjects(appData[@"version"], @"1.2.3", @"App KV should be included");
}

#pragma mark - Mixed Scenario Tests

- (void)testMixedKeyValues_PrivacyDenial_OnlyAppKVsIncluded {
    // SOLID: Tests the INTERACTION between user and app KVs under privacy
    [self.kvState setUserKeyValue:@"age" value:@"28"];
    [self.kvState setUserKeyValue:@"gender" value:@"male"];
    [self.kvState setAppKeyValue:@"version" value:@"1.2.3"];
    [self.kvState setAppKeyValue:@"build" value:@"debug"];
    self.mockPrivacyService.shouldClearPersonalData = YES;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    // User KVs should be cleared
    NSDictionary *userExt = json[@"user"][@"ext"];
    XCTAssertTrue([userExt count] == 0 || userExt[@"data"] == nil, 
                  @"User KVs should be cleared");
    
    // App KVs should persist
    NSDictionary *appData = json[@"app"][@"ext"][@"data"];
    XCTAssertEqualObjects(appData[@"version"], @"1.2.3", @"App KV should persist");
    XCTAssertEqualObjects(appData[@"build"], @"debug", @"App KV should persist");
}

- (void)testMixedKeyValues_PrivacyAllows_BothIncluded {
    [self.kvState setUserKeyValue:@"age" value:@"28"];
    [self.kvState setAppKeyValue:@"version" value:@"1.2.3"];
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    XCTAssertEqualObjects(json[@"user"][@"ext"][@"data"][@"age"], @"28", 
                         @"User KV should be included");
    XCTAssertEqualObjects(json[@"app"][@"ext"][@"data"][@"version"], @"1.2.3", 
                         @"App KV should be included");
}

#pragma mark - Hashed User ID Tests

- (void)testHashedUserId_IncludedWhenPrivacyAllows {
    self.kvState.hashedUserId = @"hashed-abc123";
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSArray *eids = json[@"user"][@"ext"][@"eids"];
    XCTAssertNotNil(eids, @"EIDs should exist when privacy allows");
    XCTAssertEqual(eids.count, 1, @"Should have one EID entry");
    XCTAssertEqualObjects(eids[0][@"uids"][0][@"id"], @"hashed-abc123", 
                         @"Hashed user ID should be at correct path");
}

- (void)testHashedUserId_ClearedWhenPrivacyDenies {
    self.kvState.hashedUserId = @"hashed-abc123";
    self.mockPrivacyService.shouldClearPersonalData = YES;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    NSArray *eids = json[@"user"][@"ext"][@"eids"];
    XCTAssertTrue(eids == nil || eids.count == 0, 
                  @"EIDs should be cleared when privacy denies");
}

#pragma mark - No Key-Values Set Tests

- (void)testNoKeyValuesSet_NoInjection {
    // SOLID: Tests default behavior when no KVs are set
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    // Should not have ext.data fields if no KVs were set
    id userExtData = json[@"user"][@"ext"][@"data"];
    id appExtData = json[@"app"][@"ext"][@"data"];
    
    // Either nil or empty
    XCTAssertTrue(userExtData == nil || [userExtData count] == 0, 
                  @"User ext.data should not exist without KVs");
    XCTAssertTrue(appExtData == nil || [appExtData count] == 0, 
                  @"App ext.data should not exist without KVs");
}

#pragma mark - No Server Paths Configured Tests

- (void)testNoServerPaths_NoInjection {
    // SOLID: Tests behavior when server doesn't provide path configuration
    [self.kvState setUserKeyValue:@"age" value:@"28"];
    [self.kvState setAppKeyValue:@"version" value:@"1.2.3"];
    self.kvState.keyValuePaths = nil; // No server configuration
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    NSDictionary *json = [config json];
    
    // Without paths, KVs cannot be injected
    id userExtData = json[@"user"][@"ext"][@"data"];
    id appExtData = json[@"app"][@"ext"][@"data"];
    
    XCTAssertTrue(userExtData == nil || [userExtData count] == 0, 
                  @"Cannot inject without path configuration");
    XCTAssertTrue(appExtData == nil || [appExtData count] == 0, 
                  @"Cannot inject without path configuration");
}

#pragma mark - Empty Key-Values Tests

- (void)testEmptyKeyValues_NoInjection {
    // SOLID: Tests behavior with empty string values
    [self.kvState setUserKeyValue:@"" value:@"value"];
    [self.kvState setAppKeyValue:@"key" value:@""];
    self.mockPrivacyService.shouldClearPersonalData = NO;
    
    CLXBiddingConfigRequest *config = [self createTestBiddingConfig];
    
    // Should handle gracefully without crashing
    XCTAssertNoThrow([config json], @"Should handle empty key-values gracefully");
}

@end

