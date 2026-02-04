//
//  CLXTrackingFieldResolverBidDimensionTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-17.
//

// TODO: [2026-01-28] Removed iOS-specific fallback tests to match Android implementation.
// If iOS bid responses have issues (missing w/h, creativeId→crid mapping, dealid in debug data),
// we may need to add these features back. Removed tests:
// - testBidWidth_ShouldFallbackToBidRequestFormat
// - testBidHeight_ShouldResolveFromBidRequestFormat
// - testBidCreativeId_ShouldMapToCridField
// - testBidDealId_ShouldExtractFromDebugData
//
// Also deleted: CLXTrackingFieldResolverArrayLookupTests.m
// - Tested internal methods (resolveArrayLookup, resolveConditionValue, valuesAreEqual) that were removed
// - Tested placeholder expansion in array filters like ${bid.ext.cloudx.rank}
// - May need to verify array lookup still works if issues arise

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access internal methods for testing
@interface CLXTrackingFieldResolver (BidDimensionTesting)
- (nullable id)resolveBidDimensionField:(NSString *)auctionId field:(NSString *)field impid:(NSString *)impid;
- (nullable id)resolveBidField:(NSString *)auctionId field:(NSString *)field;
- (void)setConfigJSON:(NSDictionary *)configJSON;
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
              pluginVersion:(nullable NSString *)pluginVersion
             deviceTypeName:(NSString *)deviceTypeName
             deviceTypeCode:(NSInteger)deviceTypeCode
                abTestGroup:(NSString *)abTestGroup
                  appBundle:(NSString *)appBundle;
- (void)setSdkParam:(NSString *)auctionId key:(NSString *)key value:(NSString *)value;
- (nullable NSString *)buildPayload:(NSString *)auctionId bidId:(nullable NSString *)bidId;
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field bidId:(nullable NSString *)bidId;
@end

@interface CLXTrackingFieldResolverBidDimensionTests : XCTestCase
@property (nonatomic, strong) CLXTrackingFieldResolver *resolver;
@property (nonatomic, strong) NSString *testAuctionId;
@property (nonatomic, strong) NSString *testBidId;
@property (nonatomic, strong) NSString *testImpId;
@end

@implementation CLXTrackingFieldResolverBidDimensionTests

- (void)setUp {
    [super setUp];
    self.resolver = [[CLXTrackingFieldResolver alloc] init];
    self.testAuctionId = @"test-auction-123";
    self.testBidId = @"test-bid-456";
    self.testImpId = @"test-imp-789";
}

#pragma mark - Bidder Field Resolution Tests

/**
 * Test bid.ext.prebid.meta.adaptercode field resolution using direct JSON access
 * Validates our fix for the bidder field corruption issue
 */
- (void)testBidderField_ShouldResolveDirectlyFromJSON {
    // Given: Bid response with Meta bidder in ext.prebid.meta.adaptercode
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"price": @99.99,
                @"ext": @{
                    @"prebid": @{
                        @"meta": @{
                            @"adaptercode": @"meta"
                        }
                    }
                }
            }]
        }]
    };
    
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolve bidder field using direct JSON access
    id bidder = [self.resolver resolveBidField:self.testAuctionId field:@"bid.ext.prebid.meta.adaptercode"];
    
    // Then: Should return "meta" without corruption
    XCTAssertNotNil(bidder, @"Bidder should be resolved");
    XCTAssertEqualObjects(bidder, @"meta", @"Should return 'meta' from direct JSON access");
}

/**
 * Test bidder field resolution with different adapter names
 */
- (void)testBidderField_ShouldResolveVariousAdapters {
    NSArray *testAdapters = @[@"meta", @"google", @"amazon", @"prebid"];
    
    for (NSString *adapterName in testAdapters) {
        // Given: Bid response with specific adapter
        NSDictionary *bidResponse = @{
            @"seatbid": @[@{
                @"bid": @[@{
                    @"id": self.testBidId,
                    @"impid": self.testImpId,
                    @"price": @99.99,
                    @"ext": @{
                        @"prebid": @{
                            @"meta": @{
                                @"adaptercode": adapterName
                            }
                        }
                    }
                }]
            }]
        };
        
        [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
            
        // When: Resolve bidder field
        id bidder = [self.resolver resolveBidField:self.testAuctionId field:@"bid.ext.prebid.meta.adaptercode"];
        
        // Then: Should return correct adapter name
        XCTAssertEqualObjects(bidder, adapterName, @"Should return '%@' for adapter", adapterName);
    }
}

#pragma mark - Bid Dimension Resolution Tests

/**
 * Test bid.w field resolution from bid response first, then bid request fallback
 * Validates our fix for dynamic dimension resolution
 */
- (void)testBidWidth_ShouldResolveFromBidResponseFirst {
    // Given: Bid response with width field
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"price": @99.99,
                @"w": @320  // Width in bid response
            }]
        }]
    };
    
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolve bid.w field
    id width = [self.resolver resolveBidField:self.testAuctionId field:@"bid.w"];
    
    // Then: Should return width from bid response
    XCTAssertNotNil(width, @"Width should be resolved");
    XCTAssertEqualObjects(width, @320, @"Should return 320 from bid response");
}

