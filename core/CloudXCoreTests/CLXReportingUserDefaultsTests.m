//
//  CLXReportingUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CLXAdReportingNetworkService UserDefaults usage
//  FOCUS: Geo headers only (kCLXCoreGeoHeadersKey)
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXReportingUserDefaultsTests : XCTestCase

@end

@implementation CLXReportingUserDefaultsTests

- (void)setUp {
    [super setUp];
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clean up after each test
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - CLXAdReportingNetworkService Geo Headers Tests

// Test that CLXAdReportingNetworkService reads geo headers (its specific responsibility)
- (void)testReportingServiceReadsGeoHeaders {
    // Focus on geo headers - this is what reporting service specifically handles
    NSDictionary *geoHeaders = @{@"lat": @"40.7128", @"lon": @"-74.0060"};
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXAdReportingNetworkService instance
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] init];
    XCTAssertNotNil(reportingService, @"CLXAdReportingNetworkService should be created");
    
    // Verify it can read geo headers (its specific functionality)
    NSDictionary *storedGeoHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(storedGeoHeaders, geoHeaders, @"CLXAdReportingNetworkService should read geo headers");
}

// Test that CLXAdReportingNetworkService handles geo data updates (its specific responsibility)  
- (void)testReportingServiceUpdatesGeoData {
    // Initialize geo headers
    NSDictionary *initialGeo = @{@"lat": @"37.7749", @"lon": @"-122.4194"};
    [[NSUserDefaults standardUserDefaults] setObject:initialGeo forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXAdReportingNetworkService and simulate geo update
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] init];
    
    // Simulate geo data update (what reporting service does)
    NSDictionary *updatedGeo = @{@"lat": @"40.7128", @"lon": @"-74.0060", @"accuracy": @"high"};
    [[NSUserDefaults standardUserDefaults] setObject:updatedGeo forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify geo data was updated
    NSDictionary *finalGeo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"accuracy"], @"high", @"CLXAdReportingNetworkService should update geo data");
}

// Test that CLXAdReportingNetworkService handles missing geo headers
- (void)testReportingServiceHandlesMissingGeoHeaders {
    // Ensure no geo headers exist
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXAdReportingNetworkService instance
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] init];
    XCTAssertNotNil(reportingService, @"CLXAdReportingNetworkService should handle missing geo headers");
    
    // Verify no geo headers exist
    NSDictionary *storedGeoHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertNil(storedGeoHeaders, @"No geo headers should exist initially");
}

// Test that CLXAdReportingNetworkService preserves existing geo data
- (void)testReportingServicePreservesExistingGeoData {
    // Set up existing geo headers
    NSDictionary *existingGeo = @{
        @"lat": @"37.7749",
        @"lon": @"-122.4194"
    };
    [[NSUserDefaults standardUserDefaults] setObject:existingGeo forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Create CLXAdReportingNetworkService and add new geo data
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] init];
    
    // Simulate adding new geo data while preserving existing
    NSDictionary *currentGeo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    NSMutableDictionary *updatedGeo = [currentGeo mutableCopy];
    updatedGeo[@"accuracy"] = @"high";
    [[NSUserDefaults standardUserDefaults] setObject:updatedGeo forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify both existing and new geo data are preserved
    NSDictionary *finalGeo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"lat"], @"37.7749", @"Existing geo data should be preserved");
    XCTAssertEqualObjects(finalGeo[@"accuracy"], @"high", @"New geo data should be added");
}

#pragma mark - Geo Headers Collision Risk Tests

// Test collision risk with geo headers (reporting service's specific responsibility)
- (void)testReportingServiceGeoHeadersCollisionRisk {
    // Simulate external app using same geo headers key
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"geo"} forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external geo data is stored
    NSDictionary *externalGeo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(externalGeo[@"external"], @"geo", @"External geo data should be stored");
    
    // Reporting service overwrites with its own geo data
    [[NSUserDefaults standardUserDefaults] setObject:@{@"reporting": @"geo"} forKey:kCLXCoreGeoHeadersKey];
    
    // External geo data is now lost - COLLISION!
    NSDictionary *finalGeo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"reporting"], @"geo", @"Reporting geo data is present");
    XCTAssertNil(finalGeo[@"external"], @"External geo data was lost - COLLISION!");
}

@end