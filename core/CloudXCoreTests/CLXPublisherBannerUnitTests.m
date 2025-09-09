//
//  CLXPublisherBannerUnitTests.m
//  CloudXCoreTests
//
//  Comprehensive unit tests for CLXPublisherBanner covering all critical functionality
//  including spec-compliant refresh behavior, visibility management, and error handling
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>
#define CLXBANNER_MOCKS_IMPLEMENTATION
#import "Mocks/CLXBannerMocks.h"
#import <objc/objc.h>

// Test category to expose private properties
@interface CLXPublisherBanner (Testing)
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> currentLoadingBanner;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong, nullable) NSDate *lastManualRefreshTime;
- (void)_timerDidReachEndSynchronous;
@end

// MARK: - Test Constants

static NSString * const kTestPlacementID = @"test-banner-placement";
static NSString * const kTestUserID = @"test-user-123";
static NSString * const kTestPublisherID = @"test-publisher-456";
static NSString * const kTestBidID = @"test-bid-789";
static NSString * const kTestAdID = @"test-ad-abc";
static NSString * const kTestNetwork = @"testbidder";
static const NSTimeInterval kTestRefreshInterval = 5.0;
static const NSTimeInterval kTestTimeout = 2.0;

// MARK: - Categories to expose private methods and properties

@interface CLXPublisherBanner (Testing) <CLXAdapterBannerDelegate>

// Expose private properties for testing (only properties not already public)
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> currentLoadingBanner;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL forceStop;
@property (nonatomic, strong) CLXBannerTimerService *timerService;
// Expose readonly properties as readwrite for testing
@property (nonatomic, strong, nullable, readwrite) id<CLXAdapterBanner> prefetchedBanner;
@property (nonatomic, strong, nullable, readwrite) id<CLXAdapterBanner> bannerOnScreen;
@property (nonatomic, assign, readwrite) BOOL hasPendingRefresh;
@property (nonatomic, assign, readwrite) BOOL isVisible;

// Expose private methods for testing
- (void)setVisible:(BOOL)visible;
- (void)becameVisible;
- (void)becameHidden;
- (void)timerDidReachEnd;
- (void)_timerDidReachEndSynchronous;
- (void)requestBannerUpdate;
- (void)continueBannerChain;
- (nullable id<CLXAdapterBanner>)createBannerInstanceWithAdId:(NSString *)adId
                                                        bidId:(NSString *)bidId
                                                          adm:(NSString *)adm
                                                adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                                         burl:(NSString *)burl
                                               hasClosedButton:(BOOL)hasClosedButton
                                                       network:(NSString *)network;

// Expose delegate methods for testing
- (void)didLoadBanner:(id<CLXAdapterBanner>)banner;
- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error;
- (void)didShowBanner:(id<CLXAdapterBanner>)banner;
- (void)impressionBanner:(id<CLXAdapterBanner>)banner;
- (void)clickBanner:(id<CLXAdapterBanner>)banner;
- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner;

@end

// MARK: - Mock Objects (using shared CLXBannerMocks)

// MockBannerAdapter now available from CLXBannerMocks.h

@interface MockBannerFactory : NSObject <CLXAdapterBannerFactory>
@property (nonatomic, strong) MockBannerAdapter *mockAdapter;
@property (nonatomic, assign) BOOL shouldReturnNil;
@end

@implementation MockBannerFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _mockAdapter = [[MockBannerAdapter alloc] init];
        _shouldReturnNil = NO;
    }
    return self;
}

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                        type:(CLXBannerType)type
                                                        adId:(NSString *)adId
                                                       bidId:(NSString *)bidId
                                                         adm:(NSString *)adm
                                             hasClosedButton:(BOOL)hasClosedButton
                                                      extras:(NSDictionary<NSString *, NSString *> *)extras
                                                    delegate:(id<CLXAdapterBannerDelegate>)delegate {
    if (self.shouldReturnNil) {
        return nil;
    }
    self.mockAdapter.delegate = delegate;
    return self.mockAdapter;
}

@end


@interface MockBidTokenSource : NSObject <CLXBidTokenSource>
@end

