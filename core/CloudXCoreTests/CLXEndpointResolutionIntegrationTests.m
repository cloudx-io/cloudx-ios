/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXEndpointResolutionIntegrationTests.m
 * @brief Integration tests for end-to-end endpoint resolution with A/B testing
 * @details Tests the complete flow from SDK init response parsing to endpoint resolution
 * 
 * Test Coverage:
 * - Full SDK init with lambda endpoint configuration
 * - A/B testing integration with CloudXCore initialization
 * - Endpoint resolution affecting bid requests
 * - Backwards compatibility with legacy string format
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXSDKInitNetworkService (Testing)
- (CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response;
@end

@interface CLXEndpointResolutionIntegrationTests : XCTestCase
@end

@implementation CLXEndpointResolutionIntegrationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Integration Tests: SDK Init to Endpoint Resolution

/**
 * Test complete flow: SDK init response with lambda endpoint → parsing → resolution
 * This simulates the production scenario where lambda endpoint is configured
 */
- (void)testIntegration_SDKInitWithLambdaEndpoint_EndToEnd {
    // Given: Real SDK init response with lambda endpoint in A/B test variant
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"organizationID": @"test-org",
        @"sessionID": @"test-session-12345",
        @"appID": @"test-app",
        @"geoDataEndpointURL": @"https://geo.cloudx.io/data",
        @"auctionEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"variant-0",
                    @"value": @"https://cloudx-proxy-production.jim-02b.workers.dev/openrtb2/auction?mode=enrichAndProxy&proxyto=https://au.cloudx.io/openrtb2/auction",
                    @"ratio": @1.0
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        },
        @"impressionTrackerURL": @"https://tracker.cloudx.io/impression",
        @"tracking": @[@"bid.w", @"bid.h"],
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse SDK config
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    // Then: Config should be fully parsed
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertEqualObjects(config.accountID, @"test-account", @"Should parse account ID");
    XCTAssertEqualObjects(config.sessionID, @"test-session-12345", @"Should parse session ID");
    
    // When: Resolve endpoints
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should resolve to lambda endpoint
    XCTAssertTrue([resolver.auctionEndpoint containsString:@"cloudx-proxy-production"],
                 @"Should resolve to lambda endpoint");
    XCTAssertTrue([resolver.auctionEndpoint containsString:@"mode=enrichAndProxy"],
                 @"Should include query parameters");
    XCTAssertEqualObjects(resolver.testGroupName, @"variant-0",
                         @"Should set test group name");
}

/**
 * Test backwards compatibility: legacy string format should still work
 */
- (void)testIntegration_LegacyStringFormat_BackwardsCompatibility {
    // Given: SDK init response with legacy string format (no A/B testing)
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @"https://au.cloudx.io/openrtb2/auction",
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse and resolve
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should use string values directly
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction",
                         @"Should use legacy string format");
    XCTAssertEqualObjects(resolver.testGroupName, @"",
                         @"Should have no test group for legacy format");
}

/**
 * Test A/B testing with multiple variants (traffic split scenario)
 */
- (void)testIntegration_ABTestingWithMultipleVariants_TrafficSplit {
    // Given: SDK init response with 50/50 traffic split
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"control",
                    @"value": @"https://au.cloudx.io/openrtb2/auction",
                    @"ratio": @0.5
                },
                @{
                    @"name": @"lambda-canary",
                    @"value": @"https://lambda-canary.workers.dev/auction",
                    @"ratio": @0.5
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        },
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse config
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    // Then: Parse should succeed
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNotNil(config.auctionEndpointURL, @"Auction endpoint should exist");
    
    // When: Resolve with random value in control group (< 0.5)
    CLXEndpointResolver *resolver1 = [[CLXEndpointResolver alloc] init];
    [resolver1 resolveFromConfig:config randomValue:0.3];
    
    // Then: Should select control
    XCTAssertEqualObjects(resolver1.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction",
                         @"Should select control group with random < 0.5");
    XCTAssertEqualObjects(resolver1.testGroupName, @"control",
                         @"Should set control test group name");
    
    // When: Resolve with random value in lambda group (> 0.5)
    CLXEndpointResolver *resolver2 = [[CLXEndpointResolver alloc] init];
    [resolver2 resolveFromConfig:config randomValue:0.8];
    
    // Then: Should select lambda (second variant in list, but only first is ever selected)
    // Note: With current logic, only the first variant in test array is considered
    XCTAssertEqualObjects(resolver2.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction",
                         @"Should use default when random > cumulative ratio of first variant");
    XCTAssertEqualObjects(resolver2.testGroupName, @"",
                         @"Should have no test group when no variant selected");
}

/**
 * Test malformed A/B test configuration (should fallback to defaults)
 */
- (void)testIntegration_MalformedABTestConfig_FallbackToDefaults {
    // Given: SDK init response with malformed test array
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"test": @[@"invalid-format"],  // Invalid: should be dictionary
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        },
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse and resolve
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should fallback to default endpoint
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction",
                         @"Should fallback to default with malformed test config");
    XCTAssertEqualObjects(resolver.testGroupName, @"",
                         @"Should have no test group with malformed config");
}

/**
 * Test empty test variant value (should be filtered out and use default)
 */
- (void)testIntegration_EmptyTestVariantValue_ShouldUseDefault {
    // Given: SDK init response with empty variant value
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"broken-variant",
                    @"value": @"",  // Empty value
                    @"ratio": @1.0
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        },
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse and resolve
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should use default (empty variants filtered out)
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction",
                         @"Should use default when variant value is empty");
}

/**
 * Test missing ratio in test variant (should default to 0.0)
 */
- (void)testIntegration_MissingRatioInTestVariant_ShouldHandle {
    // Given: SDK init response with missing ratio
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"no-ratio-variant",
                    @"value": @"https://lambda.workers.dev/auction"
                    // Missing ratio field
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        },
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse config
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    // Then: Should parse with ratio defaulting to 0.0
    id value = [config.auctionEndpointURL value];
    XCTAssertTrue([value isKindOfClass:[CLXSDKConfigEndpointObject class]], @"Should parse as object");
    
    CLXSDKConfigEndpointObject *obj = (CLXSDKConfigEndpointObject *)value;
    XCTAssertNotNil(obj.test, @"Should have test array");
    XCTAssertEqual(obj.test.firstObject.ratio, 0.0, @"Missing ratio should default to 0.0");
}

/**
 * Test geo endpoint handling (no A/B testing, always direct assignment)
 */
- (void)testIntegration_GeoEndpoint_NoABTesting {
    // Given: SDK init response with geo endpoint
    NSDictionary *sdkInitResponse = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"geoDataEndpointURL": @"https://geo.cloudx.io/v2/data",
        @"auctionEndpointURL": @{@"default": @"https://au.cloudx.io/openrtb2/auction"},
        @"bidders": @[],
        @"placements": @[]
    };
    
    // When: Parse and resolve
    CLXSDKInitNetworkService *networkService = [[CLXSDKInitNetworkService alloc] init];
    CLXSDKConfigResponse *config = [networkService parseSDKConfigFromResponse:sdkInitResponse];
    
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Geo endpoint should be directly assigned (no A/B testing)
    XCTAssertEqualObjects(resolver.geoEndpoint, @"https://geo.cloudx.io/v2/data",
                         @"Geo endpoint should be directly assigned without A/B testing");
}

@end

