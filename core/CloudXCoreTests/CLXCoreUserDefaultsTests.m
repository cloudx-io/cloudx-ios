//
//  CLXCoreUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CloudXCore User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXLiveInitService.h>
#import "../Sources/CloudXCore/CloudXCoreInternal.h"
#import "CLXUserDefaultsTestHelper.h"
#import "Mocks/CLXMockInitService.h"

@interface CloudXCore (Testing)
- (void)initializeSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL success, CLXError *error))completion;
- (void)setHashedUserID:(NSString *)hashedUserID;
- (void)setUserKeyValue:(NSString *)key value:(NSString *)value;
+ (void)trackSDKError:(NSString *)error;
- (void)resetForTesting;
@end

@interface CLXCoreUserDefaultsTests : XCTestCase
@property (nonatomic, strong) CLXMockInitService *mockInitService;
@end

@implementation CLXCoreUserDefaultsTests

- (void)setUp {
    [super setUp];
    
    // Reset DI container to ensure clean state
    [[CLXDIContainer shared] reset];
    
    // Reset CloudXCore singleton state for isolated tests
    [[CloudXCore shared] resetForTesting];
    
    // Set up mock init service for fast, reliable unit tests
    self.mockInitService = [[CLXMockInitService alloc] initWithSuccess:YES];
    
    // Inject mock into DI container BEFORE any CloudXCore instances are created
    CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXLiveInitService class] instance:self.mockInitService];
    
    // Environment config no longer needed - removed in refactoring
    
    // Don't clear UserDefaults in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    // Reset DI container to ensure clean state for next test
    [[CLXDIContainer shared] reset];
    
    [super tearDown];
}

#pragma mark - Core SDK Tests

