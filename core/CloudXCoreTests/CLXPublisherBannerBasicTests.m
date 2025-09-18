//
//  CLXPublisherBannerBasicTests.m
//  CloudXCoreTests
//
//  Basic tests for CLXPublisherBanner that focus on direct method testing
//  without relying on the full bid request chain
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>

// Test category to expose private properties
@interface CLXPublisherBanner (Testing)
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> currentLoadingBanner;
@end

// MARK: - Test Constants

static NSString * const kBasicTestPlacementID = @"basic-test-placement";
static NSString * const kBasicTestUserID = @"basic-user-123";
static NSString * const kBasicTestPublisherID = @"basic-publisher-456";
static NSString * const kBasicTestNetwork = @"testbidder";
static const NSTimeInterval kBasicRefreshInterval = 5.0;

// MARK: - Simple Mock Objects

@interface BasicMockAdapter : NSObject <CLXAdapterBanner>
@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy) NSString *adapterID;
@end

@implementation BasicMockAdapter

- (instancetype)initWithID:(NSString *)adapterID {
    self = [super init];
    if (self) {
        _bannerView = [[UIView alloc] init];
        _sdkVersion = @"1.0.0";
        _adapterID = adapterID;
    }
    return self;
}

- (void)load {
    // Mock load - we'll manually trigger delegate callbacks in tests
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.delegate didShowBanner:self];
}

- (void)destroy {
    // Mock destroy
}

@end

@interface BasicMockDelegate : NSObject <CLXBannerDelegate, CLXAdapterBannerDelegate>
@property (nonatomic, assign) NSInteger didLoadCount;
@property (nonatomic, assign) NSInteger failToLoadCount;
@property (nonatomic, assign) NSInteger didShowCount;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, strong, nullable) CLXAd *lastAd;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> lastBanner;
@end

@implementation BasicMockDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    self.didLoadCount++;
    self.lastAd = ad;
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    self.failToLoadCount++;
    self.lastAd = ad;
    self.lastError = error;
}

- (void)didShowWithAd:(CLXAd *)ad {
    self.didShowCount++;
    self.lastAd = ad;
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    // Not used in basic tests
}

- (void)didHideWithAd:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)didClickWithAd:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)impressionOn:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    self.didLoadCount++;
    self.lastBanner = banner;
}

- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error {
    self.failToLoadCount++;
    self.lastBanner = banner;
    self.lastError = error;
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
    self.didShowCount++;
    self.lastBanner = banner;
}

- (void)impressionBanner:(id<CLXAdapterBanner>)banner {
    // Not used in basic tests
}

- (void)clickBanner:(id<CLXAdapterBanner>)banner {
    // Not used in basic tests
}

- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner {
    // Not used in basic tests
}

@end

// MARK: - Categories for Testing

@interface CLXPublisherBanner (BasicTesting)
// Expose private properties for testing (only properties not already public)
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL hasPendingRefresh;
@property (nonatomic, strong, nullable, readwrite) id<CLXAdapterBanner> prefetchedBanner;
@property (nonatomic, strong, nullable, readwrite) id<CLXAdapterBanner> bannerOnScreen;
@property (nonatomic, assign, readwrite) BOOL isVisible;
// Expose private methods for testing
- (void)setVisible:(BOOL)visible;
- (void)timerDidReachEnd;
- (void)_timerDidReachEndSynchronous;
- (void)didLoadBanner:(id<CLXAdapterBanner>)banner;
- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error;
@end

// MARK: - Basic Test Class

@interface CLXPublisherBannerBasicTests : XCTestCase
@property (nonatomic, strong) CLXPublisherBanner *banner;
@property (nonatomic, strong) BasicMockDelegate *mockDelegate;
@property (nonatomic, strong) UIViewController *testViewController;
@property (nonatomic, strong) CLXSDKConfigPlacement *testPlacement;
@property (nonatomic, strong) CLXConfigImpressionModel *testImpModel;
@property (nonatomic, strong) CLXSettings *testSettings;
@end

@implementation CLXPublisherBannerBasicTests

- (void)setUp {
    [super setUp];
    
    // Create minimal test objects
    self.testViewController = [[UIViewController alloc] init];
    self.mockDelegate = [[BasicMockDelegate alloc] init];
    
    // Create test placement
    self.testPlacement = [[CLXSDKConfigPlacement alloc] init];
    self.testPlacement.id = kBasicTestPlacementID;
    self.testPlacement.bannerRefreshRateMs = (int64_t)(kBasicRefreshInterval * 1000);
    
    // Create minimal required objects
    self.testImpModel = [[CLXConfigImpressionModel alloc] init];
    self.testSettings = [[CLXSettings alloc] init];
    
    // Create banner with minimal setup
    self.banner = [[CLXPublisherBanner alloc] initWithViewController:self.testViewController
                                                           placement:self.testPlacement
                                                              userID:kBasicTestUserID
                                                         publisherID:kBasicTestPublisherID
                                            suspendPreloadWhenInvisible:NO
                                                             delegate:self.mockDelegate
                                                           bannerType:CLXBannerTypeW320H50
                                                 waterfallMaxBackOffTime:30.0
                                                            impModel:self.testImpModel
                                                        adFactories:@{}
                                                     bidTokenSources:@{}
                                                  bidRequestTimeout:5.0
                                                   reportingService:nil
                                                            settings:self.testSettings
                                                               tmax:@30
];
}

- (void)tearDown {
    [self.banner destroy];
    self.banner = nil;
    self.mockDelegate = nil;
    [super tearDown];
}

#pragma mark - Basic Initialization Tests

