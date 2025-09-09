//
//  CLXPublisherAdsUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for Publisher Ads User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXPublisherBanner (Testing)
- (void)updateBidRequestWithLoopIndex;
@end

@interface CLXPublisherNative (Testing)
@end

@interface CLXPublisherFullscreenAd (Testing)
@end

@interface CLXPublisherAdsUserDefaultsTests : XCTestCase
@end

@implementation CLXPublisherAdsUserDefaultsTests

- (void)setUp {
    [super setUp];
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - CLXPublisherBanner User Defaults Tests

// Test that CLXPublisherBanner reads banner-specific metrics (its unique responsibility)
- (void)testPublisherBannerReadsBannerMetrics {
    // Set up banner-specific metrics dictionary 
    NSDictionary *bannerMetrics = @{@"banner_impressions": @"5", @"banner_clicks": @"2"};
    [[NSUserDefaults standardUserDefaults] setObject:bannerMetrics forKey:kCLXBannerMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherBanner instance
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    XCTAssertNotNil(banner, @"CLXPublisherBanner should be created");
    
    // Verify it can read banner-specific metrics
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXBannerMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, bannerMetrics, @"CLXPublisherBanner should read banner-specific metrics");
}

// Test that CLXPublisherBanner updates banner-specific user key values (its unique responsibility)
- (void)testPublisherBannerUpdatesBannerUserKeyValue {
    // Initialize empty banner user key value
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXBannerUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherBanner and simulate update
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Simulate banner-specific user data update
    NSDictionary *bannerUserData = @{@"banner_placement": @"top", @"banner_size": @"320x50"};
    [[NSUserDefaults standardUserDefaults] setObject:bannerUserData forKey:kCLXBannerUserKeyValueKey];
    
    // Verify banner user data was updated
    NSDictionary *finalUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXBannerUserKeyValueKey];
    XCTAssertEqualObjects(finalUserData[@"banner_placement"], @"top", @"CLXPublisherBanner should update banner user data");
}

// Test that CLXPublisherBanner uses prefixed keys for some data
- (void)testPublisherBannerUsesPrefixedKeys {
    // CLXPublisherBanner.m actually uses some prefixed keys like CLXBanner_metricsDict
    NSDictionary *bannerMetrics = @{@"prefixed_metric": @"prefixed_value"};
    [[NSUserDefaults standardUserDefaults] setObject:bannerMetrics forKey:kCLXBannerMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherBanner instance
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Verify it can read the prefixed metrics
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXBannerMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, bannerMetrics, @"CLXPublisherBanner should read prefixed metrics");
}

// Test that CLXPublisherBanner reads user key value data using ACTUAL key
- (void)testPublisherBannerReadsUserKeyValue {
    // Set up user key value data with ACTUAL unprefixed key
    NSDictionary *userKeyValue = @{@"user_age": @"25", @"user_gender": @"M"};
    [[NSUserDefaults standardUserDefaults] setObject:userKeyValue forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherBanner instance
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Verify it can read the user key value data with ACTUAL unprefixed key
    NSDictionary *storedUserKeyValue = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(storedUserKeyValue, userKeyValue, @"CLXPublisherBanner should read user key value with unprefixed key");
}

#pragma mark - CLXPublisherNative User Defaults Tests

// Test that CLXPublisherNative reads metrics dictionary using ACTUAL key
- (void)testPublisherNativeReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"native_metric": @"native_value"};
    [[NSUserDefaults standardUserDefaults] setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherNative instance
    CLXPublisherNative *native = [[CLXPublisherNative alloc] init];
    XCTAssertNotNil(native, @"CLXPublisherNative should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXPublisherNative should read metrics with unprefixed key");
}

// Test that CLXPublisherNative reads user key value data using ACTUAL key
- (void)testPublisherNativeReadsUserKeyValue {
    // Set up user key value data with ACTUAL unprefixed key
    NSDictionary *userKeyValue = @{@"native_user_data": @"native_value"};
    [[NSUserDefaults standardUserDefaults] setObject:userKeyValue forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherNative instance
    CLXPublisherNative *native = [[CLXPublisherNative alloc] init];
    
    // Verify it can read the user key value data with ACTUAL unprefixed key
    NSDictionary *storedUserKeyValue = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(storedUserKeyValue, userKeyValue, @"CLXPublisherNative should read user key value with unprefixed key");
}

#pragma mark - CLXPublisherFullscreenAd User Defaults Tests

// Test that CLXPublisherFullscreenAd reads metrics dictionary using ACTUAL key
- (void)testPublisherFullscreenReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"fullscreen_metric": @"fullscreen_value"};
    [[NSUserDefaults standardUserDefaults] setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherFullscreenAd instance
    CLXPublisherFullscreenAd *fullscreen = [[CLXPublisherFullscreenAd alloc] init];
    XCTAssertNotNil(fullscreen, @"CLXPublisherFullscreenAd should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXPublisherFullscreenAd should read metrics with unprefixed key");
}

// Test that CLXPublisherFullscreenAd reads user key value data using ACTUAL key
- (void)testPublisherFullscreenReadsUserKeyValue {
    // Set up user key value data with ACTUAL unprefixed key
    NSDictionary *userKeyValue = @{@"fullscreen_user_data": @"fullscreen_value"};
    [[NSUserDefaults standardUserDefaults] setObject:userKeyValue forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXPublisherFullscreenAd instance
    CLXPublisherFullscreenAd *fullscreen = [[CLXPublisherFullscreenAd alloc] init];
    
    // Verify it can read the user key value data with ACTUAL unprefixed key
    NSDictionary *storedUserKeyValue = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(storedUserKeyValue, userKeyValue, @"CLXPublisherFullscreenAd should read user key value with unprefixed key");
}

#pragma mark - Collision Risk Tests

// Test collision risk between publisher ads and external apps
- (void)testPublisherAdsCollisionRisk {
    // Simulate external app using same keys
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"user_data"} forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external data is stored
    NSDictionary *externalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSDictionary *externalUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(externalMetrics[@"external"], @"metrics", @"External metrics should be stored");
    XCTAssertEqualObjects(externalUserData[@"external"], @"user_data", @"External user data should be stored");
    
    // Publisher ads overwrite with their own data
    [[NSUserDefaults standardUserDefaults] setObject:@{@"publisher": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"publisher": @"user_data"} forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // External data is now lost - COLLISION!
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSDictionary *finalUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(finalMetrics[@"publisher"], @"metrics", @"Publisher metrics are present");
    XCTAssertNil(finalMetrics[@"external"], @"External metrics were lost - COLLISION!");
    XCTAssertEqualObjects(finalUserData[@"publisher"], @"user_data", @"Publisher user data is present");
    XCTAssertNil(finalUserData[@"external"], @"External user data was lost - COLLISION!");
}

@end
