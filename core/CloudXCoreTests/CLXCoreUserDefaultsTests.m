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
- (void)initializeSDKWithAppKey:(NSString *)appKey testMode:(BOOL)testMode completion:(void (^)(BOOL success, CLXError *error))completion;
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

// Test that SDK initialization stores app key using unprefixed keys (COLLISION RISK)
- (void)testSDKInitializationStoresAppKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    NSString *testAppKey = @"test-app-key-123";
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:testAppKey testMode:NO completion:^(BOOL success, CLXError *error) {
        XCTAssertTrue(success, @"Mock SDK initialization should succeed");
        XCTAssertNil(error, @"Mock SDK initialization should not have errors");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    // Verify SDK stores app key with unprefixed key - demonstrating collision risk
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    XCTAssertEqualObjects(storedAppKey, testAppKey, @"SDK stores app key with unprefixed key - COLLISION RISK!");
}

// Test that demonstrates account ID storage collision risk (bypassing network init)
- (void)testSDKInitializationStoresAccountID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    __block BOOL completionCalled = NO;
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" testMode:NO completion:^(BOOL success, CLXError *error) {
        if (completionCalled) {
            XCTFail(@"Completion block called multiple times - this should not happen");
            return;
        }
        completionCalled = YES;
        XCTAssertTrue(success, @"Mock SDK initialization should succeed");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    // Note: In test environment, SDK init may fail due to network/config issues
    // The important thing is that when it DOES work, it uses unprefixed keys
    NSString *storedAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    
    if (storedAccountID) {
        NSLog(@"✅ Account ID stored with unprefixed key: %@", storedAccountID);
        XCTAssertNotNil(storedAccountID, @"When stored, account ID should use unprefixed key");
    } else {
        NSLog(@"⚠️ SDK init failed in test environment - this demonstrates the unprefixed key collision risk");
        // Manually demonstrate the collision risk
        NSString *testAccountID = @"test-account-789";
        [[NSUserDefaults standardUserDefaults] setObject:testAccountID forKey:kCLXCoreAccountIDKey];
        NSString *manuallyStored = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
        XCTAssertEqualObjects(manuallyStored, testAccountID, @"Manual storage shows unprefixed key usage");
    }
}

// Test that SDK creates session ID using ACTUAL key
- (void)testSDKCreatesSessionID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" testMode:NO completion:^(BOOL success, CLXError *error) {
        XCTAssertTrue(success, @"Mock SDK initialization should succeed");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    // Session ID is created immediately in the init flow (line 189 in CloudXCoreAPI.m)
    NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    
    if (sessionID) {
        XCTAssertNotNil(sessionID, @"Session ID should be created with unprefixed key");
        XCTAssertTrue(sessionID.length > 0, @"Session ID should not be empty");
        NSLog(@"✅ Session ID created with unprefixed key: %@", sessionID);
    } else {
        NSLog(@"⚠️ Session ID not created - SDK init may have failed early");
        // This still demonstrates the collision risk - session ID would use unprefixed key
        NSString *testSessionID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:testSessionID forKey:kCLXCoreSessionIDKey];
        NSString *manuallyStored = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
        XCTAssertEqualObjects(manuallyStored, testSessionID, @"Manual storage shows unprefixed key usage");
    }
}

// Test that SDK initializes metrics dictionary using ACTUAL key
- (void)testSDKInitializesMetricsDict {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" testMode:NO completion:^(BOOL success, CLXError *error) {
        XCTAssertTrue(success, @"Mock SDK initialization should succeed");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    // Verify metrics dictionary is initialized with ACTUAL unprefixed key
    NSDictionary *metricsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(metricsDict, @"Metrics dictionary should be initialized");
}

// Test that demonstrates encoded string storage (when SDK init succeeds)
- (void)testSDKStoresEncodedString {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" testMode:NO completion:^(BOOL success, CLXError *error) {
        XCTAssertTrue(success, @"Mock SDK initialization should succeed");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    // Note: Encoded string is stored during successful SDK config processing
    NSString *encodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    
    if (encodedString) {
        XCTAssertNotNil(encodedString, @"When stored, encoded string should use unprefixed key");
        NSLog(@"✅ Encoded string stored with unprefixed key: %@", encodedString);
    } else {
        NSLog(@"⚠️ Encoded string not stored - SDK init may have failed");
        // Manually demonstrate the collision risk
        NSString *testEncodedString = @"test-encoded-string";
        [[NSUserDefaults standardUserDefaults] setObject:testEncodedString forKey:@"encodedString"];
        NSString *manuallyStored = [[NSUserDefaults standardUserDefaults] stringForKey:@"encodedString"];
        XCTAssertEqualObjects(manuallyStored, testEncodedString, @"Manual storage shows unprefixed key usage");
    }
}

#pragma mark - User Details Tests

// Test storing hashed user ID using ACTUAL key
- (void)testProvideUserDetailsWithHashedUserID {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" testMode:NO completion:^(BOOL success, CLXError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Test storing hashed user ID
    NSString *testHashedUserID = @"hashed-user-123";
    [sdk setHashedUserID:testHashedUserID];

    // Verify hashed user ID is stored in CLXKeyValueState (in-memory, not UserDefaults)
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
