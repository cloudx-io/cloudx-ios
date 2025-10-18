/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXEndpointResolverTests.m
 * @brief Unit tests for CLXEndpointResolver with A/B testing support
 * @details Tests endpoint resolution logic with various configurations:
 * - Simple string endpoints (legacy format)
 * - Object format with default only
 * - Object format with A/B test variants
 * - Edge cases and error handling
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access parseEndpointObject for testing
@interface CLXSDKInitNetworkService (Testing)
- (CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response;
- (CLXSDKConfigEndpointObject *)parseEndpointObject:(NSDictionary *)endpointDict;
@end

@interface CLXEndpointResolverTests : XCTestCase
@property (nonatomic, strong) CLXSDKInitNetworkService *networkService;
@end

@implementation CLXEndpointResolverTests

- (void)setUp {
    [super setUp];
    self.networkService = [[CLXSDKInitNetworkService alloc] init];
}

- (void)tearDown {
    self.networkService = nil;
    [super tearDown];
}

#pragma mark - Endpoint Parsing Tests

/**
 * Test parsing simple string format auction endpoint (legacy)
 */
- (void)testParseEndpoint_SimpleString_AuctionEndpoint {
    // Given: SDK response with simple string auction endpoint
    NSDictionary *response = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @"https://au.cloudx.io/openrtb2/auction"
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse as simple string
    XCTAssertNotNil(config.auctionEndpointURL, @"Auction endpoint should be parsed");
    id value = [config.auctionEndpointURL value];
    XCTAssertTrue([value isKindOfClass:[NSString class]], @"Should be simple string");
    XCTAssertEqualObjects(value, @"https://au.cloudx.io/openrtb2/auction", @"Should match input URL");
}

/**
 * Test parsing object format with default only (no A/B testing)
 */
- (void)testParseEndpoint_ObjectWithDefaultOnly {
    // Given: SDK response with object format, default only
    NSDictionary *response = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        }
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse as endpoint object
    XCTAssertNotNil(config.auctionEndpointURL, @"Auction endpoint should be parsed");
    id value = [config.auctionEndpointURL value];
    XCTAssertTrue([value isKindOfClass:[CLXSDKConfigEndpointObject class]], @"Should be endpoint object");
    
    CLXSDKConfigEndpointObject *obj = (CLXSDKConfigEndpointObject *)value;
    XCTAssertEqualObjects(obj.defaultKey, @"https://au.cloudx.io/openrtb2/auction", @"Should have default URL");
    XCTAssertNil(obj.test, @"Should have no test variants");
}

/**
 * Test parsing object format with A/B test variants (lambda endpoint scenario)
 */
- (void)testParseEndpoint_ObjectWithABTestVariants {
    // Given: SDK response with lambda endpoint in test array (production scenario)
    NSDictionary *response = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"auctionEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"variant-0",
                    @"value": @"https://cloudx-proxy-production.workers.dev/openrtb2/auction?mode=enrichAndProxy&proxyto=https://au.cloudx.io/openrtb2/auction",
                    @"ratio": @1.0
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        }
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse test variants
    XCTAssertNotNil(config.auctionEndpointURL, @"Auction endpoint should be parsed");
    id value = [config.auctionEndpointURL value];
    XCTAssertTrue([value isKindOfClass:[CLXSDKConfigEndpointObject class]], @"Should be endpoint object");
    
    CLXSDKConfigEndpointObject *obj = (CLXSDKConfigEndpointObject *)value;
    XCTAssertEqualObjects(obj.defaultKey, @"https://au.cloudx.io/openrtb2/auction", @"Should have default URL");
    XCTAssertNotNil(obj.test, @"Should have test variants");
    XCTAssertEqual(obj.test.count, 1, @"Should have 1 test variant");
    
    CLXSDKConfigEndpointValue *variant = obj.test.firstObject;
    XCTAssertEqualObjects(variant.name, @"variant-0", @"Should have variant name");
    XCTAssertTrue([variant.value containsString:@"cloudx-proxy-production.workers.dev"], @"Should have lambda URL");
    XCTAssertEqual(variant.ratio, 1.0, @"Should have ratio of 1.0");
}

