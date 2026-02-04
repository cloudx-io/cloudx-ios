//
//  CLXDelegateCallbackTypeTests.m
//  CloudXCoreTests
//
//  Unit tests to verify all ad format delegate callbacks return CLXAd objects
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBidResponse.h>

@interface CLXDelegateCallbackTypeTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSString *> *receivedCallbacks;
@property (nonatomic, strong) NSMutableArray<id> *receivedAdObjects;
@end

@implementation CLXDelegateCallbackTypeTests

- (void)setUp {
    [super setUp];
    self.receivedCallbacks = [NSMutableArray array];
    self.receivedAdObjects = [NSMutableArray array];
}

- (void)tearDown {
    [self.receivedCallbacks removeAllObjects];
    [self.receivedAdObjects removeAllObjects];
    [super tearDown];
}

#pragma mark - Test Delegate Implementation

// Test that all interstitial delegate callbacks receive CLXAd objects
- (void)didLoadAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didLoadAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didLoadAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {
    [self.receivedCallbacks addObject:@"didFailToLoadAd"];
    XCTAssertNotNil(placementName, @"didFailToLoadAd should receive non-nil placementName");
    XCTAssertNotNil(error, @"didFailToLoadAd should receive non-nil error");
}

- (void)didDisplayAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didDisplayAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didDisplayAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"didFailToDisplayAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didFailToDisplayAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didHideAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didHideAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didHideAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didClickAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didClickAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didClickAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didRecordImpressionForAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didRecordImpressionForAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"closedByUserActionWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"closedByUserActionWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

#pragma mark - Helper Methods

// Test that CLXAd factory method creates proper objects
- (void)testCLXAdFactoryMethodCreatesValidObjects {
    // Create mock CLXBidResponseBid with proper structure
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.adid = @"ext_123";  // This maps to externalPlacementId

    // Create the extension structure for bidder info and revenue
    CLXBidResponseCloudX *cloudxExt = [[CLXBidResponseCloudX alloc] init];
    cloudxExt.adapterExtras = @{@"bidder": @"test_bidder"};
    cloudxExt.revenue = 1.25;  // Revenue from ext.cloudx.revenue

    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = cloudxExt;

    mockBid.ext = ext;

    CLXAd *ad = [CLXAd adFromBid:mockBid adUnitId:@"placement_123" adFormat:CLXAdFormatInterstitial placement:nil];

    XCTAssertNotNil(ad, @"Factory method should create CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"Factory method should return CLXAd instance");
    XCTAssertEqualObjects(ad.adUnitName, @"placement_123", @"Ad unit name should use adUnitId as fallback");
    XCTAssertEqualObjects(ad.adUnitId, @"placement_123", @"Ad unit ID should be set from parameter");
    XCTAssertEqualObjects(ad.networkName, @"test_bidder", @"Network name should be extracted from bid");
    XCTAssertEqualObjects(ad.networkPlacement, @"ext_123", @"Network placement should be extracted from bid");
    XCTAssertEqualObjects(ad.revenue, @1.25, @"Revenue should be extracted from ext.cloudx.revenue");
}

// Test that CLXAd initializer creates proper objects
- (void)testCLXAdInitializerCreatesValidObjects {
    CLXAd *ad = [[CLXAd alloc] initWithAdUnitName:@"test_name"
                                         adUnitId:@"test_id"
                                      networkName:@"test_bidder"
                                 networkPlacement:@"ext_id"
                                          revenue:@2.50
                                         adFormat:CLXAdFormatInterstitial
                                        placement:nil];

    XCTAssertNotNil(ad, @"Initializer should create CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"Initializer should return CLXAd instance");
    XCTAssertEqualObjects(ad.adUnitName, @"test_name", @"Ad unit name should be set");
    XCTAssertEqualObjects(ad.adUnitId, @"test_id", @"Ad unit ID should be set");
    XCTAssertEqualObjects(ad.networkName, @"test_bidder", @"Network name should be set");
    XCTAssertEqualObjects(ad.networkPlacement, @"ext_id", @"Network placement should be set");
    XCTAssertEqualObjects(ad.revenue, @2.50, @"Revenue should be set");
}

// Test that CLXAd properties are readonly and properly typed
- (void)testCLXAdPropertiesAreReadonlyAndTyped {
    CLXAd *ad = [[CLXAd alloc] initWithAdUnitName:@"test"
                                         adUnitId:@"test"
                                      networkName:@"test"
                                 networkPlacement:@"test"
                                          revenue:@1.0
                                         adFormat:CLXAdFormatInterstitial
                                        placement:nil];
    
    // Verify all properties exist and are of correct type (new names)
    XCTAssertTrue([ad respondsToSelector:@selector(adUnitName)], @"CLXAd should have adUnitName property");
    XCTAssertTrue([ad respondsToSelector:@selector(adUnitId)], @"CLXAd should have adUnitId property");
    XCTAssertTrue([ad respondsToSelector:@selector(networkName)], @"CLXAd should have networkName property");
    XCTAssertTrue([ad respondsToSelector:@selector(networkPlacement)], @"CLXAd should have networkPlacement property");
    XCTAssertTrue([ad respondsToSelector:@selector(revenue)], @"CLXAd should have revenue property");
    
    // Note: Deprecated property aliases (placementName, placementId, bidder, externalPlacementId) 
    // have been removed as part of the placement → adUnit migration
    
    // Verify properties return correct types
    if (ad.adUnitName) {
        XCTAssertTrue([ad.adUnitName isKindOfClass:[NSString class]], @"adUnitName should be NSString");
    }
    if (ad.adUnitId) {
        XCTAssertTrue([ad.adUnitId isKindOfClass:[NSString class]], @"adUnitId should be NSString");
    }
    if (ad.networkName) {
        XCTAssertTrue([ad.networkName isKindOfClass:[NSString class]], @"networkName should be NSString");
    }
    if (ad.networkPlacement) {
        XCTAssertTrue([ad.networkPlacement isKindOfClass:[NSString class]], @"networkPlacement should be NSString");
    }
    if (ad.revenue) {
        XCTAssertTrue([ad.revenue isKindOfClass:[NSNumber class]], @"revenue should be NSNumber");
    }
}

// Test that delegate method signatures are correct
- (void)testDelegateMethodSignaturesAreCorrect {
    // Verify that all delegate methods expect CLXAd * parameters
    // This test ensures compile-time type safety
    
    // Create a test CLXAd
    CLXAd *testAd = [[CLXAd alloc] initWithAdUnitName:@"test"
                                             adUnitId:@"test"
                                          networkName:@"test"
                                     networkPlacement:@"test"
                                              revenue:@1.0
                                             adFormat:CLXAdFormatInterstitial
                                            placement:nil];
    
    NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    
    // These should compile without warnings if signatures are correct
    [self didLoadAd:testAd];
    [self didFailToLoadAd:@"test_placement" error:testError];
    [self didDisplayAd:testAd];
    [self didFailToDisplayAd:testAd error:testError];
    [self didHideAd:testAd];
    [self didClickAd:testAd];
    [self didRecordImpressionForAd:testAd];
    [self closedByUserActionWithAd:testAd];

    // Verify all callbacks were received
    XCTAssertEqual(self.receivedCallbacks.count, 8, @"All delegate methods should have been called");
    XCTAssertEqual(self.receivedAdObjects.count, 7, @"All delegate methods (except didFailToLoadAd) should have received ad objects");
    
    // Verify all received objects are CLXAd instances
    for (id adObject in self.receivedAdObjects) {
        XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], @"All delegate callbacks should receive CLXAd objects");
    }
}

@end
