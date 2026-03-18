//
//  CLXSDKInitNetworkServiceIntegrationTests.m
//  CloudXCoreIntegrationTests
//
//  Tests for CLXSDKInitNetworkService.createRequest that depend on
//  CLXSystemInformation singleton, real NSUserDefaults, and the
//  TARGET_IPHONE_SIMULATOR compile-time flag.
//
//  Moved from unit tests because these tests mutate shared global
//  state (NSUserDefaults) and read from a singleton, which causes
//  failures under parallel test execution and environment-dependent
//  behavior (simulator-only bundle override).
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSystemInformation.h>

@interface CLXSDKInitNetworkService (Testing)
- (CLXSDKConfigRequest *)createRequest;
@end

@interface CLXSDKInitNetworkServiceIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXSDKInitNetworkService *networkService;
@end

@implementation CLXSDKInitNetworkServiceIntegrationTests

- (void)setUp {
    [super setUp];
    self.networkService = [[CLXSDKInitNetworkService alloc] init];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.networkService = nil;
    [super tearDown];
}

#pragma mark - Bundle Override Tests

- (void)testCreateRequest_UsesBundleOverrideWhenPresent {
    NSString *overrideBundle = @"io.cloudx.override.bundle";
    [[NSUserDefaults standardUserDefaults] setObject:overrideBundle forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CLXSDKConfigRequest *request = [self.networkService createRequest];

#if TARGET_IPHONE_SIMULATOR
    XCTAssertEqualObjects(request.bundle, overrideBundle,
                          @"On simulator, init request bundle must honor override");
#else
    NSString *realBundle = [CLXSystemInformation shared].appBundleIdentifier;
    XCTAssertEqualObjects(request.bundle, realBundle,
                          @"On device, init request bundle must ignore override");
#endif
}

- (void)testCreateRequest_UsesSystemBundleWhenNoOverride {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CLXSDKConfigRequest *request = [self.networkService createRequest];
    NSString *expectedBundle = [CLXSystemInformation shared].appBundleIdentifier;

    XCTAssertEqualObjects(request.bundle, expectedBundle,
                          @"init request should use system bundle when override is absent");
}

#pragma mark - Adapter Metadata Tests

- (void)testCreateRequest_PopulatesAdaptersArray {
    CLXSDKConfigRequest *request = [self.networkService createRequest];

    XCTAssertNotNil(request.adapters, @"adapters should not be nil");
}

- (void)testCreateRequest_AdaptersIncludedInJson {
    CLXSDKConfigRequest *request = [self.networkService createRequest];
    NSDictionary *json = [request json];

    XCTAssertNotNil(json[@"adapters"], @"JSON should include adapters key");
    XCTAssertTrue([json[@"adapters"] isKindOfClass:[NSArray class]], @"adapters should be an array");
}

@end