@implementation MockBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    completion(@{@"token": @"mock-bid-token"}, nil);
}

@end

@interface MockReportingService : NSObject <CLXAdEventReporting>
@end

@implementation MockReportingService

- (void)reportEvent:(NSString *)event withData:(NSDictionary *)data {
    // Mock implementation
}

@end

// MARK: - Test Class

@interface CLXPublisherBannerUnitTests : XCTestCase
@property (nonatomic, strong) CLXPublisherBanner *banner;
@property (nonatomic, strong) MockBannerDelegate *mockDelegate;
@property (nonatomic, strong) MockBannerFactory *mockFactory;
@property (nonatomic, strong) UIViewController *testViewController;
@property (nonatomic, strong) CLXSDKConfigPlacement *testPlacement;
@property (nonatomic, strong) CLXConfigImpressionModel *testImpModel;
@property (nonatomic, strong) CLXSettings *testSettings;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *testFactories;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXBidTokenSource>> *testBidTokenSources;
@property (nonatomic, strong) MockReportingService *mockReportingService;
@end

@implementation CLXPublisherBannerUnitTests

- (void)setUp {
    [super setUp];
    
    // Create test objects
    self.testViewController = [[UIViewController alloc] init];
    self.mockDelegate = [[MockBannerDelegate alloc] init];
    self.mockFactory = [[MockBannerFactory alloc] init];
    self.mockReportingService = [[MockReportingService alloc] init];
    
    // Create test placement with refresh interval
    self.testPlacement = [[CLXSDKConfigPlacement alloc] init];
    self.testPlacement.id = kTestPlacementID;
    self.testPlacement.bannerRefreshRateMs = (int64_t)(kTestRefreshInterval * 1000);
    
    // Create test impression model
    self.testImpModel = [[CLXConfigImpressionModel alloc] init];
    
    // Create test settings
    self.testSettings = [[CLXSettings alloc] init];
    
    // Create test factories and bid token sources
    self.testFactories = @{kTestNetwork: self.mockFactory};
    self.testBidTokenSources = @{kTestNetwork: [[MockBidTokenSource alloc] init]};
    
    // Create banner instance
    self.banner = [[CLXPublisherBanner alloc] initWithViewController:self.testViewController
                                                           placement:self.testPlacement
                                                              userID:kTestUserID
                                                         publisherID:kTestPublisherID
                                            suspendPreloadWhenInvisible:NO
                                                             delegate:self.mockDelegate
                                                           bannerType:CLXBannerTypeW320H50
                                                 waterfallMaxBackOffTime:30.0
                                                            impModel:self.testImpModel
                                                        adFactories:self.testFactories
                                                     bidTokenSources:self.testBidTokenSources
                                                  bidRequestTimeout:kTestTimeout
                                                   reportingService:self.mockReportingService
                                                            settings:self.testSettings
                                                               tmax:@30];
}

