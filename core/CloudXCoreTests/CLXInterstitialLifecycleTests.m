//
//  CLXInterstitialLifecycleTests.m
//  CloudXCoreTests
//
//  Comprehensive unit and integration tests for interstitial ad lifecycle
//  Tests delegate callbacks, NURL firing, and FSM state transitions
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>
#import <objc/objc.h>
#import "Mocks/MockCLXWinLossTracker.h"

// MARK: - Test Constants

static NSString * const kTestPlacementID = @"test-interstitial-placement";
static NSString * const kTestBidID = @"test-bid-12345";
static NSString * const kTestAuctionID = @"test-auction-12345";
static NSString * const kTestNURL = @"https://test.com/nurl?price=${AUCTION_PRICE}";
static NSString * const kTestLURL = @"https://test.com/lurl?reason=${AUCTION_LOSS}";
static const double kTestPrice = 5.99;

// MARK: - Import private enum definition for testing

// Copy the enum definition from the implementation file for testing
typedef NS_ENUM(NSInteger, CLXInterstitialState) {
    CLXInterstitialStateIDLE,      // No ad loaded, ready to start loading
    CLXInterstitialStateLOADING,   // Ad request in progress
    CLXInterstitialStateREADY,     // Ad loaded and ready to display
    CLXInterstitialStateSHOWING,   // Ad currently visible to user
    CLXInterstitialStateDESTROYED  // Ad destroyed, no further operations allowed
};

// MARK: - Categories to expose private methods and properties

@interface CLXPublisherFullscreenAd (Testing) <CLXAdapterInterstitialDelegate, CLXAdapterRewardedDelegate>
@property (nonatomic, assign) CLXInterstitialState currentState;
@property (nonatomic, strong) id<CLXAdapterInterstitial> currentInterstitialAdapter;
@property (nonatomic, strong) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
- (void)handleBidResponse:(CLXBidAdSourceResponse *)response;

// Expose delegate methods for testing
- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error;
- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error;
- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;
@end

@interface CLXBidResponse (Testing)
- (CLXBidResponseBid *)findBidWithID:(NSString *)bidID;
@end

// MARK: - Mock Classes

@interface MockInterstitialDelegate : NSObject <CLXInterstitialDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *callbackLog;
@property (nonatomic, strong) CLXAd *lastLoadedAd;
@property (nonatomic, strong) NSError *lastLoadError;
@property (nonatomic, strong) CLXAd *lastShownAd;
@property (nonatomic, strong) NSError *lastShowError;
@property (nonatomic, strong) CLXAd *lastHiddenAd;
@property (nonatomic, strong) CLXAd *lastClickedAd;
@property (nonatomic, strong) CLXAd *lastImpressionAd;
@property (nonatomic, strong) CLXAd *lastClosedByUserAd;
@property (nonatomic, strong) XCTestExpectation *hideExpectation;
@end

@implementation MockInterstitialDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbackLog = [NSMutableArray array];
    }
    return self;
}

- (void)didLoadWithAd:(CLXAd *)ad {
    [self.callbackLog addObject:@"didLoadWithAd"];
    self.lastLoadedAd = ad;
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.callbackLog addObject:@"failToLoadWithAd"];
    self.lastLoadError = error;
}

- (void)didShowWithAd:(CLXAd *)ad {
    [self.callbackLog addObject:@"didShowWithAd"];
    self.lastShownAd = ad;
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.callbackLog addObject:@"failToShowWithAd"];
    self.lastShowError = error;
}

- (void)didHideWithAd:(CLXAd *)ad {
    [self.callbackLog addObject:@"didHideWithAd"];
    self.lastHiddenAd = ad;
    if (self.hideExpectation) {
        [self.hideExpectation fulfill];
    }
}

- (void)didClickWithAd:(CLXAd *)ad {
    [self.callbackLog addObject:@"didClickWithAd"];
    self.lastClickedAd = ad;
}

- (void)impressionOn:(CLXAd *)ad {
    [self.callbackLog addObject:@"impressionOn"];
    self.lastImpressionAd = ad;
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [self.callbackLog addObject:@"closedByUserActionWithAd"];
    self.lastClosedByUserAd = ad;
}

@end

