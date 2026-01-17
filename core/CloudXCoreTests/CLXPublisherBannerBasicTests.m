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

- (void)didLoadAd:(CLXAd *)ad {
    self.didLoadCount++;
    self.lastAd = ad;
}

- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {
    self.failToLoadCount++;
    self.lastError = error;
}

- (void)didDisplayAd:(CLXAd *)ad {
    self.didShowCount++;
    self.lastAd = ad;
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(NSError *)error {
    // Not used in basic tests
}

- (void)didHideAd:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)didClickAd:(CLXAd *)ad {
    // Not used in basic tests
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
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
@property (nonatomic, assign) BOOL bypassVisibilityCheck; // For testing bypass feature
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
    // Error is wrapped in CLXError - check code and underlying error are preserved
    XCTAssertTrue([self.mockDelegate.lastError isKindOfClass:[CLXError class]], @"Error should be CLXError");
    XCTAssertEqual(self.mockDelegate.lastError.code, testError.code, @"Error code should be preserved");
    XCTAssertEqualObjects(self.mockDelegate.lastError.userInfo[NSUnderlyingErrorKey], testError, @"Underlying error should be original");
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
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXBidAdSourceErrorNoBid, @"Error code should be preserved from original error");
    XCTAssertEqualObjects(self.mockDelegate.lastError.domain, CLXErrorDomain, @"Error domain should be CLXErrorDomain");
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
    
    // Test timer expiry while hidden (should queue when bypass is OFF)
    [self.banner setVisible:NO];
    self.banner.bypassVisibilityCheck = NO; // Ensure bypass is off
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should queue when hidden and bypass is OFF");
}

#pragma mark - Bypass Visibility Check Tests (PR #98 feature)

// Test that bypass flag starts as NO
- (void)testBypassVisibilityCheckStartsDisabled {
    XCTAssertFalse(self.banner.bypassVisibilityCheck, @"Bypass should be OFF initially");
}

// Test that load failure enables bypass
- (void)testLoadFailureEnablesbypassVisibilityCheck {
    XCTAssertFalse(self.banner.bypassVisibilityCheck, @"Bypass should start OFF");
    
    NSError *testError = [NSError errorWithDomain:@"TestError" code:100 userInfo:nil];
    [self.banner failToLoadBanner:nil error:testError];
    
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should be ON after load failure");
}

// Test that successful load disables bypass
- (void)testSuccessfulLoadDisablesBypassVisibilityCheck {
    // First, enable bypass via failure
    NSError *testError = [NSError errorWithDomain:@"TestError" code:100 userInfo:nil];
    [self.banner failToLoadBanner:nil error:testError];
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should be ON after failure");
    
    // Now load successfully
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"test-adapter"];
    self.banner.currentLoadingBanner = mockAdapter;
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertFalse(self.banner.bypassVisibilityCheck, @"Bypass should be OFF after successful load");
}

// Test that becoming visible disables bypass
- (void)testBecomingVisibleDisablesBypassVisibilityCheck {
    // Enable bypass via failure
    NSError *testError = [NSError errorWithDomain:@"TestError" code:100 userInfo:nil];
    [self.banner failToLoadBanner:nil error:testError];
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should be ON after failure");
    
    // Hide banner
    [self.banner setVisible:NO];
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should remain ON while hidden");
    
    // Make visible
    [self.banner setVisible:YES];
    XCTAssertFalse(self.banner.bypassVisibilityCheck, @"Bypass should be OFF after becoming visible");
}

// Test timer fires load (not queue) when hidden WITH bypass enabled
- (void)testTimerLoadsWhenHiddenWithBypassEnabled {
    // Hide banner and enable bypass
    [self.banner setVisible:NO];
    self.banner.bypassVisibilityCheck = YES;
    self.banner.hasPendingRefresh = NO; // Reset
    
    // Timer fires while hidden with bypass
    [self.banner _timerDidReachEndSynchronous];
    
    // Should NOT queue (hasPendingRefresh should stay NO because it triggered a load)
    // The bypass allows load to proceed despite being hidden
    XCTAssertFalse(self.banner.hasPendingRefresh, 
                  @"Should NOT queue when bypass is enabled - should trigger load instead");
}

// Test complete bypass flow: failure → hidden → timer → load while hidden
- (void)testCompleteBypassFlow {
    // 1. Start visible, trigger a failure
    XCTAssertTrue(self.banner.isVisible, @"Should start visible");
    NSError *testError = [NSError errorWithDomain:@"TestError" code:100 userInfo:nil];
    [self.banner failToLoadBanner:nil error:testError];
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should be enabled after failure");
    
    // 2. Hide banner (simulates publisher showing fallback ad)
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Banner should be hidden");
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should remain enabled while hidden");
    
    // 3. Timer fires - should trigger load (not queue) because bypass is enabled
    self.banner.hasPendingRefresh = NO;
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertFalse(self.banner.hasPendingRefresh, 
                  @"Should NOT queue - bypass should allow load while hidden");
    
    // 4. Simulate successful load while hidden
    BasicMockAdapter *mockAdapter = [[BasicMockAdapter alloc] initWithID:@"prefetch-adapter"];
    self.banner.currentLoadingBanner = mockAdapter;
    [self.banner didLoadBanner:mockAdapter];
    
    // 5. Banner should be prefetched (not displayed since hidden)
    XCTAssertEqual(self.banner.prefetchedBanner, mockAdapter, 
                  @"Should prefetch banner when loading while hidden");
    XCTAssertFalse(self.banner.bypassVisibilityCheck, 
                  @"Bypass should be disabled after successful load");
    
    // 6. Make visible - prefetched banner should display
    [self.banner setVisible:YES];
    XCTAssertEqual(self.banner.bannerOnScreen, mockAdapter, 
                  @"Prefetched banner should be displayed when becoming visible");
    XCTAssertNil(self.banner.prefetchedBanner, 
                @"Prefetch should be cleared after display");
}

// Test destroy clears bypass flag
- (void)testDestroyCleansBypassFlag {
    // Enable bypass
    self.banner.bypassVisibilityCheck = YES;
    XCTAssertTrue(self.banner.bypassVisibilityCheck, @"Bypass should be enabled");
    
    [self.banner destroy];
    
    XCTAssertFalse(self.banner.bypassVisibilityCheck, @"Bypass should be cleared on destroy");
}

@end