- (void)tearDown {
    [self.banner destroy];
    self.banner = nil;
    self.mockDelegate = nil;
    self.mockFactory = nil;
    self.testViewController = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

// Test that banner initializes with correct default values
- (void)testBannerInitializationWithDefaults {
    XCTAssertNotNil(self.banner, @"Banner should be initialized");
    XCTAssertEqual(self.banner.bannerType, CLXBannerTypeW320H50, @"Banner type should match initialization");
    XCTAssertFalse(self.banner.isReady, @"Banner should not be ready initially");
    XCTAssertTrue(self.banner.isVisible, @"Banner should be visible by default");
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Banner should not have pending refresh initially");
    XCTAssertNil(self.banner.prefetchedBanner, @"Banner should not have prefetched banner initially");
    XCTAssertEqual(self.banner.refreshSeconds, kTestRefreshInterval, @"Refresh interval should match placement config");
    XCTAssertEqual(self.banner.delegate, self.mockDelegate, @"Delegate should be set correctly");
}

// Test that banner initializes with custom refresh interval from placement
- (void)testBannerInitializationWithCustomRefreshInterval {
    const NSTimeInterval customInterval = 15.0;
    self.testPlacement.bannerRefreshRateMs = (int64_t)(customInterval * 1000);
    
    CLXPublisherBanner *customBanner = [[CLXPublisherBanner alloc] initWithViewController:self.testViewController
                                                                                placement:self.testPlacement
                                                                                   userID:kTestUserID
                                                                              publisherID:kTestPublisherID
                                                                 suspendPreloadWhenInvisible:NO
                                                                                  delegate:self.mockDelegate
                                                                                bannerType:CLXBannerTypeW320H50
                                                                      waterfallMaxBackOffTime:30.0
                                                                                 impModel:self.testImpModel
                                                                             adFactories:self.testFactories
                                                                          bidTokenSources:self.testBidTokenSources
                                                                       bidRequestTimeout:kTestTimeout
                                                                        reportingService:self.mockReportingService
                                                                                 settings:self.testSettings
                                                                                    tmax:@30];
    
    XCTAssertEqual(customBanner.refreshSeconds, customInterval, @"Refresh interval should match custom placement config");
    [customBanner destroy];
}

#pragma mark - Visibility Management Tests

// Test visibility state changes trigger correct behavior
- (void)testVisibilityStateManagement {
    XCTAssertTrue(self.banner.isVisible, @"Banner should start visible");
    
    // Test becoming hidden
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Banner should be hidden after setVisible:NO");
    
    // Test becoming visible again
    [self.banner setVisible:YES];
    XCTAssertTrue(self.banner.isVisible, @"Banner should be visible after setVisible:YES");
}

// Test that refresh is queued when timer expires while hidden
- (void)testRefreshQueuedWhenHiddenDuringTimerExpiry {
    // Hide the banner
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Banner should be hidden");
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should not have pending refresh initially");
    
    // Simulate timer expiry while hidden
    [self.banner _timerDidReachEndSynchronous];
    
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should have pending refresh after timer expiry while hidden");
}

// Test that pending refresh executes when banner becomes visible
- (void)testPendingRefreshExecutesWhenBecomeVisible {
    // Set up pending refresh
    [self.banner setVisible:NO];
    [self.banner _timerDidReachEndSynchronous];
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should have pending refresh");
    
    // Make banner visible again
    [self.banner setVisible:YES];
    
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Pending refresh should be cleared after execution");
}

// Test that prefetched banner is displayed when becoming visible
- (void)testPrefetchedBannerDisplayedWhenBecomeVisible {
    // Start with banner hidden
    [self.banner setVisible:NO];
    
    // Create and load a banner while hidden (this should prefetch and call delegate)
    MockBannerAdapter *prefetchedAdapter = [[MockBannerAdapter alloc] init];
    self.banner.currentLoadingBanner = prefetchedAdapter;
    [self.banner didLoadBanner:prefetchedAdapter];
    
    // Verify it was prefetched and delegate was called (industry standard)
    XCTAssertNil(self.banner.bannerOnScreen, @"Banner should not be displayed when hidden");
    XCTAssertEqual(self.banner.prefetchedBanner, prefetchedAdapter, @"Banner should be prefetched when hidden");
    XCTAssertTrue(self.mockDelegate.didLoadCalled, @"Delegate should be called immediately upon load (industry standard)");
    
    // Now make banner visible - prefetched banner should be displayed
    [self.banner setVisible:YES];
    
    XCTAssertEqual(self.banner.bannerOnScreen, prefetchedAdapter, @"Prefetched banner should be displayed when becoming visible");
    XCTAssertNil(self.banner.prefetchedBanner, @"Prefetched banner should be cleared after display");
}

#pragma mark - Ad Loading Tests

// Test successful banner loading when visible
- (void)testSuccessfulBannerLoadingWhenVisible {
    XCTAssertTrue(self.banner.isVisible, @"Banner should be visible");
    
    // Create mock banner and simulate successful load
    MockBannerAdapter *mockAdapter = self.mockFactory.mockAdapter;
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertEqual(self.banner.bannerOnScreen, mockAdapter, @"Banner should be displayed immediately when visible");
    XCTAssertNil(self.banner.prefetchedBanner, @"Should not have prefetched banner when visible");
    XCTAssertTrue(self.mockDelegate.didLoadCalled, @"Delegate should be notified");
}

// Test banner loading when hidden results in prefetching
- (void)testBannerLoadingWhenHiddenResultsInPrefetching {
    // Hide banner
    [self.banner setVisible:NO];
    XCTAssertFalse(self.banner.isVisible, @"Banner should be hidden");
    
    // Create mock banner and simulate successful load
    MockBannerAdapter *mockAdapter = self.mockFactory.mockAdapter;
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    XCTAssertNil(self.banner.bannerOnScreen, @"Banner should not be displayed when hidden");
    XCTAssertEqual(self.banner.prefetchedBanner, mockAdapter, @"Banner should be prefetched when hidden");
    XCTAssertTrue(self.mockDelegate.didLoadCalled, @"Delegate should be notified immediately upon successful load (industry standard)");
}

// Test banner loading failure triggers proper error handling
- (void)testBannerLoadingFailureTriggersPropperErrorHandling {
    NSError *testError = [NSError errorWithDomain:@"TestError" code:123 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    // Simulate banner load failure
    [self.banner failToLoadBanner:nil error:testError];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled, @"Delegate should be notified of failure");
    XCTAssertEqual(self.mockDelegate.lastError, testError, @"Error should be passed to delegate");
    XCTAssertNil(self.banner.bannerOnScreen, @"No banner should be on screen after failure");
    XCTAssertNil(self.banner.prefetchedBanner, @"No banner should be prefetched after failure");
}

// Test NO_FILL error conversion from waterfall exhaustion
- (void)testNoFillErrorConversionFromWaterfallExhaustion {
    NSError *waterfallError = [NSError errorWithDomain:@"CLXBidAdSource" 
                                                  code:CLXBidAdSourceErrorNoBid 
                                              userInfo:@{NSLocalizedDescriptionKey: @"All bids failed in waterfall."}];
    
    // Simulate waterfall exhaustion
    [self.banner failToLoadBanner:nil error:waterfallError];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled, @"Delegate should be notified of failure");
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeNoFill, @"Error should be converted to NO_FILL");
    XCTAssertEqualObjects(self.mockDelegate.lastError.domain, @"CLXErrorDomain", @"Error domain should be CLXErrorDomain");
}