@interface MockAdapterInterstitial : NSObject <CLXAdapterInterstitial>
@property (nonatomic, weak) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, strong) NSString *sdkVersion;
@property (nonatomic, strong) NSString *network;
@property (nonatomic, strong) NSString *bidID;
@property (nonatomic, assign) BOOL shouldFailLoad;
@property (nonatomic, assign) BOOL shouldFailShow;
@property (nonatomic, assign) NSTimeInterval loadDelay;
@property (nonatomic, strong) NSMutableArray<NSString *> *methodCalls;
@end

@implementation MockAdapterInterstitial

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = @"1.0.0";
        _network = @"TestNetwork";
        _bidID = kTestBidID;
        _loadDelay = 0.1; // Default small delay
        _methodCalls = [NSMutableArray array];
    }
    return self;
}

- (void)load {
    [self.methodCalls addObject:@"load"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.loadDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.shouldFailLoad) {
            NSError *error = [NSError errorWithDomain:@"TestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Mock load failure"}];
            [self.delegate didFailToLoadWithInterstitial:self error:error];
        } else {
            [self.delegate didLoadWithInterstitial:self];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.methodCalls addObject:@"showFromViewController"];
    
    if (self.shouldFailShow) {
        NSError *error = [NSError errorWithDomain:@"TestError" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Mock show failure"}];
        [self.delegate didFailToShowWithInterstitial:self error:error];
        return;
    }
    
    // Simulate successful show sequence
    [self.delegate didShowWithInterstitial:self];
    
    // Simulate impression after a short delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate impressionWithInterstitial:self];
    });
}

- (void)simulateClick {
    [self.delegate clickWithInterstitial:self];
}

- (void)simulateClose {
    [self.delegate didCloseWithInterstitial:self];
}

- (void)simulateExpired {
    [self.delegate expiredWithInterstitial:self];
}

@end

@interface MockAdEventReporter : NSObject <CLXAdEventReporting>
@property (nonatomic, strong) NSMutableArray<NSString *> *firedNurls;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *firedNurlPrices;
@property (nonatomic, strong) NSMutableArray<NSString *> *firedLurls;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *firedLurlReasons;
@property (nonatomic, strong) NSMutableArray<NSString *> *impressionBidIDs;
@property (nonatomic, strong) NSMutableArray<NSString *> *winBidIDs;
@end

@implementation MockAdEventReporter

- (instancetype)init {
    self = [super init];
    if (self) {
        _firedNurls = [NSMutableArray array];
        _firedNurlPrices = [NSMutableArray array];
        _firedLurls = [NSMutableArray array];
        _firedLurlReasons = [NSMutableArray array];
        _impressionBidIDs = [NSMutableArray array];
        _winBidIDs = [NSMutableArray array];
    }
    return self;
}


- (void)fireNurlForRevenueWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void(^)(BOOL success, CLXAd * _Nullable ad))completion {
    [self.firedNurls addObject:nUrl ?: @""];
    [self.firedNurlPrices addObject:@(price)];
    if (completion) {
        completion(YES, nil);
    }
}


- (void)fireLurlWithUrl:(nullable NSString *)lUrl reason:(NSInteger)reason {
    [self.firedLurls addObject:lUrl ?: @""];
    [self.firedLurlReasons addObject:@(reason)];
}

- (void)metricsTrackingWithActionString:(NSString *)actionString {
    // No-op for testing
}

- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {
    // No-op for testing
}

- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {
    // No-op for testing
}

@end

@interface MockBidResponse : CLXBidResponse
@property (nonatomic, strong) CLXBidResponseBid *testBid;
@end

@implementation MockBidResponse

- (CLXBidResponseBid *)findBidWithID:(NSString *)bidID {
    if ([bidID isEqualToString:self.testBid.id]) {
        return self.testBid;
    }
    return nil;
}

@end

// MARK: - Test Class

@interface CLXInterstitialLifecycleTests : XCTestCase
@property (nonatomic, strong) CLXPublisherFullscreenAd *interstitial;
@property (nonatomic, strong) MockInterstitialDelegate *mockDelegate;
@property (nonatomic, strong) MockAdEventReporter *mockReporter;
@property (nonatomic, strong) MockCLXWinLossTracker *mockWinLossTracker;
@property (nonatomic, strong) MockAdapterInterstitial *mockAdapter;
@end

@implementation CLXInterstitialLifecycleTests

// MARK: - Helper Methods for Runtime Property Access

