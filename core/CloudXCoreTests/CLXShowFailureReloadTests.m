//
//  CLXShowFailureReloadTests.m
//  CloudXCoreTests
//
//  Unit tests verifying that fullscreen ads can be reloaded immediately
//  after show failure. Tests the fix for state not being cleared before
//  didFailToDisplayAd callback - matching Android PR #112.
//
//  Design: Pure state machine tests with zero external dependencies.
//  - No network calls
//  - No SQLite (mocked in-memory)
//  - No real adapters
//  - Deterministic, fast (< 50ms total)
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdEventReporter.h>

#pragma mark - Expose Private State for Verification

typedef NS_ENUM(NSInteger, CLXFullscreenAdState) {
    CLXFullscreenAdStateIDLE,
    CLXFullscreenAdStateLOADING,
    CLXFullscreenAdStateREADY,
    CLXFullscreenAdStateSHOWING,
    CLXFullscreenAdStateDESTROYED
};

@interface CLXPublisherFullscreenAdBase (Testing)
@property (nonatomic, assign) CLXFullscreenAdState currentState;
@end

#pragma mark - Expose Adapter Delegate Method for Testing

@interface CLXInterstitial (Testing) <CLXAdapterInterstitialDelegate>
@end

#pragma mark - Minimal Test Delegate (No Logic, Just Capture)

@interface ReloadInCallbackDelegate : NSObject <CLXInterstitialDelegate>
@property (nonatomic, copy) void (^onFailToDisplay)(CLXAd *ad, NSError *error);
@end

@implementation ReloadInCallbackDelegate

- (void)didFailToDisplayAd:(CLXAd *)ad error:(NSError *)error {
    if (self.onFailToDisplay) self.onFailToDisplay(ad, error);
}

// Required protocol stubs - no logic, no assertions
- (void)didLoadAd:(CLXAd *)ad {}
- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {}
- (void)didDisplayAd:(CLXAd *)ad {}
- (void)didHideAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didRecordImpressionForAd:(CLXAd *)ad {}
- (void)closedByUserActionWithAd:(CLXAd *)ad {}

@end

#pragma mark - Null Reporter (Conforms to Protocol, Does Nothing)

@interface CLXNullReporter : NSObject <CLXAdEventReporting>
@end

@implementation CLXNullReporter
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
@end

#pragma mark - Mock Adapter (Conforms to Protocol, Does Nothing)

@interface CLXMockInterstitialAdapter : NSObject <CLXAdapterInterstitial>
@property (nonatomic, weak) id<CLXAdapterInterstitialDelegate> delegate;
@end

@implementation CLXMockInterstitialAdapter
- (NSString *)sdkVersion { return @"1.0.0"; }
- (NSString *)network { return @"mock"; }
- (NSString *)bidID { return @"mock-bid-id"; }
- (void)load {}
- (void)showFromViewController:(UIViewController *)viewController {}
@end

#pragma mark - Test Class

@interface CLXShowFailureReloadTests : XCTestCase
@property (nonatomic, strong) CLXNullReporter *nullReporter;
@property (nonatomic, strong) CLXMockInterstitialAdapter *mockAdapter;
@end

@implementation CLXShowFailureReloadTests

#pragma mark - Setup/Teardown (Database Isolation)

- (void)setUp {
    [super setUp];
    // Null reporter: conforms to protocol, does nothing
    self.nullReporter = [[CLXNullReporter alloc] init];
    // Mock adapter: conforms to protocol, does nothing
    self.mockAdapter = [[CLXMockInterstitialAdapter alloc] init];
}

- (void)tearDown {
    self.nullReporter = nil;
    self.mockAdapter = nil;
    [super tearDown];
}

#pragma mark - Factory (Null Dependencies = No Side Effects)

- (CLXInterstitial *)createInterstitialWithNullDependencies {
    CLXSDKConfigAdUnit *placement = [[CLXSDKConfigAdUnit alloc] init];
    placement.id = @"test-placement";
    
    // ALL external dependencies are nil or minimal mocks
    return [[CLXInterstitial alloc] initWithAdUnit:placement
                                          publisherID:@"test"
                                               userID:@"test"
                                  rewardedCallbackUrl:nil
                                             impModel:[[CLXConfigImpressionModel alloc] init]
                                          adFactories:nil                              // No adapters
                                      bidTokenSources:@{}                              // No tokens
                                   bidRequestTimeout:1.0
                                    reportingService:self.nullReporter                 // Null reporter (no network)
                                            settings:[[CLXSettings alloc] init]];
}

#pragma mark - Test 1: State Is IDLE After Show Failure

/// Verifies show failure resets state to IDLE, enabling immediate reload.
/// This is the root cause fix - state was stuck at SHOWING before this PR.
- (void)testInterstitial_stateIsIdleAfterShowFailure {
    // Arrange: Create isolated interstitial with null dependencies
    CLXInterstitial *interstitial = [self createInterstitialWithNullDependencies];
    
    // Arrange: Simulate state after show() was called
    interstitial.currentState = CLXFullscreenAdStateSHOWING;
    
    // Act: Simulate adapter reporting show failure
    [interstitial didFailToShowWithInterstitial:self.mockAdapter 
                                          error:[NSError errorWithDomain:@"test" code:1 userInfo:nil]];
    
    // Assert: State must be IDLE (not SHOWING) - this is the fix
    XCTAssertEqual(interstitial.currentState, CLXFullscreenAdStateIDLE,
                   @"State must be IDLE after show failure to allow immediate reload");
}

#pragma mark - Test 2: State Is IDLE When didFailToDisplayAd Callback Fires

/// Verifies the state is IDLE when the didFailToDisplayAd callback fires.
/// This enables publishers to call load() in the callback - the exact use case
/// that was broken before this PR.
- (void)testInterstitial_stateIsIdleWhenCallbackFires {
    // Capture variables for verification
    __block BOOL callbackInvoked = NO;
    __block CLXFullscreenAdState stateWhenCallbackFired = CLXFullscreenAdStateSHOWING;
    
    // Arrange: Create isolated interstitial
    CLXInterstitial *interstitial = [self createInterstitialWithNullDependencies];
    
    // Arrange: Create delegate that captures state when callback fires
    ReloadInCallbackDelegate *delegate = [[ReloadInCallbackDelegate alloc] init];
    delegate.onFailToDisplay = ^(CLXAd *ad, NSError *error) {
        // Capture state at callback time (should be IDLE if fix works)
        stateWhenCallbackFired = interstitial.currentState;
        callbackInvoked = YES;
    };
    interstitial.delegate = delegate;
    
    // Arrange: Simulate state after show() was called
    interstitial.currentState = CLXFullscreenAdStateSHOWING;
    
    // Act: Simulate adapter reporting show failure
    [interstitial didFailToShowWithInterstitial:self.mockAdapter 
                                          error:[NSError errorWithDomain:@"test" code:1 userInfo:nil]];
    
    // Act: Drain main queue to deliver async callback (deterministic, < 50ms)
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    
    // Assert: Callback was invoked
    XCTAssertTrue(callbackInvoked, @"didFailToDisplayAd callback must be invoked");
    
    // Assert: State was IDLE when callback fired (the fix)
    // This is the key assertion - before the fix, state was still SHOWING
    XCTAssertEqual(stateWhenCallbackFired, CLXFullscreenAdStateIDLE,
                   @"State must be IDLE when callback fires to allow reload");
}

@end
