/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
@import AppLovinSDK;
@import CloudXCore;

static NSString *const kApplovinAppKey = @"CZ_XxS0v1pDXVdV2yDXaxO4dOV8849QwTq7iDFlGLsJZngU95AEyaq2z8lF0GRlSvdknWDpTDp1GmprFC1FiJ1";
/*
 * AppLovin test ad unit ID. Works for all ad formats (banner, interstitial, rewarded)
 * on both iOS Simulator and Android Emulator. Returns test ads without needing a real ad unit.
 */
static NSString *const kAdUnitId = @"testAdUnitId";
static NSString *const kTestEndpointUrl = @"https://test.example.com/ilrd";

#pragma mark - Spy network service (inline)

@interface SpyCLXIlrdNetworkService : NSObject <CLXIlrdNetworkServiceProtocol>

@property (nonatomic, assign) NSInteger sendCallCount;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *lastPayload;
@property (nonatomic, copy, nullable) NSString *lastAppKey;
@property (nonatomic, strong, nullable) XCTestExpectation *sendExpectation;

@end

@implementation SpyCLXIlrdNetworkService

- (instancetype)init {
    self = [super init];
    if (self) {
        _sendCallCount = 0;
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    _sendCallCount++;
    _lastAppKey = [appKey copy];
    _lastPayload = [payload copy];

    if (completion) {
        completion(YES, nil);
    }

    [self.sendExpectation fulfill];
}

@end

#pragma mark - Test class

@interface CLXIlrdTrackerEndToEndTest : XCTestCase <MAAdDelegate>

@property (nonatomic, strong) CLXAlIlrd *ilrdProvider;
@property (nonatomic, strong) CLXIlrdService *ilrdService;
@property (nonatomic, strong) CLXIlrdTracker *tracker;
@property (nonatomic, strong) SpyCLXIlrdNetworkService *spyNetworkService;
@property (nonatomic, strong) MAInterstitialAd *interstitialAd;
@property (nonatomic, strong) XCTestExpectation *adDisplayedExpectation;
@property (nonatomic, strong) UIWindow *testWindow;
@property (nonatomic, strong) UIViewController *testViewController;

@end

@implementation CLXIlrdTrackerEndToEndTest

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;

    /*
     * Create a window + root VC for the test runner process.
     * The UI test runner has no key window by default,
     * so AppLovin cannot find a VC to present from.
     */
    self.testViewController = [[UIViewController alloc] init];
    self.testWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.testWindow.rootViewController = self.testViewController;
    [self.testWindow makeKeyAndVisible];

    XCTestExpectation *sdkInitExpectation = [self expectationWithDescription:@"AppLovin SDK initialized"];

    ALSdkInitializationConfiguration *config =
        [ALSdkInitializationConfiguration configurationWithSdkKey:kApplovinAppKey builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {
            builder.mediationProvider = ALMediationProviderMAX;
        }];

    ALSdk *sdk = [ALSdk shared];
    sdk.settings.verboseLoggingEnabled = YES;
    [sdk initializeWithConfiguration:config completionHandler:^(ALSdkConfiguration *sdkConfig) {
        NSLog(@"AppLovin SDK initialized: %@", sdkConfig);
        [sdkInitExpectation fulfill];
    }];

    [self waitForExpectations:@[sdkInitExpectation] timeout:30.0];

    /* Wire the full chain: provider -> service -> tracker -> spy network service */
    self.ilrdProvider = [[CLXAlIlrd alloc] initWithAccountName:@"test-account"];

    self.ilrdService = [[CLXIlrdService alloc] initWithProviders:@{
        @(CLXIlrdPlatformAl): self.ilrdProvider,
    }];

    self.spyNetworkService = [[SpyCLXIlrdNetworkService alloc] init];

    self.tracker = [[CLXIlrdTracker alloc] initWithAppKey:kApplovinAppKey
                                                accountId:@"test-account"
                                                sessionId:@"test-session"
                                               sdkVersion:@"2.0.0-test"
                                              endpointUrl:kTestEndpointUrl
                                              ilrdService:self.ilrdService
                                           networkService:self.spyNetworkService];
}

- (void)tearDown {
    [self.tracker stop];

    if (self.testViewController.presentedViewController) {
        [self.testViewController dismissViewControllerAnimated:NO completion:nil];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }

    self.interstitialAd = nil;
    self.tracker = nil;
    self.ilrdService = nil;
    self.ilrdProvider = nil;
    self.spyNetworkService = nil;
    self.testWindow.hidden = YES;
    self.testWindow = nil;
    self.testViewController = nil;
    [super tearDown];
}

- (void)testIlrdJsonPayloadSentWhenInterstitialShown {
    // Arrange
    self.spyNetworkService.sendExpectation = [self expectationWithDescription:@"Network service received payload"];
    self.adDisplayedExpectation = [self expectationWithDescription:@"Ad displayed"];

    [self.tracker start];

    // Act
    self.interstitialAd = [[MAInterstitialAd alloc] initWithAdUnitIdentifier:kAdUnitId];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAd];

    [self waitForExpectations:@[self.adDisplayedExpectation] timeout:30.0];
    [self waitForExpectations:@[self.spyNetworkService.sendExpectation] timeout:30.0];

    // Assert - payload fields
    NSDictionary<NSString *, id> *payload = self.spyNetworkService.lastPayload;
    XCTAssertNotNil(payload, @"Payload should not be nil");

    /* Provider event fields */
    NSNumber *timestamp = payload[@"timestamp"];
    XCTAssertNotNil(timestamp, @"timestamp should be present");
    XCTAssertGreaterThan(timestamp.doubleValue, 0, @"timestamp should be positive");

    XCTAssertEqualObjects(payload[@"platform"], @"AppLovin", @"platform should be AppLovin");

    NSNumber *revenue = payload[@"revenue"];
    XCTAssertNotNil(revenue, @"revenue should be present");

    XCTAssertNotNil(payload[@"adFormat"], @"adFormat should be present (camelCase)");

    /* SDK identity fields */
    XCTAssertEqualObjects(payload[@"accountId"], @"test-account", @"accountId should be set");
    XCTAssertEqualObjects(payload[@"sessionId"], @"test-session", @"sessionId should be set");
    XCTAssertEqualObjects(payload[@"os"], @"ios", @"os should be ios");
    XCTAssertEqualObjects(payload[@"sdkVersion"], @"2.0.0-test", @"sdkVersion should be set");

    /* Tracker passed correct appKey */
    XCTAssertEqualObjects(self.spyNetworkService.lastAppKey, kApplovinAppKey, @"appKey should match");
}

#pragma mark - MAAdDelegate

- (void)didLoadAd:(MAAd *)ad {
    NSLog(@"didLoadAd: %@, network: %@", ad.adUnitIdentifier, ad.networkName);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showAdForPlacement:nil customData:nil viewController:self.testViewController];
    });
}

- (void)didDisplayAd:(MAAd *)ad {
    NSLog(@"didDisplayAd: %@", ad.adUnitIdentifier);
    [self.adDisplayedExpectation fulfill];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    NSLog(@"didFailToLoadAd: %@, code: %ld, message: %@", adUnitIdentifier, (long)error.code, error.message);
    XCTFail(@"Failed to load ad: %@", error.message);
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    NSLog(@"didFailToDisplayAd: %@, code: %ld, message: %@", ad.adUnitIdentifier, (long)error.code, error.message);
    XCTFail(@"Failed to display ad: %@", error.message);
}

- (void)didClickAd:(MAAd *)ad {}
- (void)didHideAd:(MAAd *)ad {}

@end
