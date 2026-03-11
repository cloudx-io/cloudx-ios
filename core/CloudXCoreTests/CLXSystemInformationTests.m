//
//  CLXSystemInformationTests.m
//  CloudXCoreTests
//
//  Tests for CLXSystemInformation, specifically effectiveAppBundleIdentifier
//  and its interaction with the emulator bundle override.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXSystemInformationTests : XCTestCase
@end

@implementation CLXSystemInformationTests

- (void)setUp {
    [super setUp];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

#pragma mark - appBundleIdentifier

- (void)testAppBundleIdentifier_ReturnsMainBundleIdentifier {
    NSString *expected = [[NSBundle mainBundle] bundleIdentifier] ?: @"";

    NSString *result = [CLXSystemInformation shared].appBundleIdentifier;

    XCTAssertEqualObjects(result, expected);
}

- (void)testAppBundleIdentifier_IgnoresBundleOverride {
    [[NSUserDefaults standardUserDefaults] setObject:@"io.cloudx.override" forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSString *expected = [[NSBundle mainBundle] bundleIdentifier] ?: @"";

    NSString *result = [CLXSystemInformation shared].appBundleIdentifier;

    XCTAssertEqualObjects(result, expected, @"appBundleIdentifier must always return the real bundle, regardless of override");
}

#pragma mark - effectiveAppBundleIdentifier

- (void)testEffectiveAppBundleIdentifier_ReturnsRealBundleWhenNoOverride {
    NSString *expected = [CLXSystemInformation shared].appBundleIdentifier;

    NSString *result = [CLXSystemInformation shared].effectiveAppBundleIdentifier;

    XCTAssertEqualObjects(result, expected, @"Without override, effective bundle should equal real bundle");
}

- (void)testEffectiveAppBundleIdentifier_HonorsOverrideOnSimulator {
    NSString *overrideBundle = @"io.cloudx.override.bundle";
    [[NSUserDefaults standardUserDefaults] setObject:overrideBundle forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSString *result = [CLXSystemInformation shared].effectiveAppBundleIdentifier;

#if TARGET_IPHONE_SIMULATOR
    XCTAssertEqualObjects(result, overrideBundle, @"On simulator, effective bundle must honor override");
#else
    NSString *realBundle = [CLXSystemInformation shared].appBundleIdentifier;
    XCTAssertEqualObjects(result, realBundle, @"On device, effective bundle must ignore override");
#endif
}

- (void)testEffectiveAppBundleIdentifier_IgnoresEmptyOverride {
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSString *expected = [CLXSystemInformation shared].appBundleIdentifier;

    NSString *result = [CLXSystemInformation shared].effectiveAppBundleIdentifier;

    XCTAssertEqualObjects(result, expected, @"Empty override string should fall back to real bundle");
}

- (void)testEffectiveAppBundleIdentifier_OverrideRemovedRestoresRealBundle {
    NSString *overrideBundle = @"io.cloudx.temp.override";
    [[NSUserDefaults standardUserDefaults] setObject:overrideBundle forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

#if TARGET_IPHONE_SIMULATOR
    XCTAssertEqualObjects([CLXSystemInformation shared].effectiveAppBundleIdentifier, overrideBundle);
#endif

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSString *expected = [CLXSystemInformation shared].appBundleIdentifier;
    XCTAssertEqualObjects([CLXSystemInformation shared].effectiveAppBundleIdentifier, expected,
                          @"After removing override, effective bundle must revert to real bundle");
}

@end
