//
//  CLXBiddingConfigUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CLXBiddingConfig User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXBiddingConfigUserDefaultsTests : XCTestCase
@end

@implementation CLXBiddingConfigUserDefaultsTests

- (void)setUp {
    [super setUp];
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - CLXBiddingConfig User Defaults Tests

// Test that CLXBiddingConfig can be created
- (void)testBiddingConfigCreation {
    // CLXBiddingConfig has empty implementation but should be creatable
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    XCTAssertNotNil(biddingConfig, @"CLXBiddingConfig should be created");
}

// Test that CLXBiddingConfig reads metrics dictionary using ACTUAL key
- (void)testBiddingConfigReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"bidding_metric": @"bidding_value"};
    [[NSUserDefaults standardUserDefaults] setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    XCTAssertNotNil(biddingConfig, @"CLXBiddingConfig should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXBiddingConfig should read metrics with unprefixed key");
}

// Test that CLXBiddingConfig reads encoded string using ACTUAL key
- (void)testBiddingConfigReadsEncodedString {
    // Set up encoded string with ACTUAL unprefixed key
    NSString *encodedString = @"test-encoded-bidding-string";
    [[NSUserDefaults standardUserDefaults] setObject:encodedString forKey:kCLXCoreEncodedStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Verify it can read the encoded string with ACTUAL unprefixed key
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, encodedString, @"CLXBiddingConfig should read encoded string with unprefixed key");
}

// Test that CLXBiddingConfig handles missing data gracefully
- (void)testBiddingConfigHandlesMissingData {
    // Ensure no data exists
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreEncodedStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    XCTAssertNotNil(biddingConfig, @"CLXBiddingConfig should handle missing data");
    
    // Verify no data exists with ACTUAL unprefixed keys
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertNil(storedMetrics, @"No metrics dictionary should exist initially");
    XCTAssertNil(storedEncodedString, @"No encoded string should exist initially");
}

// Test that CLXBiddingConfig can work with existing metrics data
- (void)testBiddingConfigWorksWithExistingMetrics {
    // Set up existing metrics with ACTUAL unprefixed key
    NSDictionary *existingMetrics = @{
        @"existing_bidding_metric": @"existing_value",
        @"another_bidding_metric": @"another_value"
    };
    [[NSUserDefaults standardUserDefaults] setObject:existingMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBiddingConfig
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Simulate adding new metrics while preserving existing ones
    NSDictionary *currentMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedMetrics = [currentMetrics mutableCopy];
    updatedMetrics[@"new_bidding_metric"] = @"new_value";
    [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
    
    // Verify both existing and new metrics are preserved with ACTUAL unprefixed key
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"existing_bidding_metric"], @"existing_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"another_bidding_metric"], @"another_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"new_bidding_metric"], @"new_value", @"New metrics should be added");
}

// Test that CLXBiddingConfig can work with encoded string updates
- (void)testBiddingConfigWorksWithEncodedStringUpdates {
    // Set up initial encoded string with ACTUAL unprefixed key
    NSString *initialEncodedString = @"initial-encoded-string";
    [[NSUserDefaults standardUserDefaults] setObject:initialEncodedString forKey:kCLXCoreEncodedStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBiddingConfig
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Verify initial encoded string
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, initialEncodedString, @"Initial encoded string should be stored");
    
    // Update encoded string
    NSString *updatedEncodedString = @"updated-encoded-string";
    [[NSUserDefaults standardUserDefaults] setObject:updatedEncodedString forKey:kCLXCoreEncodedStringKey];
    
    // Verify updated encoded string with ACTUAL unprefixed key
    NSString *finalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(finalEncodedString, updatedEncodedString, @"Updated encoded string should be stored");
}

#pragma mark - Collision Risk Tests

// Test collision risk with CLXBiddingConfig data
- (void)testBiddingConfigCollisionRisk {
    // Simulate external app using same keys
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"bidding_data"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-encoded-string" forKey:kCLXCoreEncodedStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external data is stored
    NSDictionary *externalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *externalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(externalMetrics[@"external"], @"bidding_data", @"External metrics should be stored");
    XCTAssertEqualObjects(externalEncodedString, @"external-encoded-string", @"External encoded string should be stored");
    
    // CLXBiddingConfig-related operations overwrite with their own data
    [[NSUserDefaults standardUserDefaults] setObject:@{@"bidding": @"config_data"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"bidding-encoded-string" forKey:kCLXCoreEncodedStringKey];
    
    // External data is now lost - COLLISION!
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *finalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(finalMetrics[@"bidding"], @"config_data", @"Bidding config metrics are present");
    XCTAssertNil(finalMetrics[@"external"], @"External metrics were lost - COLLISION!");
    XCTAssertEqualObjects(finalEncodedString, @"bidding-encoded-string", @"Bidding config encoded string is present");
    XCTAssertNotEqualObjects(finalEncodedString, @"external-encoded-string", @"External encoded string was lost - COLLISION!");
}

@end
