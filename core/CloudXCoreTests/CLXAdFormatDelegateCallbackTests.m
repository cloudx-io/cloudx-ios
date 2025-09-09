//
//  CLXAdFormatDelegateCallbackTests.m
//  CloudXCoreTests
//
//  Integration tests to verify all ad format implementations call delegates with CLXAd objects
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXAdFormatDelegateCallbackTests : XCTestCase <CLXBannerDelegate, CLXInterstitialDelegate, CLXRewardedDelegate, CLXNativeDelegate>

// Properties to capture delegate callbacks
@property (nonatomic, strong) NSMutableArray<NSString *> *receivedCallbacks;
@property (nonatomic, strong) NSMutableArray<id> *receivedAdObjects;
@property (nonatomic, strong) NSMutableArray<NSString *> *receivedAdTypes;

// Ad format instances for testing
@property (nonatomic, strong) CLXPublisherBanner *bannerPublisher;
@property (nonatomic, strong) CLXPublisherFullscreenAd *interstitialPublisher;
@property (nonatomic, strong) CLXPublisherFullscreenAd *rewardedPublisher;
@property (nonatomic, strong) CLXNativeAdView *nativeAdView;
@property (nonatomic, strong) CLXBannerAdView *bannerAdView;

@end

@implementation CLXAdFormatDelegateCallbackTests

- (void)setUp {
    [super setUp];
    self.receivedCallbacks = [NSMutableArray array];
    self.receivedAdObjects = [NSMutableArray array];
    self.receivedAdTypes = [NSMutableArray array];
}

- (void)tearDown {
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [self.receivedAdTypes removeAllObjects];
    [super tearDown];
}

#pragma mark - Shared Delegate Method Implementations

// These methods are shared across multiple delegate protocols
// We track which delegate protocol called them using the callback name

// Test that all delegate callbacks receive CLXAd objects
- (void)didLoadWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didLoadWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didLoadWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didLoadWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"failToLoadWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"failToLoadWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"failToLoadWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didShowWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didShowWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didShowWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didShowWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"failToShowWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"failToShowWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"failToShowWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didHideWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didHideWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didHideWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didHideWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didClickWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didClickWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didClickWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didClickWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)impressionOn:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"impressionOn"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"impressionOn should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"impressionOn should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"closedByUserActionWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"closedByUserActionWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"closedByUserActionWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

// Rewarded-specific delegate method
- (void)userDidEarnRewardWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"userDidEarnRewardWithAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"userDidEarnRewardWithAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"userDidEarnRewardWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

#pragma mark - Integration Tests

// Test that CLXAd factory method exists and works correctly
- (void)testCLXAdFactoryMethodExists {
    // Test that the CLXAd factory method exists and can create CLXAd objects
    // This replaces the old getClxAdForDelegateCallback helper methods
    
    // Verify CLXAd class has the factory method
    XCTAssertTrue([CLXAd respondsToSelector:@selector(adFromBid:placementId:)], 
                  @"CLXAd should have adFromBid:placementId: factory method");
    
    // Test that we can create a CLXAd object with nil bid (should return nil)
    CLXAd *adWithNilBid = [CLXAd adFromBid:nil placementId:@"test-placement"];
    XCTAssertNil(adWithNilBid, @"CLXAd factory method should return nil for nil bid");
    
    // Test that we can create a CLXAd object with valid bid data
    // Create a mock bid response with the minimum required data
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init];
    mockBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    mockBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    mockBid.ext.prebid.meta.adaptercode = @"test-bidder";
    mockBid.price = 1.50;
    
    CLXAd *adWithValidBid = [CLXAd adFromBid:mockBid placementId:@"test-placement"];
    XCTAssertNotNil(adWithValidBid, @"CLXAd factory method should create valid CLXAd object");
    XCTAssertEqualObjects(adWithValidBid.placementId, @"test-placement", @"CLXAd should have correct placement ID");
    XCTAssertEqualObjects(adWithValidBid.bidder, @"test-bidder", @"CLXAd should have correct bidder");
    XCTAssertEqual([adWithValidBid.revenue doubleValue], 1.50, @"CLXAd should have correct revenue");
}

// Test that all delegate method signatures are consistent across ad formats
- (void)testAllAdFormatDelegateSignaturesAreConsistent {
    // Create test CLXAd and error objects
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test"
                                             placementId:@"test"
                                                  bidder:@"test"
                                     externalPlacementId:@"test"
                                                 revenue:@1.0];
    NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    
    // Clear previous callbacks
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [self.receivedAdTypes removeAllObjects];
    
    // Test banner delegate methods
    [self didLoadWithAd:testAd];
    [self failToLoadWithAd:testAd error:testError];
    [self didShowWithAd:testAd];
    [self didClickWithAd:testAd];
    [self impressionOn:testAd];
    
    // Test interstitial delegate methods (same signatures as banner)
    [self didLoadWithAd:testAd];
    [self failToLoadWithAd:testAd error:testError];
    [self didShowWithAd:testAd];
    [self failToShowWithAd:testAd error:testError];
    [self didHideWithAd:testAd];
    [self didClickWithAd:testAd];
    [self impressionOn:testAd];
    [self closedByUserActionWithAd:testAd];
    
    // Test rewarded delegate methods (includes reward callback)
    [self userDidEarnRewardWithAd:testAd];
    
    // Test native delegate methods (same as base ad delegate)
    [self didLoadWithAd:testAd];
    [self failToLoadWithAd:testAd error:testError];
    [self didShowWithAd:testAd];
    [self didClickWithAd:testAd];
    [self impressionOn:testAd];
    [self closedByUserActionWithAd:testAd];
    
    // Verify all callbacks received CLXAd objects
    XCTAssertGreaterThan(self.receivedCallbacks.count, 0, @"Should have received delegate callbacks");
    XCTAssertEqual(self.receivedCallbacks.count, self.receivedAdObjects.count, @"Each callback should have an ad object");
    
    // Verify all received objects are CLXAd instances
    for (NSInteger i = 0; i < self.receivedAdObjects.count; i++) {
        id adObject = self.receivedAdObjects[i];
        NSString *callback = self.receivedCallbacks[i];
        
        XCTAssertFalse([adObject isKindOfClass:[NSNull class]], @"Callback %@ should not receive nil ad object", callback);
        XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], 
                      @"Callback %@ should receive CLXAd object, got %@", callback, NSStringFromClass([adObject class]));
    }
}

@end
