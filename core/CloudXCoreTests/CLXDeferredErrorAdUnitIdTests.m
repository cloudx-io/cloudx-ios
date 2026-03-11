/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXDeferredErrorAdUnitIdTests.m
 * @brief Regression tests for nil adUnitId in failure callbacks
 *
 * When ad creation happens before SDK initialization (deferred init) or
 * when ad unit validation fails, failure callbacks must still include a
 * non-nil adUnitId. These tests verify that adUnitId set at creation time
 * in CloudXCoreAPI is correctly passed through to delegate callbacks for
 * all ad formats: Banner, Interstitial, Rewarded, and Native.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXInterstitial.h>
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXError.h>

static NSString * const kTestAdUnitId = @"test-deferred-ad-unit";

#pragma mark - Test Categories

@interface CLXPublisherBanner (DeferredErrorTest)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy) NSString *adUnitId;
@end

@interface CLXPublisherFullscreenAdBase (DeferredErrorTest)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy) NSString *adUnitId;
@end

@interface CLXPublisherNative (DeferredErrorTest)
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, copy) NSString *adUnitId;
@end

#pragma mark - Mock Delegates

@interface DeferredErrorMockBannerDelegate : NSObject <CLXBannerDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation DeferredErrorMockBannerDelegate

- (void)didFailToLoadAd:(NSString *)adUnitId error:(NSError *)error {
    self.receivedAdUnitId = adUnitId;
    self.receivedError = error;
    if (self.failureCallback) self.failureCallback();
}

- (void)didLoadAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}

@end

@interface DeferredErrorMockInterstitialDelegate : NSObject <CLXInterstitialDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation DeferredErrorMockInterstitialDelegate

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

@interface DeferredErrorMockRewardedDelegate : NSObject <CLXRewardedDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation DeferredErrorMockRewardedDelegate

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

@interface DeferredErrorMockNativeDelegate : NSObject <CLXNativeDelegate, CLXAdapterNativeDelegate>
@property (nonatomic, copy, nullable) NSString *receivedAdUnitId;
@property (nonatomic, strong, nullable) NSError *receivedError;
@property (nonatomic, copy, nullable) void (^failureCallback)(void);
@end

@implementation DeferredErrorMockNativeDelegate

- (void)didFailToLoadAd:(NSString *)adUnitId error:(NSError *)error {
    self.receivedAdUnitId = adUnitId;
    self.receivedError = error;
    if (self.failureCallback) self.failureCallback();
}

- (void)didLoadAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didLoadWithNative:(id<CLXAdapterNative>)native {}
- (void)failToLoadWithNative:(id<CLXAdapterNative>)native error:(NSError *)error {}
- (void)didShowWithNative:(id<CLXAdapterNative>)native {}
- (void)impressionWithNative:(id<CLXAdapterNative>)native {}
- (void)clickWithNative:(id<CLXAdapterNative>)native {}
- (void)closeWithNative:(id<CLXAdapterNative>)native {}

@end

#pragma mark - Mock Reporting Service

@interface DeferredErrorMockReportingService : NSObject <CLXAdEventReporting>
@end

@implementation DeferredErrorMockReportingService
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
@end

#pragma mark - Test Class

@interface CLXDeferredErrorAdUnitIdTests : XCTestCase
@end

@implementation CLXDeferredErrorAdUnitIdTests

#pragma mark - Banner

- (void)testBannerDeferredErrorCallbackIncludesAdUnitId {
    // Arrange
    DeferredErrorMockBannerDelegate *delegate = [[DeferredErrorMockBannerDelegate alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    DeferredErrorMockReportingService *reporting = [[DeferredErrorMockReportingService alloc] init];

    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] initWithAdUnit:nil
                                                                    userID:@""
                                                               publisherID:@""
                                                  suspendPreloadWhenInvisible:NO
                                                                   delegate:delegate
                                                                 bannerType:CLXBannerTypeW320H50
                                                                  impModel:nil
                                                               adFactories:@{}
                                                            bidTokenSources:@{}
                                                        bidRequestTimeout:2.0
                                                         reportingService:reporting
                                                                  settings:settings];

    banner.adUnitId = kTestAdUnitId;
    banner.requestedAdUnitId = kTestAdUnitId;
    banner.deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                       description:@"No adapters registered"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Banner failure callback"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [banner load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);

    [banner destroy];
}

#pragma mark - Interstitial

- (void)testInterstitialDeferredErrorCallbackIncludesAdUnitId {
    // Arrange
    DeferredErrorMockInterstitialDelegate *delegate = [[DeferredErrorMockInterstitialDelegate alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    DeferredErrorMockReportingService *reporting = [[DeferredErrorMockReportingService alloc] init];

    CLXInterstitial *interstitial = [[CLXInterstitial alloc] initWithAdUnit:nil
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
    interstitial.adUnitId = kTestAdUnitId;
    interstitial.requestedAdUnitId = kTestAdUnitId;
    interstitial.deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                             description:@"No adapters registered"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Interstitial failure callback"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [interstitial load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);

    [interstitial destroy];
}

#pragma mark - Rewarded

- (void)testRewardedDeferredErrorCallbackIncludesAdUnitId {
    // Arrange
    DeferredErrorMockRewardedDelegate *delegate = [[DeferredErrorMockRewardedDelegate alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    DeferredErrorMockReportingService *reporting = [[DeferredErrorMockReportingService alloc] init];

    CLXRewarded *rewarded = [[CLXRewarded alloc] initWithAdUnit:nil
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
    rewarded.adUnitId = kTestAdUnitId;
    rewarded.requestedAdUnitId = kTestAdUnitId;
    rewarded.deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                         description:@"No adapters registered"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Rewarded failure callback"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [rewarded load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);

    [rewarded destroy];
}

#pragma mark - Native

- (void)testNativeDeferredErrorCallbackIncludesAdUnitId {
    // Arrange
    DeferredErrorMockNativeDelegate *delegate = [[DeferredErrorMockNativeDelegate alloc] init];
    DeferredErrorMockReportingService *reporting = [[DeferredErrorMockReportingService alloc] init];
    UIViewController *vc = [[UIViewController alloc] init];

    CLXPublisherNative *native = [[CLXPublisherNative alloc] initWithViewController:vc
                                                                           adUnit:nil
                                                                           userID:@""
                                                                      publisherID:@""
                                                         suspendPreloadWhenInvisible:NO
                                                                          delegate:delegate
                                                                        nativeType:CLXNativeTemplateDefault
                                                                          impModel:nil
                                                                       adFactories:@{}
                                                                    bidTokenSources:@{}
                                                                 bidRequestTimeout:2.0
                                                                  reportingService:reporting];

    native.adUnitId = kTestAdUnitId;
    native.requestedAdUnitId = kTestAdUnitId;
    native.deferredError = [CLXError errorWithCode:CLXErrorCodeNoAdaptersFound
                                       description:@"No adapters registered"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Native failure callback"];
    delegate.failureCallback = ^{ [expectation fulfill]; };

    // Act
    [native load];

    // Assert
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(delegate.receivedAdUnitId, @"adUnitId must not be nil in failure callback");
    XCTAssertEqualObjects(delegate.receivedAdUnitId, kTestAdUnitId);
    XCTAssertNotNil(delegate.receivedError);

    [native destroy];
}

@end