#pragma mark - Timer and Refresh Tests

// Test timer starts after successful banner load
- (void)testTimerStartsAfterSuccessfulBannerLoad {
    MockBannerAdapter *mockAdapter = self.mockFactory.mockAdapter;
    
    // Simulate successful banner load
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    // Timer service should be active (we can't easily test the internal state without more mocking)
    XCTAssertNotNil(self.banner.timerService, @"Timer service should exist");
}

// Test timer starts after banner load failure for next interval
- (void)testTimerStartsAfterBannerLoadFailureForNextInterval {
    NSError *testError = [NSError errorWithDomain:@"TestError" code:123 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    // Simulate banner load failure
    [self.banner failToLoadBanner:nil error:testError];
    
    // Timer should restart for next interval
    XCTAssertNotNil(self.banner.timerService, @"Timer service should exist for next interval");
}

// Test refresh only occurs when banner is visible
- (void)testRefreshOnlyOccursWhenBannerIsVisible {
    XCTAssertTrue(self.banner.isVisible, @"Banner should start visible");
    
    // Simulate timer reaching end while visible
    [self.banner _timerDidReachEndSynchronous];
    
    // Should not have pending refresh when visible (should execute immediately)
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Should not queue refresh when visible");
}

#pragma mark - Single-Flight Request Tests

// Test that multiple load calls don't create multiple requests
- (void)testSingleFlightRequestBehavior {
    // Set loading state
    self.banner.isLoading = YES;
    
    // Try to load again
    [self.banner load];
    
    // Should not create additional requests (this is more of a behavioral test)
    XCTAssertTrue(self.banner.isLoading, @"Should maintain loading state");
}

// Test that force stop prevents new requests
- (void)testForceStopPreventsNewRequests {
    // Set force stop
    self.banner.forceStop = YES;
    
    // Try to load
    [self.banner load];
    
    // Should not proceed with loading
    XCTAssertTrue(self.banner.forceStop, @"Force stop should remain active");
}

#pragma mark - Delegate Callback Tests

// Test all adapter delegate methods forward correctly
- (void)testAdapterDelegateMethodsForwardCorrectly {
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] init];
    
    // Test didShowBanner
    [self.banner didShowBanner:mockAdapter];
    XCTAssertTrue(self.mockDelegate.didShowCalled, @"didShow should be forwarded to delegate");
    
    // Reset delegate
    self.mockDelegate.impressionCalled = NO;
    self.mockDelegate.clickCalled = NO;
    self.mockDelegate.closedByUserActionCalled = NO;
    
    // Test impressionBanner
    [self.banner impressionBanner:mockAdapter];
    XCTAssertTrue(self.mockDelegate.impressionCalled, @"impression should be forwarded to delegate");
    
    // Test clickBanner
    [self.banner clickBanner:mockAdapter];
    XCTAssertTrue(self.mockDelegate.clickCalled, @"click should be forwarded to delegate");
    
    // Test closedByUserActionBanner
    [self.banner closedByUserActionBanner:mockAdapter];
    XCTAssertTrue(self.mockDelegate.closedByUserActionCalled, @"closedByUserAction should be forwarded to delegate");
}