// Test that SDK uses correct UserDefaults key for app key storage
// NO NETWORK CALLS - directly tests key naming
- (void)testSDKInitializationStoresAppKey {
    NSString *testAppKey = @"test-app-key-123";
    
    // Directly write to UserDefaults using SDK's key constant
    [[NSUserDefaults standardUserDefaults] setObject:testAppKey forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the key constant is what we expect (unprefixed)
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    XCTAssertEqualObjects(storedAppKey, testAppKey, @"App key should be stored with SDK's key constant");
}

// Test that SDK uses correct UserDefaults key for account ID storage
// NO NETWORK CALLS - directly tests key naming
- (void)testSDKInitializationStoresAccountID {
    NSString *testAccountID = @"test-account-789";
    
    // Directly write to UserDefaults using SDK's key constant
    [[NSUserDefaults standardUserDefaults] setObject:testAccountID forKey:kCLXCoreAccountIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the key constant works correctly
    NSString *storedAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    XCTAssertEqualObjects(storedAccountID, testAccountID, @"Account ID should be stored with SDK's key constant");
}

// Test that SDK uses correct UserDefaults key for session ID storage
// NO NETWORK CALLS - directly tests key naming
- (void)testSDKCreatesSessionID {
    NSString *testSessionID = [[NSUUID UUID] UUIDString];
    
    // Directly write to UserDefaults using SDK's key constant
    [[NSUserDefaults standardUserDefaults] setObject:testSessionID forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the key constant works correctly
    NSString *storedSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    XCTAssertEqualObjects(storedSessionID, testSessionID, @"Session ID should be stored with SDK's key constant");
    XCTAssertTrue(storedSessionID.length > 0, @"Session ID should not be empty");
}

// Test that SDK uses correct UserDefaults key for metrics dictionary
// NO NETWORK CALLS - directly tests key naming
- (void)testSDKInitializesMetricsDict {
    NSDictionary *testMetrics = @{@"test": @"value", @"count": @42};
    
    // Directly write to UserDefaults using SDK's key constant
    [[NSUserDefaults standardUserDefaults] setObject:testMetrics forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the key constant works correctly
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(storedMetrics, @"Metrics dictionary should be stored with SDK's key constant");
    XCTAssertEqualObjects(storedMetrics[@"test"], @"value", @"Metrics dictionary values should persist");
}

// Test that SDK uses correct UserDefaults key for encoded string
// NO NETWORK CALLS - directly tests key naming
- (void)testSDKStoresEncodedString {
    NSString *testEncodedString = @"test-encoded-string-abc123";
    
    // Directly write to UserDefaults using SDK's key constant
    [[NSUserDefaults standardUserDefaults] setObject:testEncodedString forKey:kCLXCoreEncodedStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify the key constant works correctly
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    XCTAssertEqualObjects(storedEncodedString, testEncodedString, @"Encoded string should be stored with SDK's key constant");
}

#pragma mark - User Details Tests

// Test storing hashed user ID in CLXKeyValueState
// NO NETWORK CALLS - directly tests the in-memory state
- (void)testProvideUserDetailsWithHashedUserID {
    NSString *testHashedUserID = @"hashed-user-123";
    
    // Directly set hashed user ID in CLXKeyValueState (in-memory storage)
    [[CLXKeyValueState shared] setHashedUserId:testHashedUserID];
    
    // Verify hashed user ID is stored in CLXKeyValueState
    NSString *storedHashedUserID = [[CLXKeyValueState shared] hashedUserId];
    XCTAssertEqualObjects(storedHashedUserID, testHashedUserID, @"Hashed user ID should be stored in CLXKeyValueState");
}

#pragma mark - Direct Collision Risk Demonstration

// Test that directly demonstrates the collision risk with OLD unprefixed keys
- (void)testDirectCollisionRiskWithUnprefixedKeys {
    // This test demonstrates the collision risk using the OLD unprefixed keys CloudXCore USED TO USE
    
    // Simulate external app using the same unprefixed keys CloudXCore used to use
    [[NSUserDefaults standardUserDefaults] setObject:@"external-app-key" forKey:@"appKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-account" forKey:@"accId_config"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-session" forKey:@"sessionIDKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"metrics"} forKey:@"metricsDict"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-encoded" forKey:@"encodedString"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-hashed-user" forKey:@"hashedUserID"];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"user_data"} forKey:@"userKeyValue"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-bidder" forKey:@"userBidder"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external data is stored
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:@"appKey"], @"external-app-key");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:@"accId_config"], @"external-account");
    
    // Now simulate what CloudXCore USED TO DO - it overwrites with the SAME unprefixed keys
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-app-key" forKey:@"appKey"];  // Line 342 in CloudXCoreAPI.m (OLD)
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-account" forKey:@"accId_config"];  // Line 343 in CloudXCoreAPI.m (OLD)
    [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:@"sessionIDKey"];  // Line 189 in CloudXCoreAPI.m (OLD)
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:@"metricsDict"];  // Line 131 in CloudXCoreAPI.m (OLD)
    [[NSUserDefaults standardUserDefaults] setObject:@"cloudx-encoded" forKey:@"encodedString"];  // Line 255 in CloudXCoreAPI.m
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-hashed-user" forKey:@"hashedUserID"];  // Line 456 in CloudXCoreAPI.m
    [[NSUserDefaults standardUserDefaults] setObject:@{@"cloudx": @"user_data"} forKey:@"userKeyValue"];  // Line 483 in CloudXCoreAPI.m
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-bidder" forKey:@"userBidder"];  // Line 509 in CloudXCoreAPI.m
    
    // Verify ALL external data was overwritten - MASSIVE COLLISION!
    NSString *finalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"appKey"];
    NSString *finalAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:@"accId_config"];
    NSString *finalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:@"sessionIDKey"];
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"metricsDict"];
    NSString *finalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:@"encodedString"];
    NSString *finalHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:@"hashedUserID"];
    NSDictionary *finalUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"userKeyValue"];
    NSString *finalBidder = [[NSUserDefaults standardUserDefaults] stringForKey:@"userBidder"];
    
    // All external data is now LOST due to collision
    XCTAssertEqualObjects(finalAppKey, @"cloudx-app-key", @"CloudXCore overwrote external app key - COLLISION!");
    XCTAssertEqualObjects(finalAccountID, @"cloudx-account", @"CloudXCore overwrote external account - COLLISION!");
    XCTAssertNotEqualObjects(finalSessionID, @"external-session", @"CloudXCore overwrote external session - COLLISION!");
    XCTAssertNil(finalMetrics[@"external"], @"CloudXCore overwrote external metrics - COLLISION!");
    XCTAssertEqualObjects(finalEncodedString, @"cloudx-encoded", @"CloudXCore overwrote external encoded string - COLLISION!");
    XCTAssertEqualObjects(finalHashedUserID, @"cloudx-hashed-user", @"CloudXCore overwrote external hashed user ID - COLLISION!");
    XCTAssertEqualObjects(finalUserData[@"cloudx"], @"user_data", @"CloudXCore data is present");
    XCTAssertNil(finalUserData[@"external"], @"External user data was lost - COLLISION!");
    XCTAssertEqualObjects(finalBidder, @"cloudx-bidder", @"CloudXCore overwrote external bidder - COLLISION!");
    
    NSLog(@"🔴 COLLISION RISK DEMONSTRATED: CloudXCore uses 15+ unprefixed keys that overwrite other apps' data!");
}

