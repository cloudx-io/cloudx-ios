/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRetryHelperTests.m
 * @brief Unit tests for CLXRetryHelper
 *
 * Tests:
 * - Ad-type specific retry enablement (Banner, MREC, Interstitial, Rewarded, Native)
 * - Settings injection via MockCLXSettings
 * - Failure block execution when retries disabled
 * - Error message content
 *
 * PRINCIPLES:
 * - Uses MockCLXSettings for SYNCHRONOUS behavior (no UserDefaults)
 * - All tests are deterministic - no timing dependencies
 * - Meaningful assertions on actual values
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXRetryHelper.h>
#import <CloudXCore/CLXAdType.h>
#import "Mocks/MockCLXSettings.h"

#pragma mark - CLXRetryHelperTests

@interface CLXRetryHelperTests : XCTestCase
@property (nonatomic, strong) MockCLXSettings *mockSettings;
@end

@implementation CLXRetryHelperTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    self.mockSettings = [[MockCLXSettings alloc] init];
}

- (void)tearDown {
    self.mockSettings = nil;
    [super tearDown];
}

#pragma mark - MARK: Banner Retry Tests

- (void)testShouldRetry_BannerEnabled_ReturnsYES {
    self.mockSettings.bannerRetriesEnabled = YES;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertTrue(shouldRetry, @"Should return YES when banner retries are enabled");
}

- (void)testShouldRetry_BannerDisabled_ReturnsNO {
    self.mockSettings.bannerRetriesEnabled = NO;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"Should return NO when banner retries are disabled");
}

- (void)testShouldRetry_BannerDisabled_CallsFailureBlock {
    self.mockSettings.bannerRetriesEnabled = NO;
    
    __block BOOL failureBlockCalled = NO;
    __block NSError *capturedError = nil;
    
    [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                settings:self.mockSettings
                                  logger:nil
                            failureBlock:^(NSError *error) {
        failureBlockCalled = YES;
        capturedError = error;
    }];
    
    XCTAssertTrue(failureBlockCalled, @"Failure block should be called when retries disabled");
    XCTAssertNotNil(capturedError, @"Error should be passed to failure block");
}

- (void)testShouldRetry_BannerEnabled_DoesNotCallFailureBlock {
    self.mockSettings.bannerRetriesEnabled = YES;
    
    __block BOOL failureBlockCalled = NO;
    
    [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                settings:self.mockSettings
                                  logger:nil
                            failureBlock:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    XCTAssertFalse(failureBlockCalled, @"Failure block should NOT be called when retries enabled");
}

#pragma mark - MARK: MREC Retry Tests (Uses Banner Setting)

- (void)testShouldRetry_MRECEnabled_ReturnsYES {
    // MREC uses banner retry setting
    self.mockSettings.bannerRetriesEnabled = YES;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeMrec
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertTrue(shouldRetry, @"MREC should use banner retry setting");
}

- (void)testShouldRetry_MRECDisabled_ReturnsNO {
    self.mockSettings.bannerRetriesEnabled = NO;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeMrec
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"MREC should use banner retry setting");
}

- (void)testShouldRetry_MRECUsesBannerSetting_NotIndependent {
    // Verify MREC doesn't have its own setting - it follows banner
    self.mockSettings.bannerRetriesEnabled = YES;
    
    BOOL shouldRetryMREC = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeMrec
                                                       settings:self.mockSettings
                                                         logger:nil
                                                   failureBlock:nil];
    
    BOOL shouldRetryBanner = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                                         settings:self.mockSettings
                                                           logger:nil
                                                     failureBlock:nil];
    
    XCTAssertEqual(shouldRetryMREC, shouldRetryBanner, @"MREC should match banner retry setting");
}

#pragma mark - MARK: Interstitial Retry Tests

- (void)testShouldRetry_InterstitialEnabled_ReturnsYES {
    self.mockSettings.interstitialRetriesEnabled = YES;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertTrue(shouldRetry, @"Should return YES when interstitial retries are enabled");
}

- (void)testShouldRetry_InterstitialDisabled_ReturnsNO {
    self.mockSettings.interstitialRetriesEnabled = NO;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"Should return NO when interstitial retries are disabled");
}

