//
//  CLXBidAdSourceUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CLXBidAdSource User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXBidAdSource (Testing)
- (void)requestBidWithAdUnitID:(NSString *)adUnitID
                    completion:(void (^)(NSString *bidResponse, NSError *error))completion;
@end

@interface CLXBidAdSourceUserDefaultsTests : XCTestCase
@end

@implementation CLXBidAdSourceUserDefaultsTests

- (void)setUp {
    [super setUp];
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - CLXBidAdSource User Defaults Tests

// Test that CLXBidAdSource reads metrics dictionary using ACTUAL key
- (void)testBidAdSourceReadsMetricsDict {
    // Set up initial metrics dictionary with ACTUAL unprefixed key
    NSDictionary *initialMetrics = @{@"test_metric": @"test_value"};
    [[NSUserDefaults standardUserDefaults] setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBidAdSource instance
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] init];
    XCTAssertNotNil(bidAdSource, @"CLXBidAdSource should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXBidAdSource should read metrics with unprefixed key");
}

// Test that CLXBidAdSource updates metrics dictionary using ACTUAL key
- (void)testBidAdSourceUpdatesMetricsDict {
    // Initialize empty metrics dictionary with ACTUAL unprefixed key
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBidAdSource and simulate bid request
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] init];
    
    // Simulate the metrics update that happens during bid requests
    NSDictionary *existingMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedMetrics = [existingMetrics mutableCopy];
    updatedMetrics[@"bid_request_count"] = @"1";
    [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
    
    // Verify metrics were updated with ACTUAL unprefixed key
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"bid_request_count"], @"1", @"CLXBidAdSource should update metrics with unprefixed key");
}

// Test that CLXBidAdSource handles missing metrics dictionary
- (void)testBidAdSourceHandlesMissingMetricsDict {
    // Ensure no metrics dictionary exists
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBidAdSource instance
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] init];
    XCTAssertNotNil(bidAdSource, @"CLXBidAdSource should handle missing metrics dictionary");
    
    // Verify no metrics dictionary exists with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNil(storedMetrics, @"No metrics dictionary should exist initially");
}

// Test that CLXBidAdSource preserves existing metrics data
- (void)testBidAdSourcePreservesExistingMetrics {
    // Set up existing metrics with ACTUAL unprefixed key
    NSDictionary *existingMetrics = @{
        @"existing_metric": @"existing_value",
        @"another_metric": @"another_value"
    };
    [[NSUserDefaults standardUserDefaults] setObject:existingMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXBidAdSource and add new metrics
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] init];
    
    // Simulate adding new metrics while preserving existing ones
    NSDictionary *currentMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedMetrics = [currentMetrics mutableCopy];
    updatedMetrics[@"new_metric"] = @"new_value";
    [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
    
    // Verify both existing and new metrics are preserved with ACTUAL unprefixed key
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"existing_metric"], @"existing_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"another_metric"], @"another_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"new_metric"], @"new_value", @"New metrics should be added");
}

// Test collision risk with CLXBidAdSource metrics
- (void)testBidAdSourceCollisionRisk {
    // Simulate external app using same key
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"data"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external data is stored
    NSDictionary *externalData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(externalData[@"external"], @"data", @"External data should be stored");
    
    // CLXBidAdSource overwrites with its own metrics
    [[NSUserDefaults standardUserDefaults] setObject:@{@"cloudx_bid": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    
    // External data is now lost - COLLISION!
    NSDictionary *finalData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalData[@"cloudx_bid"], @"metrics", @"CLXBidAdSource data is present");
    XCTAssertNil(finalData[@"external"], @"External data was lost - COLLISION!");
}

@end
