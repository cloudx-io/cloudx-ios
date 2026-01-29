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
    malformedBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    malformedBid.ext.cloudx.revenue = 1.50;

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
    emptyBidderBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    emptyBidderBid.ext.cloudx.revenue = 1.50;

    CLXAd *ad = [CLXAd adFromBid:emptyBidderBid placementId:@"empty-bidder-test"];

    XCTAssertNil(ad, @"CLXAd should be nil when bidder is empty string");
}

// Test CLXAd creation with zero revenue (should still work)
- (void)testCLXAdCreationWithZeroRevenue {
    // Create bid with zero revenue
    CLXBidResponseBid *zeroRevenueBid = [[CLXBidResponseBid alloc] init];
    zeroRevenueBid.ext = [[CLXBidResponseExt alloc] init];
    zeroRevenueBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    zeroRevenueBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    zeroRevenueBid.ext.prebid.meta.adaptercode = @"zero-revenue-bidder";
    zeroRevenueBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    zeroRevenueBid.ext.cloudx.revenue = 0.0;

    CLXAd *ad = [CLXAd adFromBid:zeroRevenueBid placementId:@"zero-revenue-test"];

    XCTAssertNotNil(ad, @"CLXAd should be created even with zero revenue");
    XCTAssertEqual([ad.revenue doubleValue], 0.0, @"Revenue should be zero");
    XCTAssertEqualObjects(ad.networkName, @"zero-revenue-bidder", @"Network name should still be extracted");
}

// Test CLXAd creation with nil placement ID (should still work)
- (void)testCLXAdCreationWithNilPlacementId {
    // Create valid bid
    CLXBidResponseBid *validBid = [[CLXBidResponseBid alloc] init];
    validBid.ext = [[CLXBidResponseExt alloc] init];
    validBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    validBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    validBid.ext.prebid.meta.adaptercode = @"test-bidder";
    validBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    validBid.ext.cloudx.revenue = 1.50;

    CLXAd *ad = [CLXAd adFromBid:validBid placementId:nil];

    XCTAssertNotNil(ad, @"CLXAd should be created even with nil ad unit ID");
    XCTAssertNil(ad.adUnitId, @"Ad unit ID should be nil");
    XCTAssertEqualObjects(ad.networkName, @"test-bidder", @"Network name should still be extracted");
}

@end
