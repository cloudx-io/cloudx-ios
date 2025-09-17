//
//  CLXTrackingFieldResolverBidDimensionTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-17.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Private interface to access internal methods for testing
@interface CLXTrackingFieldResolver (BidDimensionTesting)
- (nullable id)resolveBidDimensionField:(NSString *)auctionId field:(NSString *)field impid:(NSString *)impid;
- (nullable id)resolveBidField:(NSString *)auctionId field:(NSString *)field;
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

#pragma mark - Bid Dimension Resolution Tests

/**
 * Test bid.w field resolution from bid request dimensions
 * Validates our fix for Meta's -1 width issue
 */
- (void)testBidWidth_ShouldResolveFromBidRequestFormat {
    // Given: Bid request with banner format dimensions
    NSDictionary *bidRequest = @{
        @"imp": @[@{
            @"id": self.testImpId,
            @"banner": @{
                @"format": @[@{
                    @"w": @320,
                    @"h": @50
                }]
            }
        }]
    };
    
    // And: Bid response with winning bid (no w/h fields)
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
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
    // When: Resolve bid.w field
    id width = [self.resolver resolveBidField:self.testAuctionId field:@"bid.w"];
    
    // Then: Should return width from bid request format
    XCTAssertNotNil(width, @"Width should be resolved");
    XCTAssertEqualObjects(width, @320, @"Should return 320 from bid request format");
}

/**
 * Test bid.h field resolution from bid request dimensions
 */
- (void)testBidHeight_ShouldResolveFromBidRequestFormat {
    // Given: Bid request with banner format dimensions
    NSDictionary *bidRequest = @{
        @"imp": @[@{
            @"id": self.testImpId,
            @"banner": @{
                @"format": @[@{
                    @"w": @320,
                    @"h": @50
                }]
            }
        }]
    };
    
    // And: Bid response with winning bid
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
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
    // When: Resolve bid.h field
    id height = [self.resolver resolveBidField:self.testAuctionId field:@"bid.h"];
    
    // Then: Should return height from bid request format
    XCTAssertNotNil(height, @"Height should be resolved");
    XCTAssertEqualObjects(height, @50, @"Should return 50 from bid request format");
}

#pragma mark - OpenRTB Field Mapping Tests

/**
 * Test bid.creativeId maps to crid field
 * Validates our OpenRTB field mapping fix
 */
- (void)testBidCreativeId_ShouldMapToCridField {
    // Given: Bid response with crid field (OpenRTB standard)
    NSDictionary *bidResponse = @{
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": self.testBidId,
                @"impid": self.testImpId,
                @"crid": @"creative-123",
                @"price": @99.99
            }]
        }]
    };
    
    [self.resolver setResponseData:self.testAuctionId bidResponseJSON:bidResponse];
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
    // When: Resolve bid.creativeId field
    id creativeId = [self.resolver resolveBidField:self.testAuctionId field:@"bid.creativeId"];
    
    // Then: Should return value from crid field
    XCTAssertNotNil(creativeId, @"Creative ID should be resolved");
    XCTAssertEqualObjects(creativeId, @"creative-123", @"Should map bid.creativeId to crid field");
}

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
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
    // When: Resolve bid.dealid field
    id dealId = [self.resolver resolveBidField:self.testAuctionId field:@"bid.dealid"];
    
    // Then: Should return nil gracefully
    XCTAssertNil(dealId, @"Deal ID should be nil when field doesn't exist");
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
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
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
    [self.resolver saveLoadedBid:self.testAuctionId bidId:self.testBidId];
    
    // When: Try to resolve dimensions
    id width = [self.resolver resolveBidField:self.testAuctionId field:@"bid.w"];
    
    // Then: Should handle gracefully
    XCTAssertNil(width, @"Width should be nil with empty format array");
}

@end
