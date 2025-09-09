//
//  CLXRevenueCallbackEdgeCaseTests.m
//  CloudXCoreTests
//
//  Simple edge case tests for CLXAd creation with invalid data
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXRevenueCallbackEdgeCaseTests : XCTestCase
@end

@implementation CLXRevenueCallbackEdgeCaseTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - CLXAd Creation Edge Cases

// Test CLXAd creation with malformed bid structure
- (void)testCLXAdCreationWithMalformedBidStructure {
    // Create bid with malformed structure (nil meta)
    CLXBidResponseBid *malformedBid = [[CLXBidResponseBid alloc] init];
    malformedBid.ext = [[CLXBidResponseExt alloc] init];
    malformedBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    malformedBid.ext.prebid.meta = nil; // This should cause creation to fail
    malformedBid.price = 1.50;
    
    CLXAd *ad = [CLXAd adFromBid:malformedBid placementId:@"malformed-test"];
    
    XCTAssertNil(ad, @"CLXAd should be nil with malformed bid structure");
}

// Test CLXAd creation with empty bidder string
- (void)testCLXAdCreationWithEmptyBidder {
    // Create bid with empty bidder string
    CLXBidResponseBid *emptyBidderBid = [[CLXBidResponseBid alloc] init];
    emptyBidderBid.ext = [[CLXBidResponseExt alloc] init];
    emptyBidderBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    emptyBidderBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    emptyBidderBid.ext.prebid.meta.adaptercode = @""; // Empty string
    emptyBidderBid.price = 1.50;
    
    CLXAd *ad = [CLXAd adFromBid:emptyBidderBid placementId:@"empty-bidder-test"];
    
    XCTAssertNil(ad, @"CLXAd should be nil when bidder is empty string");
}

// Test CLXAd creation with zero price (should still work)
- (void)testCLXAdCreationWithZeroPrice {
    // Create bid with zero price
    CLXBidResponseBid *zeroPriceBid = [[CLXBidResponseBid alloc] init];
    zeroPriceBid.ext = [[CLXBidResponseExt alloc] init];
    zeroPriceBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    zeroPriceBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    zeroPriceBid.ext.prebid.meta.adaptercode = @"zero-price-bidder";
    zeroPriceBid.price = 0.0;
    
    CLXAd *ad = [CLXAd adFromBid:zeroPriceBid placementId:@"zero-price-test"];
    
    XCTAssertNotNil(ad, @"CLXAd should be created even with zero price");
    XCTAssertEqual([ad.revenue doubleValue], 0.0, @"Revenue should be zero");
    XCTAssertEqualObjects(ad.bidder, @"zero-price-bidder", @"Bidder should still be extracted");
}

// Test CLXAd creation with nil placement ID (should still work)
- (void)testCLXAdCreationWithNilPlacementId {
    // Create valid bid
    CLXBidResponseBid *validBid = [[CLXBidResponseBid alloc] init];
    validBid.ext = [[CLXBidResponseExt alloc] init];
    validBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    validBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    validBid.ext.prebid.meta.adaptercode = @"test-bidder";
    validBid.price = 1.50;
    
    CLXAd *ad = [CLXAd adFromBid:validBid placementId:nil];
    
    XCTAssertNotNil(ad, @"CLXAd should be created even with nil placement ID");
    XCTAssertNil(ad.placementId, @"Placement ID should be nil");
    XCTAssertEqualObjects(ad.bidder, @"test-bidder", @"Bidder should still be extracted");
}

@end
