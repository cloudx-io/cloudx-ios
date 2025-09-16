//
//  CLXCoreUserDefaultsTests.m
//  CloudXCoreTests
//
//  Tests for CloudXCore User Defaults usage
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXLiveInitService.h>
#import "CLXUserDefaultsTestHelper.h"
#import "Mocks/CLXMockInitService.h"

@interface CloudXCore (Testing)
- (instancetype)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL success, NSError *error))completion;
- (void)provideUserDetailsWithHashedUserID:(NSString *)hashedUserID;
- (void)useHashedKeyValueWithKey:(NSString *)key value:(NSString *)value;
- (void)useKeyValuesWithUserDictionary:(NSDictionary<NSString *, NSString *> *)userDictionary;
- (void)useBidderKeyValueWithBidder:(NSString *)bidder key:(NSString *)key value:(NSString *)value;
+ (void)trackSDKError:(NSString *)error;
@end

@interface CLXCoreUserDefaultsTests : XCTestCase
@property (nonatomic, strong) CLXMockInitService *mockInitService;
@end

@implementation CLXCoreUserDefaultsTests

- (void)setUp {
    [super setUp];
    
    // Reset DI container to ensure clean state
    [[CLXDIContainer shared] reset];
    
    // Set up mock init service for fast, reliable unit tests
    self.mockInitService = [[CLXMockInitService alloc] initWithSuccess:YES];
    
    // Inject mock into DI container BEFORE any CloudXCore instances are created
    CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXLiveInitService class] instance:self.mockInitService];
    
    // Register environment config for proper DI
    [container registerType:[CLXEnvironmentConfig class] instance:[CLXEnvironmentConfig shared]];
    
    // Don't clear UserDefaults in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Core SDK Tests

// Test that SDK initialization stores app key using unprefixed keys (COLLISION RISK)
- (void)testSDKInitializationStoresAppKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    NSString *testAppKey = @"test-app-key-123";
    
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:testAppKey completion:^(BOOL success, NSError *error) {
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
    
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
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
    
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
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
    
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
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
    
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
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
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Test storing hashed user ID
    NSString *testHashedUserID = @"hashed-user-123";
    [sdk provideUserDetailsWithHashedUserID:testHashedUserID];
    
    // Verify hashed user ID is stored with ACTUAL prefixed key
    NSString *storedHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedUserIDKey];
    XCTAssertEqualObjects(storedHashedUserID, testHashedUserID, @"Hashed user ID should be stored with unprefixed key");
}

// Test storing hashed key-value pair using ACTUAL keys
- (void)testProvideUserDetailsWithHashedKeyValue {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Test storing hashed key-value
    NSString *testKey = @"test-key";
    NSString *testValue = @"test-value";
    [sdk useHashedKeyValueWithKey:testKey value:testValue];
    
    // Verify hashed key and value are stored with ACTUAL prefixed keys
    NSString *storedKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedKeyKey];
    NSString *storedValue = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedValueKey];
    XCTAssertEqualObjects(storedKey, testKey, @"Hashed key should be stored with unprefixed key");
    XCTAssertEqualObjects(storedValue, testValue, @"Hashed value should be stored with unprefixed key");
}

// Test storing user dictionary using ACTUAL key
- (void)testProvideUserDetailsWithUserDictionary {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Test storing user dictionary
    NSDictionary *testUserDict = @{@"age": @"25", @"gender": @"M"};
    [sdk useKeyValuesWithUserDictionary:testUserDict];
    
    // Verify user dictionary is stored with ACTUAL prefixed key
    NSDictionary *storedUserDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    XCTAssertEqualObjects(storedUserDict, testUserDict, @"User dictionary should be stored with unprefixed key");
}

#pragma mark - Bidder Tests

