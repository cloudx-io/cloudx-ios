//
//  CLXGeoInfoTests.m
//  CloudXCoreTests
//
//  Tests for CLXGeoInfo data model, privacy methods, and geo field accessors.
//

#import <XCTest/XCTest.h>
#import "CLXGeoInfo.h"

@interface CLXGeoInfoTests : XCTestCase
@end

@implementation CLXGeoInfoTests

#pragma mark - Initialization Tests

- (void)testInitWithAllData {
    NSDictionary *processedGeo = @{
        @"city": @"San Francisco",
        @"region": @"CA",
        @"zip": @"94102",
        @"metro": @"807"
    };

    NSDictionary *rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA",
        @"cloudfront-viewer-latitude": @"37.7749",
        @"cloudfront-viewer-longitude": @"-122.4194"
    };

    NSString *hashedIp = @"abc123def456";

    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:processedGeo
                                                            rawGeoInfo:rawGeo
                                                           hashedGeoIp:hashedIp];

    XCTAssertNotNil(geoInfo, @"Should create GeoInfo instance");
    XCTAssertEqualObjects(geoInfo.processedGeoInfo, processedGeo, @"Should store processed geo info");
    XCTAssertEqualObjects(geoInfo.rawGeoInfo, rawGeo, @"Should store raw geo info");
    XCTAssertEqualObjects(geoInfo.hashedGeoIp, hashedIp, @"Should store hashed geo IP");
}

- (void)testInitWithNilHashedGeoIp {
    NSDictionary *processedGeo = @{@"city": @"London"};
    NSDictionary *rawGeo = @{@"cloudfront-viewer-country-iso3": @"GBR"};

    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:processedGeo
                                                            rawGeoInfo:rawGeo
                                                           hashedGeoIp:nil];

    XCTAssertNotNil(geoInfo, @"Should create GeoInfo with nil hashed IP");
    XCTAssertNil(geoInfo.hashedGeoIp, @"Should allow nil hashed geo IP");
}

- (void)testEmptyGeoInfo {
    CLXGeoInfo *emptyGeo = [CLXGeoInfo emptyGeoInfo];

    XCTAssertNotNil(emptyGeo, @"Should create empty GeoInfo");
    XCTAssertEqual(emptyGeo.processedGeoInfo.count, 0, @"Empty geo should have no processed data");
    XCTAssertEqual(emptyGeo.rawGeoInfo.count, 0, @"Empty geo should have no raw data");
    XCTAssertNil(emptyGeo.hashedGeoIp, @"Empty geo should have nil hashed IP");
}

#pragma mark - Privacy Compliance Tests

- (void)testIsUSUser {
    // Test USA country code (uppercase)
    NSDictionary *rawGeo = @{@"cloudfront-viewer-country-iso3": @"USA"};
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isUSUser], @"Should detect USA as US user");

    // Test usa country code (lowercase)
    rawGeo = @{@"cloudfront-viewer-country-iso3": @"usa"};
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isUSUser], @"Should detect usa as US user (case insensitive)");

    // Test mixed case
    rawGeo = @{@"cloudfront-viewer-country-iso3": @"UsA"};
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isUSUser], @"Should detect UsA as US user (case insensitive)");

    // Test non-US countries
    NSArray *nonUSCountries = @[@"CAN", @"GBR", @"FRA", @"DEU", @"JPN"];
    for (NSString *country in nonUSCountries) {
        rawGeo = @{@"cloudfront-viewer-country-iso3": country};
        geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
        XCTAssertFalse([geoInfo isUSUser], @"Should not detect %@ as US user", country);
    }

    // Test missing country code
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:@{} hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isUSUser], @"Should return NO when country code missing");
}

- (void)testIsCaliforniaUser {
    // Test California user (USA + CA region)
    NSDictionary *rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    };
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isCaliforniaUser], @"Should detect California user");

    // Test California region code (lowercase)
    rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"ca"
    };
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isCaliforniaUser], @"Should detect California user (case insensitive)");

    // Test US user but different state
    rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"NY"
    };
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isCaliforniaUser], @"Should not detect NY as California user");

    // Test CA region but non-US country
    rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"CA"
    };
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isCaliforniaUser], @"Should not detect Canadian CA as California user");

    // Test missing region
    rawGeo = @{@"cloudfront-viewer-country-iso3": @"USA"};
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isCaliforniaUser], @"Should return NO when region missing");
}

- (void)testIsEUUser {
    // Test GDPR applies = "true" (string)
    NSDictionary *rawGeo = @{@"gdpr-applies": @"true"};
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isEUUser], @"Should detect EU user when gdpr-applies=true");

    // Test GDPR applies = "TRUE" (uppercase)
    rawGeo = @{@"gdpr-applies": @"TRUE"};
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertTrue([geoInfo isEUUser], @"Should detect EU user when gdpr-applies=TRUE (case insensitive)");

    // Test GDPR applies = "false"
    rawGeo = @{@"gdpr-applies": @"false"};
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isEUUser], @"Should not detect EU user when gdpr-applies=false");

    // Test missing gdpr-applies header
    geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:@{} hashedGeoIp:nil];
    XCTAssertFalse([geoInfo isEUUser], @"Should return NO when gdpr-applies missing");
}

#pragma mark - Geo Field Accessor Tests

- (void)testLatitudeLongitude {
    // Test valid lat/lon
    NSDictionary *rawGeo = @{
        @"cloudfront-viewer-latitude": @"37.7749",
        @"cloudfront-viewer-longitude": @"-122.4194"
    };
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];

    XCTAssertNotNil([geoInfo latitude], @"Should parse latitude");
    XCTAssertNotNil([geoInfo longitude], @"Should parse longitude");
    XCTAssertEqualWithAccuracy([[geoInfo latitude] doubleValue], 37.7749, 0.0001, @"Latitude should match");
    XCTAssertEqualWithAccuracy([[geoInfo longitude] doubleValue], -122.4194, 0.0001, @"Longitude should match");
}

- (void)testLatitudeLongitudeMissing {
    // Test missing lat/lon
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:@{} hashedGeoIp:nil];

    XCTAssertNil([geoInfo latitude], @"Should return nil when latitude missing");
    XCTAssertNil([geoInfo longitude], @"Should return nil when longitude missing");
}

- (void)testLatitudeLongitudeInvalidFormat {
    // Test invalid lat/lon format
    NSDictionary *rawGeo = @{
        @"cloudfront-viewer-latitude": @"invalid",
        @"cloudfront-viewer-longitude": @"not_a_number"
    };
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];

    XCTAssertNil([geoInfo latitude], @"Should return nil for invalid latitude");
    XCTAssertNil([geoInfo longitude], @"Should return nil for invalid longitude");
}

#pragma mark - Edge Case Tests

- (void)testEmptyStringsInRawGeo {
    NSDictionary *rawGeo = @{
        @"cloudfront-viewer-country-iso3": @"",
        @"cloudfront-viewer-country-region": @"",
        @"gdpr-applies": @""
    };
    CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{} rawGeoInfo:rawGeo hashedGeoIp:nil];

    XCTAssertFalse([geoInfo isUSUser], @"Should handle empty country code");
    XCTAssertFalse([geoInfo isCaliforniaUser], @"Should handle empty region");
    XCTAssertFalse([geoInfo isEUUser], @"Should handle empty gdpr-applies");
}

// Note: Immutability is enforced at compile-time via readonly properties,
// so no runtime test needed

@end