- (void)testShouldRetry_InterstitialDisabled_CallsFailureBlock {
    self.mockSettings.interstitialRetriesEnabled = NO;
    
    __block BOOL failureBlockCalled = NO;
    
    [CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial
                                settings:self.mockSettings
                                  logger:nil
                            failureBlock:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    XCTAssertTrue(failureBlockCalled, @"Failure block should be called when interstitial retries disabled");
}

#pragma mark - MARK: Rewarded Retry Tests

- (void)testShouldRetry_RewardedEnabled_ReturnsYES {
    self.mockSettings.rewardedRetriesEnabled = YES;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertTrue(shouldRetry, @"Should return YES when rewarded retries are enabled");
}

- (void)testShouldRetry_RewardedDisabled_ReturnsNO {
    self.mockSettings.rewardedRetriesEnabled = NO;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"Should return NO when rewarded retries are disabled");
}

- (void)testShouldRetry_RewardedDisabled_CallsFailureBlock {
    self.mockSettings.rewardedRetriesEnabled = NO;
    
    __block BOOL failureBlockCalled = NO;
    
    [CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded
                                settings:self.mockSettings
                                  logger:nil
                            failureBlock:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    XCTAssertTrue(failureBlockCalled, @"Failure block should be called when rewarded retries disabled");
}

#pragma mark - MARK: Native Retry Tests

- (void)testShouldRetry_NativeEnabled_ReturnsYES {
    self.mockSettings.nativeRetriesEnabled = YES;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertTrue(shouldRetry, @"Should return YES when native retries are enabled");
}

- (void)testShouldRetry_NativeDisabled_ReturnsNO {
    self.mockSettings.nativeRetriesEnabled = NO;
    
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"Should return NO when native retries are disabled");
}

- (void)testShouldRetry_NativeDisabled_CallsFailureBlock {
    self.mockSettings.nativeRetriesEnabled = NO;
    
    __block BOOL failureBlockCalled = NO;
    
    [CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative
                                settings:self.mockSettings
                                  logger:nil
                            failureBlock:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    XCTAssertTrue(failureBlockCalled, @"Failure block should be called when native retries disabled");
}

#pragma mark - MARK: Error Message Tests

- (void)testRetriesDisabledError_Banner_ContainsAdTypeName {
    NSError *error = [CLXRetryHelper retriesDisabledErrorForAdType:CLXAdTypeBanner errorCode:1001];
    
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqualObjects(error.domain, @"CLXRetryHelper", @"Error domain should be CLXRetryHelper");
    XCTAssertEqual(error.code, 1001, @"Error code should match provided code");
    XCTAssertTrue([error.localizedDescription containsString:@"Banner"], 
                  @"Error description should contain 'Banner'");
}

- (void)testRetriesDisabledError_MREC_ContainsAdTypeName {
    NSError *error = [CLXRetryHelper retriesDisabledErrorForAdType:CLXAdTypeMrec errorCode:1002];
    
    XCTAssertTrue([error.localizedDescription containsString:@"MREC"], 
                  @"Error description should contain 'MREC'");
}

- (void)testRetriesDisabledError_Interstitial_ContainsAdTypeName {
    NSError *error = [CLXRetryHelper retriesDisabledErrorForAdType:CLXAdTypeInterstitial errorCode:1003];
    
    XCTAssertTrue([error.localizedDescription containsString:@"Interstitial"], 
                  @"Error description should contain 'Interstitial'");
}

- (void)testRetriesDisabledError_Rewarded_ContainsAdTypeName {
    NSError *error = [CLXRetryHelper retriesDisabledErrorForAdType:CLXAdTypeRewarded errorCode:1004];
    
    XCTAssertTrue([error.localizedDescription containsString:@"Rewarded"], 
                  @"Error description should contain 'Rewarded'");
}

- (void)testRetriesDisabledError_Native_ContainsAdTypeName {
    NSError *error = [CLXRetryHelper retriesDisabledErrorForAdType:CLXAdTypeNative errorCode:1005];
    
    XCTAssertTrue([error.localizedDescription containsString:@"Native"], 
                  @"Error description should contain 'Native'");
}

#pragma mark - MARK: nameForAdType Tests

- (void)testNameForAdType_Banner_ReturnsBanner {
    NSString *name = [CLXRetryHelper nameForAdType:CLXAdTypeBanner];
    XCTAssertEqualObjects(name, @"Banner", @"Should return 'Banner'");
}

- (void)testNameForAdType_MREC_ReturnsMREC {
    NSString *name = [CLXRetryHelper nameForAdType:CLXAdTypeMrec];
    XCTAssertEqualObjects(name, @"MREC", @"Should return 'MREC'");
}

- (void)testNameForAdType_Interstitial_ReturnsInterstitial {
    NSString *name = [CLXRetryHelper nameForAdType:CLXAdTypeInterstitial];
    XCTAssertEqualObjects(name, @"Interstitial", @"Should return 'Interstitial'");
}

- (void)testNameForAdType_Rewarded_ReturnsRewarded {
    NSString *name = [CLXRetryHelper nameForAdType:CLXAdTypeRewarded];
    XCTAssertEqualObjects(name, @"Rewarded", @"Should return 'Rewarded'");
}

- (void)testNameForAdType_Native_ReturnsNative {
    NSString *name = [CLXRetryHelper nameForAdType:CLXAdTypeNative];
    XCTAssertEqualObjects(name, @"Native", @"Should return 'Native'");
}

#pragma mark - MARK: Default State Tests

- (void)testDefaultSettings_AllRetriesDisabled {
    // MockCLXSettings defaults to all retries disabled (matching production default)
    MockCLXSettings *freshSettings = [[MockCLXSettings alloc] init];
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner 
                                              settings:freshSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Banner retries should be disabled by default");
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial 
                                              settings:freshSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Interstitial retries should be disabled by default");
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded 
                                              settings:freshSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Rewarded retries should be disabled by default");
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                              settings:freshSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Native retries should be disabled by default");
}

- (void)testEnableAllRetries_AllAdTypesEnabled {
    [self.mockSettings enableAllRetries];
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Banner should be enabled after enableAllRetries");
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeMrec 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"MREC should be enabled after enableAllRetries");
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Interstitial should be enabled after enableAllRetries");
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Rewarded should be enabled after enableAllRetries");
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Native should be enabled after enableAllRetries");
}

