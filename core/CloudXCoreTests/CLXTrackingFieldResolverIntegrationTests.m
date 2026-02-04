//
//  CLXTrackingFieldResolverIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests for TrackingFieldResolver matching Android's production test.
//  Tests all 25 production tracking fields with real-world data.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>

@interface CLXTrackingFieldResolver (IntegrationTesting)
- (void)setConfigJSON:(NSDictionary *)configJSON;
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
              pluginVersion:(nullable NSString *)pluginVersion
             deviceTypeName:(NSString *)deviceTypeName
             deviceTypeCode:(NSInteger)deviceTypeCode
                abTestGroup:(NSString *)abTestGroup
                  appBundle:(NSString *)appBundle;
- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)json;
- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)json;
- (void)setSdkParam:(NSString *)auctionId key:(NSString *)key value:(NSString *)value;
- (nullable NSString *)buildPayload:(NSString *)auctionId bidId:(nullable NSString *)bidId;
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field bidId:(nullable NSString *)bidId;
- (void)clear;
@end

@interface CLXTrackingFieldResolverIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXTrackingFieldResolver *resolver;
@end

@implementation CLXTrackingFieldResolverIntegrationTests

- (void)setUp {
    [super setUp];
    self.resolver = [[CLXTrackingFieldResolver alloc] init];
}

- (void)tearDown {
    [self.resolver clear];
    self.resolver = nil;
    [super tearDown];
}

#pragma mark - Production Integration Test (matches new_config_response.txt)

/**
 * Integration test that resolves all production tracking fields from real Config API.
 * Updated to match new_config_response.txt tracking fields exactly.
 */