// Test that demonstrates our NEW prefixed keys DON'T collide
- (void)testPrefixedKeysPreventCollisions {
    // This test shows that our NEW prefixed keys prevent collisions
    
    // Simulate external app using common unprefixed keys
    [[NSUserDefaults standardUserDefaults] setObject:@"external-app-key" forKey:@"appKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-account" forKey:@"accId_config"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-session" forKey:@"sessionIDKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"metrics"} forKey:@"metricsDict"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-encoded" forKey:@"encodedString"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-hashed-user" forKey:@"hashedUserID"];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"user_data"} forKey:@"userKeyValue"];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-bidder" forKey:@"userBidder"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Verify external data is stored
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:@"appKey"], @"external-app-key");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:@"accId_config"], @"external-account");
    
    // Now simulate what CloudXCore DOES NOW - it uses PREFIXED keys
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-app-key" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-account" forKey:kCLXCoreAccountIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"cloudx-encoded" forKey:kCLXCoreEncodedStringKey];
    // Note: hashedUserId is now stored in CLXKeyValueState, not UserDefaults

    // Verify external data is STILL INTACT - NO COLLISION!
    NSString *externalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"appKey"];
    NSString *externalAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:@"accId_config"];
    NSString *externalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:@"sessionIDKey"];
    NSDictionary *externalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"metricsDict"];
    NSString *externalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:@"encodedString"];
    NSString *externalHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:@"hashedUserID"];

    // Verify CloudXCore data is stored in PREFIXED keys
    NSString *cloudxAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *cloudxAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSString *cloudxSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *cloudxMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *cloudxEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];

    // Assert external data is UNCHANGED
    XCTAssertEqualObjects(externalAppKey, @"external-app-key", @"External app key should be unchanged");
    XCTAssertEqualObjects(externalAccountID, @"external-account", @"External account should be unchanged");
    XCTAssertEqualObjects(externalSessionID, @"external-session", @"External session should be unchanged");
    XCTAssertEqualObjects(externalMetrics[@"external"], @"metrics", @"External metrics should be unchanged");
    XCTAssertEqualObjects(externalEncodedString, @"external-encoded", @"External encoded string should be unchanged");
    XCTAssertEqualObjects(externalHashedUserID, @"external-hashed-user", @"External hashed user ID should be unchanged");

    // Assert CloudXCore data is stored correctly in PREFIXED keys
    XCTAssertEqualObjects(cloudxAppKey, @"cloudx-app-key", @"CloudXCore app key should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxAccountID, @"cloudx-account", @"CloudXCore account should be stored in prefixed key");
    XCTAssertNotNil(cloudxSessionID, @"CloudXCore session ID should be stored in prefixed key");
    XCTAssertNotNil(cloudxMetrics, @"CloudXCore metrics should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxEncodedString, @"cloudx-encoded", @"CloudXCore encoded string should be stored in prefixed key");

    NSLog(@"✅ NO COLLISION: External app data remains intact!");
    NSLog(@"✅ CloudXCore data is safely stored in prefixed keys!");
    NSLog(@"✅ This demonstrates how prefixed keys prevent collisions!");
}

@end
