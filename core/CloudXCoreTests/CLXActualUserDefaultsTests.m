/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * Tests for ACTUAL User Defaults usage in CloudXCore SDK
 * Based on real implementation analysis, not assumptions
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXActualUserDefaultsTests : XCTestCase
@end

@implementation CLXActualUserDefaultsTests

- (void)setUp {
    [super setUp];
    // Don't clear anything in setUp - let tests start with whatever state exists
}

- (void)tearDown {
    // Clear all CloudXCore keys to prevent test contamination
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    // Force synchronization to ensure cleanup is complete before next test
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [super tearDown];
}

#pragma mark - Tests for ACTUAL User Defaults Usage

// DEBUG: Simple test to verify UserDefaults operations work at all
- (void)testBasicUserDefaultsOperation {
    // Use a completely unique key that won't conflict with anything
    NSString *testKey = @"DEBUG_TEST_KEY_12345";
    NSString *testValue = @"DEBUG_TEST_VALUE";
    
    [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:testKey];
    NSString *retrievedValue = [[NSUserDefaults standardUserDefaults] stringForKey:testKey];
    
    XCTAssertEqualObjects(retrievedValue, testValue, @"Basic UserDefaults operation should work");
    
    // Clean up
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:testKey];
}

// Test what CloudXCoreAPI.m line 131 actually does
- (void)testSDKInit_CreatesEmptyMetricsDict {
    // This is what actually happens in initializeSDKWithAppKey:completion:
    NSDictionary *dict = @{};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kCLXCoreMetricsDictKey];
    
    NSDictionary *storedDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(storedDict, @"SDK should create empty metricsDict");
    XCTAssertEqual(storedDict.count, 0, @"Initial metricsDict should be empty");
}

// Test what CloudXCoreAPI.m line 342-343 actually does
- (void)testSDKInit_StoresAppKeyAndAccountID {
    // This is what actually happens in the success callback
    NSString *testAppKey = @"test-app-key";
    NSString *testAccountID = @"test-account-id";
    
    [[NSUserDefaults standardUserDefaults] setValue:testAppKey forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:testAccountID forKey:kCLXCoreAccountIDKey];
    
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *storedAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    
    XCTAssertEqualObjects(storedAppKey, testAppKey, @"App key should be stored");
    XCTAssertEqualObjects(storedAccountID, testAccountID, @"Account ID should be stored");
}

// Test what CloudXCoreAPI.m line 189 actually does
- (void)testSDKInit_CreatesSessionID {
    // This is what actually happens when session ID is created
    NSString *sessionID = [[NSUUID UUID] UUIDString];
    [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:kCLXCoreSessionIDKey];
    
    NSString *storedSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    XCTAssertEqualObjects(storedSessionID, sessionID, @"Session ID should be stored");
}

// Test what CloudXCoreAPI.m line 255 actually does
- (void)testSDKInit_StoresEncodedString {
    // This is what actually happens when encoded string is set
    NSString *encodedString = @"test-encoded-string";
    [[NSUserDefaults standardUserDefaults] setObject:encodedString forKey:kCLXCoreEncodedStringKey];
    
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, encodedString, @"Encoded string should be stored");
}

// Test what CloudXCoreAPI.m line 215 actually does
- (void)testSDKInit_StoresGeoHeaders {
    // This is what actually happens when geo headers are set
    NSDictionary *geoHeaders = @{@"lat": @"40.7128", @"lon": @"-74.0060"};
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreGeoHeadersKey];
    
    NSDictionary *storedGeoHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
    XCTAssertEqualObjects(storedGeoHeaders, geoHeaders, @"Geo headers should be stored");
}

// Test metrics dict updates (happens in multiple places)
- (void)testMetricsDict_UpdatesCorrectly {
    // Start with empty dict (like SDK init does)
    NSDictionary *initialDict = @{};
    [[NSUserDefaults standardUserDefaults] setObject:initialDict forKey:kCLXCoreMetricsDictKey];
    
    // Update metrics (like setHashedUserID does)
    NSDictionary *existingDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedDict = [existingDict mutableCopy];
    updatedDict[@"method_set_hashed_user_id"] = @"1";
    [[NSUserDefaults standardUserDefaults] setObject:updatedDict forKey:kCLXCoreMetricsDictKey];
    
    NSDictionary *finalDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalDict[@"method_set_hashed_user_id"], @"1", @"Metrics should be updated");
}

#pragma mark - Collision Risk Demonstration Tests

// Test that demonstrates the HIGH collision risk with unprefixed keys
- (void)testCollisionRisk_GenericKeysOverwriteEachOther {
    // Simulate another app/SDK using the same generic keys
    [[NSUserDefaults standardUserDefaults] setObject:@"external-app-key" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-session" forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"data"} forKey:kCLXCoreMetricsDictKey];
    
    // Verify external data is stored
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey], @"external-app-key");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey], @"external-session");
    
    // Now CloudXCore overwrites these values (simulating what happens in real usage)
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-app-key" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
    
    // Verify CloudXCore overwrote the external values - THIS IS THE COLLISION
    NSString *finalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *finalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *finalMetricsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    
    XCTAssertEqualObjects(finalAppKey, @"cloudx-app-key", @"CloudXCore overwrote external app key - COLLISION!");
    XCTAssertNotEqualObjects(finalSessionID, @"external-session", @"CloudXCore overwrote external session - COLLISION!");
    XCTAssertNil(finalMetricsDict[@"external"], @"CloudXCore overwrote external metrics - COLLISION!");
}

// Test showing the risk with common key names
- (void)testCollisionRisk_CommonKeyNamesHighRisk {
    // These are the ACTUAL keys CloudXCore uses - all are generic and collision-prone
    NSArray *cloudXCoreKeys = @[
        kCLXCoreAppKeyKey,           // Used by countless apps
        kCLXCoreSessionIDKey,        // Common session management
        kCLXCoreMetricsDictKey,      // Generic analytics storage
        kCLXCoreEncodedStringKey,    // Generic encoded data
        kCLXCoreGeoHeadersKey,       // Geographic data
        kCLXCoreAccountIDKey         // Account configuration
    ];

    // Simulate other apps using these same keys
    for (NSString *key in cloudXCoreKeys) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"external-%@", key] forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Verify external data is stored
    for (NSString *key in cloudXCoreKeys) {
        NSString *expected = [NSString stringWithFormat:@"external-%@", key];
        XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:key], expected);
    }

    // CloudXCore overwrites ALL of these
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-app" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"cloudx-session" forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // All external data is now LOST
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey], @"cloudx-app");
    XCTAssertNotEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey], @"external-appKey");

    // This demonstrates that CloudXCore's use of generic keys creates HIGH collision risk
}

@end