/**
 * Test parsing multiple A/B test variants with different ratios
 */
- (void)testParseEndpoint_MultipleABTestVariants {
    // Given: SDK response with multiple test variants
    NSDictionary *response = @{
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
                    @"name": @"lambda-v1",
                    @"value": @"https://lambda-v1.workers.dev/auction",
                    @"ratio": @0.3
                },
                @{
                    @"name": @"lambda-v2",
                    @"value": @"https://lambda-v2.workers.dev/auction",
                    @"ratio": @0.2
                }
            ],
            @"default": @"https://au.cloudx.io/openrtb2/auction"
        }
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse all test variants
    id value = [config.auctionEndpointURL value];
    CLXSDKConfigEndpointObject *obj = (CLXSDKConfigEndpointObject *)value;
    
    XCTAssertEqual(obj.test.count, 3, @"Should have 3 test variants");
    XCTAssertEqualObjects(obj.test[0].name, @"control", @"First variant should be control");
    XCTAssertEqual(obj.test[0].ratio, 0.5, @"Control should have 0.5 ratio");
    XCTAssertEqualObjects(obj.test[1].name, @"lambda-v1", @"Second variant should be lambda-v1");
    XCTAssertEqual(obj.test[1].ratio, 0.3, @"Lambda-v1 should have 0.3 ratio");
    XCTAssertEqualObjects(obj.test[2].name, @"lambda-v2", @"Third variant should be lambda-v2");
    XCTAssertEqual(obj.test[2].ratio, 0.2, @"Lambda-v2 should have 0.2 ratio");
}

/**
 * Test parsing CDP endpoint with A/B testing
 */
- (void)testParseEndpoint_CDPWithABTesting {
    // Given: SDK response with CDP endpoint having test variants
    NSDictionary *response = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"cdpEndpointURL": @{
            @"test": @[
                @{
                    @"name": @"cdp-variant-1",
                    @"value": @"https://cdp-test.cloudx.io/enrich",
                    @"ratio": @1.0
                }
            ],
            @"default": @"https://cdp.cloudx.io/enrich"
        }
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse CDP endpoint with test variants
    XCTAssertNotNil(config.cdpEndpointURL, @"CDP endpoint should be parsed");
    XCTAssertEqualObjects(config.cdpEndpointURL.defaultKey, @"https://cdp.cloudx.io/enrich", @"Should have default URL");
    XCTAssertNotNil(config.cdpEndpointURL.test, @"Should have test variants");
    XCTAssertEqual(config.cdpEndpointURL.test.count, 1, @"Should have 1 test variant");
}

/**
 * Test parsing empty CDP endpoint (common production scenario)
 */
- (void)testParseEndpoint_EmptyCDPEndpoint {
    // Given: SDK response with empty CDP endpoint
    NSDictionary *response = @{
        @"accountID": @"test-account",
        @"sessionID": @"test-session",
        @"cdpEndpointURL": @{
            @"default": @""
        }
    };
    
    // When: Parse SDK config
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response];
    
    // Then: Should parse empty CDP endpoint
    XCTAssertNotNil(config.cdpEndpointURL, @"CDP endpoint object should exist");
    XCTAssertEqualObjects(config.cdpEndpointURL.defaultKey, @"", @"Should have empty default");
}

#pragma mark - Endpoint Resolution Tests

/**
 * Test endpoint resolution with default values (no A/B testing)
 */
