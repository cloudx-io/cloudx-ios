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

#pragma mark - CLXAdRevenueDelegate Protocol Tests

// Test that CLXAdRevenueDelegate protocol exists and has required method
- (void)testRevenueDelegateProtocolExists {
    Protocol *revenueDelegate = @protocol(CLXAdRevenueDelegate);
    XCTAssertNotNil(revenueDelegate, @"CLXAdRevenueDelegate protocol should exist");
}

// Test that ad view classes have revenueDelegate property
- (void)testAdViewClassesHaveRevenueDelegate {
    XCTAssertTrue([CLXBannerAdView instancesRespondToSelector:@selector(revenueDelegate)],
                  @"CLXBannerAdView should have revenueDelegate property");
    XCTAssertTrue([CLXBannerAdView instancesRespondToSelector:@selector(setRevenueDelegate:)],
                  @"CLXBannerAdView should have setRevenueDelegate: method");

    XCTAssertTrue([CLXNativeAdView instancesRespondToSelector:@selector(revenueDelegate)],
                  @"CLXNativeAdView should have revenueDelegate property");
    XCTAssertTrue([CLXNativeAdView instancesRespondToSelector:@selector(setRevenueDelegate:)],
                  @"CLXNativeAdView should have setRevenueDelegate: method");
}

// Test that fullscreen ad classes have revenueDelegate property
- (void)testFullscreenAdClassesHaveRevenueDelegate {
    XCTAssertTrue([CLXInterstitial instancesRespondToSelector:@selector(revenueDelegate)],
                  @"CLXInterstitial should have revenueDelegate property");
    XCTAssertTrue([CLXInterstitial instancesRespondToSelector:@selector(setRevenueDelegate:)],
                  @"CLXInterstitial should have setRevenueDelegate: method");

    XCTAssertTrue([CLXRewarded instancesRespondToSelector:@selector(revenueDelegate)],
                  @"CLXRewarded should have revenueDelegate property");
    XCTAssertTrue([CLXRewarded instancesRespondToSelector:@selector(setRevenueDelegate:)],
                  @"CLXRewarded should have setRevenueDelegate: method");
}

#pragma mark - Native Ad View Bridge Tests

// Tests for didPayRevenueForAd: bridge method have been removed.
// The bridge method is now internal - revenue callbacks are relayed via revenueDelegate.
// See testAdViewClassesHaveRevenueDelegate above for verification of the new pattern.

@end
