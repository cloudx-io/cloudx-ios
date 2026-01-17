/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXProtectedOperationsTests.m
 * @brief Smoke tests verifying protected operations don't crash with bad input
 * @details These tests verify @try/@catch protection handles edge cases gracefully.
 *          Tests pass if no crash occurs - no misleading XCTAssertTrue(YES) assertions.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXErrorReporter.h>
#import "Helper/CLXUserDefaultsTestHelper.h"

@interface CLXProtectedOperationsTests : XCTestCase
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@property (nonatomic, strong) CLXErrorReporter *errorReporter;
@end

@implementation CLXProtectedOperationsTests

- (void)setUp {
    [super setUp];
    self.errorReporter = [[CLXErrorReporter alloc] init];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:self.errorReporter];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    self.gppProvider = nil;
    self.errorReporter = nil;
    [super tearDown];
}

#pragma mark - GPP Provider Protection Tests

- (void)testGPPProvider_DecodeWithValidFormat_DoesNotCrash {
    [self.gppProvider setGppString:@"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA"];
    [self.gppProvider setGppSid:@[@7]];
    
    // Should not crash - consent may be nil for invalid/unsupported data
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    // No assertion needed - test passes if no crash
    (void)consent;
}

- (void)testGPPProvider_CorruptedBase64_DoesNotCrash {
    NSArray<NSString *> *corruptedStrings = @[
        @"Invalid!Base64@#$%",
        @"DBABrw~CorruptedData!!!",
        @"",
        @"A",
        @"DBABrw~"
    ];
    
    for (NSString *corruptedString in corruptedStrings) {
        [self.gppProvider setGppString:corruptedString];
        [self.gppProvider setGppSid:@[@7]];
        
        // Should not crash with corrupted input
        CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
        (void)consent;
    }
}

- (void)testGPPProvider_NilValues_DoesNotCrash {
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    // Should handle nil gracefully
    NSString *gppString = [self.gppProvider gppString];
    NSArray *gppSid = [self.gppProvider gppSid];
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:nil];
    
    XCTAssertNil(gppString, @"GPP string should be nil after setting nil");
    XCTAssertNil(gppSid, @"GPP SID should be nil after setting nil");
    (void)consent;
}

- (void)testGPPProvider_ExtremeStringLength_DoesNotCrash {
    NSString *extremeString = [@"" stringByPaddingToLength:100000 withString:@"EXTREME" startingAtIndex:0];
    
    [self.gppProvider setGppString:extremeString];
    NSString *retrieved = [self.gppProvider gppString];
    
    XCTAssertEqualObjects(retrieved, extremeString, @"Should store and retrieve extreme length string");
}

#pragma mark - Settings Protection Tests

- (void)testSettings_UserDefaultsAccess_HandlesInvalidTypes {
    CLXSettings *settings = [CLXSettings sharedInstance];
    
    // Default value
    BOOL retries1 = [settings shouldEnableBannerRetries];
    XCTAssertFalse(retries1, @"Default should be NO");
    
    // Valid bool value - use the actual key from CLXUserDefaultsKeys.h
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXCore_EnableBannerRetries"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BOOL retries2 = [settings shouldEnableBannerRetries];
    XCTAssertTrue(retries2, @"Should return YES when set to YES");
    
    // Invalid type - should not crash
    [[NSUserDefaults standardUserDefaults] setObject:@"not_a_bool" forKey:@"CLXCore_EnableBannerRetries"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BOOL retries3 = [settings shouldEnableBannerRetries];
    // Value is undefined but should not crash
    (void)retries3;
}

#pragma mark - URL Provider Protection Tests

- (void)testURLProvider_URLConstruction_ReturnsExpectedValues {
    NSURL *initUrl = [CLXURLProvider initApiUrl];
    NSString *auctionUrl = [CLXURLProvider auctionApiUrl];
    NSString *metricsUrl = [CLXURLProvider metricsApiUrl];
    
    XCTAssertNotNil(initUrl, @"Init API URL should be valid");
    XCTAssertNil(auctionUrl, @"Auction API URL should be nil (deprecated - comes from SDK response)");
    XCTAssertNil(metricsUrl, @"Metrics API URL should be nil (deprecated - comes from SDK response)");
}

#pragma mark - Bid Network Service Tests

- (void)testBidNetworkService_Initialization_Succeeds {
    CLXBidNetworkServiceClass *bidService = [[CLXBidNetworkServiceClass alloc] initWithAuctionEndpointUrl:@"https://test.com"
                                                                                            errorReporter:self.errorReporter];
    XCTAssertNotNil(bidService, @"Bid network service should initialize");
}

#pragma mark - Performance Tests

- (void)testProtectedOperations_Performance_ReasonableOverhead {
    [self measureBlock:^{
        CLXSettings *settings = [CLXSettings sharedInstance];
        for (NSInteger i = 0; i < 1000; i++) {
            [self.gppProvider setGppString:[NSString stringWithFormat:@"test_%ld", (long)i]];
            (void)[self.gppProvider gppString];
            (void)[settings shouldEnableBannerRetries];
            (void)[CLXURLProvider initApiUrl];
        }
    }];
}

#pragma mark - Thread Safety Tests

- (void)testProtectedOperations_ConcurrentAccess_NoRaceConditions {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent operations"];
    
    __block NSInteger completedOperations = 0;
    NSInteger totalOperations = 100;
    
    for (NSInteger i = 0; i < totalOperations; i++) {
        [queue addOperationWithBlock:^{
            CLXSettings *settings = [CLXSettings sharedInstance];
            [self.gppProvider setGppString:[NSString stringWithFormat:@"concurrent_%ld", (long)i]];
            (void)[self.gppProvider gppString];
            (void)[settings shouldEnableBannerRetries];
            (void)[CLXURLProvider initApiUrl];
            
            @synchronized(self) {
                completedOperations++;
                if (completedOperations == totalOperations) {
                    [expectation fulfill];
                }
            }
        }];
    }
    
    [self waitForExpectations:@[expectation] timeout:10.0];
    XCTAssertEqual(completedOperations, totalOperations, @"All concurrent operations should complete");
}

@end