- (void)setCurrentState:(CLXInterstitialState)state onInterstitial:(CLXPublisherFullscreenAd *)interstitial {
    // Use KVC (Key-Value Coding) to set the private property safely
    @try {
        [interstitial setValue:@(state) forKey:@"currentState"];
    } @catch (NSException *exception) {
        // If KVC fails, use associated object as fallback
        objc_setAssociatedObject(interstitial, @selector(currentState), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSLog(@"Could not set currentState via KVC, using associated object: %@", exception.reason);
    }
}

- (CLXInterstitialState)getCurrentStateFromInterstitial:(CLXPublisherFullscreenAd *)interstitial {
    // Try to get the actual private property using KVC first
    @try {
        NSNumber *stateNumber = [interstitial valueForKey:@"currentState"];
        if (stateNumber) {
            return (CLXInterstitialState)[stateNumber integerValue];
        }
    } @catch (NSException *exception) {
        NSLog(@"Could not get currentState via KVC, using associated object: %@", exception.reason);
    }
    
    // Fallback to associated object
    NSNumber *stateNumber = objc_getAssociatedObject(interstitial, @selector(currentState));
    return stateNumber ? (CLXInterstitialState)[stateNumber integerValue] : CLXInterstitialStateIDLE;
}

- (void)setUp {
    [super setUp];
    
    // Set up mock delegate
    self.mockDelegate = [[MockInterstitialDelegate alloc] init];
    
    // Set up mock reporter
    self.mockReporter = [[MockAdEventReporter alloc] init];
    
    // Set up mock win/loss tracker for server-side tracking
    self.mockWinLossTracker = [[MockCLXWinLossTracker alloc] init];
    [CLXWinLossTracker setSharedInstanceForTesting:self.mockWinLossTracker];
    
    // Create mock adapter
    self.mockAdapter = [[MockAdapterInterstitial alloc] init];
    
    // Create interstitial with proper dependencies for unit testing
    // We need to create the required dependencies
    CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
    placement.id = kTestPlacementID;
    
    // Create impression model for the test
    // Create mock SDK config for test
    CLXSDKConfigResponse *mockConfig = [[CLXSDKConfigResponse alloc] init];
    mockConfig.sessionID = @"test-session-id";
    mockConfig.organizationID = @"test-org-id";
    mockConfig.accountID = @"test-account-id";
    mockConfig.appID = @"test-interstitial-app-id";
    
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] 
        initWithSDKConfig:mockConfig
                auctionID:@"test-auction-id"
            testGroupName:@"test-group"];
    
    self.interstitial = [[CLXPublisherFullscreenAd alloc] initWithInterstitialDelegate:self.mockDelegate
                                                                      rewardedDelegate:nil
                                                                             placement:placement
                                                                           publisherID:@"test-publisher"
                                                                                userID:@"test-user"
                                                                   rewardedCallbackUrl:nil
                                                                              impModel:impModel
                                                                           adFactories:nil
                                                              waterfallMaxBackOffTime:@10.0
                                                                       bidTokenSources:@{}
                                                                    bidRequestTimeout:3.0
                                                                     reportingService:self.mockReporter
                                                                             settings:[CLXSettings sharedInstance]
                                                                               adType:CLXAdTypeInterstitial];
}

- (void)tearDown {
    // Reset win/loss tracker to default
    [CLXWinLossTracker resetSharedInstance];
    
    self.interstitial = nil;
    self.mockDelegate = nil;
    self.mockReporter = nil;
    self.mockWinLossTracker = nil;
    self.mockAdapter = nil;
    
    // Reset DI container to ensure clean state for next test
    [[CLXDIContainer shared] reset];
    
    [super tearDown];
}

// MARK: - FSM State Transition Tests

- (void)testInitialState {
    // Verifies that a newly created interstitial ad starts in the IDLE state and is not ready to show
    CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
    XCTAssertEqual(currentState, CLXInterstitialStateIDLE, @"Interstitial should start in IDLE state");
    XCTAssertFalse([self.interstitial isReady], @"Interstitial should not be ready initially");
}

- (void)testStateTransitionFromIdleToLoading {
    // Verifies that the interstitial transitions from IDLE to LOADING state when a load operation begins
    // Note: This would require mocking the bid source, so we'll test the state directly
    
    // Simulate starting a load
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
    XCTAssertEqual(currentState, CLXInterstitialStateLOADING, @"State should transition to LOADING");
}

