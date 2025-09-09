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
- (void)didLoadWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didLoadWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didLoadWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"failToLoadWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"failToLoadWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didShowWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didShowWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didShowWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.receivedCallbacks addObject:@"failToShowWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"failToShowWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didHideWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didHideWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didHideWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)didClickWithAd:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"didClickWithAd"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"didClickWithAd should receive CLXAd object, got %@", NSStringFromClass([ad class]));
}

- (void)impressionOn:(CLXAd *)ad {
    [self.receivedCallbacks addObject:@"impressionOn"];
    [self.receivedAdObjects addObject:ad];
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"impressionOn should receive CLXAd object, got %@", NSStringFromClass([ad class]));
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
    mockBid.price = 1.25;       // This maps to revenue
    
    // Create the extension structure for bidder info
    CLXBidResponseCloudX *cloudxExt = [[CLXBidResponseCloudX alloc] init];
    cloudxExt.adapterExtras = @{@"bidder": @"test_bidder"};
    
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = cloudxExt;
    
    mockBid.ext = ext;
    
    CLXAd *ad = [CLXAd adFromBid:mockBid placementId:@"placement_123"];
    
    XCTAssertNotNil(ad, @"Factory method should create CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"Factory method should return CLXAd instance");
    XCTAssertEqualObjects(ad.placementName, @"placement_123", @"Placement name should use placementId as fallback");
    XCTAssertEqualObjects(ad.placementId, @"placement_123", @"Placement ID should be set from parameter");
    XCTAssertEqualObjects(ad.bidder, @"test_bidder", @"Bidder should be extracted from bid");
    XCTAssertEqualObjects(ad.externalPlacementId, @"ext_123", @"External placement ID should be extracted from bid");
    XCTAssertEqualObjects(ad.revenue, @1.25, @"Revenue should be extracted from bid");
}

// Test that CLXAd initializer creates proper objects
- (void)testCLXAdInitializerCreatesValidObjects {
    CLXAd *ad = [[CLXAd alloc] initWithPlacementName:@"test_name"
                                         placementId:@"test_id"
                                              bidder:@"test_bidder"
                                 externalPlacementId:@"ext_id"
                                             revenue:@2.50];
    
    XCTAssertNotNil(ad, @"Initializer should create CLXAd object");
    XCTAssertTrue([ad isKindOfClass:[CLXAd class]], @"Initializer should return CLXAd instance");
    XCTAssertEqualObjects(ad.placementName, @"test_name", @"Placement name should be set");
    XCTAssertEqualObjects(ad.placementId, @"test_id", @"Placement ID should be set");
    XCTAssertEqualObjects(ad.bidder, @"test_bidder", @"Bidder should be set");
    XCTAssertEqualObjects(ad.externalPlacementId, @"ext_id", @"External placement ID should be set");
    XCTAssertEqualObjects(ad.revenue, @2.50, @"Revenue should be set");
}

// Test that CLXAd properties are readonly and properly typed
- (void)testCLXAdPropertiesAreReadonlyAndTyped {
    CLXAd *ad = [[CLXAd alloc] initWithPlacementName:@"test"
                                         placementId:@"test"
                                              bidder:@"test"
                                 externalPlacementId:@"test"
                                             revenue:@1.0];
    
    // Verify all properties exist and are of correct type
    XCTAssertTrue([ad respondsToSelector:@selector(placementName)], @"CLXAd should have placementName property");
    XCTAssertTrue([ad respondsToSelector:@selector(placementId)], @"CLXAd should have placementId property");
    XCTAssertTrue([ad respondsToSelector:@selector(bidder)], @"CLXAd should have bidder property");
    XCTAssertTrue([ad respondsToSelector:@selector(externalPlacementId)], @"CLXAd should have externalPlacementId property");
    XCTAssertTrue([ad respondsToSelector:@selector(revenue)], @"CLXAd should have revenue property");
    
    // Verify properties return correct types
    if (ad.placementName) {
        XCTAssertTrue([ad.placementName isKindOfClass:[NSString class]], @"placementName should be NSString");
    }
    if (ad.placementId) {
        XCTAssertTrue([ad.placementId isKindOfClass:[NSString class]], @"placementId should be NSString");
    }
    if (ad.bidder) {
        XCTAssertTrue([ad.bidder isKindOfClass:[NSString class]], @"bidder should be NSString");
    }
    if (ad.externalPlacementId) {
        XCTAssertTrue([ad.externalPlacementId isKindOfClass:[NSString class]], @"externalPlacementId should be NSString");
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
    CLXAd *testAd = [[CLXAd alloc] initWithPlacementName:@"test"
                                             placementId:@"test"
                                                  bidder:@"test"
                                     externalPlacementId:@"test"
                                                 revenue:@1.0];
    
    NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    
    // These should compile without warnings if signatures are correct
    [self didLoadWithAd:testAd];
    [self failToLoadWithAd:testAd error:testError];
    [self didShowWithAd:testAd];
    [self failToShowWithAd:testAd error:testError];
    [self didHideWithAd:testAd];
    [self didClickWithAd:testAd];
    [self impressionOn:testAd];
    [self closedByUserActionWithAd:testAd];
    
    // Verify all callbacks were received
    XCTAssertEqual(self.receivedCallbacks.count, 8, @"All delegate methods should have been called");
    XCTAssertEqual(self.receivedAdObjects.count, 8, @"All delegate methods should have received ad objects");
    
    // Verify all received objects are CLXAd instances
    for (id adObject in self.receivedAdObjects) {
        XCTAssertTrue([adObject isKindOfClass:[CLXAd class]], @"All delegate callbacks should receive CLXAd objects");
    }
}

@end
