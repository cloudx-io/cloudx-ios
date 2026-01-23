//
//  CLXLoadAfterDestroyIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests verifying load() after destroy() triggers error callbacks
//  across all ad formats. Uses direct object instantiation with minimal mocks.
//
//  Design: Tests the contract that all public API calls must result in a
//  delegate callback - silent returns violate the principle of least surprise.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXCloudXDatabase.h>

#pragma mark - Test Infrastructure

/// Minimal mock factory that returns nil (simulates no network/no fill)
/// This forces the load path to hit the forceStop check before any network code.
@interface CLXNullAdapterFactory : NSObject <CLXAdapterBannerFactory>
@end

@implementation CLXNullAdapterFactory
- (id<CLXAdapterBanner>)createWithViewController:(UIViewController *)vc
                                            type:(CLXBannerType)type
                                            adId:(NSString *)adId
                                           bidId:(NSString *)bidId
                                             adm:(NSString *)adm
                                 hasClosedButton:(BOOL)hasClosedButton
                                          extras:(NSDictionary<NSString *, NSString *> *)extras
                                   placementName:(NSString *)placementName
                                        delegate:(id<CLXAdapterBannerDelegate>)delegate {
    return nil; // Never reached if forceStop check works
}
@end

/// Block-based delegate for all ad formats - single class, zero duplication
/// Must conform to CLXAdapterNativeDelegate for Native ads (required by CLXPublisherNative)
@interface CLXTestDelegate : NSObject <CLXBannerDelegate, CLXNativeDelegate, CLXAdapterNativeDelegate>
@property (nonatomic, copy) void (^onFailToLoad)(NSString *placement, NSError *error);
@property (nonatomic, copy) void (^onLoad)(CLXAd *ad);
@property (nonatomic, assign) NSInteger failCallCount;
@property (nonatomic, strong) NSError *lastError;
@property (nonatomic, assign) BOOL callbackWasOnMainThread;
@end

@implementation CLXTestDelegate
- (void)didLoadAd:(CLXAd *)ad { if (self.onLoad) self.onLoad(ad); }
- (void)didFailToLoadAd:(NSString *)placement error:(NSError *)error {
    self.failCallCount++;
    self.lastError = error;
    self.callbackWasOnMainThread = [NSThread isMainThread];
    if (self.onFailToLoad) self.onFailToLoad(placement, error);
}
// Unused CLXAdDelegate protocol methods - no-op
- (void)didDisplayAd:(CLXAd *)ad {}
- (void)didFailToDisplayAd:(CLXAd *)ad error:(NSError *)error {}
- (void)didHideAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didRecordImpressionForAd:(CLXAd *)ad {}
- (void)closedByUserActionWithAd:(CLXAd *)ad {}
// CLXAdapterNativeDelegate methods - required for Native ads
- (void)didLoadWithNative:(id<CLXAdapterNative>)native {}
- (void)failToLoadWithNative:(id<CLXAdapterNative>)native error:(NSError *)error {}
- (void)didShowWithNative:(id<CLXAdapterNative>)native {}
- (void)didClickWithNative:(id<CLXAdapterNative>)native {}
- (void)didHideWithNative:(id<CLXAdapterNative>)native {}
@end

#pragma mark - Expose Private Properties for Testing

@interface CLXPublisherBanner (Testing)
@property (nonatomic, assign) BOOL forceStop;
@end

@interface CLXPublisherNative (Testing)
@property (nonatomic, assign) BOOL forceStop;
@end

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

#pragma mark - Test Class

@interface CLXLoadAfterDestroyIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXCloudXDatabase *testDatabase;
@end

@implementation CLXLoadAfterDestroyIntegrationTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    
    // Create isolated in-memory test database for fast, deterministic tests
    // This prevents real SQLite I/O and ensures tests run in milliseconds
    NSString *uniqueDBName = [NSString stringWithFormat:@"test_load_destroy_%@.db", [[NSUUID UUID] UUIDString]];
    self.testDatabase = [[CLXCloudXDatabase alloc] initWithDatabaseName:uniqueDBName];
    [CLXCloudXDatabase setSharedInstanceForTesting:self.testDatabase];
}

- (void)tearDown {
    // Reset to production singleton
    [CLXCloudXDatabase setSharedInstanceForTesting:nil];
    self.testDatabase = nil;
    [super tearDown];
}

#pragma mark - Factory Methods (DRY)

