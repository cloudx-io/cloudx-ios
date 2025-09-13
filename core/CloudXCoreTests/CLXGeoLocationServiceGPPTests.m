//
//  CLXGeoLocationServiceGPPTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXGeoLocationServiceGPPTests : XCTestCase
@property (nonatomic, strong) CLXGeoLocationService *geoService;
@end

@implementation CLXGeoLocationServiceGPPTests

- (void)setUp {
    [super setUp];
    self.geoService = [CLXGeoLocationService shared];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Geographic Detection Tests

// Test US user detection with various country codes
- (void)testUSUserDetection {
    // Test USA country code (uppercase)
    [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": @"USA"}];
    XCTAssertTrue([self.geoService isUSUser], @"Should detect USA as US user");
    
    // Test usa country code (lowercase)
    [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": @"usa"}];
    XCTAssertTrue([self.geoService isUSUser], @"Should detect usa as US user (case insensitive)");
    
    // Test mixed case
    [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": @"UsA"}];
    XCTAssertTrue([self.geoService isUSUser], @"Should detect UsA as US user (case insensitive)");
    
    // Test non-US countries
    NSArray *nonUSCountries = @[@"CAN", @"GBR", @"FRA", @"DEU", @"JPN"];
    for (NSString *country in nonUSCountries) {
        [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": country}];
        XCTAssertFalse([self.geoService isUSUser], @"Should not detect %@ as US user", country);
    }
}

// Test California user detection
- (void)testCaliforniaUserDetection {
    // Test California with US country
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    }];
    XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect CA region in USA as California user");
    
    // Test california (lowercase)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"ca"
    }];
    XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect ca region as California user (case insensitive)");
    
    // Test other US states
    NSArray *otherStates = @[@"NY", @"TX", @"FL", @"WA"];
    for (NSString *state in otherStates) {
        [self setGeoHeaders:@{
            @"cloudfront-viewer-country-iso3": @"USA",
            @"cloudfront-viewer-country-region": state
        }];
        XCTAssertFalse([self.geoService isCaliforniaUser], @"Should not detect %@ as California user", state);
    }
    
    // Test CA region in non-US country (should not be California user)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"CA"
    }];
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should not detect CA region in Canada as California user");
}

// Test geo headers retrieval
- (void)testGeoHeadersRetrieval {
    NSDictionary *testHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA",
        @"cloudfront-viewer-latitude": @"37.7749",
        @"cloudfront-viewer-longitude": @"-122.4194"
    };
    
    [self setGeoHeaders:testHeaders];
    
    NSDictionary *retrievedHeaders = [self.geoService geoHeaders];
    XCTAssertEqualObjects(retrievedHeaders, testHeaders, @"Should retrieve geo headers correctly");
}

// Test missing geo headers handling
- (void)testMissingGeoHeadersHandling {
    // Clear geo headers
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreGeoHeadersKey];
    
    // Should default to non-US user when no geo data
    XCTAssertFalse([self.geoService isUSUser], @"Should default to non-US user when no geo headers");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should default to non-California user when no geo headers");
    
    NSDictionary *geoHeaders = [self.geoService geoHeaders];
    XCTAssertNil(geoHeaders, @"Should return nil when no geo headers are set");
}

// Test partial geo headers handling
- (void)testPartialGeoHeadersHandling {
    // Test with country but no region
    [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": @"USA"}];
    XCTAssertTrue([self.geoService isUSUser], @"Should detect US user with country only");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should not detect California user without region");
    
    // Test with region but no country
    [self setGeoHeaders:@{@"cloudfront-viewer-country-region": @"CA"}];
    XCTAssertFalse([self.geoService isUSUser], @"Should not detect US user without country");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should not detect California user without country");
}

// Test edge cases for geographic detection
- (void)testGeographicDetectionEdgeCases {
    // Test empty strings
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"",
        @"cloudfront-viewer-country-region": @""
    }];
    XCTAssertFalse([self.geoService isUSUser], @"Should not detect US user with empty country");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should not detect California user with empty region");
    
    // Test nil values in dictionary (using empty strings since NSUserDefaults can't store NSNull)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"",
        @"cloudfront-viewer-country-region": @""
    }];
    XCTAssertFalse([self.geoService isUSUser], @"Should handle empty string values gracefully");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should handle empty string values gracefully");
    
    // Test non-string values
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @123,
        @"cloudfront-viewer-country-region": @456
    }];
    XCTAssertFalse([self.geoService isUSUser], @"Should handle non-string values gracefully");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should handle non-string values gracefully");
}

// Test California user must be US user
- (void)testCaliforniaUserMustBeUSUser {
    // California user should always be US user
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    }];
    
    BOOL isUS = [self.geoService isUSUser];
    BOOL isCalifornia = [self.geoService isCaliforniaUser];
    
    if (isCalifornia) {
        XCTAssertTrue(isUS, @"California user must also be US user");
    }
}

// Test geographic targeting for privacy compliance
- (void)testGeographicTargetingForPrivacyCompliance {
    // Test US-CA targeting (should use SID=8)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    }];
    XCTAssertTrue([self.geoService isUSUser], @"California user should be US user");
    XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect California user for SID=8 targeting");
    
    // Test US non-CA targeting (should use SID=7)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"NY"
    }];
    XCTAssertTrue([self.geoService isUSUser], @"NY user should be US user");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"NY user should not be California user for SID=7 targeting");
    
    // Test non-US targeting (no GPP restrictions)
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"ON"
    }];
    XCTAssertFalse([self.geoService isUSUser], @"Canadian user should not be US user");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Canadian user should not be California user");
}

#pragma mark - Helper Methods

- (void)setGeoHeaders:(NSDictionary *)headers {
    [[NSUserDefaults standardUserDefaults] setObject:headers forKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