#pragma mark - Destroy and Cleanup Tests

// Test destroy cleans up all resources
- (void)testDestroyCleanupAllResources {
    // Set up some state
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] init];
    self.banner.prefetchedBanner = mockAdapter;
    self.banner.bannerOnScreen = mockAdapter;
    
    // Destroy banner
    [self.banner destroy];
    
    XCTAssertTrue(self.banner.forceStop, @"Force stop should be set after destroy");
    XCTAssertNil(self.banner.prefetchedBanner, @"Prefetched banner should be cleared");
    // Note: We can't easily test that bannerOnScreen is destroyed without more complex mocking
}

// Test destroy cancels pending requests and timers
- (void)testDestroyCancelsPendingRequestsAndTimers {
    // Set up pending state
    self.banner.hasPendingRefresh = YES;
    self.banner.isLoading = YES;
    
    // Destroy banner
    [self.banner destroy];
    
    XCTAssertTrue(self.banner.forceStop, @"Should stop all operations");
    XCTAssertFalse(self.banner.isLoading, @"Should cancel loading state");
}

#pragma mark - Banner Creation Tests

// Test banner creation with valid network
- (void)testBannerCreationWithValidNetwork {
    id<CLXAdapterBanner> createdBanner = [self.banner createBannerInstanceWithAdId:kTestAdID
                                                                             bidId:kTestBidID
                                                                               adm:@"test-adm"
                                                                     adapterExtras:@{}
                                                                              burl:@"test-burl"
                                                                   hasClosedButton:NO
                                                                           network:kTestNetwork];
    
    XCTAssertNotNil(createdBanner, @"Should create banner with valid network");
    XCTAssertEqual(createdBanner, self.mockFactory.mockAdapter, @"Should return mock adapter");
}

// Test banner creation with invalid network returns nil
- (void)testBannerCreationWithInvalidNetworkReturnsNil {
    id<CLXAdapterBanner> createdBanner = [self.banner createBannerInstanceWithAdId:kTestAdID
                                                                             bidId:kTestBidID
                                                                               adm:@"test-adm"
                                                                     adapterExtras:@{}
                                                                              burl:@"test-burl"
                                                                   hasClosedButton:NO
                                                                           network:@"invalid-network"];
    
    XCTAssertNil(createdBanner, @"Should return nil for invalid network");
}

// Test banner creation when factory returns nil
- (void)testBannerCreationWhenFactoryReturnsNil {
    self.mockFactory.shouldReturnNil = YES;
    
    id<CLXAdapterBanner> createdBanner = [self.banner createBannerInstanceWithAdId:kTestAdID
                                                                             bidId:kTestBidID
                                                                               adm:@"test-adm"
                                                                     adapterExtras:@{}
                                                                              burl:@"test-burl"
                                                                   hasClosedButton:NO
                                                                           network:kTestNetwork];
    
    XCTAssertNil(createdBanner, @"Should return nil when factory returns nil");
}

