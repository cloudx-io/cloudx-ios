//
//  CLXSDKInitNetworkServiceTests.m
//  CloudXCoreTests
//
//  Tests for SDK initialization network service, specifically tracking array parsing
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access internal methods for testing
@interface CLXSDKInitNetworkService (Testing)
- (CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response;
@end

@interface CLXSDKInitNetworkServiceTests : XCTestCase
@property (nonatomic, strong) CLXSDKInitNetworkService *networkService;
@end

@implementation CLXSDKInitNetworkServiceTests

- (void)setUp {
    [super setUp];
    self.networkService = [[CLXSDKInitNetworkService alloc] init];
}

#pragma mark - Tracking Array Parsing Tests

/**
 * Test that tracking array is correctly parsed from SDK init response
 * Validates our fix for missing tracking array parsing
 */
- (void)testParseSDKConfig_ShouldParseTrackingArray {
    // Given: SDK init response with tracking array
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"organizationID": @"CLDX2",
        @"sessionID": @"test-session-123",
        @"preCacheSize": @5,
        @"geoDataEndpointURL": @"https://geo.cloudx.io",
        @"tracking": @[
            @"bid.ext.prebid.meta.adaptercode",
            @"bid.w",
            @"bid.h",
            @"bid.dealid",
            @"bid.creativeId",
            @"bid.price",
            @"sdk.responseTimeMillis",
            @"sdk.releaseVersion",
            @"bidRequest.id",
            @"config.accountID",
            @"config.organizationID",
            @"bidRequest.app.bundle",
            @"bidRequest.imp.tagid",
            @"bidRequest.device.model",
            @"sdk.deviceType",
            @"bidRequest.device.os",
            @"bidRequest.device.osv",
            @"sdk.sessionId",
            @"bidRequest.device.ifa",
            @"bidRequest.loopIndex",
            @"config.testGroupName",
            @"config.placements[id=${bidRequest.imp.tagid}].name",
            @"bidRequest.device.geo.country",
            @"config.placements[id=${bidRequest.imp.tagid}].externalId",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId"
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse all fields including tracking array
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqualObjects(config.accountID, @"CLDX2_dc", @"Should parse account ID");
    XCTAssertEqualObjects(config.organizationID, @"CLDX2", @"Should parse organization ID");
    XCTAssertEqualObjects(config.sessionID, @"test-session-123", @"Should parse session ID");
    XCTAssertEqual(config.preCacheSize, 5, @"Should parse pre-cache size");
    XCTAssertEqualObjects(config.geoDataEndpointURL, @"https://geo.cloudx.io", @"Should parse geo endpoint URL");
    
    // Most importantly: verify tracking array is parsed
    XCTAssertNotNil(config.tracking, @"Tracking array should be parsed");
    XCTAssertEqual(config.tracking.count, 26, @"Should parse all 26 tracking fields");
    XCTAssertEqualObjects(config.tracking[0], @"bid.ext.prebid.meta.adaptercode", @"First field should be bidder field");
    XCTAssertEqualObjects(config.tracking[1], @"bid.w", @"Second field should be width");
    XCTAssertEqualObjects(config.tracking[2], @"bid.h", @"Third field should be height");
}

/**
 * Test SDK config parsing with empty tracking array
 */
- (void)testParseSDKConfig_EmptyTrackingArray_ShouldHandleGracefully {
    // Given: SDK init response with empty tracking array
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"organizationID": @"CLDX2",
        @"sessionID": @"test-session-123",
        @"tracking": @[]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should handle empty array gracefully
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNotNil(config.tracking, @"Tracking array should be present");
    XCTAssertEqual(config.tracking.count, 0, @"Tracking array should be empty");
}

/**
 * Test SDK config parsing with missing tracking array
 */
- (void)testParseSDKConfig_MissingTrackingArray_ShouldHandleGracefully {
    // Given: SDK init response without tracking array
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"organizationID": @"CLDX2",
        @"sessionID": @"test-session-123"
        // No tracking array
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should handle missing array gracefully
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(config.tracking, @"Tracking array should be nil when missing");
}

/**
 * Test SDK config parsing with malformed tracking array
 */
- (void)testParseSDKConfig_MalformedTrackingArray_ShouldHandleGracefully {
    // Given: SDK init response with malformed tracking array
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"organizationID": @"CLDX2",
        @"sessionID": @"test-session-123",
        @"tracking": @"not-an-array"  // String instead of array
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should handle malformed array gracefully
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(config.tracking, @"Tracking array should be nil when malformed");
}

/**
 * Test that bidder field is first in tracking configuration
 * Validates that our server-driven tracking has bidder as priority field
 */
- (void)testTrackingConfiguration_BidderFieldShouldBeFirst {
    // Given: SDK init response with tracking array
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"tracking": @[
            @"bid.ext.prebid.meta.adaptercode",  // Bidder should be first
            @"bid.w",
            @"bid.h"
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Bidder field should be first for priority tracking
    XCTAssertNotNil(config.tracking, @"Tracking array should be parsed");
    XCTAssertTrue(config.tracking.count > 0, @"Tracking array should not be empty");
    XCTAssertEqualObjects(config.tracking[0], @"bid.ext.prebid.meta.adaptercode", 
                         @"Bidder field should be first in tracking configuration");
}

@end