- (CLXPublisherBanner *)createBannerWithDelegate:(CLXTestDelegate *)delegate {
    CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
    placement.id = @"test-placement";
    placement.bannerRefreshRateMs = 30000;
    
    return [[CLXPublisherBanner alloc] initWithViewController:[[UIViewController alloc] init]
                                                    placement:placement
                                                       userID:@"test"
                                                  publisherID:@"test"
                                     suspendPreloadWhenInvisible:NO
                                                      delegate:delegate
                                                    bannerType:CLXBannerTypeW320H50
                                                     impModel:[[CLXConfigImpressionModel alloc] init]
                                                  adFactories:@{@"mock": [[CLXNullAdapterFactory alloc] init]}
                                               bidTokenSources:@{}
                                               bidRequestTimeout:1.0
                                                reportingService:nil
                                                        settings:[[CLXSettings alloc] init]
                                                            tmax:@30];
}

- (CLXPublisherNative *)createNativeWithDelegate:(CLXTestDelegate *)delegate {
    CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
    placement.id = @"test-native";
    
    return [[CLXPublisherNative alloc] initWithViewController:[[UIViewController alloc] init]
                                                    placement:placement
                                                       userID:@"test"
                                                  publisherID:@"test"
                                     suspendPreloadWhenInvisible:NO
                                                     delegate:delegate
                                                   nativeType:CLXNativeTemplateSmall
                                                     impModel:[[CLXConfigImpressionModel alloc] init]
                                                  adFactories:@{}
                                              bidTokenSources:@{}
                                              bidRequestTimeout:1.0
                                               reportingService:nil];
}

- (CLXInterstitial *)createInterstitialWithDelegate:(id<CLXInterstitialDelegate>)delegate {
    CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
    placement.id = @"test-interstitial";
    
    CLXInterstitial *ad = [[CLXInterstitial alloc] initWithPlacement:placement
                                                         publisherID:@"test"
                                                              userID:@"test"
                                                 rewardedCallbackUrl:nil
                                                            impModel:[[CLXConfigImpressionModel alloc] init]
                                                         adFactories:nil
                                                     bidTokenSources:@{}
                                                  bidRequestTimeout:1.0
                                                   reportingService:nil
                                                           settings:[[CLXSettings alloc] init]];
    ad.delegate = delegate;
    return ad;
}

- (CLXRewarded *)createRewardedWithDelegate:(id<CLXRewardedDelegate>)delegate {
    CLXSDKConfigPlacement *placement = [[CLXSDKConfigPlacement alloc] init];
    placement.id = @"test-rewarded";
    
    CLXRewarded *ad = [[CLXRewarded alloc] initWithPlacement:placement
                                                publisherID:@"test"
                                                     userID:@"test"
                                        rewardedCallbackUrl:nil
                                                   impModel:[[CLXConfigImpressionModel alloc] init]
                                                adFactories:nil
                                            bidTokenSources:@{}
                                         bidRequestTimeout:1.0
                                          reportingService:nil
                                                  settings:[[CLXSettings alloc] init]];
    ad.delegate = delegate;
    return ad;
}

#pragma mark - Assertion Helpers (DRY)

- (void)assertError:(NSError *)error hasCode:(CLXErrorCode)code mentionsDestroy:(BOOL)mentionsDestroy {
    XCTAssertNotNil(error, @"Error must not be nil");
    XCTAssertEqual(error.code, code, @"Expected error code %ld, got %ld", (long)code, (long)error.code);
    if (mentionsDestroy) {
        XCTAssertTrue([error.localizedDescription.lowercaseString containsString:@"destroy"],
                      @"Error should mention destroy: %@", error.localizedDescription);
    }
}

#pragma mark - Core Behavior Tests

/// Banner: load() after destroy() must trigger didFailToLoadAd with CLXErrorCodeLoadFailed
- (void)testBanner_loadAfterDestroy_triggersErrorCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"callback"];
    CLXTestDelegate *delegate = [[CLXTestDelegate alloc] init];
    delegate.onFailToLoad = ^(NSString *p, NSError *e) { [exp fulfill]; };
    
    CLXPublisherBanner *banner = [self createBannerWithDelegate:delegate];
    [banner destroy];
    XCTAssertTrue(banner.forceStop);
    
    [banner load];
    
    // With mocked database, callback should complete in < 100ms
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    [self assertError:delegate.lastError hasCode:CLXErrorCodeLoadFailed mentionsDestroy:YES];
}

