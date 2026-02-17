//
//  CLXBiddingConfigUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CLXBiddingConfig User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXBiddingConfigUserDefaultsTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXBiddingConfigUserDefaultsTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [NSString stringWithFormat:@"CLXBiddingConfigUserDefaultsTests-%@", [[NSUUID UUID] UUIDString]];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
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
    [self.testDefaults setObject:initialMetrics forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    XCTAssertNotNil(biddingConfig, @"CLXBiddingConfig should be created");
    
    // Verify it can read the metrics dictionary with ACTUAL unprefixed key
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(storedMetrics, initialMetrics, @"CLXBiddingConfig should read metrics with unprefixed key");
}

// Test that CLXBiddingConfig reads encoded string using ACTUAL key
- (void)testBiddingConfigReadsEncodedString {
    // Set up encoded string with ACTUAL unprefixed key
    NSString *encodedString = @"test-encoded-bidding-string";
    [self.testDefaults setObject:encodedString forKey:kCLXCoreEncodedStringKey];
    [self.testDefaults synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Verify it can read the encoded string with ACTUAL unprefixed key
    NSString *storedEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, encodedString, @"CLXBiddingConfig should read encoded string with unprefixed key");
}

// Test that CLXBiddingConfig handles missing data gracefully
- (void)testBiddingConfigHandlesMissingData {
    // Ensure no data exists
    [self.testDefaults removeObjectForKey:kCLXCoreMetricsDictKey];
    [self.testDefaults removeObjectForKey:kCLXCoreEncodedStringKey];
    [self.testDefaults synchronize];
    
    // Create CLXBiddingConfig instance
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    XCTAssertNotNil(biddingConfig, @"CLXBiddingConfig should handle missing data");
    
    // Verify no data exists with ACTUAL unprefixed keys
    NSDictionary *storedMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *storedEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
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
    [self.testDefaults setObject:existingMetrics forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults synchronize];
    
    // Create CLXBiddingConfig
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Simulate adding new metrics while preserving existing ones
    NSDictionary *currentMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedMetrics = [currentMetrics mutableCopy];
    updatedMetrics[@"new_bidding_metric"] = @"new_value";
    [self.testDefaults setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
    
    // Verify both existing and new metrics are preserved with ACTUAL unprefixed key
    NSDictionary *finalMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"existing_bidding_metric"], @"existing_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"another_bidding_metric"], @"another_value", @"Existing metrics should be preserved");
    XCTAssertEqualObjects(finalMetrics[@"new_bidding_metric"], @"new_value", @"New metrics should be added");
}

// Test that CLXBiddingConfig can work with encoded string updates
- (void)testBiddingConfigWorksWithEncodedStringUpdates {
    // Set up initial encoded string with ACTUAL unprefixed key
    NSString *initialEncodedString = @"initial-encoded-string";
    [self.testDefaults setObject:initialEncodedString forKey:kCLXCoreEncodedStringKey];
    [self.testDefaults synchronize];
    
    // Create CLXBiddingConfig
    CLXBiddingConfig *biddingConfig = [[CLXBiddingConfig alloc] init];
    
    // Verify initial encoded string
    NSString *storedEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, initialEncodedString, @"Initial encoded string should be stored");
    
    // Update encoded string
    NSString *updatedEncodedString = @"updated-encoded-string";
    [self.testDefaults setObject:updatedEncodedString forKey:kCLXCoreEncodedStringKey];
    
    // Verify updated encoded string with ACTUAL unprefixed key
    NSString *finalEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(finalEncodedString, updatedEncodedString, @"Updated encoded string should be stored");
}

#pragma mark - Collision Risk Tests

// Test collision risk with CLXBiddingConfig data
- (void)testBiddingConfigCollisionRisk {
    // Simulate external app using same keys
    [self.testDefaults setObject:@{@"external": @"bidding_data"} forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults setObject:@"external-encoded-string" forKey:kCLXCoreEncodedStringKey];
    [self.testDefaults synchronize];
    
    // Verify external data is stored
    NSDictionary *externalMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *externalEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(externalMetrics[@"external"], @"bidding_data", @"External metrics should be stored");
    XCTAssertEqualObjects(externalEncodedString, @"external-encoded-string", @"External encoded string should be stored");
    
    // CLXBiddingConfig-related operations overwrite with their own data
    [self.testDefaults setObject:@{@"bidding": @"config_data"} forKey:kCLXCoreMetricsDictKey];
    [self.testDefaults setObject:@"bidding-encoded-string" forKey:kCLXCoreEncodedStringKey];
    
    // External data is now lost - COLLISION!
    NSDictionary *finalMetrics = [self.testDefaults dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *finalEncodedString = [self.testDefaults stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(finalMetrics[@"bidding"], @"config_data", @"Bidding config metrics are present");
    XCTAssertNil(finalMetrics[@"external"], @"External metrics were lost - COLLISION!");
    XCTAssertEqualObjects(finalEncodedString, @"bidding-encoded-string", @"Bidding config encoded string is present");
    XCTAssertNotEqualObjects(finalEncodedString, @"external-encoded-string", @"External encoded string was lost - COLLISION!");
}

@end
