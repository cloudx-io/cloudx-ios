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
    XCTAssertEqualObjects(config.geoDataEndpointURL, @"https://geo.cloudx.io", @"Should parse geo endpoint URL");
    
    // Most importantly: verify tracking array is parsed
    XCTAssertNotNil(config.tracking, @"Tracking array should be parsed");
    XCTAssertEqual(config.tracking.count, 25, @"Should parse all 25 tracking fields");
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

#pragma mark - Placement Reward Configuration Tests

/**
 * Test parsing of rewarded placement with reward configuration
 * Validates the demo-rewarded-1 placement format from server
 */
- (void)testParseSDKConfig_RewardedPlacement_ShouldParseRewardFields {
    // Given: SDK init response with rewarded placement containing reward config
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"placements": @[
            @{
                @"id": @"um9Ek08ScJBWuzSMTyW3b",
                @"name": @"demo-rewarded-1",
                @"bidResponseTimeoutMs": @1000,
                @"adLoadTimeoutMs": @3000,
                @"type": @"rewarded",
                @"rewardAmount": @1000,
                @"rewardCurrency": @"Golden Coins",
                @"rewardCallbackUrl": @"https://httpbin.org/post"
            }
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse placement with reward fields
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqual(config.placements.count, 1, @"Should have 1 placement");
    
    CLXSDKConfigPlacement *placement = config.placements.firstObject;
    XCTAssertEqualObjects(placement.id, @"um9Ek08ScJBWuzSMTyW3b", @"Should parse placement ID");
    XCTAssertEqualObjects(placement.name, @"demo-rewarded-1", @"Should parse placement name");
    XCTAssertEqual(placement.type, SDKConfigAdTypeRewarded, @"Should parse placement type as rewarded");
    XCTAssertEqual(placement.bidResponseTimeoutMs, 1000, @"Should parse bid timeout");
    XCTAssertEqual(placement.adLoadTimeoutMs, 3000, @"Should parse ad load timeout");
    
    // Verify reward fields
    XCTAssertEqual(placement.rewardAmount, 1000, @"Should parse rewardAmount");
    XCTAssertEqualObjects(placement.rewardCurrency, @"Golden Coins", @"Should parse rewardCurrency");
    XCTAssertEqualObjects(placement.rewardCallbackUrl, @"https://httpbin.org/post", @"Should parse rewardCallbackUrl");
}

/**
 * Test parsing of rewarded placement without optional reward fields
 */
- (void)testParseSDKConfig_RewardedPlacementWithoutRewardConfig_ShouldUseDefaults {
    // Given: SDK init response with rewarded placement but no reward config
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"placements": @[
            @{
                @"id": @"test-rewarded-id",
                @"name": @"test-rewarded",
                @"type": @"rewarded"
                // No rewardAmount, rewardCurrency, or rewardCallbackUrl
            }
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should use default values for missing reward fields
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqual(config.placements.count, 1, @"Should have 1 placement");
    
    CLXSDKConfigPlacement *placement = config.placements.firstObject;
    XCTAssertEqual(placement.type, SDKConfigAdTypeRewarded, @"Should parse placement type as rewarded");
    XCTAssertEqual(placement.rewardAmount, 0, @"Default rewardAmount should be 0");
    XCTAssertNil(placement.rewardCurrency, @"Default rewardCurrency should be nil");
    XCTAssertNil(placement.rewardCallbackUrl, @"Default rewardCallbackUrl should be nil");
}

/**
 * Test parsing of non-rewarded placement ignores reward fields
 */
- (void)testParseSDKConfig_NonRewardedPlacement_ShouldNotHaveRewardFields {
    // Given: SDK init response with interstitial placement
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"placements": @[
            @{
                @"id": @"test-interstitial-id",
                @"name": @"test-interstitial",
                @"type": @"interstitial"
            }
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should have default/empty reward values (not applicable for non-rewarded)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqual(config.placements.count, 1, @"Should have 1 placement");
    
    CLXSDKConfigPlacement *placement = config.placements.firstObject;
    XCTAssertEqual(placement.type, SDKConfigAdTypeInterstitial, @"Should parse placement type as interstitial");
    XCTAssertEqual(placement.rewardAmount, 0, @"Non-rewarded placement should have rewardAmount 0");
    XCTAssertNil(placement.rewardCurrency, @"Non-rewarded placement should have nil rewardCurrency");
    XCTAssertNil(placement.rewardCallbackUrl, @"Non-rewarded placement should have nil rewardCallbackUrl");
}

/**
 * Test parsing multiple placements including rewarded with reward config
 */
- (void)testParseSDKConfig_MultiplePlacements_ShouldParseAllWithRewardFields {
    // Given: SDK init response with multiple placement types
    NSDictionary *response = @{
        @"accountID": @"CLDX2_dc",
        @"placements": @[
            @{
                @"id": @"banner-id",
                @"name": @"demo-banner",
                @"type": @"banner"
            },
            @{
                @"id": @"rewarded-id",
                @"name": @"demo-rewarded",
                @"type": @"rewarded",
                @"rewardAmount": @500,
                @"rewardCurrency": @"gems"
            },
            @{
                @"id": @"interstitial-id",
                @"name": @"demo-interstitial",
                @"type": @"interstitial"
            }
        ]
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse all placements correctly
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqual(config.placements.count, 3, @"Should have 3 placements");
    
    // Find rewarded placement
    CLXSDKConfigPlacement *rewardedPlacement = nil;
    for (CLXSDKConfigPlacement *p in config.placements) {
        if (p.type == SDKConfigAdTypeRewarded) {
            rewardedPlacement = p;
            break;
        }
    }
    
    XCTAssertNotNil(rewardedPlacement, @"Should find rewarded placement");
    XCTAssertEqual(rewardedPlacement.rewardAmount, 500, @"Should parse rewardAmount");
    XCTAssertEqualObjects(rewardedPlacement.rewardCurrency, @"gems", @"Should parse rewardCurrency");
}

@end