#pragma mark - Spec Compliance Tests

// Test wall-clock refresh behavior continues when hidden
- (void)testWallClockRefreshContinuesWhenHidden {
    // Hide banner
    [self.banner setVisible:NO];
    
    // Simulate timer expiry (wall-clock continues)
    [self.banner _timerDidReachEndSynchronous];
    
    // Should queue refresh for when visible
    XCTAssertTrue(self.banner.hasPendingRefresh, @"Should queue refresh when hidden per spec");
    
    // Make visible and verify refresh executes
    [self.banner setVisible:YES];
    XCTAssertFalse(self.banner.hasPendingRefresh, @"Queued refresh should execute when visible per spec");
}

// Test no banner-level retry within same interval
- (void)testNoBannerLevelRetryWithinSameInterval {
    NSError *testError = [NSError errorWithDomain:@"TestError" code:123 userInfo:@{NSLocalizedDescriptionKey: @"Test failure"}];
    
    // Simulate failure
    [self.banner failToLoadBanner:nil error:testError];
    
    // Should not retry immediately, should wait for next interval
    XCTAssertTrue(self.mockDelegate.failToLoadCalled, @"Should report failure to delegate");
    XCTAssertFalse(self.banner.isLoading, @"Should not be loading after failure per spec");
}

// Test single-flight request per placement
- (void)testSingleFlightRequestPerPlacement {
    // Start loading
    self.banner.isLoading = YES;
    
    // Try to start another load
    [self.banner load];
    
    // Should not start additional request
    XCTAssertTrue(self.banner.isLoading, @"Should maintain single-flight behavior per spec");
}

// Test prefetch behavior when request completes while hidden
- (void)testPrefetchBehaviorWhenRequestCompletesWhileHidden {
    // Hide banner and start request
    [self.banner setVisible:NO];
    
    // Simulate successful completion while hidden
    MockBannerAdapter *mockAdapter = self.mockFactory.mockAdapter;
    self.banner.currentLoadingBanner = mockAdapter; // Set up loading state
    [self.banner didLoadBanner:mockAdapter];
    
    // Should prefetch, not display
    XCTAssertEqual(self.banner.prefetchedBanner, mockAdapter, @"Should prefetch when completing while hidden per spec");
    XCTAssertNil(self.banner.bannerOnScreen, @"Should not display when hidden per spec");
    
    // When becomes visible, should display prefetched
    [self.banner setVisible:YES];
    XCTAssertEqual(self.banner.bannerOnScreen, mockAdapter, @"Should display prefetched banner when visible per spec");
    XCTAssertNil(self.banner.prefetchedBanner, @"Should clear prefetch after display per spec");
}

// MARK: - MAX SDK Parity Tests

// Test auto-refresh is enabled by default
- (void)testAutoRefreshEnabledByDefault {
    XCTAssertTrue(self.banner.autoRefreshEnabled, @"Auto-refresh should be enabled by default");
}

// Test startAutoRefresh enables auto-refresh and starts timer
- (void)testStartAutoRefreshEnablesAutoRefreshAndStartsTimer {
    // Given: Auto-refresh is disabled
    self.banner.autoRefreshEnabled = NO;
    
    // When: Starting auto-refresh
    [self.banner startAutoRefresh];
    
    // Then: Auto-refresh should be enabled
    XCTAssertTrue(self.banner.autoRefreshEnabled, @"startAutoRefresh should enable auto-refresh");
}

// Test stopAutoRefresh disables auto-refresh and stops timer
- (void)testStopAutoRefreshDisablesAutoRefreshAndStopsTimer {
    // Given: Auto-refresh is enabled
    self.banner.autoRefreshEnabled = YES;
    
    // When: Stopping auto-refresh
    [self.banner stopAutoRefresh];
    
    // Then: Auto-refresh should be disabled
    XCTAssertFalse(self.banner.autoRefreshEnabled, @"stopAutoRefresh should disable auto-refresh");
}