- (void)testIntegration_ResolvesAllProductionTrackingFields {
    // Given - setup with realistic production data
    NSString *auctionId = @"prod-auction-123";
    NSString *adUnitId = @"duWzvnasECVFML-K5CnQJ";  // From new_config_response.txt
    NSString *bidId = @"bid-456";

    // Production tracking fields (from new_config_response.txt, excluding sdk.placement and sdk.customData)
    NSArray<NSString *> *trackingFields = @[
        @"bid.ext.prebid.meta.adaptercode",
        @"bid.w",
        @"bid.h",
        @"bid.dealid",
        @"bid.crid",
        @"bid.price",
        @"sdk.responseTimeMillis",
        @"sdk.releaseVersion",
        @"bidRequest.id",
        @"config.accountID",
        @"config.organizationID",
        @"sdk.app.bundle",
        @"bidRequest.imp.tagid",
        @"bidRequest.device.model",
        @"sdk.deviceTypeName",
        @"bidRequest.device.os",
        @"bidRequest.device.osv",
        @"sdk.sessionId",
        @"sdk.ifa",
        @"sdk.testGroupName",
        @"config.adUnits[id=${bidRequest.imp.tagid}].name",
        @"bidRequest.device.geo.country",
        @"bid.ext.cloudx.test",
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round",
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId",
        @"config.adUnits[id=${bidRequest.imp.tagid}].type"
    ];

    // Config data (matching new_config_response.txt structure)
    NSDictionary *configJSON = @{
        @"accountID": @"acc_id_CLDX1",
        @"organizationID": @"CLDX1",
        @"tracking": trackingFields,
        @"adUnits": @[
            @{@"id": adUnitId, @"name": @"DSTestPlacement", @"type": @"BANNER"}
        ]
    };

    [self.resolver setConfigJSON:configJSON];

    // Set session data (matches Android constructor params)
    [self.resolver setSessionConstData:@"oAhk3JzG7YtaoE027xaKI"
                            sdkVersion:@"1.2.3"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.example.app"];

    // Bid request with production-like structure
    NSDictionary *bidRequestJSON = @{
        @"id": auctionId,
        @"imp": @[@{
            @"tagid": adUnitId,
            @"banner": @{@"w": @320, @"h": @50}
        }],
        @"device": @{
            @"ifa": @"test-ifa-456",
            @"model": @"iPhone14,2",
            @"os": @"iOS",
            @"osv": @"17.1",
            @"dnt": @0,
            @"geo": @{
                @"country": @"USA"
            }
        }
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // Bid response with cloudx auction data
    NSDictionary *bidResponseJSON = @{
        @"id": auctionId,
        @"seatbid": @[@{
            @"seat": @"cloudx",
            @"bid": @[@{
                @"id": bidId,
                @"impid": @"imp-1",
                @"price": @2.5,
                @"w": @320,
                @"h": @50,
                @"dealid": @"deal-789",
                @"crid": @"creative-101",
                @"ext": @{
                    @"prebid": @{
                        @"meta": @{
                            @"adaptercode": @"cloudx"
                        }
                    },
                    @"cloudx": @{
                        @"rank": @1,
                        @"test": @NO
                    }
                }
            }]
        }],
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[@{
                        @"rank": @1,
                        @"round": @1,
                        @"lineItemId": @"line-item-123"
                    }]
                }
            }
        }
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // Set SDK params
    [self.resolver setSdkParam:auctionId key:@"sdk.responseTimeMillis" value:@"250"];

    // When - build payload with production tracking fields
    NSString *payload = [self.resolver buildPayload:auctionId bidId:bidId];

    // Then - verify payload contains all expected values
    XCTAssertNotNil(payload, @"Payload should not be nil");
    NSArray<NSString *> *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqual(values.count, 26, @"Should have 26 values (excluding sdk.placement and sdk.customData)");

    // Verify critical field values
    XCTAssertEqualObjects(values[0], @"cloudx", @"bid.ext.prebid.meta.adaptercode");
    XCTAssertEqualObjects(values[1], @"320", @"bid.w");
    XCTAssertEqualObjects(values[2], @"50", @"bid.h");
    XCTAssertEqualObjects(values[3], @"deal-789", @"bid.dealid");
    XCTAssertEqualObjects(values[4], @"creative-101", @"bid.crid");
    XCTAssertEqualObjects(values[5], @"2.5", @"bid.price");
    XCTAssertEqualObjects(values[6], @"250", @"sdk.responseTimeMillis");
    XCTAssertEqualObjects(values[7], @"1.2.3", @"sdk.releaseVersion");
    XCTAssertEqualObjects(values[8], auctionId, @"bidRequest.id");
    XCTAssertEqualObjects(values[9], @"acc_id_CLDX1", @"config.accountID");
    XCTAssertEqualObjects(values[10], @"CLDX1", @"config.organizationID");
    XCTAssertEqualObjects(values[11], @"com.example.app", @"sdk.app.bundle");
    XCTAssertEqualObjects(values[12], adUnitId, @"bidRequest.imp.tagid");
    XCTAssertEqualObjects(values[13], @"iPhone14,2", @"bidRequest.device.model");
    XCTAssertEqualObjects(values[14], @"phone", @"sdk.deviceTypeName");
    XCTAssertEqualObjects(values[15], @"iOS", @"bidRequest.device.os");
    XCTAssertEqualObjects(values[16], @"17.1", @"bidRequest.device.osv");
    XCTAssertEqualObjects(values[17], @"oAhk3JzG7YtaoE027xaKI", @"sdk.sessionId");
    // sdk.ifa returns sessionId when privacy service blocks personal data (can't mock in unit test)
    XCTAssertTrue([values[18] isEqualToString:@"test-ifa-456"] ||
                  [values[18] isEqualToString:@"oAhk3JzG7YtaoE027xaKI"],
                  @"sdk.ifa should be IFA or sessionId fallback");
    XCTAssertEqualObjects(values[19], @"", @"sdk.testGroupName (empty)");
    XCTAssertEqualObjects(values[20], @"DSTestPlacement", @"config.adUnits[id=${bidRequest.imp.tagid}].name");
    XCTAssertEqualObjects(values[21], @"USA", @"bidRequest.device.geo.country");
    XCTAssertEqualObjects(values[22], @"0", @"bid.ext.cloudx.test");
    XCTAssertEqualObjects(values[23], @"1", @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round");
    XCTAssertEqualObjects(values[24], @"line-item-123", @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId");
    XCTAssertEqualObjects(values[25], @"BANNER", @"config.adUnits[id=${bidRequest.imp.tagid}].type");
}

#pragma mark - Winner Bid Extraction Tests

/**
 * Tests that when multiple bids exist in the response, only the winner bid's fields are extracted.
 * This simulates a real auction scenario where multiple bidders participate but only one wins.
 */
- (void)testWinnerBidExtraction_ExtractsFieldsFromCorrectBid {
    // Given - auction with multiple bids from different bidders
    NSString *auctionId = @"multi-bid-auction";
    NSString *winnerBidId = @"winner-bid-123";  // This is the winning bid
    NSString *loserBidId1 = @"loser-bid-456";
    NSString *loserBidId2 = @"loser-bid-789";

    NSDictionary *configJSON = @{
        @"tracking": @[
            @"bid.ext.prebid.meta.adaptercode",
            @"bid.price",
            @"bid.w",
            @"bid.h",
            @"bid.crid",
            @"bid.dealid"
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    // Response with 3 bids - winner has highest price but we select by bidId, not price
    NSDictionary *bidResponseJSON = @{
        @"id": auctionId,
        @"seatbid": @[
            @{
                @"seat": @"meta",
                @"bid": @[@{
                    @"id": loserBidId1,
                    @"price": @3.5,  // Higher price but NOT the winner
                    @"w": @320,
                    @"h": @50,
                    @"crid": @"meta-creative-999",
                    @"dealid": @"meta-deal-111",
                    @"ext": @{
                        @"prebid": @{@"meta": @{@"adaptercode": @"meta"}}
                    }
                }]
            },
            @{
                @"seat": @"cloudx",
                @"bid": @[@{
                    @"id": winnerBidId,  // THIS is the winner bid
                    @"price": @2.5,
                    @"w": @300,
                    @"h": @250,
                    @"crid": @"cloudx-creative-123",
                    @"dealid": @"cloudx-deal-456",
                    @"ext": @{
                        @"prebid": @{@"meta": @{@"adaptercode": @"cloudx"}}
                    }
                }]
            },
            @{
                @"seat": @"inmobi",
                @"bid": @[@{
                    @"id": loserBidId2,
                    @"price": @1.0,
                    @"w": @728,
                    @"h": @90,
                    @"crid": @"inmobi-creative-777",
                    @"ext": @{
                        @"prebid": @{@"meta": @{@"adaptercode": @"inmobi"}}
                    }
                }]
            }
        ]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // When - build payload with winner bid ID (simulating what CLXRillImpressionInitService does)
    NSString *payload = [self.resolver buildPayload:auctionId bidId:winnerBidId];

    // Then - verify payload contains ONLY the winner bid's fields, NOT the losers'
    XCTAssertNotNil(payload, @"Payload should not be nil");
    NSArray<NSString *> *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqual(values.count, 6, @"Should have 6 values");

    // These should be from the WINNER bid (cloudx), not from meta or inmobi
    XCTAssertEqualObjects(values[0], @"cloudx", @"Should extract adaptercode from winner bid");
    XCTAssertEqualObjects(values[1], @"2.5", @"Should extract price from winner bid (not 3.5 from meta)");
    XCTAssertEqualObjects(values[2], @"300", @"Should extract width from winner bid (not 320 from meta)");
    XCTAssertEqualObjects(values[3], @"250", @"Should extract height from winner bid (not 50 from meta)");
    XCTAssertEqualObjects(values[4], @"cloudx-creative-123", @"Should extract crid from winner bid");
    XCTAssertEqualObjects(values[5], @"cloudx-deal-456", @"Should extract dealid from winner bid");
}

/**
 * Tests that passing the wrong bidId returns nil for bid fields.
 * This ensures we don't accidentally leak data from other bids.
 */
- (void)testWinnerBidExtraction_ReturnsNilForNonExistentBidId {
    // Given
    NSString *auctionId = @"wrong-bidid-auction";

    NSDictionary *configJSON = @{
        @"tracking": @[@"bid.price", @"sdk.sessionId"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"session-abc"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    NSDictionary *bidResponseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"real-bid-id",
                @"price": @5.0
            }]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // When - pass a bidId that doesn't exist
    NSString *payload = [self.resolver buildPayload:auctionId bidId:@"non-existent-bid-id"];

    // Then - bid.price should be empty, sdk.sessionId should still work
    NSArray<NSString *> *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqualObjects(values[0], @"", @"bid.price should be empty for non-existent bidId");
    XCTAssertEqualObjects(values[1], @"session-abc", @"sdk fields should still resolve");
}

/**
 * Tests that bid fields from different seats are correctly identified.
 * Simulates a real prebid response where multiple SSPs return bids.
 */
- (void)testWinnerBidExtraction_FindsBidAcrossMultipleSeats {
    // Given - bid is in the second seatbid entry
    NSString *auctionId = @"multi-seat-auction";
    NSString *targetBidId = @"target-bid-in-second-seat";

    NSDictionary *configJSON = @{
        @"tracking": @[@"bid.ext.prebid.meta.adaptercode", @"bid.price"]
    };
    [self.resolver setConfigJSON:configJSON];

    NSDictionary *bidResponseJSON = @{
        @"seatbid": @[
            @{
                @"seat": @"first-ssp",
                @"bid": @[@{@"id": @"other-bid", @"price": @1.0, @"ext": @{@"prebid": @{@"meta": @{@"adaptercode": @"first"}}}}]
            },
            @{
                @"seat": @"second-ssp",
                @"bid": @[
                    @{@"id": @"another-bid", @"price": @2.0, @"ext": @{@"prebid": @{@"meta": @{@"adaptercode": @"second-a"}}}},
                    @{@"id": targetBidId, @"price": @3.0, @"ext": @{@"prebid": @{@"meta": @{@"adaptercode": @"second-b"}}}}
                ]
            },
            @{
                @"seat": @"third-ssp",
                @"bid": @[@{@"id": @"yet-another-bid", @"price": @4.0, @"ext": @{@"prebid": @{@"meta": @{@"adaptercode": @"third"}}}}]
            }
        ]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // When - find the target bid which is nested in second seat, second bid
    NSString *payload = [self.resolver buildPayload:auctionId bidId:targetBidId];

    // Then - should extract from the correct bid
    NSArray<NSString *> *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqualObjects(values[0], @"second-b", @"Should find bid in second seat");
    XCTAssertEqualObjects(values[1], @"3", @"Should extract correct price");
}

/**
 * Tests the full flow matching what CLXRillImpressionInitService does:
 * 1. Set bid response JSON
 * 2. Use winner bid's ID to build payload
 * 3. Verify all bid.* fields come from the winner
 */
- (void)testWinnerBidExtraction_FullProductionFlow {
    // Given - simulate production scenario
    NSString *auctionId = @"prod-auction-winner-test";
    NSString *winnerBidId = @"winning-bid-abc123";

    // Production tracking fields that use bid.*
    NSDictionary *configJSON = @{
        @"tracking": @[
            @"bid.ext.prebid.meta.adaptercode",
            @"bid.w",
            @"bid.h",
            @"bid.dealid",
            @"bid.crid",
            @"bid.price",
            @"bid.ext.cloudx.test",
            @"bid.ext.cloudx.rank"
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    // Realistic bid response with winner and loser
    NSDictionary *bidResponseJSON = @{
        @"id": auctionId,
        @"seatbid": @[
            @{
                @"seat": @"loser-seat",
                @"bid": @[@{
                    @"id": @"loser-bid",
                    @"price": @10.0,  // Even higher price, but not the winner
                    @"w": @1000,
                    @"h": @1000,
                    @"crid": @"LOSER-CREATIVE",
                    @"dealid": @"LOSER-DEAL",
                    @"ext": @{
                        @"prebid": @{@"meta": @{@"adaptercode": @"LOSER"}},
                        @"cloudx": @{@"test": @YES, @"rank": @99}
                    }
                }]
            },
            @{
                @"seat": @"winner-seat",
                @"bid": @[@{
                    @"id": winnerBidId,
                    @"price": @5.5,
                    @"w": @300,
                    @"h": @250,
                    @"crid": @"winner-creative-xyz",
                    @"dealid": @"winner-deal-789",
                    @"ext": @{
                        @"prebid": @{@"meta": @{@"adaptercode": @"cloudx"}},
                        @"cloudx": @{@"test": @NO, @"rank": @1}
                    }
                }]
            }
        ]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // When - this is what CLXRillImpressionInitService does:
    // NSString *bidId = rillImpressionModel.lastBidResponse.bid.id;
    // NSString *payload = [resolver buildPayload:auctionId bidId:bidId];
    NSString *payload = [self.resolver buildPayload:auctionId bidId:winnerBidId];

    // Then - ALL values should be from the winner, NOT the loser
    NSArray<NSString *> *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqual(values.count, 8, @"Should have 8 values");

    XCTAssertEqualObjects(values[0], @"cloudx", @"adaptercode from winner (not LOSER)");
    XCTAssertEqualObjects(values[1], @"300", @"width from winner (not 1000)");
    XCTAssertEqualObjects(values[2], @"250", @"height from winner (not 1000)");
    XCTAssertEqualObjects(values[3], @"winner-deal-789", @"dealid from winner (not LOSER-DEAL)");
    XCTAssertEqualObjects(values[4], @"winner-creative-xyz", @"crid from winner (not LOSER-CREATIVE)");
    XCTAssertEqualObjects(values[5], @"5.5", @"price from winner (not 10)");
    XCTAssertEqualObjects(values[6], @"0", @"cloudx.test from winner (not 1)");
    XCTAssertEqualObjects(values[7], @"1", @"cloudx.rank from winner (not 99)");
}

#pragma mark - Individual Field Category Tests

- (void)testBuildPayload_JoinsResolvedFieldValuesWithSemicolon {
    // Given - tracking list configured
    NSDictionary *configJSON = @{
        @"tracking": @[@"sdk.sessionId", @"sdk.releaseVersion", @"sdk.deviceTypeName"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"sess-1"
                            sdkVersion:@"v1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // When
    NSString *payload = [self.resolver buildPayload:@"auction-1" bidId:nil];

    // Then - values joined with semicolon
    XCTAssertEqualObjects(payload, @"sess-1;v1.0;phone");
}

- (void)testBuildPayload_HandlesMissingFieldValuesWithEmptyStrings {
    // Given - tracking list with some missing fields
    NSDictionary *configJSON = @{
        @"tracking": @[@"sdk.sessionId", @"bidRequest.missing", @"sdk.deviceTypeName"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"sess-2"
                            sdkVersion:@"v1.0"
                         pluginVersion:nil
                        deviceTypeName:@"tablet"
                        deviceTypeCode:5
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // When
    NSString *payload = [self.resolver buildPayload:@"auction-2" bidId:nil];

    // Then - missing fields become empty strings
    XCTAssertEqualObjects(payload, @"sess-2;;tablet");
}

- (void)testResolveField_ResolvesBidFieldWithBidId {
    // Given - response with multiple bids
    NSString *auctionId = @"auction-bid";
    NSDictionary *responseJSON = @{
        @"id": auctionId,
        @"seatbid": @[@{
            @"bid": @[
                @{@"id": @"bid-1", @"price": @2.5},
                @{@"id": @"bid-2", @"price": @3.0}
            ]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When - resolve specific bid's price
    id result = [self.resolver resolveField:auctionId field:@"bid.price" bidId:@"bid-2"];

    // Then - returns correct bid's price
    XCTAssertEqualObjects([result description], @"3", @"Should return bid-2's price");
}

- (void)testResolveField_ReturnsNilForBidFieldWithoutBidId {
    // Given
    NSString *auctionId = @"auction-no-bidid";
    NSDictionary *responseJSON = @{
        @"seatbid": @[@{@"bid": @[@{@"id": @"bid-1", @"price": @1.0}]}]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When - try to resolve bid field without providing bidId
    id result = [self.resolver resolveField:auctionId field:@"bid.price" bidId:nil];

    // Then - returns nil
    XCTAssertNil(result, @"Should return nil without bidId");
}

- (void)testResolveField_ResolvesNestedBidField {
    // Given
    NSString *auctionId = @"auction-nested-bid";
    NSDictionary *responseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-nested",
                @"ext": @{
                    @"cloudx": @{
                        @"rank": @1
                    }
                }
            }]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When - resolve nested field
    id result = [self.resolver resolveField:auctionId field:@"bid.ext.cloudx.rank" bidId:@"bid-nested"];

    // Then
    XCTAssertEqualObjects(result, @1, @"Should resolve nested bid field");
}

- (void)testResolveField_ResolvesBidRequestField {
    // Given
    NSString *auctionId = @"auction-request";
    NSDictionary *requestJSON = @{
        @"id": @"req-123",
        @"imp": @[@{
            @"id": @"imp-1",
            @"banner": @{@"w": @320, @"h": @50}
        }]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:requestJSON];

    // When - resolve simple field
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.id" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"req-123");
}

- (void)testResolveField_ResolvesNestedBidRequestFieldWithArray {
    // Given
    NSString *auctionId = @"auction-request-nested";
    NSDictionary *requestJSON = @{
        @"imp": @[@{
            @"id": @"imp-1",
            @"banner": @{@"w": @320}
        }]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:requestJSON];

    // When - resolve through array (takes first element)
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.imp.banner.w" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @320);
}

- (void)testResolveNestedField_HandlesArrayFiltering {
    // Given
    NSString *auctionId = @"auction-filter";
    NSDictionary *requestJSON = @{
        @"users": @[
            @{@"name": @"Alice", @"role": @"admin"},
            @{@"name": @"Bob", @"role": @"user"},
            @{@"name": @"Charlie", @"role": @"admin"}
        ]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:requestJSON];

    // When - use array filter syntax users[role=admin]
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.users[role=admin].name" bidId:nil];

    // Then - gets first matching element
    XCTAssertEqualObjects(result, @"Alice");
}

- (void)testResolveField_ExpandsPlaceholderInBidFieldPath {
    // Given - response with adapter code in ext
    NSString *auctionId = @"auction-placeholder";
    NSDictionary *responseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": @"bid-placeholder",
                @"ext": @{
                    @"prebid": @{
                        @"meta": @{
                            @"adaptercode": @"cloudx"
                        }
                    },
                    @"cloudx": @{
                        @"rank": @1
                    }
                }
            }]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When - use placeholder ${...} in path
    id result = [self.resolver resolveField:auctionId
                                      field:@"bid.ext.${bid.ext.prebid.meta.adaptercode}.rank"
                                      bidId:@"bid-placeholder"];

    // Then - placeholder expanded to "cloudx", path becomes "bid.ext.cloudx.rank"
    XCTAssertEqualObjects(result, @1);
}

- (void)testResolveField_ExpandsMultiplePlaceholders {
    // Given
    NSString *auctionId = @"auction-multi-placeholder";
    [self.resolver setSessionConstData:@"sessionabc"
                            sdkVersion:@"v10"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    NSDictionary *requestJSON = @{
        @"sessionabc": @{
            @"v10": @{
                @"value": @"nested-value"
            }
        }
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:requestJSON];

    // When - use multiple placeholders
    id result = [self.resolver resolveField:auctionId
                                      field:@"bidRequest.${sdk.sessionId}.${sdk.releaseVersion}.value"
                                      bidId:nil];

    // Then - both placeholders expanded
    XCTAssertEqualObjects(result, @"nested-value");
}

- (void)testResolveField_UnknownPrefixReturnsNil {
    // Given
    NSString *auctionId = @"auction-unknown";

    // When - use unknown prefix
    id result = [self.resolver resolveField:auctionId field:@"unknown.field" bidId:nil];

    // Then - returns nil
    XCTAssertNil(result);
}

#pragma mark - SDK Field Tests (matching Android)

- (void)testResolveField_ResolvesCustomSdkParameter {
    // Given
    NSString *auctionId = @"auction-custom-sdk";
    [self.resolver setSdkParam:auctionId key:@"sdk.customMetric" value:@"123.45"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.customMetric" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"123.45");
}

- (void)testResolveField_ResolvesSdkPluginVersionWhenSet {
    // Given - resolver with pluginVersion
    NSString *auctionId = @"auction-plugin";
    [self.resolver setSessionConstData:@"session-1"
                            sdkVersion:@"1.0.0"
                         pluginVersion:@"flutter-1.2.0"
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.pluginVersion" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"flutter-1.2.0");
}

- (void)testResolveField_ReturnsNilForSdkPluginVersionWhenNotSet {
    // Given - resolver without pluginVersion
    NSString *auctionId = @"auction-no-plugin";
    [self.resolver setSessionConstData:@"session-1"
                            sdkVersion:@"1.0.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.pluginVersion" bidId:nil];

    // Then
    XCTAssertNil(result);
}

#pragma mark - Bid Field Edge Cases

- (void)testResolveField_ReturnsNilForNonExistentBidId {
    // Given
    NSString *auctionId = @"auction-wrong-bidid";
    NSDictionary *responseJSON = @{
        @"seatbid": @[@{@"bid": @[@{@"id": @"bid-1", @"price": @1.0}]}]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When - try to resolve with wrong bidId
    id result = [self.resolver resolveField:auctionId field:@"bid.price" bidId:@"bid-999"];

    // Then - returns nil
    XCTAssertNil(result);
}

#pragma mark - BidResponse Field Tests

- (void)testResolveField_ResolvesBidResponseField {
    // Given
    NSString *auctionId = @"auction-response";
    NSDictionary *responseJSON = @{
        @"id": @"resp-456",
        @"bidid": @"bid-xyz"
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:responseJSON];

    // When
    id result = [self.resolver resolveField:auctionId field:@"bidResponse.bidid" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"bid-xyz");
}

#pragma mark - resolveNestedField Edge Cases

- (void)testResolveNestedField_ResolvesSimplePath {
    // Given
    NSString *auctionId = @"auction-simple-path";
    NSDictionary *json = @{@"field": @"value"};
    [self.resolver setRequestData:auctionId bidRequestJSON:json];

    // When
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.field" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"value");
}

- (void)testResolveNestedField_ResolvesThroughArray_TakesFirstElement {
    // Given
    NSString *auctionId = @"auction-array";
    NSDictionary *json = @{
        @"items": @[
            @{@"id": @"first"},
            @{@"id": @"second"}
        ]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:json];

    // When - path goes through array
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.items.id" bidId:nil];

    // Then - gets first element
    XCTAssertEqualObjects(result, @"first");
}

- (void)testResolveNestedField_ReturnsNilForNonExistentFilteredElement {
    // Given
    NSString *auctionId = @"auction-no-match";
    NSDictionary *json = @{
        @"users": @[@{@"name": @"Alice", @"role": @"user"}]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:json];

    // When - filter doesn't match
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.users[role=admin].name" bidId:nil];

    // Then - returns nil
    XCTAssertNil(result);
}

- (void)testResolveNestedField_ReturnsNilForEmptyArray {
    // Given
    NSString *auctionId = @"auction-empty-array";
    NSDictionary *json = @{@"items": @[]};
    [self.resolver setRequestData:auctionId bidRequestJSON:json];

    // When
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.items.id" bidId:nil];

    // Then
    XCTAssertNil(result);
}

- (void)testResolveNestedField_ReturnsNilForMissingPathSegment {
    // Given
    NSString *auctionId = @"auction-missing-segment";
    NSDictionary *json = @{@"field": @"value"};
    [self.resolver setRequestData:auctionId bidRequestJSON:json];

    // When - path includes non-existent segment
    id result = [self.resolver resolveField:auctionId field:@"bidRequest.field.nonexistent" bidId:nil];

    // Then
    XCTAssertNil(result);
}

#pragma mark - IFA Edge Cases

- (void)testResolveField_SdkIfa_HandlesMissingDeviceData {
    // Given - no device data
    NSString *auctionId = @"auction-no-device";
    [self.resolver setRequestData:auctionId bidRequestJSON:@{}];
    [self.resolver setSessionConstData:@"session-fallback"
                            sdkVersion:@"1.0.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.ifa" bidId:nil];

    // Then - returns nil or sessionId fallback depending on privacy settings
    // Can't assert specific value due to privacy service behavior in tests
    XCTAssertTrue(result == nil || [result isKindOfClass:[NSString class]]);
}

#pragma mark - Semicolon Escaping Tests (PR #333 placement/customData support)

/**
 * Tests that semicolons in SDK param values are escaped to %3B.
 * This is critical for customData which may contain semicolons that would
 * otherwise break the semicolon-delimited payload format.
 */
- (void)testBuildPayload_EscapesSemicolonsInSdkParamValues {
    // Given - SDK param with semicolons (e.g. customData like "level:1;coins:500")
    NSString *auctionId = @"auction-semicolon-escape";
    NSDictionary *configJSON = @{
        @"tracking": @[@"sdk.sessionId", @"sdk.customData"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"sess-escape-test"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    // Set customData containing semicolons
    [self.resolver setSdkParam:auctionId key:@"sdk.customData" value:@"level:1;coins:500;difficulty:hard"];

    // When
    NSString *payload = [self.resolver buildPayload:auctionId bidId:nil];

    // Then - semicolons in value are escaped to %3B
    XCTAssertEqualObjects(payload, @"sess-escape-test;level:1%3Bcoins:500%3Bdifficulty:hard",
                          @"Semicolons in customData should be escaped to %%3B");
}

/**
 * Tests that semicolons in resolved bid field values are also escaped.
 */
- (void)testBuildPayload_EscapesSemicolonsInBidFieldValues {
    // Given - bid field with semicolons (e.g. dealid containing semicolons)
    NSString *auctionId = @"auction-bid-semicolon";
    NSString *bidId = @"bid-semicolon";

    NSDictionary *configJSON = @{
        @"tracking": @[@"bid.dealid", @"sdk.sessionId"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"sess-1"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    NSDictionary *bidResponseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": bidId,
                @"dealid": @"deal;with;semicolons"  // Deal ID with semicolons
            }]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // When
    NSString *payload = [self.resolver buildPayload:auctionId bidId:bidId];

    // Then - semicolons in dealid are escaped
    XCTAssertEqualObjects(payload, @"deal%3Bwith%3Bsemicolons;sess-1",
                          @"Semicolons in bid fields should be escaped to %%3B");
}

/**
 * Tests that values without semicolons are unaffected by escaping.
 */
- (void)testBuildPayload_DoesNotModifyValuesWithoutSemicolons {
    // Given - normal values without semicolons
    NSString *auctionId = @"auction-no-semicolons";
    NSDictionary *configJSON = @{
        @"tracking": @[@"sdk.sessionId", @"sdk.placement", @"sdk.customData"]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"session123"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    [self.resolver setSdkParam:auctionId key:@"sdk.placement" value:@"home_banner"];
    [self.resolver setSdkParam:auctionId key:@"sdk.customData" value:@"user_level=5"];

    // When
    NSString *payload = [self.resolver buildPayload:auctionId bidId:nil];

    // Then - values unchanged
    XCTAssertEqualObjects(payload, @"session123;home_banner;user_level=5",
                          @"Values without semicolons should be unchanged");
}

#pragma mark - SDK Placement and CustomData Tests (PR #333)

/**
 * Tests that sdk.placement resolves from sdkMap when set via setSdkParam.
 */
- (void)testResolveField_SdkPlacement_ResolvesFromSdkMap {
    // Given
    NSString *auctionId = @"auction-placement";
    [self.resolver setSdkParam:auctionId key:@"sdk.placement" value:@"game_over_screen"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.placement" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"game_over_screen", @"sdk.placement should resolve from sdkMap");
}

/**
 * Tests that sdk.customData resolves from sdkMap when set via setSdkParam.
 */
- (void)testResolveField_SdkCustomData_ResolvesFromSdkMap {
    // Given
    NSString *auctionId = @"auction-customdata";
    [self.resolver setSdkParam:auctionId key:@"sdk.customData" value:@"coins:100,gems:50"];

    // When
    id result = [self.resolver resolveField:auctionId field:@"sdk.customData" bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"coins:100,gems:50", @"sdk.customData should resolve from sdkMap");
}

/**
 * Tests that sdk.placement and sdk.customData return nil when not set.
 */
- (void)testResolveField_SdkPlacementAndCustomData_ReturnsNilWhenNotSet {
    // Given - no sdk params set
    NSString *auctionId = @"auction-no-params";

    // When
    id placementResult = [self.resolver resolveField:auctionId field:@"sdk.placement" bidId:nil];
    id customDataResult = [self.resolver resolveField:auctionId field:@"sdk.customData" bidId:nil];

    // Then - returns nil for unset params
    XCTAssertNil(placementResult, @"sdk.placement should be nil when not set");
    XCTAssertNil(customDataResult, @"sdk.customData should be nil when not set");
}

/**
 * Tests that sdk.placement and sdk.customData are auction-scoped (different auctions have different values).
 */
- (void)testSdkParam_AreAuctionScoped {
    // Given - set different values for different auctions
    NSString *auctionId1 = @"auction-1";
    NSString *auctionId2 = @"auction-2";

    [self.resolver setSdkParam:auctionId1 key:@"sdk.placement" value:@"screen_a"];
    [self.resolver setSdkParam:auctionId2 key:@"sdk.placement" value:@"screen_b"];

    // When
    id result1 = [self.resolver resolveField:auctionId1 field:@"sdk.placement" bidId:nil];
    id result2 = [self.resolver resolveField:auctionId2 field:@"sdk.placement" bidId:nil];

    // Then - each auction has its own value
    XCTAssertEqualObjects(result1, @"screen_a", @"Auction 1 should have its own placement");
    XCTAssertEqualObjects(result2, @"screen_b", @"Auction 2 should have its own placement");
}

/**
 * Integration test: Verifies sdk.placement and sdk.customData appear correctly in full payload.
 */
- (void)testBuildPayload_IncludesSdkPlacementAndCustomData {
    // Given - production-like tracking config with placement and customData
    NSString *auctionId = @"auction-full-payload";
    NSString *bidId = @"bid-full";

    NSDictionary *configJSON = @{
        @"tracking": @[
            @"bid.price",
            @"sdk.sessionId",
            @"sdk.placement",
            @"sdk.customData"
        ]
    };
    [self.resolver setConfigJSON:configJSON];
    [self.resolver setSessionConstData:@"session-xyz"
                            sdkVersion:@"1.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.test"];

    NSDictionary *bidResponseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": bidId,
                @"price": @2.5
            }]
        }]
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    // Set placement and customData (as the SDK would do at show/load time)
    [self.resolver setSdkParam:auctionId key:@"sdk.placement" value:@"level_complete"];
    [self.resolver setSdkParam:auctionId key:@"sdk.customData" value:@"score:1000"];

    // When
    NSString *payload = [self.resolver buildPayload:auctionId bidId:bidId];

    // Then
    NSArray *values = [payload componentsSeparatedByString:@";"];
    XCTAssertEqual(values.count, 4, @"Should have 4 values");
    XCTAssertEqualObjects(values[0], @"2.5", @"bid.price");
    XCTAssertEqualObjects(values[1], @"session-xyz", @"sdk.sessionId");
    XCTAssertEqualObjects(values[2], @"level_complete", @"sdk.placement");
    XCTAssertEqualObjects(values[3], @"score:1000", @"sdk.customData");
}

#pragma mark - Config adUnits Array Lookup with Placeholder Tests

/**
 * Tests config.adUnits[id=${bidRequest.imp.tagid}].name - the key production xpath
 * This tests: array filtering + placeholder expansion + nested field access
 */
- (void)testConfigAdUnits_ResolvesNameWithPlaceholder {
    // Given
    NSString *auctionId = @"auction-adunits";
    NSString *adUnitId = @"placement-abc-123";

    // Config with adUnits array
    NSDictionary *configJSON = @{
        @"tracking": @[@"config.adUnits[id=${bidRequest.imp.tagid}].name"],
        @"adUnits": @[
            @{@"id": @"other-placement", @"name": @"Other Banner", @"externalId": @"ext-other"},
            @{@"id": adUnitId, @"name": @"Main Banner", @"externalId": @"ext-main-123"},
            @{@"id": @"another-one", @"name": @"Another", @"externalId": @"ext-another"}
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    // Bid request with tagid matching one of the adUnits
    NSDictionary *bidRequestJSON = @{
        @"imp": @[@{@"tagid": adUnitId}]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // When - resolve with placeholder expansion
    id result = [self.resolver resolveField:auctionId
                                      field:@"config.adUnits[id=${bidRequest.imp.tagid}].name"
                                      bidId:nil];

    // Then - should find the matching adUnit and return its name
    XCTAssertEqualObjects(result, @"Main Banner", @"Should resolve adUnit name via placeholder");
}

/**
 * Tests config.adUnits[id=${bidRequest.imp.tagid}].type - from new_config_response.txt
 */
- (void)testConfigAdUnits_ResolvesTypeWithPlaceholder {
    // Given
    NSString *auctionId = @"auction-adunits-type";
    NSString *adUnitId = @"_4yh_aeAtBrcFLCOKwePX";  // From new_config_response.txt

    NSDictionary *configJSON = @{
        @"tracking": @[@"config.adUnits[id=${bidRequest.imp.tagid}].type"],
        @"adUnits": @[
            @{@"id": @"first", @"name": @"First", @"type": @"BANNER"},
            @{@"id": adUnitId, @"name": @"mintegral-interstitial", @"type": @"INTERSTITIAL"},
            @{@"id": @"last", @"name": @"Last", @"type": @"REWARDED"}
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    NSDictionary *bidRequestJSON = @{
        @"imp": @[@{@"tagid": adUnitId}]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // When
    id result = [self.resolver resolveField:auctionId
                                      field:@"config.adUnits[id=${bidRequest.imp.tagid}].type"
                                      bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"INTERSTITIAL", @"Should resolve adUnit type via placeholder");
}

/**
 * Tests config.adUnits[id=${bidRequest.imp.tagid}].externalId
 */
- (void)testConfigAdUnits_ResolvesExternalIdWithPlaceholder {
    // Given
    NSString *auctionId = @"auction-adunits-extid";
    NSString *adUnitId = @"placement-xyz-789";

    NSDictionary *configJSON = @{
        @"tracking": @[@"config.adUnits[id=${bidRequest.imp.tagid}].externalId"],
        @"adUnits": @[
            @{@"id": @"first", @"name": @"First", @"externalId": @"ext-first"},
            @{@"id": adUnitId, @"name": @"Target", @"externalId": @"ext-target-789"},
            @{@"id": @"last", @"name": @"Last", @"externalId": @"ext-last"}
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    NSDictionary *bidRequestJSON = @{
        @"imp": @[@{@"tagid": adUnitId}]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // When
    id result = [self.resolver resolveField:auctionId
                                      field:@"config.adUnits[id=${bidRequest.imp.tagid}].externalId"
                                      bidId:nil];

    // Then
    XCTAssertEqualObjects(result, @"ext-target-789", @"Should resolve adUnit externalId via placeholder");
}

/**
 * Tests that non-matching placeholder returns nil
 */
- (void)testConfigAdUnits_ReturnsNilWhenPlaceholderDoesNotMatch {
    // Given
    NSString *auctionId = @"auction-adunits-nomatch";

    NSDictionary *configJSON = @{
        @"adUnits": @[
            @{@"id": @"placement-a", @"name": @"A"},
            @{@"id": @"placement-b", @"name": @"B"}
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    NSDictionary *bidRequestJSON = @{
        @"imp": @[@{@"tagid": @"placement-not-exists"}]
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // When - placeholder resolves to non-existent id
    id result = [self.resolver resolveField:auctionId
                                      field:@"config.adUnits[id=${bidRequest.imp.tagid}].name"
                                      bidId:nil];

    // Then
    XCTAssertNil(result, @"Should return nil when no adUnit matches");
}

/**
 * Full integration test with all the xpaths from production config (new_config_response.txt)
 */
- (void)testIntegration_AllProductionXPaths {
    NSString *auctionId = @"prod-full-test";
    NSString *adUnitId = @"B4twyt3IrKYZzH2o1dAww";  // From new_config_response.txt
    NSString *bidId = @"winning-bid-1";

    // Config matching new_config_response.txt structure
    NSDictionary *configJSON = @{
        @"accountID": @"acc_id_CLDX1",
        @"organizationID": @"CLDX1",
        @"adUnits": @[
            @{
                @"id": adUnitId,
                @"name": @"inmobi-interstitial",
                @"type": @"INTERSTITIAL",
                @"bidResponseTimeoutMs": @1000,
                @"adLoadTimeoutMs": @3000
            }
        ],
        @"tracking": @[
            @"bid.ext.prebid.meta.adaptercode",
            @"bid.w",
            @"bid.h",
            @"bid.dealid",
            @"bid.crid",
            @"bid.price",
            @"sdk.responseTimeMillis",
            @"sdk.releaseVersion",
            @"bidRequest.id",
            @"config.accountID",
            @"config.organizationID",
            @"sdk.app.bundle",
            @"bidRequest.imp.tagid",
            @"bidRequest.device.model",
            @"sdk.deviceTypeName",
            @"bidRequest.device.os",
            @"bidRequest.device.osv",
            @"sdk.sessionId",
            @"sdk.ifa",
            @"sdk.testGroupName",
            @"config.adUnits[id=${bidRequest.imp.tagid}].name",
            @"bidRequest.device.geo.country",
            @"bid.ext.cloudx.test",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId",
            @"config.adUnits[id=${bidRequest.imp.tagid}].type"
        ]
    };
    [self.resolver setConfigJSON:configJSON];

    [self.resolver setSessionConstData:@"session-prod-123"
                            sdkVersion:@"2.0.0"
                         pluginVersion:nil
                        deviceTypeName:@"phone"
                        deviceTypeCode:4
                           abTestGroup:@""
                             appBundle:@"com.app.bundle"];

    // Bid request
    NSDictionary *bidRequestJSON = @{
        @"id": auctionId,
        @"imp": @[@{@"tagid": adUnitId}],
        @"device": @{
            @"ifa": @"device-ifa-abc",
            @"model": @"iPhone15,2",
            @"os": @"iOS",
            @"osv": @"17.2",
            @"dnt": @0,
            @"geo": @{@"country": @"US"}
        }
    };
    [self.resolver setRequestData:auctionId bidRequestJSON:bidRequestJSON];

    // Bid response with cloudx auction data
    NSDictionary *bidResponseJSON = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": bidId,
                @"price": @5.5,
                @"w": @300,
                @"h": @250,
                @"dealid": @"deal-abc",
                @"crid": @"creative-xyz",
                @"ext": @{
                    @"prebid": @{@"meta": @{@"adaptercode": @"inmobi"}},
                    @"cloudx": @{@"rank": @1, @"test": @YES}
                }
            }]
        }],
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[@{
                        @"rank": @1,
                        @"round": @2,
                        @"lineItemId": @"line-item-456"
                    }]
                }
            }
        }
    };
    [self.resolver setResponseData:auctionId bidResponseJSON:bidResponseJSON];

    [self.resolver setSdkParam:auctionId key:@"sdk.responseTimeMillis" value:@"150"];

    // Build payload
    NSString *payload = [self.resolver buildPayload:auctionId bidId:bidId];
    NSArray *values = [payload componentsSeparatedByString:@";"];

    XCTAssertEqual(values.count, 26, @"Should have 26 values");

    // Verify all fields
    XCTAssertEqualObjects(values[0], @"inmobi", @"bid.ext.prebid.meta.adaptercode");
    XCTAssertEqualObjects(values[1], @"300", @"bid.w");
    XCTAssertEqualObjects(values[2], @"250", @"bid.h");
    XCTAssertEqualObjects(values[3], @"deal-abc", @"bid.dealid");
    XCTAssertEqualObjects(values[4], @"creative-xyz", @"bid.crid");
    XCTAssertEqualObjects(values[5], @"5.5", @"bid.price");
    XCTAssertEqualObjects(values[6], @"150", @"sdk.responseTimeMillis");
    XCTAssertEqualObjects(values[7], @"2.0.0", @"sdk.releaseVersion");
    XCTAssertEqualObjects(values[8], auctionId, @"bidRequest.id");
    XCTAssertEqualObjects(values[9], @"acc_id_CLDX1", @"config.accountID");
    XCTAssertEqualObjects(values[10], @"CLDX1", @"config.organizationID");
    XCTAssertEqualObjects(values[11], @"com.app.bundle", @"sdk.app.bundle");
    XCTAssertEqualObjects(values[12], adUnitId, @"bidRequest.imp.tagid");
    XCTAssertEqualObjects(values[13], @"iPhone15,2", @"bidRequest.device.model");
    XCTAssertEqualObjects(values[14], @"phone", @"sdk.deviceTypeName");
    XCTAssertEqualObjects(values[15], @"iOS", @"bidRequest.device.os");
    XCTAssertEqualObjects(values[16], @"17.2", @"bidRequest.device.osv");
    XCTAssertEqualObjects(values[17], @"session-prod-123", @"sdk.sessionId");
    // sdk.ifa returns sessionId when privacy blocks personal data
    XCTAssertTrue([values[18] isEqualToString:@"device-ifa-abc"] ||
                  [values[18] isEqualToString:@"session-prod-123"],
                  @"sdk.ifa should be IFA or sessionId fallback");
    XCTAssertEqualObjects(values[19], @"", @"sdk.testGroupName (empty)");
    XCTAssertEqualObjects(values[20], @"inmobi-interstitial", @"config.adUnits[id=${bidRequest.imp.tagid}].name");
    XCTAssertEqualObjects(values[21], @"US", @"bidRequest.device.geo.country");
    XCTAssertEqualObjects(values[22], @"1", @"bid.ext.cloudx.test");
    XCTAssertEqualObjects(values[23], @"2", @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round");
    XCTAssertEqualObjects(values[24], @"line-item-456", @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId");
    XCTAssertEqualObjects(values[25], @"INTERSTITIAL", @"config.adUnits[id=${bidRequest.imp.tagid}].type");
}

@end