- (void)testDisableAllRetries_AllAdTypesDisabled {
    // First enable all
    [self.mockSettings enableAllRetries];
    
    // Then disable all
    [self.mockSettings disableAllRetries];
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner 
                                              settings:self.mockSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Banner should be disabled after disableAllRetries");
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial 
                                              settings:self.mockSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Interstitial should be disabled after disableAllRetries");
}

#pragma mark - MARK: Nil FailureBlock Tests

- (void)testShouldRetry_Disabled_NilFailureBlock_DoesNotCrash {
    self.mockSettings.bannerRetriesEnabled = NO;
    
    // Should not crash when failureBlock is nil
    BOOL shouldRetry = [CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner
                                                   settings:self.mockSettings
                                                     logger:nil
                                               failureBlock:nil];
    
    XCTAssertFalse(shouldRetry, @"Should return NO without crashing");
}

#pragma mark - MARK: Independent Settings Tests

- (void)testIndependentSettings_BannerDoesNotAffectInterstitial {
    self.mockSettings.bannerRetriesEnabled = YES;
    self.mockSettings.interstitialRetriesEnabled = NO;
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeBanner 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Banner should be enabled");
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeInterstitial 
                                              settings:self.mockSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Interstitial should be disabled");
}

- (void)testIndependentSettings_RewardedDoesNotAffectNative {
    self.mockSettings.rewardedRetriesEnabled = NO;
    self.mockSettings.nativeRetriesEnabled = YES;
    
    XCTAssertFalse([CLXRetryHelper shouldRetryForAdType:CLXAdTypeRewarded 
                                              settings:self.mockSettings 
                                                logger:nil 
                                          failureBlock:nil],
                   @"Rewarded should be disabled");
    
    XCTAssertTrue([CLXRetryHelper shouldRetryForAdType:CLXAdTypeNative 
                                             settings:self.mockSettings 
                                               logger:nil 
                                         failureBlock:nil],
                  @"Native should be enabled");
}

@end