- (void)testEndpointResolution_DefaultValues_NoABTesting {
    // Given: Config with default endpoints only
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointString = @"https://au.cloudx.io/openrtb2/auction";
    config.auctionEndpointURL = auctionQuantum;
    
    CLXSDKConfigEndpointObject *cdpObj = [[CLXSDKConfigEndpointObject alloc] init];
    cdpObj.defaultKey = @"https://cdp.cloudx.io/enrich";
    config.cdpEndpointURL = cdpObj;
    
    config.geoDataEndpointURL = @"https://geo.cloudx.io/data";
    
    // When: Resolve endpoints
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should use default values
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction", 
                         @"Should resolve auction endpoint");
    XCTAssertEqualObjects(resolver.cdpEndpoint, @"https://cdp.cloudx.io/enrich", 
                         @"Should resolve CDP endpoint");
    XCTAssertEqualObjects(resolver.geoEndpoint, @"https://geo.cloudx.io/data", 
                         @"Should resolve geo endpoint");
    XCTAssertEqualObjects(resolver.testGroupName, @"", @"Should have no test group");
}

/**
 * Test endpoint resolution with A/B test variant (ratio = 1.0, should always select)
 */
- (void)testEndpointResolution_ABTestVariant_Ratio100Percent {
    // Given: Config with A/B test variant at 100% traffic
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    CLXSDKConfigEndpointValue *variant = [[CLXSDKConfigEndpointValue alloc] init];
    variant.name = @"lambda-production";
    variant.value = @"https://lambda.workers.dev/auction";
    variant.ratio = 1.0;
    
    CLXSDKConfigEndpointObject *auctionObj = [[CLXSDKConfigEndpointObject alloc] init];
    auctionObj.defaultKey = @"https://au.cloudx.io/openrtb2/auction";
    auctionObj.test = @[variant];
    
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointObject = auctionObj;
    config.auctionEndpointURL = auctionQuantum;
    
    CLXSDKConfigEndpointObject *cdpObj = [[CLXSDKConfigEndpointObject alloc] init];
    cdpObj.defaultKey = @"";
    config.cdpEndpointURL = cdpObj;
    
    // When: Resolve endpoints with any random value (should always select variant)
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config randomValue:0.5];
    
    // Then: Should use test variant
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://lambda.workers.dev/auction", 
                         @"Should resolve to lambda endpoint");
    XCTAssertEqualObjects(resolver.testGroupName, @"lambda-production", 
                         @"Should set test group name");
}

/**
 * Test endpoint resolution with A/B test variant (ratio = 0.5, boundary testing)
 */
- (void)testEndpointResolution_ABTestVariant_Ratio50Percent_LowerBound {
    // Given: Config with A/B test variant at 50% traffic
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    CLXSDKConfigEndpointValue *variant = [[CLXSDKConfigEndpointValue alloc] init];
    variant.name = @"lambda-test";
    variant.value = @"https://lambda.workers.dev/auction";
    variant.ratio = 0.5;
    
    CLXSDKConfigEndpointObject *auctionObj = [[CLXSDKConfigEndpointObject alloc] init];
    auctionObj.defaultKey = @"https://au.cloudx.io/openrtb2/auction";
    auctionObj.test = @[variant];
    
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointObject = auctionObj;
    config.auctionEndpointURL = auctionQuantum;
    
    CLXSDKConfigEndpointObject *cdpObj = [[CLXSDKConfigEndpointObject alloc] init];
    cdpObj.defaultKey = @"";
    config.cdpEndpointURL = cdpObj;
    
    // When: Resolve with random value at lower bound (should select variant)
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config randomValue:0.3];
    
    // Then: Should use test variant
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://lambda.workers.dev/auction", 
                         @"Should resolve to lambda endpoint with random < 0.5");
}

/**
 * Test endpoint resolution with A/B test variant (ratio = 0.5, above threshold)
 */