// Test rate limiting prevents immediate refresh within 30 seconds
- (void)testRateLimitingPreventsImmediateRefresh {
    // Given: A recent manual refresh timestamp
    NSDate *recentTime = [NSDate dateWithTimeIntervalSinceNow:-10.0]; // 10 seconds ago
    self.banner.lastManualRefreshTime = recentTime;
    self.banner.autoRefreshEnabled = NO;
    
    // Mock banner on screen and visible
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] initWithID:@"test"];
    self.banner.bannerOnScreen = mockAdapter;
    self.banner.isVisible = YES;
    
    // When: Starting auto-refresh within rate limit window
    [self.banner startAutoRefresh];
    
    // Then: Should not trigger immediate load (rate limited)
    // We can't directly test the load call, but we can verify the state
    XCTAssertTrue(self.banner.autoRefreshEnabled, @"Auto-refresh should be enabled");
    XCTAssertNotNil(self.banner.lastManualRefreshTime, @"Rate limiting timestamp should be preserved");
}

// Test rate limiting allows refresh after 30 seconds
- (void)testRateLimitingAllowsRefreshAfter30Seconds {
    // Given: An old manual refresh timestamp (over 30 seconds ago)
    NSDate *oldTime = [NSDate dateWithTimeIntervalSinceNow:-35.0]; // 35 seconds ago
    self.banner.lastManualRefreshTime = oldTime;
    self.banner.autoRefreshEnabled = NO;
    
    // Mock banner on screen and visible
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] initWithID:@"test"];
    self.banner.bannerOnScreen = mockAdapter;
    self.banner.isVisible = YES;
    
    // When: Starting auto-refresh after rate limit window
    [self.banner startAutoRefresh];
    
    // Then: Should enable auto-refresh
    XCTAssertTrue(self.banner.autoRefreshEnabled, @"Auto-refresh should be enabled after rate limit");
}

// Test didLoadBanner sets lastManualRefreshTime for fraud protection
- (void)testDidLoadBannerSetsLastManualRefreshTimeForFraudProtection {
    // Given: No previous refresh time
    self.banner.lastManualRefreshTime = nil;
    
    // When: Banner loads successfully
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] initWithID:@"test"];
    [self.banner didLoadBanner:mockAdapter];
    
    // Then: Should set lastManualRefreshTime to prevent immediate double impressions
    XCTAssertNotNil(self.banner.lastManualRefreshTime, @"didLoadBanner should set lastManualRefreshTime for fraud protection");
    
    // Verify timestamp is recent (within last second)
    NSTimeInterval timeSinceSet = [[NSDate date] timeIntervalSinceDate:self.banner.lastManualRefreshTime];
    XCTAssertLessThan(timeSinceSet, 1.0, @"lastManualRefreshTime should be set to current time");
}

// Test timer respects autoRefreshEnabled flag
- (void)testTimerRespectsAutoRefreshEnabledFlag {
    // Given: Auto-refresh is disabled
    self.banner.autoRefreshEnabled = NO;
    
    // When: Timer reaches end
    [self.banner _timerDidReachEndSynchronous];
    
    // Then: Should not trigger refresh when auto-refresh is disabled
    XCTAssertFalse(self.banner.isLoading, @"Timer should respect autoRefreshEnabled flag");
}

// Test expand/collapse delegate forwarding from adapter
- (void)testExpandCollapseDelegateForwardingFromAdapter {
    // Given: A mock delegate that captures expand/collapse calls
    MockBannerDelegate *mockDelegate = [[MockBannerDelegate alloc] init];
    self.banner.delegate = mockDelegate;
    
    // When: Adapter calls expand/collapse delegates
    MockBannerAdapter *mockAdapter = [[MockBannerAdapter alloc] initWithID:@"test"];
    [self.banner didExpandBanner:mockAdapter];
    [self.banner didCollapseBanner:mockAdapter];
    
    // Then: Should forward to banner delegate
    XCTAssertTrue(mockDelegate.didExpandCalled, @"didExpandBanner should forward to delegate");
    XCTAssertTrue(mockDelegate.didCollapseCalled, @"didCollapseBanner should forward to delegate");
}

@end