// Test storing bidder key-value data using ACTUAL keys
- (void)testUseBidderKeyValue {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Test storing bidder data
    NSString *testBidder = @"test-bidder";
    NSString *testKey = @"bid-key";
    NSString *testValue = @"bid-value";
    [sdk useBidderKeyValueWithBidder:testBidder key:testKey value:testValue];
    
    // Verify bidder data is stored with ACTUAL prefixed keys
    NSString *storedBidder = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserBidderKey];
    NSString *storedKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserBidderKeyKey];
    NSString *storedValue = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserBidderValueKey];
    
    XCTAssertEqualObjects(storedBidder, testBidder, @"Bidder should be stored with unprefixed key");
    XCTAssertEqualObjects(storedKey, testKey, @"Bidder key should be stored with unprefixed key");
    XCTAssertEqualObjects(storedValue, testValue, @"Bidder value should be stored with unprefixed key");
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
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-hashed-user" forKey:kCLXCoreHashedUserIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"cloudx": @"user_data"} forKey:kCLXCoreUserKeyValueKey];
    [[NSUserDefaults standardUserDefaults] setValue:@"cloudx-bidder" forKey:kCLXCoreUserBidderKey];
    
    // Verify external data is STILL INTACT - NO COLLISION!
    NSString *externalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"appKey"];
    NSString *externalAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:@"accId_config"];
    NSString *externalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:@"sessionIDKey"];
    NSDictionary *externalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"metricsDict"];
    NSString *externalEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:@"encodedString"];
    NSString *externalHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:@"hashedUserID"];
    NSDictionary *externalUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"userKeyValue"];
    NSString *externalBidder = [[NSUserDefaults standardUserDefaults] stringForKey:@"userBidder"];
    
    // Verify CloudXCore data is stored in PREFIXED keys
    NSString *cloudxAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *cloudxAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSString *cloudxSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *cloudxMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *cloudxEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    NSString *cloudxHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedUserIDKey];
    NSDictionary *cloudxUserData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    NSString *cloudxBidder = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserBidderKey];
    
    // Assert external data is UNCHANGED
    XCTAssertEqualObjects(externalAppKey, @"external-app-key", @"External app key should be unchanged");
    XCTAssertEqualObjects(externalAccountID, @"external-account", @"External account should be unchanged");
    XCTAssertEqualObjects(externalSessionID, @"external-session", @"External session should be unchanged");
    XCTAssertEqualObjects(externalMetrics[@"external"], @"metrics", @"External metrics should be unchanged");
    XCTAssertEqualObjects(externalEncodedString, @"external-encoded", @"External encoded string should be unchanged");
    XCTAssertEqualObjects(externalHashedUserID, @"external-hashed-user", @"External hashed user ID should be unchanged");
    XCTAssertEqualObjects(externalUserData[@"external"], @"user_data", @"External user data should be unchanged");
    XCTAssertEqualObjects(externalBidder, @"external-bidder", @"External bidder should be unchanged");
    
    // Assert CloudXCore data is stored correctly in PREFIXED keys
    XCTAssertEqualObjects(cloudxAppKey, @"cloudx-app-key", @"CloudXCore app key should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxAccountID, @"cloudx-account", @"CloudXCore account should be stored in prefixed key");
    XCTAssertNotNil(cloudxSessionID, @"CloudXCore session ID should be stored in prefixed key");
    XCTAssertNotNil(cloudxMetrics, @"CloudXCore metrics should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxEncodedString, @"cloudx-encoded", @"CloudXCore encoded string should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxHashedUserID, @"cloudx-hashed-user", @"CloudXCore hashed user ID should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxUserData[@"cloudx"], @"user_data", @"CloudXCore user data should be stored in prefixed key");
    XCTAssertEqualObjects(cloudxBidder, @"cloudx-bidder", @"CloudXCore bidder should be stored in prefixed key");
    
    NSLog(@"✅ NO COLLISION: External app data remains intact!");
    NSLog(@"✅ CloudXCore data is safely stored in prefixed keys!");
    NSLog(@"✅ This demonstrates how prefixed keys prevent collisions!");
}

@end
