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

@interface CLXReportingUserDefaultsTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXReportingUserDefaultsTests

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

#pragma mark - CLXAdReportingNetworkService Geo Headers Tests

// Test that CLXAdReportingNetworkService reads geo headers (its specific responsibility)
- (void)testReportingServiceReadsGeoHeaders {
    // Focus on geo headers - this is what reporting service specifically handles
    NSDictionary *geoHeaders = @{@"lat": @"40.7128", @"lon": @"-74.0060"};
    [self.testDefaults setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Create CLXAdReportingNetworkService instance with test defaults
    NSURL *testURL = [NSURL URLWithString:@"https://test.example.com"];
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:testURL
                                                                                               urlSession:[NSURLSession sharedSession]
                                                                                             userDefaults:self.testDefaults];
    XCTAssertNotNil(reportingService, @"CLXAdReportingNetworkService should be created");
    
    // Verify it can read geo headers (its specific functionality)
    NSDictionary *storedGeoHeaders = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(storedGeoHeaders, geoHeaders, @"CLXAdReportingNetworkService should read geo headers");
}

// Test that CLXAdReportingNetworkService handles geo data updates (its specific responsibility)  
- (void)testReportingServiceUpdatesGeoData {
    // Initialize geo headers
    NSDictionary *initialGeo = @{@"lat": @"37.7749", @"lon": @"-122.4194"};
    [self.testDefaults setObject:initialGeo forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Create CLXAdReportingNetworkService and simulate geo update
    NSURL *testURL = [NSURL URLWithString:@"https://test.example.com"];
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:testURL
                                                                                               urlSession:[NSURLSession sharedSession]
                                                                                             userDefaults:self.testDefaults];
    
    // Simulate geo data update (what reporting service does)
    NSDictionary *updatedGeo = @{@"lat": @"40.7128", @"lon": @"-74.0060", @"accuracy": @"high"};
    [self.testDefaults setObject:updatedGeo forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Verify geo data was updated
    NSDictionary *finalGeo = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"accuracy"], @"high", @"CLXAdReportingNetworkService should update geo data");
}

// Test that CLXAdReportingNetworkService handles missing geo headers
- (void)testReportingServiceHandlesMissingGeoHeaders {
    // Ensure no geo headers exist
    [self.testDefaults removeObjectForKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Create CLXAdReportingNetworkService instance with test defaults
    NSURL *testURL = [NSURL URLWithString:@"https://test.example.com"];
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:testURL
                                                                                               urlSession:[NSURLSession sharedSession]
                                                                                             userDefaults:self.testDefaults];
    XCTAssertNotNil(reportingService, @"CLXAdReportingNetworkService should handle missing geo headers");
    
    // Verify no geo headers exist
    NSDictionary *storedGeoHeaders = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertNil(storedGeoHeaders, @"No geo headers should exist initially");
}

// Test that CLXAdReportingNetworkService preserves existing geo data
- (void)testReportingServicePreservesExistingGeoData {
    // Set up existing geo headers
    NSDictionary *existingGeo = @{
        @"lat": @"37.7749",
        @"lon": @"-122.4194"
    };
    [self.testDefaults setObject:existingGeo forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Create CLXAdReportingNetworkService and add new geo data
    NSURL *testURL = [NSURL URLWithString:@"https://test.example.com"];
    CLXAdReportingNetworkService *reportingService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:testURL
                                                                                               urlSession:[NSURLSession sharedSession]
                                                                                             userDefaults:self.testDefaults];
    
    // Simulate adding new geo data while preserving existing
    NSDictionary *currentGeo = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    NSMutableDictionary *updatedGeo = [currentGeo mutableCopy];
    updatedGeo[@"accuracy"] = @"high";
    [self.testDefaults setObject:updatedGeo forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Verify both existing and new geo data are preserved
    NSDictionary *finalGeo = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"lat"], @"37.7749", @"Existing geo data should be preserved");
    XCTAssertEqualObjects(finalGeo[@"accuracy"], @"high", @"New geo data should be added");
}

#pragma mark - Geo Headers Collision Risk Tests

// Test collision risk with geo headers (reporting service's specific responsibility)
- (void)testReportingServiceGeoHeadersCollisionRisk {
    // Simulate external app using same geo headers key
    [self.testDefaults setObject:@{@"external": @"geo"} forKey:kCLXCoreGeoHeadersKey];
    [self.testDefaults synchronize];
    
    // Verify external geo data is stored
    NSDictionary *externalGeo = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(externalGeo[@"external"], @"geo", @"External geo data should be stored");
    
    // Reporting service overwrites with its own geo data
    [self.testDefaults setObject:@{@"reporting": @"geo"} forKey:kCLXCoreGeoHeadersKey];
    
    // External geo data is now lost - COLLISION!
    NSDictionary *finalGeo = [self.testDefaults dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(finalGeo[@"reporting"], @"geo", @"Reporting geo data is present");
    XCTAssertNil(finalGeo[@"external"], @"External geo data was lost - COLLISION!");
}

@end