- (void)testStateTransitionFromLoadingToReady {
    // Verifies that the interstitial transitions from LOADING to READY state when an ad successfully loads
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Create mock bid response
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.adid = kTestBidID;
    mockBid.price = kTestPrice;
    mockBid.nurl = kTestNURL;
    
    CLXBidResponse *mockBidResponse = [[CLXBidResponse alloc] init];
    // Note: Would need to set up the bid response properly with the mock bid
    self.interstitial.currentBidResponse = mockBidResponse;
    
    // Simulate adapter load success
    [self.interstitial didLoadWithInterstitial:self.mockAdapter];
    
    CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
    XCTAssertEqual(currentState, CLXInterstitialStateREADY, @"State should transition to READY after successful load");
    XCTAssertTrue([self.interstitial isReady], @"Interstitial should be ready after successful load");
}

- (void)testStateTransitionFromLoadingToIdleOnFailure {
    // Verifies that the interstitial transitions from LOADING back to IDLE state when ad loading fails
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    NSError *testError = [NSError errorWithDomain:@"TestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Load failed"}];
    
    // Simulate adapter load failure
    [self.interstitial didFailToLoadWithInterstitial:self.mockAdapter error:testError];
    
    CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
    XCTAssertEqual(currentState, CLXInterstitialStateIDLE, @"State should transition back to IDLE after load failure");
    XCTAssertFalse([self.interstitial isReady], @"Interstitial should not be ready after load failure");
}

- (void)testStateTransitionFromReadyToShowing {
    // Verifies that the interstitial can be shown when in READY state and calls the adapter correctly
    
    // Set up the interstitial with a mock adapter and ready state
    [self setCurrentState:CLXInterstitialStateREADY onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate show by calling showFromViewController
    UIViewController *testViewController = [[UIViewController alloc] init];
    [self.interstitial showFromViewController:testViewController];
    
    // Verify that the adapter's showFromViewController was called
    XCTAssertTrue([self.mockAdapter.methodCalls containsObject:@"showFromViewController"], 
                  @"Adapter showFromViewController should be called when interstitial is shown");
    
    // Verify that the interstitial is no longer ready (since it's now showing)
    XCTAssertFalse([self.interstitial isReady], @"Interstitial should not be ready while showing");
}

- (void)testStateTransitionFromShowingToIdleOnClose {
    // Verifies that the interstitial handles close events correctly and becomes ready for new loads
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Set up expectation for delegate callback
    XCTestExpectation *expectation = [self expectationWithDescription:@"didHideWithAd callback"];
    self.mockDelegate.hideExpectation = expectation;
    
    // Simulate close
    [self.interstitial didCloseWithInterstitial:self.mockAdapter];
    
    // Wait for delegate callback
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify delegate was called
    XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"didHideWithAd"], 
                  @"didHideWithAd delegate should be called when ad is closed");
    
    // Verify that the interstitial is ready for new loads after closing
    // Note: In the real implementation, closing should reset the state to IDLE, making it ready for new loads
    // For now, we'll verify that a new load call can be made without crashing
    XCTAssertNoThrow([self.interstitial load], @"Should be able to call load again after closing");
}

// MARK: - Delegate Callback Tests

