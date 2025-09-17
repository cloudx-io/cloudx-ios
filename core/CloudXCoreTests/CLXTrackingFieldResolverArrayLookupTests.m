//
//  CLXTrackingFieldResolverArrayLookupTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-17.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access internal methods for testing
@interface CLXTrackingFieldResolver (ArrayLookupTesting)
- (nullable id)resolveNestedField:(id)current path:(NSString *)path;
- (nullable id)resolveNestedField:(id)current path:(NSString *)path withFullResponseData:(nullable NSDictionary *)fullResponseData;
- (nullable id)resolveArrayLookup:(id)current segment:(NSString *)segment;
- (nullable id)resolveArrayLookup:(id)current segment:(NSString *)segment withFullResponseData:(nullable NSDictionary *)fullResponseData;
- (nullable id)resolveConditionValue:(NSString *)expression;
- (nullable id)resolveConditionValue:(NSString *)expression withBidResponseData:(nullable NSDictionary *)bidResponseData;
- (BOOL)valuesAreEqual:(id)value1 to:(id)value2;
- (nullable id)resolveBidResponseField:(NSString *)auctionId field:(NSString *)field;
@end

@interface CLXTrackingFieldResolverArrayLookupTests : XCTestCase
@property (nonatomic, strong) CLXTrackingFieldResolver *resolver;
@property (nonatomic, strong) NSString *testAuctionId;
@end

@implementation CLXTrackingFieldResolverArrayLookupTests

- (void)setUp {
    [super setUp];
    self.resolver = [[CLXTrackingFieldResolver alloc] init];
    self.testAuctionId = @"test-auction-123";
}

#pragma mark - Array Lookup Tests

/**
 * Test resolving dealid from complex array lookup path
 * Tests: bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId
 */
- (void)testDealidResolution_ShouldFindMatchingParticipant {
    // Given: Bid response with auction participants array
    NSDictionary *bidResponse = @{
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[
                        @{
                            @"bid": @"50.00",
                            @"bidFloor": @0,
                            @"bidder": @"testbidder",
                            @"lineItemId": @"test-line-item-1",
                            @"rank": @2,
                            @"responseTimeMillis": @100,
                            @"round": @1
                        },
                        @{
                            @"bid": @"99.99",
                            @"bidFloor": @0,
                            @"bidder": @"meta",
                            @"lineItemId": @"f62GLNAqzyGpaBShXqAL8",
                            @"rank": @1,
                            @"responseTimeMillis": @115,
                            @"round": @1
                        }
                    ]
                }
            }
        }
    };
    
    // Setup the resolver with test data
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolving the lineItemId field for the winning bid (rank=1)
    NSString *field = @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId";
    id result = [self.resolver resolveBidResponseField:self.testAuctionId field:field];
    
    // Then: Should find the Meta participant's lineItemId
    XCTAssertNotNil(result, @"Should resolve lineItemId from auction participants");
    XCTAssertEqualObjects(result, @"f62GLNAqzyGpaBShXqAL8", @"Should return the correct lineItemId for rank 1");
}

/**
 * Test resolving round from complex array lookup path
 */
- (void)testRoundResolution_ShouldFindMatchingParticipant {
    // Given: Bid response with auction participants array
    NSDictionary *bidResponse = @{
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[
                        @{
                            @"bid": @"99.99",
                            @"bidFloor": @0,
                            @"bidder": @"meta",
                            @"lineItemId": @"f62GLNAqzyGpaBShXqAL8",
                            @"rank": @1,
                            @"responseTimeMillis": @115,
                            @"round": @1
                        }
                    ]
                }
            }
        }
    };
    
    // Setup the resolver with test data
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolving the round field for the winning bid (rank=1)
    NSString *field = @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round";
    id result = [self.resolver resolveBidResponseField:self.testAuctionId field:field];
    
    // Then: Should find the Meta participant's round
    XCTAssertNotNil(result, @"Should resolve round from auction participants");
    XCTAssertEqualObjects(result, @1, @"Should return the correct round for rank 1");
}

/**
 * Test array lookup when no matching element is found
 */
- (void)testArrayLookup_NoMatchingElement_ShouldReturnNil {
    // Given: Bid response with auction participants but no rank=1
    NSDictionary *bidResponse = @{
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[
                        @{
                            @"bid": @"50.00",
                            @"bidder": @"testbidder",
                            @"rank": @2,
                            @"round": @1
                        }
                    ]
                }
            }
        }
    };
    
    // Setup the resolver with test data
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // When: Resolving field for rank=1 (which doesn't exist)
    NSString *field = @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round";
    id result = [self.resolver resolveBidResponseField:self.testAuctionId field:field];
    
    // Then: Should return nil
    XCTAssertNil(result, @"Should return nil when no matching element is found");
}

