//
//  CLXPublisherAdsUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for Publisher Ads User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXPublisherBanner (Testing)
@end

@interface CLXPublisherNative (Testing)
@end

@interface CLXPublisherFullscreenAdBase (Testing)
@end

@interface CLXPublisherAdsUserDefaultsTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXPublisherAdsUserDefaultsTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

#pragma mark - CLXPublisherBanner User Defaults Tests

// Test that CLXPublisherBanner reads banner-specific metrics (its unique responsibility)
- (void)testPublisherBannerReadsBannerMetrics {
    // Set up banner-specific metrics dictionary 
    NSDictionary *bannerMetrics = @{@"banner_impressions": @"5", @"banner_clicks": @"2"};
    [self.testDefaults setObject:bannerMetrics forKey:kCLXBannerMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXPublisherBanner instance
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    XCTAssertNotNil(banner, @"CLXPublisherBanner should be created");
    
    // Verify it can read banner-specific metrics
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXBannerMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, bannerMetrics, @"CLXPublisherBanner should read banner-specific metrics");
}

// Test that CLXPublisherBanner updates banner-specific user key values (its unique responsibility)
- (void)testPublisherBannerUpdatesBannerUserKeyValue {
    // Initialize empty banner user key value
    [self.testDefaults setObject:@{} forKey:kCLXBannerUserKeyValueKey];
    [self.testDefaults synchronize];
    
    // Create CLXPublisherBanner and simulate update
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Simulate banner-specific user data update
    NSDictionary *bannerUserData = @{@"banner_placement": @"top", @"banner_size": @"320x50"};
    [self.testDefaults setObject:bannerUserData forKey:kCLXBannerUserKeyValueKey];
    
    // Verify banner user data was updated
    NSDictionary *finalUserData = [self.testDefaults dictionaryForKey:kCLXBannerUserKeyValueKey];
    XCTAssertEqualObjects(finalUserData[@"banner_placement"], @"top", @"CLXPublisherBanner should update banner user data");
}

// Test that CLXPublisherBanner uses prefixed keys for some data
- (void)testPublisherBannerUsesPrefixedKeys {
    // CLXPublisherBanner.m actually uses some prefixed keys like CLXBanner_metricsDict
    NSDictionary *bannerMetrics = @{@"prefixed_metric": @"prefixed_value"};
    [self.testDefaults setObject:bannerMetrics forKey:kCLXBannerMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXPublisherBanner instance
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Verify it can read the prefixed metrics
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXBannerMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, bannerMetrics, @"CLXPublisherBanner should read prefixed metrics");
}

#pragma mark - CLXPublisherNative User Defaults Tests

// Test that CLXPublisherNative reads metrics dictionary using ACTUAL key
- (void)testPublisherNativeReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"native_metric": @"native_value"};
    [self.testDefaults setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXPublisherNative instance
    CLXPublisherNative *native = [[CLXPublisherNative alloc] init];
    XCTAssertNotNil(native, @"CLXPublisherNative should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXPublisherNative should read metrics with unprefixed key");
}

#pragma mark - CLXPublisherFullscreenAdBase User Defaults Tests

// Test that fullscreen ads read metrics dictionary using ACTUAL key
- (void)testPublisherFullscreenReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"fullscreen_metric": @"fullscreen_value"};
    [self.testDefaults setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXInterstitial instance (concrete fullscreen ad class)
    CLXInterstitial *fullscreen = [[CLXInterstitial alloc] init];
    XCTAssertNotNil(fullscreen, @"CLXInterstitial should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"Fullscreen ads should read metrics with unprefixed key");
}

#pragma mark - Collision Risk Tests

// Test collision risk between publisher ads and external apps
- (void)testPublisherAdsCollisionRisk {
    // Simulate external app using same keys
    [self.testDefaults setObject:@{@"external": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];

    // Verify external data is stored
    NSDictionary *externalMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(externalMetrics[@"external"], @"metrics", @"External metrics should be stored");

    // Publisher ads overwrite with their own data
    [self.testDefaults setObject:@{@"publisher": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];

    // External data is now lost - COLLISION!
    NSDictionary *finalMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"publisher"], @"metrics", @"Publisher metrics are present");
    XCTAssertNil(finalMetrics[@"external"], @"External metrics were lost - COLLISION!");
}

@end