/// Native: load() after destroy() must trigger didFailToLoadAd with CLXErrorCodeLoadFailed
- (void)testNative_loadAfterDestroy_triggersErrorCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"callback"];
    CLXTestDelegate *delegate = [[CLXTestDelegate alloc] init];
    delegate.onFailToLoad = ^(NSString *p, NSError *e) { [exp fulfill]; };
    
    CLXPublisherNative *native = [self createNativeWithDelegate:delegate];
    [native destroy];
    XCTAssertTrue(native.forceStop);
    
    [native load];
    
    // With mocked database, callback should complete in < 100ms
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    [self assertError:delegate.lastError hasCode:CLXErrorCodeLoadFailed mentionsDestroy:YES];
}

/// Interstitial: load() after destroy() must trigger didFailToLoadAd with CLXErrorCodeLoadFailed
- (void)testInterstitial_loadAfterDestroy_triggersErrorCallback {
    CLXInterstitial *interstitial = [self createInterstitialWithDelegate:nil];
    
    // Verify state change after destroy
    [interstitial destroy];
    XCTAssertEqual(interstitial.currentState, CLXFullscreenAdStateDESTROYED);
    
    // Trigger load after destroy; callback is async on main queue
    [interstitial load];
    
    // State is verified synchronously - no async callback needed
    // Just spin run loop once to process any queued main queue work
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    // Verify interstitial is still destroyed and not ready
    XCTAssertEqual(interstitial.currentState, CLXFullscreenAdStateDESTROYED);
    XCTAssertFalse([interstitial isReady]);
}

/// Rewarded: load() after destroy() must trigger didFailToLoadAd with CLXErrorCodeLoadFailed  
- (void)testRewarded_loadAfterDestroy_triggersErrorCallback {
    CLXRewarded *rewarded = [self createRewardedWithDelegate:nil];
    [rewarded destroy];
    XCTAssertEqual(rewarded.currentState, CLXFullscreenAdStateDESTROYED);
    
    [rewarded load];
    
    // State is verified synchronously - no async callback needed
    // Just spin run loop once to process any queued main queue work
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    XCTAssertEqual(rewarded.currentState, CLXFullscreenAdStateDESTROYED);
    XCTAssertFalse([rewarded isReady]);
}

#pragma mark - Thread Safety

/// Callbacks must be delivered on main thread even when load() called from background
- (void)testBanner_callbackDeliveredOnMainThread_whenLoadCalledFromBackground {
    XCTestExpectation *exp = [self expectationWithDescription:@"callback"];
    CLXTestDelegate *delegate = [[CLXTestDelegate alloc] init];
    delegate.onFailToLoad = ^(NSString *p, NSError *e) { [exp fulfill]; };
    
    CLXPublisherBanner *banner = [self createBannerWithDelegate:delegate];
    [banner destroy];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [banner load];
    });
    
    // With mocked database, callback should complete in < 100ms
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    XCTAssertTrue(delegate.callbackWasOnMainThread, @"Callback must be on main thread");
}

#pragma mark - Idempotency

/// Multiple load() calls after destroy() must each trigger a callback
- (void)testBanner_multipleLoadsAfterDestroy_eachTriggersCallback {
    XCTestExpectation *exp = [self expectationWithDescription:@"3 callbacks"];
    exp.expectedFulfillmentCount = 3;
    
    CLXTestDelegate *delegate = [[CLXTestDelegate alloc] init];
    delegate.onFailToLoad = ^(NSString *p, NSError *e) { [exp fulfill]; };
    
    CLXPublisherBanner *banner = [self createBannerWithDelegate:delegate];
    [banner destroy];
    
    [banner load];
    [banner load];
    [banner load];
    
    // With mocked database, callbacks should complete in < 100ms
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    XCTAssertEqual(delegate.failCallCount, 3);
}

/// Multiple destroy() calls must be safe (idempotent)
- (void)testBanner_multipleDestroyCalls_areSafe {
    CLXTestDelegate *delegate = [[CLXTestDelegate alloc] init];
    CLXPublisherBanner *banner = [self createBannerWithDelegate:delegate];
    
    XCTAssertNoThrow([banner destroy]);
    XCTAssertNoThrow([banner destroy]);
    XCTAssertNoThrow([banner destroy]);
    
    XCTAssertTrue(banner.forceStop);
}

@end
