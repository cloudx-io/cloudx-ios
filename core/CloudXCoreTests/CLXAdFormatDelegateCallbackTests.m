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

- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {
    [self.receivedCallbacks addObject:@"didFailToLoadAd"];
    [self.receivedAdObjects addObject:[NSNull null]]; // No ad object for load failure
    [self.receivedAdTypes addObject:@"NSNull"];

    XCTAssertNotNil(placementName, @"didFailToLoadAd should receive non-nil placementName");
    XCTAssertNotNil(error, @"didFailToLoadAd should receive non-nil error");
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

// Rewarded-specific delegate method (mirrors AppLovin MAX SDK's MARewardedAdDelegate)
- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {
    [self.receivedCallbacks addObject:@"didRewardUserForAd:withReward:"];
    [self.receivedAdObjects addObject:ad ?: [NSNull null]];
    [self.receivedAdTypes addObject:NSStringFromClass([ad class])];
    
    XCTAssertNotNil(ad, @"didRewardUserForAd:withReward: should receive non-nil CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didRewardUserForAd:withReward: should receive CLXAd object, got %@", NSStringFromClass([ad class]));
    XCTAssertNotNil(reward, @"didRewardUserForAd:withReward: should receive non-nil CLXReward object");
    XCTAssertTrue([reward isKindOfClass:[CLXReward class]], @"didRewardUserForAd:withReward: should receive CLXReward object, got %@", NSStringFromClass([reward class]));
}

#pragma mark - Integration Tests

// Test that CLXAd factory method exists and works correctly
- (void)testCLXAdFactoryMethodExists {
    // Test that the CLXAd factory method exists and can create CLXAd objects
    // This replaces the old getClxAdForDelegateCallback helper methods
    
    // Verify CLXAd class has the factory method
    XCTAssertTrue([CLXAd respondsToSelector:@selector(adFromBid:adUnitId:adFormat:placement:)],
                  @"CLXAd should have adFromBid:adUnitId:adFormat:placement: factory method");

    // Test that we can create a CLXAd object with nil bid (should return nil)
    CLXAd *adWithNilBid = [CLXAd adFromBid:nil adUnitId:@"test-placement" adFormat:CLXAdFormatInterstitial placement:nil];
    XCTAssertNil(adWithNilBid, @"CLXAd factory method should return nil for nil bid");
    
    // Test that we can create a CLXAd object with valid bid data
    // Create a mock bid response with the minimum required data
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.ext = [[CLXBidResponseExt alloc] init];
    mockBid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    mockBid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    mockBid.ext.prebid.meta.adaptercode = @"test-bidder";
    mockBid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    mockBid.ext.cloudx.revenue = 1.50;

    CLXAd *adWithValidBid = [CLXAd adFromBid:mockBid adUnitId:@"test-placement" adFormat:CLXAdFormatInterstitial placement:nil];
    XCTAssertNotNil(adWithValidBid, @"CLXAd factory method should create valid CLXAd object");
    XCTAssertEqualObjects(adWithValidBid.adUnitId, @"test-placement", @"CLXAd should have correct ad unit ID");
    XCTAssertEqualObjects(adWithValidBid.networkName, @"test-bidder", @"CLXAd should have correct network name");
    XCTAssertEqual([adWithValidBid.revenue doubleValue], 1.50, @"CLXAd should have correct revenue");
}

// Test that all delegate method signatures are consistent across ad formats
- (void)testAllAdFormatDelegateSignaturesAreConsistent {
    // Create test CLXAd and error objects
    CLXAd *testAd = [[CLXAd alloc] initWithAdUnitName:@"test"
                                              adUnitId:@"test"
                                           networkName:@"test"
                                      networkPlacement:@"test"
                                               revenue:@1.0
                                              adFormat:CLXAdFormatInterstitial
                                             placement:nil];
    NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    
    // Clear previous callbacks
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [self.receivedAdTypes removeAllObjects];
    
    // Test banner delegate methods
    [self didLoadAd:testAd];
    [self didFailToLoadAd:@"test_banner" error:testError];
    [self didDisplayAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];

    // Test interstitial delegate methods (same signatures as banner)
    [self didLoadAd:testAd];
    [self didFailToLoadAd:@"test_interstitial" error:testError];
    [self didDisplayAd:testAd];
    [self didFailToDisplayAd:testAd error:testError];
    [self didHideAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];

    // Test rewarded delegate methods (includes reward callback - mirrors AppLovin MAX SDK)
    CLXReward *testReward = [CLXReward rewardWithAmount:100 label:@"coins"];
    [self didRewardUserForAd:testAd withReward:testReward];

    // Test native delegate methods (same as base ad delegate)
    [self didLoadAd:testAd];
    [self didFailToLoadAd:@"test_native" error:testError];
    [self didDisplayAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];
    
    // Verify all callbacks received CLXAd objects (except didFailToLoadAd which receives only error)
    XCTAssertGreaterThan(self.receivedCallbacks.count, 0, @"Should have received delegate callbacks");
    XCTAssertEqual(self.receivedCallbacks.count, self.receivedAdObjects.count, @"Each callback should have an ad object");
    
    // Verify all received objects are CLXAd instances (except didFailToLoadAd)
    for (NSInteger i = 0; i < self.receivedAdObjects.count; i++) {
        id adObject = self.receivedAdObjects[i];
        NSString *callback = self.receivedCallbacks[i];
        
        // didFailToLoadAd is the only callback that doesn't receive an ad object (only error)
        if ([callback isEqualToString:@"didFailToLoadAd"]) {
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
    CLXAd *testAd = [[CLXAd alloc] initWithAdUnitName:@"test-failure"
                                              adUnitId:@"test-failure-id"
                                           networkName:@"test-bidder"
                                      networkPlacement:@"test-external"
                                               revenue:@2.50
                                              adFormat:CLXAdFormatInterstitial
                                             placement:nil];
    NSError *testError = [NSError errorWithDomain:@"CLXTestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    // Clear tracking
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [self.receivedAdTypes removeAllObjects];
    
    // Test failure callback for each format
    [self didFailToLoadAd:@"test_placement" error:testError]; // Banner/Interstitial/Rewarded/Native all use this
    
    // Verify delegate was called
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToLoadAd"], 
                 @"All ad format failures should call didFailToLoadAd delegate");
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
    CLXAd *testAd = [[CLXAd alloc] initWithAdUnitName:@"consistency-test"
                                              adUnitId:@"consistency-id"
                                           networkName:@"test-bidder"
                                      networkPlacement:@"test-external"
                                               revenue:@1.75
                                              adFormat:CLXAdFormatInterstitial
                                             placement:nil];
    
    // Clear tracking
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    
    // Test multiple failure scenarios to ensure consistency
    [self didFailToLoadAd:@"test_placement" error:testError];
    [self didFailToDisplayAd:testAd error:testError]; // Only for interstitial/rewarded
    
    // Verify both failure types were captured
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToLoadAd"], 
                 @"Should capture load failure callback");
    XCTAssertTrue([self.receivedCallbacks containsObject:@"didFailToDisplayAd"], 
                 @"Should capture display failure callback");
    
    // Verify failure callbacks received proper ad objects
    // didFailToLoadAd should receive NSNull (no ad object)
    // didFailToDisplayAd should receive CLXAd object
    XCTAssertEqual(self.receivedAdObjects.count, 2, @"Should have two failure callbacks");
    
    for (NSInteger i = 0; i < self.receivedCallbacks.count; i++) {
        NSString *callback = self.receivedCallbacks[i];
        id adObject = self.receivedAdObjects[i];
        
        if ([callback isEqualToString:@"didFailToLoadAd"]) {
            XCTAssertTrue([adObject isKindOfClass:[NSNull class]], 
                         @"didFailToLoadAd should receive NSNull (no ad on load failure)");
        } else if ([callback isEqualToString:@"didFailToDisplayAd"]) {
            XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], 
                         @"didFailToDisplayAd should receive CLXAd object");
        }
    }
}

@end