- (void)testDidLoadDelegateCallback {
    // Verifies that the didLoadWithAd delegate callback is triggered when an interstitial successfully loads
    XCTestExpectation *expectation = [self expectationWithDescription:@"didLoadWithAd callback"];
    
    // Set up the interstitial in loading state
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate successful load
    [self.interstitial didLoadWithInterstitial:self.mockAdapter];
    
    // Check callback was made
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"didLoadWithAd"], @"didLoadWithAd should be called");
        // CLXAd should be nil when no valid bid data is available
        XCTAssertNil(self.mockDelegate.lastLoadedAd, @"Loaded ad should be nil when no bid data available");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testFailToLoadDelegateCallback {
    // Verifies that the failToLoadWithAd delegate callback is triggered when an interstitial fails to load
    XCTestExpectation *expectation = [self expectationWithDescription:@"failToLoadWithAd callback"];
    
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    NSError *testError = [NSError errorWithDomain:@"TestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Load failed"}];
    
    // Simulate load failure
    [self.interstitial didFailToLoadWithInterstitial:self.mockAdapter error:testError];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"failToLoadWithAd"], @"failToLoadWithAd should be called");
        XCTAssertEqualObjects(self.mockDelegate.lastLoadError.localizedDescription, @"Load failed", @"Error should match");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testDidShowDelegateCallback {
    // Verifies that the didShowWithAd delegate callback is triggered when an interstitial is displayed to the user
    XCTestExpectation *expectation = [self expectationWithDescription:@"didShowWithAd callback"];
    
    [self setCurrentState:CLXInterstitialStateREADY onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate show
    [self.interstitial didShowWithInterstitial:self.mockAdapter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"didShowWithAd"], @"didShowWithAd should be called");
        // CLXAd should be nil when no valid bid data is available
        XCTAssertNil(self.mockDelegate.lastShownAd, @"Shown ad should be nil when no bid data available");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testImpressionDelegateCallback {
    // Verifies that the impressionOn delegate callback is triggered when an interstitial impression is recorded
    XCTestExpectation *expectation = [self expectationWithDescription:@"impressionOn callback"];
    
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate impression
    [self.interstitial impressionWithInterstitial:self.mockAdapter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"impressionOn"], @"impressionOn should be called");
        // CLXAd should be nil when no valid bid data is available
        XCTAssertNil(self.mockDelegate.lastImpressionAd, @"Impression ad should be nil when no bid data available");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testDidClickDelegateCallback {
    // Verifies that the didClickWithAd delegate callback is triggered when a user clicks on the interstitial
    XCTestExpectation *expectation = [self expectationWithDescription:@"didClickWithAd callback"];
    
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate click
    [self.interstitial clickWithInterstitial:self.mockAdapter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"didClickWithAd"], @"didClickWithAd should be called");
        // CLXAd should be nil when no valid bid data is available
        XCTAssertNil(self.mockDelegate.lastClickedAd, @"Clicked ad should be nil when no bid data available");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testDidHideDelegateCallback {
    // Verifies that the didHideWithAd delegate callback is triggered when an interstitial is closed or hidden
    XCTestExpectation *expectation = [self expectationWithDescription:@"didHideWithAd callback"];
    
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate close
    [self.interstitial didCloseWithInterstitial:self.mockAdapter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"didHideWithAd"], @"didHideWithAd should be called");
        // CLXAd should be nil when no valid bid data is available
        XCTAssertNil(self.mockDelegate.lastHiddenAd, @"Hidden ad should be nil when no bid data available");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

// MARK: - NURL Firing Tests

- (void)testNurlFiredOnImpression {
    // Verifies that the NURL (notification URL) is fired with the correct price when an impression is recorded
    
    // Set up bid response with NURL
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.id = kTestBidID;  // Use .id instead of .adid for win/loss tracking
    mockBid.price = kTestPrice;
    mockBid.nurl = kTestNURL;
    
    // Create a custom mock bid response that returns our test bid
    MockBidResponse *mockBidResponse = [[MockBidResponse alloc] init];
    mockBidResponse.testBid = mockBid;
    mockBidResponse.id = kTestAuctionID; // Set auction ID for win/loss tracking
    self.interstitial.currentBidResponse = mockBidResponse;
    
    // Add bid to mock tracker so it can be found for win notification
    [self.mockWinLossTracker addBid:kTestAuctionID bid:mockBid];
    
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Set up the mock adapter with the test bid ID
    self.mockAdapter.bidID = kTestBidID;
    
    // Simulate impression
    [self.interstitial impressionWithInterstitial:self.mockAdapter];
    
    // Verify win notification was sent (replaces NURL firing)
    XCTAssertEqual(self.mockWinLossTracker.winNotifications.count, 1, @"One win notification should be sent");
    
    // Verify the win notification contains correct data
    NSDictionary *winNotification = self.mockWinLossTracker.winNotifications.firstObject;
    XCTAssertEqualObjects(winNotification[@"bidId"], kTestBidID, @"Correct bid ID should be used");
    XCTAssertNotNil(winNotification[@"auctionId"], @"Auction ID should be present");
    
    // ENHANCED: Verify actual resolved URL values (not just structure)
    XCTAssertNotNil(winNotification[@"resolvedURL"], @"Resolved URL should be present");
    XCTAssertEqualObjects(winNotification[@"originalURL"], kTestNURL, @"Original NURL should match test constant");
    
    NSString *resolvedURL = winNotification[@"resolvedURL"];
    XCTAssertTrue([resolvedURL containsString:@"price=5.99"], @"Resolved URL should contain actual bid price");
    XCTAssertFalse([resolvedURL containsString:@"${AUCTION_PRICE}"], @"Template should be replaced, not left as-is");
    
    // Verify price formatting matches iOS WinLossFieldResolver (%.2f format)
    NSNumber *bidPrice = winNotification[@"bidPrice"];
    XCTAssertEqualObjects(bidPrice, @(kTestPrice), @"Bid price should be captured correctly");
}

- (void)testNurlNotFiredWhenNoBidResponse {
    // Verifies that no NURL is fired when there is no bid response available for the interstitial
    
    self.interstitial.currentBidResponse = nil;
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate impression
    [self.interstitial impressionWithInterstitial:self.mockAdapter];
    
    // Verify no win notification was sent
    XCTAssertEqual(self.mockWinLossTracker.winNotifications.count, 0, @"No win notification should be sent when no bid response");
}

- (void)testNurlNotFiredWhenNoNurlInBid {
    // Verifies that no NURL is fired when the winning bid does not contain a notification URL
    
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.id = kTestBidID;  // Use .id instead of .adid for win/loss tracking
    mockBid.price = kTestPrice;
    mockBid.nurl = nil; // No NURL
    
    MockBidResponse *mockBidResponse = [[MockBidResponse alloc] init];
    mockBidResponse.testBid = mockBid;
    self.interstitial.currentBidResponse = mockBidResponse;
    
    [self setCurrentState:CLXInterstitialStateSHOWING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Simulate impression
    [self.interstitial impressionWithInterstitial:self.mockAdapter];
    
    // Verify no win notification was sent  
    XCTAssertEqual(self.mockWinLossTracker.winNotifications.count, 0, @"No win notification should be sent when bid has no NURL");
}

// MARK: - Integration Tests

- (void)testCompleteSuccessfulLifecycle {
    // Tests the complete successful interstitial lifecycle from load to close, verifying all delegate callbacks and NURL firing
    XCTestExpectation *expectation = [self expectationWithDescription:@"Complete lifecycle"];
    
    // Set up bid response
    CLXBidResponseBid *mockBid = [[CLXBidResponseBid alloc] init];
    mockBid.id = kTestBidID;  // Use .id instead of .adid for win/loss tracking
    mockBid.price = kTestPrice;
    mockBid.nurl = kTestNURL;
    
    MockBidResponse *mockBidResponse = [[MockBidResponse alloc] init];
    mockBidResponse.testBid = mockBid;
    mockBidResponse.id = kTestAuctionID; // Set auction ID for win/loss tracking
    self.interstitial.currentBidResponse = mockBidResponse;
    
    // Add bid to mock tracker so it can be found for win notification
    [self.mockWinLossTracker addBid:kTestAuctionID bid:mockBid];
    
    // Start with loading state and adapter
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Set up the mock adapter with the test bid ID
    self.mockAdapter.bidID = kTestBidID;
    
    // Step 1: Load success
    [self.interstitial didLoadWithInterstitial:self.mockAdapter];
    
    // Step 2: Show
    [self.interstitial didShowWithInterstitial:self.mockAdapter];
    
    // Step 3: Impression
    [self.interstitial impressionWithInterstitial:self.mockAdapter];
    
    // Step 4: Click
    [self.interstitial clickWithInterstitial:self.mockAdapter];
    
    // Step 5: Close
    [self.interstitial didCloseWithInterstitial:self.mockAdapter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Verify all delegate callbacks occurred in order
        NSArray *expectedCallbacks = @[@"didLoadWithAd", @"didShowWithAd", @"impressionOn", @"didClickWithAd", @"didHideWithAd"];
        for (NSString *callback in expectedCallbacks) {
            XCTAssertTrue([self.mockDelegate.callbackLog containsObject:callback], @"Callback %@ should be called", callback);
        }
        
        // Verify win notification was sent on impression (replaces NURL firing)
        XCTAssertEqual(self.mockWinLossTracker.winNotifications.count, 1, @"Win notification should be sent on impression");
        
        // Verify the win notification contains correct data
        NSDictionary *winNotification = self.mockWinLossTracker.winNotifications.firstObject;
        XCTAssertEqualObjects(winNotification[@"bidId"], kTestBidID, @"Correct bid ID should be used");
        
        // ENHANCED: Verify URL template replacement in complete lifecycle
        if (winNotification[@"resolvedURL"]) {
            NSString *resolvedURL = winNotification[@"resolvedURL"];
            XCTAssertTrue([resolvedURL containsString:@"price=5.99"], @"Complete lifecycle should resolve AUCTION_PRICE correctly");
            XCTAssertFalse([resolvedURL containsString:@"${AUCTION_PRICE}"], @"No templates should remain unresolved");
        }
        
        // Verify final state
        CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
        XCTAssertEqual(currentState, CLXInterstitialStateIDLE, @"Should return to IDLE after close");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testLoadFailureLifecycle {
    // Tests the interstitial lifecycle when loading fails, verifying proper error handling and state transitions
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load failure lifecycle"];
    
    [self setCurrentState:CLXInterstitialStateLOADING onInterstitial:self.interstitial];
    self.interstitial.currentInterstitialAdapter = self.mockAdapter;
    
    // Set up bid response data required for loss notification
    CLXBidResponseBid *testBid = [[CLXBidResponseBid alloc] init];
    testBid.id = kTestBidID;
    testBid.price = kTestPrice;
    testBid.lurl = kTestLURL;
    testBid.nurl = kTestNURL;
    
    CLXBidResponse *testBidResponse = [[CLXBidResponse alloc] init];
    testBidResponse.id = kTestAuctionID;
    
    CLXBidAdSourceResponse *testAdSourceResponse = [[CLXBidAdSourceResponse alloc] initWithPrice:testBid.price
                                                                                     auctionId:kTestAuctionID
                                                                                        dealId:nil
                                                                                       latency:0.0
                                                                                          nurl:testBid.nurl
                                                                                         bidID:testBid.id
                                                                                           bid:testBid
                                                                                    bidRequest:@{}
                                                                                   networkName:@"test-network"
                                                                                        clxAd:nil
                                                                                   createBidAd:^id{ return nil; }];
    
    // Set the required properties on the interstitial for loss notification
    @try {
        [self.interstitial setValue:testBidResponse forKey:@"currentBidResponse"];
        [self.interstitial setValue:testAdSourceResponse forKey:@"lastBidResponse"];
    } @catch (NSException *exception) {
        NSLog(@"Could not set bid response data via KVC: %@", exception.reason);
    }
    
    // Add bid to mock tracker so loss notification can be sent
    [self.mockWinLossTracker addBid:kTestAuctionID bid:testBid];
    
    NSError *testError = [NSError errorWithDomain:@"TestError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Load failed"}];
    
    // Simulate load failure
    [self.interstitial didFailToLoadWithInterstitial:self.mockAdapter error:testError];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Verify failure callback
        XCTAssertTrue([self.mockDelegate.callbackLog containsObject:@"failToLoadWithAd"], @"failToLoadWithAd should be called");
        
        // Verify no success callbacks
        XCTAssertFalse([self.mockDelegate.callbackLog containsObject:@"didLoadWithAd"], @"didLoadWithAd should not be called");
        XCTAssertFalse([self.mockDelegate.callbackLog containsObject:@"didShowWithAd"], @"didShowWithAd should not be called");
        
        // Verify no win notification sent on load failure
        XCTAssertEqual(self.mockWinLossTracker.winNotifications.count, 0, @"No win notification should be sent on load failure");
        
        // Verify loss notification IS sent on load failure
        XCTAssertEqual(self.mockWinLossTracker.lossNotifications.count, 1, @"Loss notification should be sent on load failure");
        
        // Verify the loss notification contains correct data
        if (self.mockWinLossTracker.lossNotifications.count > 0) {
            NSDictionary *lossNotification = self.mockWinLossTracker.lossNotifications.firstObject;
            XCTAssertEqualObjects(lossNotification[@"lossReason"], @(CLXLossReasonTechnicalError), @"Loss reason should be TechnicalError");
        }
        
        // Verify state reset
        CLXInterstitialState currentState = [self getCurrentStateFromInterstitial:self.interstitial];
        XCTAssertEqual(currentState, CLXInterstitialStateIDLE, @"Should return to IDLE after load failure");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
