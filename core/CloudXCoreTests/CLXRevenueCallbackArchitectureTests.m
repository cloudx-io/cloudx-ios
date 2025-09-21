//
//  CLXRevenueCallbackArchitectureTests.m
//  CloudXCoreTests
//
//  Focused tests for the new revenue callback architecture
//  Tests only the specific changes we made without complex initialization
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>

@interface CLXRevenueCallbackArchitectureTests : XCTestCase
@end

@implementation CLXRevenueCallbackArchitectureTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - CLXAd Factory Method Tests

// Test CLXAd factory method exists and works with valid data
- (void)testCLXAdFactoryMethodWithValidData {
    // Test that the CLXAd factory method exists
    XCTAssertTrue([CLXAd respondsToSelector:@selector(adFromBid:placementId:)], 
                  @"CLXAd should have adFromBid:placementId: factory method");
    
    // Create a mock bid with valid prebid bidder information
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init];
    mockBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    mockBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    mockBid.ext.prebid.meta.adaptercode = @"google";
    mockBid.price = 2.50;
    
    CLXAd *ad = [CLXAd adFromBid:mockBid placementId:@"test-placement"];
    
    XCTAssertNotNil(ad, @"CLXAd should be created with valid prebid bidder");
    XCTAssertEqualObjects(ad.bidder, @"google", @"Bidder should be extracted from prebid.meta.adaptercode");
    XCTAssertEqualObjects(ad.placementId, @"test-placement", @"Placement ID should be set correctly");
    XCTAssertEqual([ad.revenue doubleValue], 2.50, @"Revenue should match bid price");
}

// Test CLXAd factory method with CloudX fallback bidder
- (void)testCLXAdFactoryMethodWithCloudXFallback {
    // Create a mock bid with CloudX bidder information (fallback)
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init];
    mockBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    mockBid.ext.cloudx.adapterExtras = @{@"bidder": @"meta"};
    mockBid.price = 1.75;
    
    CLXAd *ad = [CLXAd adFromBid:mockBid placementId:@"fallback-placement"];
    
    XCTAssertNotNil(ad, @"CLXAd should be created with CloudX fallback bidder");
    XCTAssertEqualObjects(ad.bidder, @"meta", @"Bidder should be extracted from cloudx.adapterExtras");
    XCTAssertEqual([ad.revenue doubleValue], 1.75, @"Revenue should match bid price");
}

// Test CLXAd factory method prioritizes prebid over CloudX
- (void)testCLXAdFactoryMethodPrioritizesPrebid {
    // Create a mock bid with both prebid and CloudX bidder information
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init];
    
    // Set prebid bidder (should be prioritized)
    mockBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    mockBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    mockBid.ext.prebid.meta.adaptercode = @"prebid-bidder";
    
    // Set CloudX bidder (should be ignored)
    mockBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    mockBid.ext.cloudx.adapterExtras = @{@"bidder": @"cloudx-bidder"};
    
    mockBid.price = 4.00;
    
    CLXAd *ad = [CLXAd adFromBid:mockBid placementId:@"priority-test"];
    
    XCTAssertNotNil(ad, @"CLXAd should be created");
    XCTAssertEqualObjects(ad.bidder, @"prebid-bidder", @"Should prioritize prebid bidder over CloudX bidder");
}

// Test CLXAd factory method fails with nil bid
- (void)testCLXAdFactoryMethodWithNilBid {
    CLXAd *ad = [CLXAd adFromBid:nil placementId:@"test-placement"];
    XCTAssertNil(ad, @"CLXAd should be nil when bid is nil");
}

// Test CLXAd factory method fails with no bidder information
- (void)testCLXAdFactoryMethodWithNoBidderInfo {
    // Create a mock bid with no bidder information
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init]; // No prebid or cloudx info
    mockBid.price = 1.50;
    
    CLXAd *ad = [CLXAd adFromBid:mockBid placementId:@"no-bidder-test"];
    
    XCTAssertNil(ad, @"CLXAd should be nil when no bidder information is available");
}

#pragma mark - CLXAdEventReporting Protocol Tests

// Test removed - old protocol method no longer exists
// Win/loss tracking now uses CLXWinLossTracker for server-side tracking

#pragma mark - Native Ad View Bridge Tests

// Test that CLXNativeAdView has revenuePaid bridge method
- (void)testNativeAdViewHasRevenuePaidBridge {
    XCTAssertTrue([CLXNativeAdView instancesRespondToSelector:@selector(revenuePaid:)], 
                  @"CLXNativeAdView should have revenuePaid: bridge method");
}

// Test CLXNativeAdView revenuePaid bridge functionality
- (void)testNativeAdViewRevenuePaidBridge {
    // Create a simple test to verify the bridge method exists and can be called
    CLXNativeAdView *nativeAdView = [[CLXNativeAdView alloc] init];
    
    // Create a test CLXAd object
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test"
                                             placementId:@"test-id"
                                                  bidder:@"test-bidder"
                                     externalPlacementId:@"ext-id"
                                                 revenue:@1.50];
    
    // This should not crash - the bridge method should handle nil delegate gracefully
    XCTAssertNoThrow([nativeAdView revenuePaid:testAd], @"CLXNativeAdView revenuePaid should not crash with nil delegate");
}

@end