#pragma mark - OpenRTB Field Mapping Tests

/**
 * Test bid.dealid returns nil when field doesn't exist
 * Validates graceful handling of missing fields
 */
- (void)testBidDealId_ShouldReturnNilWhenMissing {
    // Given: Bid response without dealid field
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"price": @99.99
            }]
        }]
    };
    
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolve bid.dealid field
    id dealId = [self.resolver resolveBidField:self.testAuctionId field:@"bid.dealid"];
    
    // Then: Should return nil gracefully
    XCTAssertNil(dealId, @"Deal ID should be nil when field doesn't exist");
}

/**
 * Test bid.dealid direct extraction from bid object takes precedence
 * Validates that direct dealid field is preferred over debug data
 */
- (void)testBidDealId_DirectFieldTakesPrecedence {
    // Given: Bid response with deal ID in both bid object and debug data
    NSDictionary *bidResponse = @{
        @"id": self.testAuctionId,
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"price": @99.99,
                @"dealid": @"direct-deal-456"  // Direct field should take precedence
            }]
        }],
        @"ext": @{
            @"debug": @{
                @"rounds": @{
                    @"1": @{
                        @"resolvedrequest": @{
                            @"imp": @[@{
                                @"id": self.testImpId,
                                @"ext": @{
                                    @"prebid": @{
                                        @"bidder": @{
                                            @"meta": @{
                                                @"line_items": @[@{
                                                    @"id": @"test-line-item-123",
                                                    @"deal": @{
                                                        @"id": @"debug-deal-789",
                                                        @"wseat": @[@"meta"]
                                                    }
                                                }]
                                            }
                                        }
                                    }
                                }
                            }]
                        }
                    }
                }
            }
        }
    };
    
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolve bid.dealid field
    id dealId = [self.resolver resolveBidField:self.testAuctionId field:@"bid.dealid"];
    
    // Then: Should return direct field value, not debug data value
    XCTAssertNotNil(dealId, @"Deal ID should be resolved");
    XCTAssertEqualObjects(dealId, @"direct-deal-456", @"Should prefer direct dealid field over debug data");
}

#pragma mark - Error Handling Tests

/**
 * Test dimension resolution with missing impression
 */
- (void)testBidDimensions_MissingImpression_ShouldReturnNil {
    // Given: Bid response with impid that doesn't match any impression
    NSDictionary *bidRequest = @{
        @"imp": @[@{
            @"id": @"different-imp-id",
            @"banner": @{
                @"format": @[@{@"w": @320, @"h": @50}]
            }
        }]
    };
    
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,  // Different from bid request
                @"price": @99.99
            }]
        }]
    };
    
    [self.resolver setRequestData:self.testAuctionId bidRequestJSON:bidRequest];
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Try to resolve dimensions
    id width = [self.resolver resolveBidField:self.testAuctionId field:@"bid.w"];
    id height = [self.resolver resolveBidField:self.testAuctionId field:@"bid.h"];
    
    // Then: Should handle gracefully
    XCTAssertNil(width, @"Width should be nil when impression not found");
    XCTAssertNil(height, @"Height should be nil when impression not found");
}

/**
 * Test dimension resolution with malformed banner format
 */
- (void)testBidDimensions_MalformedFormat_ShouldReturnNil {
    // Given: Bid request with malformed banner format
    NSDictionary *bidRequest = @{
        @"imp": @[@{
            @"id": self.testImpId,
            @"banner": @{
                @"format": @[]  // Empty format array
            }
        }]
    };
    
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"price": @99.99
            }]
        }]
    };
    
    [self.resolver setRequestData:self.testAuctionId bidRequestJSON:bidRequest];
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Try to resolve dimensions
    id width = [self.resolver resolveBidField:self.testAuctionId field:@"bid.w"];
    
    // Then: Should handle gracefully
    XCTAssertNil(width, @"Width should be nil with empty format array");
}