- (void)testEndpointResolution_ABTestVariant_Ratio50Percent_AboveThreshold {
    // Given: Config with A/B test variant at 50% traffic
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    CLXSDKConfigEndpointValue *variant = [[CLXSDKConfigEndpointValue alloc] init];
    variant.name = @"lambda-test";
    variant.value = @"https://lambda.workers.dev/auction";
    variant.ratio = 0.5;
    
    CLXSDKConfigEndpointObject *auctionObj = [[CLXSDKConfigEndpointObject alloc] init];
    auctionObj.defaultKey = @"https://au.cloudx.io/openrtb2/auction";
    auctionObj.test = @[variant];
    
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointObject = auctionObj;
    config.auctionEndpointURL = auctionQuantum;
    
    CLXSDKConfigEndpointObject *cdpObj = [[CLXSDKConfigEndpointObject alloc] init];
    cdpObj.defaultKey = @"";
    config.cdpEndpointURL = cdpObj;
    
    // When: Resolve with random value above threshold (should use default)
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config randomValue:0.7];
    
    // Then: Should use default endpoint
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction", 
                         @"Should resolve to default endpoint with random > 0.5");
    XCTAssertEqualObjects(resolver.testGroupName, @"", 
                         @"Should have no test group name");
}

/**
 * Test endpoint resolution with empty test variant value (should fallback to default)
 */
- (void)testEndpointResolution_EmptyTestVariantValue_FallbackToDefault {
    // Given: Config with empty test variant value
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    
    CLXSDKConfigEndpointValue *variant = [[CLXSDKConfigEndpointValue alloc] init];
    variant.name = @"empty-variant";
    variant.value = @"";  // Empty value
    variant.ratio = 1.0;
    
    CLXSDKConfigEndpointObject *auctionObj = [[CLXSDKConfigEndpointObject alloc] init];
    auctionObj.defaultKey = @"https://au.cloudx.io/openrtb2/auction";
    auctionObj.test = @[variant];
    
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointObject = auctionObj;
    config.auctionEndpointURL = auctionQuantum;
    
    CLXSDKConfigEndpointObject *cdpObj = [[CLXSDKConfigEndpointObject alloc] init];
    cdpObj.defaultKey = @"";
    config.cdpEndpointURL = cdpObj;
    
    // When: Resolve endpoints
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config randomValue:0.5];
    
    // Then: Should use default (empty variant should be filtered out)
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"https://au.cloudx.io/openrtb2/auction", 
                         @"Should fallback to default when variant value is empty");
}

/**
 * Test endpoint resolution with nil config (error handling)
 */
- (void)testEndpointResolution_NilConfig_ShouldHandleGracefully {
    // Given: Nil config
    CLXSDKConfigResponse *config = nil;
    
    // When: Resolve endpoints
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    // Then: Should handle gracefully with empty endpoints
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"", @"Should have empty auction endpoint");
    XCTAssertEqualObjects(resolver.cdpEndpoint, @"", @"Should have empty CDP endpoint");
    XCTAssertEqualObjects(resolver.geoEndpoint, @"", @"Should have empty geo endpoint");
}

/**
 * Test reset functionality
 */
- (void)testEndpointResolver_Reset_ShouldClearAllEndpoints {
    // Given: Resolver with resolved endpoints
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    CLXSDKConfigEndpointQuantumValue *auctionQuantum = [[CLXSDKConfigEndpointQuantumValue alloc] init];
    auctionQuantum.endpointString = @"https://au.cloudx.io/openrtb2/auction";
    config.auctionEndpointURL = auctionQuantum;
    
    CLXEndpointResolver *resolver = [[CLXEndpointResolver alloc] init];
    [resolver resolveFromConfig:config];
    
    XCTAssertNotEqualObjects(resolver.auctionEndpoint, @"", @"Should have auction endpoint before reset");
    
    // When: Reset
    [resolver reset];
    
    // Then: All endpoints should be empty
    XCTAssertEqualObjects(resolver.auctionEndpoint, @"", @"Auction endpoint should be empty after reset");
    XCTAssertEqualObjects(resolver.cdpEndpoint, @"", @"CDP endpoint should be empty after reset");
    XCTAssertEqualObjects(resolver.geoEndpoint, @"", @"Geo endpoint should be empty after reset");
    XCTAssertEqualObjects(resolver.testGroupName, @"", @"Test group name should be empty after reset");
}

@end

