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

typedef NS_ENUM(NSInteger, CLXActiveAdType) {
    CLXActiveAdTypeBanner,
    CLXActiveAdTypeInterstitial,
    CLXActiveAdTypeRewarded,
};

@interface CLXAlIlrdTest : XCTestCase <MAAdDelegate, MAAdViewAdDelegate, MARewardedAdDelegate>
@property (nonatomic, strong) CLXAlIlrd *ilrdProvider;
@property (nonatomic, strong) MAAdView *bannerView;
@property (nonatomic, strong) MAInterstitialAd *interstitialAd;
@property (nonatomic, strong) MARewardedAd *rewardedAd;
@property (nonatomic, assign) CLXActiveAdType activeAdType;
@property (nonatomic, strong) XCTestExpectation *adDisplayedExpectation;
@property (nonatomic, strong) UIWindow *testWindow;
@property (nonatomic, strong) UIViewController *testViewController;
@end

@implementation CLXAlIlrdTest

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

    self.ilrdProvider = [[CLXAlIlrd alloc] initWithAccountName:@"test-account"];
}

- (void)tearDown {
    /*
     * Dismiss any fullscreen ad (interstitial/rewarded) that was presented modally,
     * then wait briefly for the dismissal animation to complete.
     */
    if (self.testViewController.presentedViewController) {
        [self.testViewController dismissViewControllerAnimated:NO completion:nil];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    [self.bannerView removeFromSuperview];
    self.bannerView = nil;
    self.interstitialAd = nil;
    self.rewardedAd = nil;
    self.ilrdProvider = nil;
    self.testWindow.hidden = YES;
    self.testWindow = nil;
    self.testViewController = nil;
    [super tearDown];
}

- (void)testIlrdEventSentWhenBannerShown {
    // Arrange
    NSError *subscribeError = nil;
    BOOL subscribed = [self.ilrdProvider subscribeWithError:&subscribeError];
    XCTAssertTrue(subscribed, @"Failed to subscribe: %@", subscribeError);

    XCTestExpectation *ilrdExpectation = [self expectationWithDescription:@"ILRD event received"];
    __block NSDictionary<NSString *, id> *capturedEvent = nil;

    [self.ilrdProvider setEventCallback:^(NSDictionary<NSString *, id> *event) {
        capturedEvent = event;
        [ilrdExpectation fulfill];
    }];

    // Act
    self.activeAdType = CLXActiveAdTypeBanner;
    self.bannerView = [[MAAdView alloc] initWithAdUnitIdentifier:kAdUnitId adFormat:MAAdFormat.banner];
    self.bannerView.delegate = self;
    self.bannerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.testViewController.view.bounds), 50);
    [self.testViewController.view addSubview:self.bannerView];
    [self.bannerView loadAd];

    /*
     * Banner ads don't fire didDisplayAd: on iOS, so we skip the displayed expectation
     * and just wait for the ILRD event which fires after the ad renders in the view.
     */
    [self waitForExpectations:@[ilrdExpectation] timeout:30.0];

    // Assert
    XCTAssertNotNil(capturedEvent, @"ILRD event should not be nil");
    XCTAssertEqualObjects(capturedEvent[@"platform"], @"AppLovin");
    XCTAssertNotNil(capturedEvent[@"revenue"], @"Revenue should be present");
    XCTAssertNotNil(capturedEvent[@"adFormat"], @"Ad format should be present");
}

- (void)testIlrdEventSentWhenInterstitialShown {
    // Arrange
    NSError *subscribeError = nil;
    BOOL subscribed = [self.ilrdProvider subscribeWithError:&subscribeError];
    XCTAssertTrue(subscribed, @"Failed to subscribe: %@", subscribeError);

    XCTestExpectation *ilrdExpectation = [self expectationWithDescription:@"ILRD event received"];
    __block NSDictionary<NSString *, id> *capturedEvent = nil;

    [self.ilrdProvider setEventCallback:^(NSDictionary<NSString *, id> *event) {
        capturedEvent = event;
        [ilrdExpectation fulfill];
    }];

    self.adDisplayedExpectation = [self expectationWithDescription:@"Ad displayed"];

    // Act
    self.activeAdType = CLXActiveAdTypeInterstitial;
    self.interstitialAd = [[MAInterstitialAd alloc] initWithAdUnitIdentifier:kAdUnitId];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAd];

    [self waitForExpectations:@[self.adDisplayedExpectation] timeout:30.0];
    [self waitForExpectations:@[ilrdExpectation] timeout:30.0];

    // Assert
    XCTAssertNotNil(capturedEvent, @"ILRD event should not be nil");
    XCTAssertEqualObjects(capturedEvent[@"platform"], @"AppLovin");
    XCTAssertNotNil(capturedEvent[@"revenue"], @"Revenue should be present");
    XCTAssertNotNil(capturedEvent[@"adFormat"], @"Ad format should be present");
}

- (void)testIlrdEventSentWhenRewardedShown {
    // Arrange
    NSError *subscribeError = nil;
    BOOL subscribed = [self.ilrdProvider subscribeWithError:&subscribeError];
    XCTAssertTrue(subscribed, @"Failed to subscribe: %@", subscribeError);

    XCTestExpectation *ilrdExpectation = [self expectationWithDescription:@"ILRD event received"];
    __block NSDictionary<NSString *, id> *capturedEvent = nil;

    [self.ilrdProvider setEventCallback:^(NSDictionary<NSString *, id> *event) {
        capturedEvent = event;
        [ilrdExpectation fulfill];
    }];

    self.adDisplayedExpectation = [self expectationWithDescription:@"Ad displayed"];

    // Act
    self.activeAdType = CLXActiveAdTypeRewarded;
    self.rewardedAd = [MARewardedAd sharedWithAdUnitIdentifier:kAdUnitId];
    self.rewardedAd.delegate = self;
    [self.rewardedAd loadAd];

    [self waitForExpectations:@[self.adDisplayedExpectation] timeout:30.0];
    [self waitForExpectations:@[ilrdExpectation] timeout:30.0];

    // Assert
    XCTAssertNotNil(capturedEvent, @"ILRD event should not be nil");
    XCTAssertEqualObjects(capturedEvent[@"platform"], @"AppLovin");
    XCTAssertNotNil(capturedEvent[@"revenue"], @"Revenue should be present");
    XCTAssertNotNil(capturedEvent[@"adFormat"], @"Ad format should be present");
}

#pragma mark - MAAdDelegate / MAAdViewAdDelegate / MARewardedAdDelegate

- (void)didLoadAd:(MAAd *)ad {
    NSLog(@"didLoadAd: %@, network: %@", ad.adUnitIdentifier, ad.networkName);
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (self.activeAdType) {
            case CLXActiveAdTypeBanner:
                /* Banner is already in the view hierarchy; didDisplayAd: fires once content renders. */
                break;
            case CLXActiveAdTypeInterstitial:
                [self.interstitialAd showAdForPlacement:nil customData:nil viewController:self.testViewController];
                break;
            case CLXActiveAdTypeRewarded:
                [self.rewardedAd showAdForPlacement:nil customData:nil viewController:self.testViewController];
                break;
        }
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
- (void)didExpandAd:(MAAd *)ad {}
- (void)didCollapseAd:(MAAd *)ad {}
- (void)didRewardUserForAd:(MAAd *)ad withReward:(MAReward *)reward {}

@end
