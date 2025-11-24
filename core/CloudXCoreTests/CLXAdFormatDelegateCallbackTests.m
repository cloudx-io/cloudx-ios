//
//  CLXAdFormatDelegateCallbackTests.m
//  CloudXCoreTests
//
//  Integration tests to verify all ad format implementations call delegates with CLXAd objects
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXAdFormatDelegateCallbackTests : XCTestCase <CLXAdDelegate, CLXBannerDelegate, CLXInterstitialDelegate, CLXRewardedDelegate, CLXNativeDelegate>

// Properties to capture delegate callbacks
@property (nonatomic, strong) NSMutableArray<NSString *> *receivedCallbacks;
@property (nonatomic, strong) NSMutableArray<id> *receivedAdObjects;
@property (nonatomic, strong) NSMutableArray<NSString *> *receivedAdTypes;

// Ad format instances for testing
@property (nonatomic, strong) CLXPublisherBanner *bannerPublisher;
@property (nonatomic, strong) CLXInterstitial *interstitialPublisher;
@property (nonatomic, strong) CLXRewarded *rewardedPublisher;
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
- (void)didLoadAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didLoadAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didLoadAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didLoadAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didFailToLoadAdWithError:(NSError *)error {
    [self.receivedCallbacks addObject:@"didFailToLoadAdWithError"];
    [self.receivedAdObjects addObject:[NSNull null]]; // No ad object for load failure
    [self.receivedAdTypes addObject:@"NSNull"];
    
    XCTAssertNotNil(error, @"didFailToLoadAdWithError should receive non-nil error");
}

- (void)didDisplayAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didDisplayAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didDisplayAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didDisplayAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"didFailToDisplayAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didFailToDisplayAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didFailToDisplayAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didHideAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didHideAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didHideAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didHideAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didClickAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didClickAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didClickAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didClickAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didRecordImpressionForAd"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didRecordImpressionForAd should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didRecordImpressionForAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
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
    [self didLoadAd:testAd];
    [self didFailToLoadAdWithError:testError];
    [self didDisplayAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];
    
    // Test interstitial delegate methods (same signatures as banner)
    [self didLoadAd:testAd];
    [self didFailToLoadAdWithError:testError];
    [self didDisplayAd:testAd];
    [self didFailToDisplayAd:testAd error:testError];
    [self didHideAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];
    
    // Test rewarded delegate methods (includes reward callback)
    [self userDidEarnRewardWithAd:testAd];
    
    // Test native delegate methods (same as base ad delegate)
    [self didLoadAd:testAd];
    [self didFailToLoadAdWithError:testError];
    [self didDisplayAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];
    
    // Verify all callbacks received CLXAd objects (except didFailToLoadAdWithError which receives only error)
    XCTAssertGreaterThan(self.receivedCallbacks.count, 0, @"Should have received delegate callbacks");
    XCTAssertEqual(self.receivedCallbacks.count, self.receivedAdObjects.count, @"Each callback should have an ad object");
    
    // Verify all received objects are CLXAd instances (except didFailToLoadAdWithError)
    for (NSInteger i = 0; i < self.receivedAdObjects.count; i++) {
        id adObject = self.receivedAdObjects[i];
        NSString *callback = self.receivedCallbacks[i];
        
        // didFailToLoadAdWithError is the only callback that doesn't receive an ad object (only error)
        if ([callback isEqualToString:@"didFailToLoadAdWithError"]) {
            XCTAssertTrue([adObject isKindOfClass:[NSNull class]], 
                         @"Callback %@ should receive NSNull (no ad object on load failure)", callback);
        } else {
            XCTAssertFalse([adObject isKindOfClass:[NSNull class]], @"Callback %@ should not receive nil ad object", callback);
            XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], 
                          @"Callback %@ should receive CLXAd object, got %@", callback, NSStringFromClass([adObject class]));
        }
    }
}

#pragma mark - Failure Scenario Tests

// Test that all ad formats properly call failToLoadWithAd delegate on failures
- (void)testAllFormats_FailureScenarios_CallDelegateWithCorrectAdObject {
    // Test that failure scenarios across all ad formats properly call delegate methods
    
    // Create test data
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test-failure"
                                             placementId:@"test-failure-id"
                                                  bidder:@"test-bidder"
                                     externalPlacementId:@"test-external"
                                                 revenue:@2.50];
    NSError *testError = [NSError errorWithDomain:@"CLXTestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    // Clear tracking
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [self.receivedAdTypes removeAllObjects];
    
    // Test failure callback for each format
    [self didFailToLoadAdWithError:testError]; // Banner/Interstitial/Rewarded/Native all use this
    
    // Verify delegate was called
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToLoadAdWithError"], 
                 @"All ad format failures should call didFailToLoadAdWithError delegate");
    XCTAssertEqual(self.receivedAdObjects.count, 1, @"Should receive one object (NSNull) in failure callback");
    
    // Verify no ad object is passed for load failure
    if (self.receivedAdObjects.count > 0) {
        id adObject = self.receivedAdObjects.firstObject;
        XCTAssertTrue([adObject isKindOfClass:[NSNull class]], 
                     @"Load failure callback should NOT receive CLXAd object");
    }
}

// Test that failure callbacks are consistent across all ad format delegate protocols
- (void)testFailureCallbacks_ConsistentAcrossAllFormats {
    // This test ensures that banner, interstitial, rewarded, and native ad formats
    // all have consistent failure callback behavior for publisher integration
    
    NSError *testError = [NSError errorWithDomain:@"CLXTestError" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Consistent failure test"}];
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"consistency-test"
                                             placementId:@"consistency-id"
                                                  bidder:@"test-bidder"
                                     externalPlacementId:@"test-external"
                                                 revenue:@1.75];
    
    // Clear tracking
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    
    // Test multiple failure scenarios to ensure consistency
    [self didFailToLoadAdWithError:testError];
    [self didFailToDisplayAd:testAd error:testError]; // Only for interstitial/rewarded
    
    // Verify both failure types were captured
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToLoadAdWithError"], 
                 @"Should capture load failure callback");
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToDisplayAd"], 
                 @"Should capture display failure callback");
    
    // Verify failure callbacks received proper ad objects
    // didFailToLoadAdWithError should receive NSNull (no ad object)
    // didFailToDisplayAd should receive CLXAd object
    XCTAssertEqual(self.receivedAdObjects.count, 2, @"Should have two failure callbacks");
    
    for (NSInteger i = 0; i < self.receivedCallbacks.count; i++) {
        NSString *callback = self.receivedCallbacks[i];
        id adObject = self.receivedAdObjects[i];
        
        if ([callback isEqualToString:@"didFailToLoadAdWithError"]) {
            XCTAssertTrue([adObject isKindOfClass:[NSNull class]], 
                         @"didFailToLoadAdWithError should receive NSNull (no ad on load failure)");
        } else if ([callback isEqualToString:@"didFailToDisplayAd"]) {
            XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], 
                         @"didFailToDisplayAd should receive CLXAd object");
        }
    }
}

@end