#pragma mark - Base64 Encoding Tests (sdk.placement and sdk.customData)

/**
 * Tests that sdk.placement is Base64 encoded when resolved.
 * Backend expects these fields encoded since they can contain delimiters.
 */
- (void)testResolveField_SdkPlacement_IsBase64Encoded {
    // Given
    NSString *rawValue = @"game_over_screen";
    [self.resolver setSdkParam:self.testAuctionId key:@"sdk.placement" value:rawValue];

    // When
    id result = [self.resolver resolveField:self.testAuctionId field:@"sdk.placement" bidId:nil];

    // Then - value should be Base64 encoded
    NSString *expectedBase64 = [[rawValue dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    XCTAssertEqualObjects(result, expectedBase64, @"sdk.placement should be Base64 encoded");
    XCTAssertNotEqualObjects(result, rawValue, @"sdk.placement should NOT be raw value");
}

/**
 * Tests that sdk.customData is Base64 encoded when resolved.
 */
- (void)testResolveField_SdkCustomData_IsBase64Encoded {
    // Given
    NSString *rawValue = @"coins:100,gems:50";
    [self.resolver setSdkParam:self.testAuctionId key:@"sdk.customData" value:rawValue];

    // When
    id result = [self.resolver resolveField:self.testAuctionId field:@"sdk.customData" bidId:nil];

    // Then - value should be Base64 encoded
    NSString *expectedBase64 = [[rawValue dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    XCTAssertEqualObjects(result, expectedBase64, @"sdk.customData should be Base64 encoded");
}

/**
 * Tests that customData with semicolons is safely Base64 encoded.
 * This is the key fix - semicolons would break the payload format without encoding.
 */
- (void)testBuildPayload_CustomDataWithSemicolons_IsBase64Encoded {
    // Given - SDK param with semicolons (the delimiter used in payloads)
    NSDictionary *configJSON = @{
        @"tracking": @[@"sdk.sessionId", @"sdk.customData"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"sess-123"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    NSString *customDataWithSemicolons = @"level:1;coins:500;difficulty:hard";
    [self.resolver setSdkParam:self.testAuctionId key:@"sdk.customData" value:customDataWithSemicolons];

    // When
    NSString *payload = [self.resolver buildPayload:self.testAuctionId bidId:nil];

    // Then - customData is Base64 encoded, payload has exactly 2 semicolon-separated values
    NSArray *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqual(values.count, 2, @"Should have exactly 2 values (sessionId and base64-encoded customData)");
    XCTAssertEqualObjects(values[0], @"sess-123", @"First value should be sessionId");

    // Verify second value is Base64 encoded customData
    NSString *expectedBase64 = [[customDataWithSemicolons dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    XCTAssertEqualObjects(values[1], expectedBase64, @"customData should be Base64 encoded");
}

/**
 * Tests that other SDK fields are NOT Base64 encoded (only placement and customData).
 */
- (void)testResolveField_OtherSdkFields_NotBase64Encoded {
    // Given
    [self.resolver setSessionConstData:@"session-abc"
                            sdkVersion:@"2.0.0"
                         pluginVersion:nil
                        deviceTypeName:@"tablet"
                        deviceTypeCode:5
                           abTestGroup:@"test-group"
                             appBundle:@"com.app"];

    // When
    id sessionId = [self.resolver resolveField:self.testAuctionId field:@"sdk.sessionId" bidId:nil];
    id sdkVersion = [self.resolver resolveField:self.testAuctionId field:@"sdk.releaseVersion" bidId:nil];
    id deviceType = [self.resolver resolveField:self.testAuctionId field:@"sdk.deviceTypeName" bidId:nil];

    // Then - these should NOT be Base64 encoded
    XCTAssertEqualObjects(sessionId, @"session-abc", @"sdk.sessionId should NOT be encoded");
    XCTAssertEqualObjects(sdkVersion, @"2.0.0", @"sdk.releaseVersion should NOT be encoded");
    XCTAssertEqualObjects(deviceType, @"tablet", @"sdk.deviceTypeName should NOT be encoded");
}

@end
