//
//  CLXInitializationCallbackTests.m
//  CloudXCoreTests
//
//  Focused unit tests validating that the initialization callback returns
//  CLXSdkConfiguration correctly on success and nil on failure.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXInitializationConfiguration.h>
#import <CloudXCore/CLXSdkConfiguration.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXLiveInitService.h>
#import "Mocks/CLXMockInitService.h"

@interface CloudXCore (Testing)
- (void)resetForTesting;
@end

@interface CLXInitializationCallbackTests : XCTestCase
@property (nonatomic, strong) CLXMockInitService *mockInitService;
@end

@implementation CLXInitializationCallbackTests

- (void)setUp {
    [super setUp];

    // Reset DI container to ensure clean state
    [[CLXDIContainer shared] reset];
    [[CloudXCore shared] resetForTesting];

    // Set up mock init service (success by default)
    self.mockInitService = [[CLXMockInitService alloc] initWithSuccess:YES];
    self.mockInitService.synchronous = YES;
    [[CLXDIContainer shared] registerType:[CLXLiveInitService class] instance:self.mockInitService];
}

- (void)tearDown {
    [[CloudXCore shared] resetForTesting];
    [[CLXDIContainer shared] reset];
    [super tearDown];
}

#pragma mark - Initialization Callback Tests

- (void)testInitializationSuccess_ReturnsSdkConfiguration {
    // Given: Mock configured for success
    self.mockInitService.shouldSucceed = YES;

    // When: Initialize SDK
    XCTestExpectation *exp = [self expectationWithDescription:@"Init"];
    CLXInitializationConfiguration *config = [CLXInitializationConfiguration configurationWithAppKey:@"test-key"];

    [[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfig, CLXError *error) {
        // Then: sdkConfiguration is non-nil, error is nil
        XCTAssertNotNil(sdkConfig, @"sdkConfiguration should be non-nil on success");
        XCTAssertNil(error, @"error should be nil on success");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testInitializationFailure_ReturnsNilConfiguration {
    // Given: Mock configured for failure
    self.mockInitService.shouldSucceed = NO;
    self.mockInitService.mockError = [NSError errorWithDomain:@"test" code:100 userInfo:nil];

    // When: Initialize SDK
    XCTestExpectation *exp = [self expectationWithDescription:@"Init"];
    CLXInitializationConfiguration *config = [CLXInitializationConfiguration configurationWithAppKey:@"test-key"];

    [[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfig, CLXError *error) {
        // Then: sdkConfiguration is nil, error is non-nil
        XCTAssertNil(sdkConfig, @"sdkConfiguration should be nil on failure");
        XCTAssertNotNil(error, @"error should be non-nil on failure");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Mutual Exclusivity (XOR Contract)

- (void)testInitializationSuccess_MutualExclusivity_NeverBothNonNil {
    // Given: Mock configured for success
    self.mockInitService.shouldSucceed = YES;

    // When: Initialize SDK
    XCTestExpectation *exp = [self expectationWithDescription:@"Init"];
    CLXInitializationConfiguration *config = [CLXInitializationConfiguration configurationWithAppKey:@"test-key"];

    [[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfig, CLXError *error) {
        // Then: XOR contract - exactly one must be non-nil
        BOOL hasConfig = (sdkConfig != nil);
        BOOL hasError = (error != nil);
        XCTAssertTrue(hasConfig != hasError, @"Callback must return exactly one of sdkConfig or error, never both");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testInitializationFailure_MutualExclusivity_NeverBothNil {
    // Given: Mock configured for failure
    self.mockInitService.shouldSucceed = NO;
    self.mockInitService.mockError = [NSError errorWithDomain:@"test" code:100 userInfo:nil];

    // When: Initialize SDK
    XCTestExpectation *exp = [self expectationWithDescription:@"Init"];
    CLXInitializationConfiguration *config = [CLXInitializationConfiguration configurationWithAppKey:@"test-key"];

    [[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfig, CLXError *error) {
        // Then: XOR contract - exactly one must be non-nil
        BOOL hasConfig = (sdkConfig != nil);
        BOOL hasError = (error != nil);
        XCTAssertTrue(hasConfig != hasError, @"Callback must return exactly one of sdkConfig or error, never both nil");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