// Test banner initializes with correct properties
- (void)testBannerInitializesWithCorrectProperties {
    XCTAssertNotNil(self.banner, @"Banner should be initialized");
    XCTAssertEqual(self.banner.bannerType, CLXBannerTypeW320H50, @"Banner type should match");
    XCTAssertFalse(self.banner.isReady, @"Banner should not be ready initially");
    XCTAssertTrue(self.banner.isVisible, @"Banner should be visible by default");
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should not have pending refresh initially");
    XCTAssertNil(self.banner.prefetchedBanner, @"Should not have prefetched banner initially");
    XCTAssertEqual(self.banner.refreshSeconds, kBasicRefreshInterval, @"Refresh interval should match");
    XCTAssertEqual(self.banner.delegate, self.mockDelegate, @"Delegate should be set");
}

#pragma mark - Visibility Management Tests

// Test visibility state changes
- (void)testVisibilityStateChanges {
    XCTAssertTrue(self.banner.isVisible, @"Should start visible");
    
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Should be hidden after setVisible:NO");
    
    [self.banner setVisible:YES];
    XCTAssertTrue(self.banner.isVisible, @"Should be visible after setVisible:YES");
}

// Test pending refresh behavior when hidden
- (void)testPendingRefreshBehaviorWhenHidden {
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should not have pending refresh initially");
    
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should queue refresh when hidden");
    
    [self.banner setVisible:YES];
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should clear pending refresh when visible");
}

#pragma mark - Direct Delegate Method Tests

// Test successful banner loading when visible
- (void)testSuccessfulBannerLoadingWhenVisible {
    XCTAssertTrue(self.banner.isVisible, @"Banner should be visible");
    
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"test-adapter"];
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertEqual(self.banner.bannerOnScreen, mockAdapter, @"Banner should be displayed when visible");
    XCTAssertNil(self.banner.prefetchedBanner, @"Should not prefetch when visible");
    XCTAssertTrue(self.mockDelegate.didLoadCount > 0, @"Delegate should be notified");
}

// Test banner prefetching when hidden
- (void)testBannerPrefetchingWhenHidden {
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Banner should be hidden");
    
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"test-adapter"];
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertNil(self.banner.bannerOnScreen, @"Banner should not be displayed when hidden");
    XCTAssertEqual(self.banner.prefetchedBanner, mockAdapter, @"Banner should be prefetched when hidden");
    XCTAssertEqual(self.mockDelegate.didLoadCount, 1, @"Delegate should be notified when banner loads (industry standard)");
}

// Test prefetched banner displays when becoming visible
- (void)testPrefetchedBannerDisplaysWhenBecomingVisible {
    // Set up prefetch scenario
    [self.banner setVisible:NO];
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"test-adapter"];
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertEqual(self.banner.prefetchedBanner, mockAdapter, @"Should have prefetched banner");
    XCTAssertEqual(self.mockDelegate.didLoadCount, 1, @"Should notify delegate when banner loads (industry standard)");
    
    // Make visible
    [self.banner setVisible:YES];
    
    XCTAssertEqual(self.banner.bannerOnScreen, mockAdapter, @"Should display prefetched banner");
    XCTAssertNil(self.banner.prefetchedBanner, @"Should clear prefetch after display");
    XCTAssertEqual(self.mockDelegate.didLoadCount, 1, @"Should not call delegate again when displaying prefetched banner");
}

// Test banner load failure handling
- (void)testBannerLoadFailureHandling {
    NSError *testError = [NSError errorWithDomain:@"TestError" code:123 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    [self.banner failToLoadBanner:nil error:testError];
    
    XCTAssertEqual(self.mockDelegate.failToLoadCount, 1, @"Delegate should be notified of failure");
    XCTAssertEqual(self.mockDelegate.lastError, testError, @"Error should be passed to delegate");
    XCTAssertNil(self.banner.bannerOnScreen, @"No banner should be on screen after failure");
    XCTAssertNil(self.banner.prefetchedBanner, @"No banner should be prefetched after failure");
}

// Test NO_FILL error conversion
- (void)testNoFillErrorConversion {
    NSError *waterfallError = [NSError errorWithDomain:@"CLXBidAdSource" 
                                                  code:CLXBidAdSourceErrorNoBid 
                                              userInfo:@{NSLocalizedDescriptionKey: @"All bids failed"}];
    
    [self.banner failToLoadBanner:nil error:waterfallError];
    
    XCTAssertEqual(self.mockDelegate.failToLoadCount, 1, @"Delegate should be notified of failure");
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeNoFill, @"Error should be converted to NO_FILL");
    XCTAssertEqualObjects(self.mockDelegate.lastError.domain, @"CLXErrorDomain", @"Error domain should be CLXErrorDomain");
}

#pragma mark - State Management Tests

// Test destroy cleans up state
- (void)testDestroyCleanupState {
    // Set up some state
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"test-adapter"];
    self.banner.prefetchedBanner = mockAdapter;
    self.banner.hasPendingRefresh = YES;
    
    [self.banner destroy];
    
    XCTAssertNil(self.banner.prefetchedBanner, @"Prefetched banner should be cleared");
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Pending refresh should be cleared");
}

// Test multiple visibility changes
- (void)testMultipleVisibilityChanges {
    // Rapid visibility changes
    [self.banner setVisible:NO];
    [self.banner setVisible:YES];
    [self.banner setVisible:NO];
    [self.banner setVisible:YES];
    
    XCTAssertTrue(self.banner.isVisible, @"Should end up visible");
}

// Test timer behavior with visibility
- (void)testTimerBehaviorWithVisibility {
    // Test timer expiry while visible (should not queue)
    XCTAssertTrue(self.banner.isVisible, @"Should start visible");
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should not queue when visible");
    
    // Test timer expiry while hidden (should queue)
    [self.banner setVisible:NO];
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should queue when hidden");
}

@end
