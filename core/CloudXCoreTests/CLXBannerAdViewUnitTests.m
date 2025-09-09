//
//  CLXBannerAdViewUnitTests.m
//  CloudXCoreTests
//
//  Unit tests for CLXBannerAdView focusing on MAX SDK parity features
//  including property population, delegation, and public API behavior
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>
#import "Mocks/CLXBannerMocks.h"

// Test category to expose private properties for testing
@interface CLXBannerAdView (Testing)
@property (nonatomic, copy, readwrite) NSString *adUnitIdentifier;
@property (nonatomic, assign, readwrite) CLXBannerType adFormat;
@end

// MARK: - Mock Objects (using shared CLXBannerMocks)

// MARK: - Test Class

@interface CLXBannerAdViewUnitTests : XCTestCase
@property (nonatomic, strong) CLXBannerAdView *bannerAdView;
@property (nonatomic, strong) MockPublisherBanner *mockBanner;
@property (nonatomic, strong) MockBannerDelegate *mockDelegate;
@end

@implementation CLXBannerAdViewUnitTests

- (void)setUp {
    [super setUp];
    self.mockBanner = [[MockPublisherBanner alloc] init];
    self.mockBanner.placementID = @"test-placement-123";
    self.mockDelegate = [[MockBannerDelegate alloc] init];
}

- (void)tearDown {
    self.bannerAdView = nil;
    self.mockBanner = nil;
    self.mockDelegate = nil;
    [super tearDown];
}

// MARK: - Property Population Tests

// Test adUnitIdentifier property is populated from underlying banner
- (void)testAdUnitIdentifierPropertyPopulation {
    // Given: A banner with a placement ID
    self.mockBanner.placementID = @"unit-test-placement-456";
    
    // When: Creating CLXBannerAdView
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // Then: adUnitIdentifier should be populated from banner's placementID
    XCTAssertEqualObjects(self.bannerAdView.adUnitIdentifier, @"unit-test-placement-456", 
                         @"adUnitIdentifier should be extracted from banner placementID");
}

// Test adFormat property is set correctly during initialization
- (void)testAdFormatPropertyPopulation {
    // Test W320H50 format
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    XCTAssertEqual(self.bannerAdView.adFormat, CLXBannerTypeW320H50, 
                  @"adFormat should match initialization parameter");
    
    // Test MREC format
    CLXBannerAdView *mrecBanner = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                                     type:CLXBannerTypeMREC 
                                                                 delegate:self.mockDelegate];
    XCTAssertEqual(mrecBanner.adFormat, CLXBannerTypeMREC, 
                  @"adFormat should match MREC initialization parameter");
}

// Test placement property getter and setter
- (void)testPlacementPropertyGetterSetter {
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // Initially should be nil
    XCTAssertNil(self.bannerAdView.placement, @"placement should initially be nil");
    
    // Test setter
    self.bannerAdView.placement = @"test-placement-value";
    XCTAssertEqualObjects(self.bannerAdView.placement, @"test-placement-value", 
                         @"placement setter should work correctly");
    
    // Test setting to nil
    self.bannerAdView.placement = nil;
    XCTAssertNil(self.bannerAdView.placement, @"placement should accept nil values");
}

// MARK: - Auto-Refresh Delegation Tests

// Test startAutoRefresh delegates to underlying banner
- (void)testStartAutoRefreshDelegation {
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // When: Calling startAutoRefresh
    [self.bannerAdView startAutoRefresh];
    
    // Then: Should delegate to underlying banner
    XCTAssertTrue(self.mockBanner.startAutoRefreshCalled, 
                 @"startAutoRefresh should delegate to underlying banner");
}

// Test stopAutoRefresh delegates to underlying banner
- (void)testStopAutoRefreshDelegation {
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // When: Calling stopAutoRefresh
    [self.bannerAdView stopAutoRefresh];
    
    // Then: Should delegate to underlying banner
    XCTAssertTrue(self.mockBanner.stopAutoRefreshCalled, 
                 @"stopAutoRefresh should delegate to underlying banner");
}

// MARK: - Delegate Forwarding Tests

// Test didExpandAd delegate forwarding
- (void)testDidExpandAdDelegateForwarding {
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // Given: A test ad object
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test" 
                                             placementId:@"test-id" 
                                                  bidder:@"test-bidder" 
                                     externalPlacementId:@"ext-id" 
                                                 revenue:@(1.50)];
    
    // When: CLXBannerAdView receives didExpandAd callback
    [self.bannerAdView didExpandAd:testAd];
    
    // Then: Should forward to external delegate
    XCTAssertTrue(self.mockDelegate.didExpandCalled, 
                 @"didExpandAd should be forwarded to external delegate");
    XCTAssertEqualObjects(self.mockDelegate.lastExpandedAd, testAd, 
                         @"Correct ad object should be forwarded");
}

// Test didCollapseAd delegate forwarding
- (void)testDidCollapseAdDelegateForwarding {
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // Given: A test ad object
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test" 
                                             placementId:@"test-id" 
                                                  bidder:@"test-bidder" 
                                     externalPlacementId:@"ext-id" 
                                                 revenue:@(2.25)];
    
    // When: CLXBannerAdView receives didCollapseAd callback
    [self.bannerAdView didCollapseAd:testAd];
    
    // Then: Should forward to external delegate
    XCTAssertTrue(self.mockDelegate.didCollapseCalled, 
                 @"didCollapseAd should be forwarded to external delegate");
    XCTAssertEqualObjects(self.mockDelegate.lastCollapsedAd, testAd, 
                         @"Correct ad object should be forwarded");
}

// MARK: - Edge Cases

// Test behavior when underlying banner doesn't support auto-refresh methods
- (void)testAutoRefreshWithNonSupportingBanner {
    // Given: A banner that doesn't respond to auto-refresh methods (but conforms to CLXBanner)
    MockPublisherBanner *nonSupportingBanner = [[MockPublisherBanner alloc] init];
    nonSupportingBanner.placementID = @"non-supporting-test";
    
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:(id<CLXBanner>)nonSupportingBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:self.mockDelegate];
    
    // When/Then: Should not crash when calling auto-refresh methods on non-CLXPublisherBanner
    XCTAssertNoThrow([self.bannerAdView startAutoRefresh], 
                    @"Should handle non-supporting banners gracefully");
    XCTAssertNoThrow([self.bannerAdView stopAutoRefresh], 
                    @"Should handle non-supporting banners gracefully");
}

// Test delegate forwarding when external delegate doesn't implement optional methods
- (void)testDelegateForwardingWithNonSupportingDelegate {
    // Given: A delegate that doesn't implement expand/collapse methods
    NSObject *nonSupportingDelegate = [[NSObject alloc] init];
    
    self.bannerAdView = [[CLXBannerAdView alloc] initWithBanner:self.mockBanner 
                                                           type:CLXBannerTypeW320H50 
                                                       delegate:nonSupportingDelegate];
    
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test" 
                                             placementId:@"test-id" 
                                                  bidder:@"test-bidder" 
                                     externalPlacementId:@"ext-id" 
                                                 revenue:@(1.00)];
    
    // When/Then: Should not crash when forwarding to non-supporting delegate
    XCTAssertNoThrow([self.bannerAdView didExpandAd:testAd], 
                    @"Should handle non-supporting delegates gracefully");
    XCTAssertNoThrow([self.bannerAdView didCollapseAd:testAd], 
                    @"Should handle non-supporting delegates gracefully");
}

@end
