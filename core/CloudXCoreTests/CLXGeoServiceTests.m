//
//  CLXGeoServiceTests.m
//  CloudXCoreTests
//
//  Tests for CLXGeoService orchestration layer - fetching and processing geo data.
//

#import <XCTest/XCTest.h>
#import "CLXGeoService.h"
#import "CLXGeoApi.h"
#import "CLXGeoInfo.h"

// Mock CLXGeoApi for testing
@interface MockCLXGeoApi : CLXGeoApi
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *mockHeaders;
@property (nonatomic, strong) NSError *mockError;
@end

@implementation MockCLXGeoApi

- (void)fetchGeoHeaders:(void (^)(NSDictionary<NSString *,NSString *> * _Nullable, NSError * _Nullable))completion {
    completion(self.mockHeaders, self.mockError);
}

@end

@interface CLXGeoServiceTests : XCTestCase
@property (nonatomic, strong) MockCLXGeoApi *mockApi;
@end

@implementation CLXGeoServiceTests

- (void)setUp {
    [super setUp];
    self.mockApi = [[MockCLXGeoApi alloc] initWithUrl:@"https://test.example.com"];
}

- (void)tearDown {
    self.mockApi = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitWithHeaderMappingAndApi {
    NSDictionary *headerMapping = @{
        @"cloudfront-viewer-latitude": @"lat",
        @"cloudfront-viewer-longitude": @"lon"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:headerMapping
                                                                      geoApi:self.mockApi];

    XCTAssertNotNil(geoService, @"Should create GeoService instance");
}

#pragma mark - Fetch and Process Tests

- (void)testFetchAndProcessGeoSuccess {
    // Setup mock response
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA",
        @"cloudfront-viewer-latitude": @"37.7749",
        @"cloudfront-viewer-longitude": @"-122.4194",
        @"x-amzn-remapped-x-forwarded-for": @"192.168.1.1"
    };

    NSDictionary *headerMapping = @{
        @"cloudfront-viewer-latitude": @"lat",
        @"cloudfront-viewer-longitude": @"lon",
        @"cloudfront-viewer-country-region": @"region"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:headerMapping
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch and process geo"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertNotNil(geoInfo, @"Should return GeoInfo");
        XCTAssertTrue([geoInfo isUSUser], @"Should detect US user");
        XCTAssertTrue([geoInfo isCaliforniaUser], @"Should detect California user");
        XCTAssertNotNil(geoInfo.hashedGeoIp, @"Should have hashed geo IP");
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 3, @"Should map 3 headers");
        XCTAssertEqualObjects(geoInfo.processedGeoInfo[@"lat"], @"37.7749", @"Should map latitude");
        XCTAssertEqualObjects(geoInfo.processedGeoInfo[@"lon"], @"-122.4194", @"Should map longitude");
        XCTAssertEqualObjects(geoInfo.processedGeoInfo[@"region"], @"CA", @"Should map region");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testFetchAndProcessGeoFailure {
    // Setup mock error
    self.mockApi.mockError = [NSError errorWithDomain:@"TestError"
                                                 code:500
                                             userInfo:@{NSLocalizedDescriptionKey: @"Network error"}];
    self.mockApi.mockHeaders = nil;

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle fetch failure"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertNotNil(geoInfo, @"Should return empty GeoInfo on failure");
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 0, @"Should have no processed data");
        XCTAssertEqual(geoInfo.rawGeoInfo.count, 0, @"Should have no raw data");
        XCTAssertNil(geoInfo.hashedGeoIp, @"Should have no hashed IP");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testFetchAndProcessGeoNilHeaders {
    // Setup mock with nil headers (no error)
    self.mockApi.mockHeaders = nil;
    self.mockApi.mockError = nil;

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle nil headers"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertNotNil(geoInfo, @"Should return empty GeoInfo when headers nil");
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 0, @"Should have no processed data");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Header Mapping Tests

- (void)testHeaderMappingWithServerConfig {
    // Test that only server-configured mappings are applied (no fallbacks)
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-latitude": @"40.7128",
        @"cloudfront-viewer-longitude": @"-74.0060",
        @"cloudfront-viewer-city": @"New York",
        @"cloudfront-viewer-postal-code": @"10001"
    };

    NSDictionary *headerMapping = @{
        @"cloudfront-viewer-latitude": @"lat",
        @"cloudfront-viewer-longitude": @"lon"
        // Note: city and postal-code NOT in mapping, so they won't be processed
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:headerMapping
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Map headers per config"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 2, @"Should only map configured headers");
        XCTAssertNotNil(geoInfo.processedGeoInfo[@"lat"], @"Should have lat");
        XCTAssertNotNil(geoInfo.processedGeoInfo[@"lon"], @"Should have lon");
        XCTAssertNil(geoInfo.processedGeoInfo[@"city"], @"Should NOT map unconfigured city");
        XCTAssertNil(geoInfo.processedGeoInfo[@"postal-code"], @"Should NOT map unconfigured postal-code");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testHeaderMappingSkipsMissingSourceHeaders {
    // Test that missing source headers are skipped
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-latitude": @"51.5074"
        // longitude is missing
    };

    NSDictionary *headerMapping = @{
        @"cloudfront-viewer-latitude": @"lat",
        @"cloudfront-viewer-longitude": @"lon"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:headerMapping
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Skip missing headers"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 1, @"Should only map available headers");
        XCTAssertNotNil(geoInfo.processedGeoInfo[@"lat"], @"Should have lat");
        XCTAssertNil(geoInfo.processedGeoInfo[@"lon"], @"Should NOT have lon (missing from source)");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Geo IP Hashing Tests

- (void)testGeoIpHashingSuccess {
    self.mockApi.mockHeaders = @{
        @"x-amzn-remapped-x-forwarded-for": @"192.168.1.1"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Hash geo IP"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertNotNil(geoInfo.hashedGeoIp, @"Should hash geo IP");
        XCTAssertEqual(geoInfo.hashedGeoIp.length, 32, @"MD5 hash should be 32 hex chars");
        XCTAssertEqualObjects(geoInfo.hashedGeoIp, @"66efff4c945d3c3b87fc271b47d456db", @"Should match known MD5 of '192.168.1.1'");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testGeoIpHashingNormalization {
    // Test that IP is normalized (lowercase, trimmed) before hashing
    NSArray *ipsToTest = @[
        @"192.168.1.1",
        @"192.168.1.1  ",  // Trailing space
        @"  192.168.1.1",  // Leading space
        @" 192.168.1.1 "   // Both
    ];

    NSMutableSet *hashes = [NSMutableSet set];

    for (NSString *ip in ipsToTest) {
        self.mockApi.mockHeaders = @{@"x-amzn-remapped-x-forwarded-for": ip};
        CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                          geoApi:self.mockApi];

        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Hash normalized IP: %@", ip]];

        [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
            [hashes addObject:geoInfo.hashedGeoIp];
            [expectation fulfill];
        }];

        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    }

    XCTAssertEqual(hashes.count, 1, @"All normalized IPs should produce same hash");
}

- (void)testGeoIpHashingMissingHeader {
    // Test that missing geo IP header results in nil hash
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA"
        // No x-amzn-remapped-x-forwarded-for
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle missing geo IP"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertNil(geoInfo.hashedGeoIp, @"Should have nil hash when geo IP header missing");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Lat/Lon From Raw Headers Tests

- (void)testLatLonAccessibleFromRawHeadersEvenWhenNotInConfig {
    // Matches Android: getLat/getLon read from raw headers even when not in config
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-latitude": @"37.7749",
        @"cloudfront-viewer-longitude": @"-122.4194"
    };

    // Only map country — lat/lon NOT in header mapping
    NSDictionary *headerMapping = @{
        @"cloudfront-viewer-country-iso3": @"country"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:headerMapping
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Lat/lon from raw headers"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        // processedGeoInfo should only have country
        XCTAssertEqual(geoInfo.processedGeoInfo.count, 1, @"Should only map configured headers");
        XCTAssertEqualObjects(geoInfo.processedGeoInfo[@"country"], @"USA");

        // But lat/lon should be accessible via raw headers
        XCTAssertEqualWithAccuracy([[geoInfo latitude] floatValue], 37.7749f, 0.001f, @"Lat should be accessible from raw headers");
        XCTAssertEqualWithAccuracy([[geoInfo longitude] floatValue], -122.4194f, 0.001f, @"Lon should be accessible from raw headers");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Raw Geo Info Tests

- (void)testRawGeoInfoPreserved {
    // Test that all raw headers are preserved in rawGeoInfo
    self.mockApi.mockHeaders = @{
        @"cloudfront-viewer-country-iso3": @"JPN",
        @"cloudfront-viewer-city": @"Tokyo",
        @"cloudfront-viewer-latitude": @"35.6762",
        @"cloudfront-viewer-longitude": @"139.6503",
        @"x-amzn-remapped-x-forwarded-for": @"203.0.113.0",
        @"custom-header": @"custom-value"
    };

    CLXGeoService *geoService = [[CLXGeoService alloc] initWithHeaderMapping:@{}
                                                                      geoApi:self.mockApi];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Preserve raw headers"];

    [geoService fetchAndProcessGeo:^(CLXGeoInfo *geoInfo) {
        XCTAssertEqual(geoInfo.rawGeoInfo.count, 6, @"Should preserve all raw headers");
        XCTAssertEqualObjects(geoInfo.rawGeoInfo[@"cloudfront-viewer-country-iso3"], @"JPN", @"Should preserve country");
        XCTAssertEqualObjects(geoInfo.rawGeoInfo[@"custom-header"], @"custom-value", @"Should preserve custom headers");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
