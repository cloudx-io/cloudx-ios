/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXFullscreenLoadWhileShowingTests.m
 * @brief Regression tests for load() while fullscreen ad is in SHOWING state
 *
 * When load() is called on a fullscreen ad that is currently being displayed,
 * the SDK must fire a didFailToLoadAd callback instead of silently dropping
 * the request. This prevents callers (e.g., React Native bridge) from getting
 * permanently stuck when the SHOWING state is never cleared.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXInterstitial.h>
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXError.h>

static NSString * const kTestAdUnitId = @"test-showing-ad-unit";
static const NSInteger kShowingState = 3; // CLXFullscreenAdStateSHOWING

#pragma mark - Test Categories

@interface CLXPublisherFullscreenAdBase (ShowingStateTest)
@property (nonatomic, assign) NSInteger currentState;
@end

#pragma mark - Mock Delegates

@interface ShowingStateMockInterstitialDelegate : NSObject <CLXInterstitialDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation ShowingStateMockInterstitialDelegate

- (void)didFailToLoadAd:(NSString *)adUnitId error:(NSError *)error {
    self.receivedAdUnitId = adUnitId;
    self.receivedError = error;
    if (self.failureCallback) self.failureCallback();
}

- (void)didLoadAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didDisplayAd:(CLXAd *)ad {}
- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {}
- (void)didHideAd:(CLXAd *)ad {}

@end

@interface ShowingStateMockRewardedDelegate : NSObject <CLXRewardedDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation ShowingStateMockRewardedDelegate

- (void)didFailToLoadAd:(NSString *)adUnitId error:(NSError *)error {
    self.receivedAdUnitId = adUnitId;
    self.receivedError = error;
    if (self.failureCallback) self.failureCallback();
}

- (void)didLoadAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didDisplayAd:(CLXAd *)ad {}
- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {}
- (void)didHideAd:(CLXAd *)ad {}
- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {}

@end

#pragma mark - Mock Reporting Service

@interface ShowingStateMockReportingService : NSObject <CLXAdEventReporting>
@end

@implementation ShowingStateMockReportingService
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
@end

#pragma mark - Test Class

@interface CLXFullscreenLoadWhileShowingTests : XCTestCase
@property (nonatomic, assign) BOOL originalIsInitialized;
@end

@implementation CLXFullscreenLoadWhileShowingTests

- (void)setUp {
    [super setUp];
    self.originalIsInitialized = [[CloudXCore shared] isInitialized];
    [[CloudXCore shared] setValue:@YES forKey:@"_isInitialized"];
}

- (void)tearDown {
    [[CloudXCore shared] setValue:@(self.originalIsInitialized) forKey:@"_isInitialized"];
    [super tearDown];
}

#pragma mark - Interstitial

- (void)testInterstitialLoadWhileShowingFiresFailureCallback {
    // Arrange
    ShowingStateMockInterstitialDelegate *delegate = [[ShowingStateMockInterstitialDelegate alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    ShowingStateMockReportingService *reporting = [[ShowingStateMockReportingService alloc] init];
    CLXSDKConfigAdUnit *adUnit = [[CLXSDKConfigAdUnit alloc] init];
    adUnit.id = kTestAdUnitId;

    CLXInterstitial *interstitial = [[CLXInterstitial alloc] initWithAdUnit:adUnit
                                                                publisherID:@""
                                                                     userID:@""
                                                        rewardedCallbackUrl:nil
                                                                   impModel:nil
                                                                adFactories:nil
                                                            bidTokenSources:@{}
                                                         bidRequestTimeout:2.0
                                                          reportingService:reporting
                                                                  settings:settings];
    interstitial.delegate = delegate;
    [interstitial setValue:@(kShowingState) forKey:@"currentState"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Interstitial load-while-showing failure"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [interstitial load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);
    XCTAssertEqual(delegate.receivedError.code, CLXErrorCodeLoadFailed);

    [interstitial destroy];
}

#pragma mark - Rewarded

- (void)testRewardedLoadWhileShowingFiresFailureCallback {
    // Arrange
    ShowingStateMockRewardedDelegate *delegate = [[ShowingStateMockRewardedDelegate alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    ShowingStateMockReportingService *reporting = [[ShowingStateMockReportingService alloc] init];
    CLXSDKConfigAdUnit *adUnit = [[CLXSDKConfigAdUnit alloc] init];
    adUnit.id = kTestAdUnitId;

    CLXRewarded *rewarded = [[CLXRewarded alloc] initWithAdUnit:adUnit
                                                     publisherID:@""
                                                          userID:@""
                                             rewardedCallbackUrl:nil
                                                        impModel:nil
                                                     adFactories:nil
                                                 bidTokenSources:@{}
                                              bidRequestTimeout:2.0
                                               reportingService:reporting
                                                       settings:settings];
    rewarded.delegate = delegate;
    [rewarded setValue:@(kShowingState) forKey:@"currentState"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Rewarded load-while-showing failure"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [rewarded load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);
    XCTAssertEqual(delegate.receivedError.code, CLXErrorCodeLoadFailed);

    [rewarded destroy];
}

@end