#pragma mark - Array Lookup Helper Method Tests

/**
 * Test the array lookup parsing logic directly
 */
- (void)testResolveArrayLookup_ShouldParseSegmentCorrectly {
    // Given: A dictionary with participants array
    NSDictionary *testData = @{
        @"participants": @[
            @{
                @"rank": @1,
                @"value": @"winner"
            },
            @{
                @"rank": @2,
                @"value": @"runner-up"
            }
        ]
    };
    
    // When: Resolving array lookup segment
    NSString *segment = @"participants[rank=${bid.ext.cloudx.rank}]";
    id result = [self.resolver resolveArrayLookup:testData segment:segment];
    
    // Then: Should find the rank=1 element
    XCTAssertNotNil(result, @"Should resolve array lookup");
    XCTAssertTrue([result isKindOfClass:[NSDictionary class]], @"Result should be a dictionary");
    NSDictionary *resultDict = (NSDictionary *)result;
    XCTAssertEqualObjects(resultDict[@"value"], @"winner", @"Should return the correct element");
}

/**
 * Test condition value resolution
 */
- (void)testResolveConditionValue_ShouldHandleExpressions {
    // When: Resolving different types of condition values
    id result1 = [self.resolver resolveConditionValue:@"${bid.ext.cloudx.rank}"];
    id result2 = [self.resolver resolveConditionValue:@"direct-value"];
    
    // Then: Should resolve expressions and direct values appropriately
    XCTAssertEqualObjects(result1, @1, @"Should resolve rank expression to 1");
    XCTAssertEqualObjects(result2, @"direct-value", @"Should return direct values as-is");
}

/**
 * Test value equality comparisons
 */
- (void)testValuesAreEqual_ShouldHandleDifferentTypes {
    // Test different type combinations
    XCTAssertTrue([self.resolver valuesAreEqual:@1 to:@1], @"Same numbers should be equal");
    XCTAssertTrue([self.resolver valuesAreEqual:@1 to:@"1"], @"Number and string representation should be equal");
    XCTAssertTrue([self.resolver valuesAreEqual:@"1" to:@1], @"String and number representation should be equal");
    XCTAssertTrue([self.resolver valuesAreEqual:@"test" to:@"test"], @"Same strings should be equal");
    XCTAssertFalse([self.resolver valuesAreEqual:@1 to:@2], @"Different numbers should not be equal");
    XCTAssertFalse([self.resolver valuesAreEqual:@"1" to:@"2"], @"Different strings should not be equal");
    XCTAssertTrue([self.resolver valuesAreEqual:nil to:nil], @"Both nil should be equal");
    XCTAssertFalse([self.resolver valuesAreEqual:@1 to:nil], @"Value and nil should not be equal");
}

#pragma mark - Integration Tests

/**
 * Test the complete field resolution flow for dealid-related fields
 */
- (void)testCompleteFieldResolution_DealidFields {
    // Given: Complete bid response structure similar to real data
    NSDictionary *bidResponse = @{
        @"id": @"A6E9EBA7-68F3-417B-9F48-5DB93134CB54",
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[
                        @{
                            @"bid": @"99.98999999999999",
                            @"bidFloor": @0,
                            @"bidder": @"meta",
                            @"lineItemId": @"f62GLNAqzyGpaBShXqAL8",
                            @"rank": @1,
                            @"responseTimeMillis": @115,
                            @"round": @1
                        }
                    ]
                }
            },
            @"lineItemId": @"f62GLNAqzyGpaBShXqAL8"
        }
    };
    
    // Setup the resolver with test data
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    
    // Test multiple fields that should all resolve correctly
    NSArray *testFields = @[
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId",
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round",
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].bidder",
        @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].bid"
    ];
    
    NSArray *expectedResults = @[
        @"f62GLNAqzyGpaBShXqAL8",
        @1,
        @"meta",
        @"99.98999999999999"
    ];
    
    for (NSInteger i = 0; i < testFields.count; i++) {
        NSString *field = testFields[i];
        id expectedResult = expectedResults[i];
        
        id result = [self.resolver resolveBidResponseField:self.testAuctionId field:field];
        XCTAssertNotNil(result, @"Field %@ should resolve", field);
        XCTAssertEqualObjects(result, expectedResult, @"Field %@ should return correct value", field);
    }
}

@end
