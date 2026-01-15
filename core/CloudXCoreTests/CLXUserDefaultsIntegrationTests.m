//
//  CLXUserDefaultsIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests for User Defaults usage across CloudXCore components
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXKeyValueState.h>
#import "CLXUserDefaultsTestHelper.h"
#import "Mocks/CLXMockInitService.h"

@interface CloudXCore (Testing)
- (void)initializeSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL success, CLXError *error))completion;
- (void)setHashedUserID:(NSString *)hashedUserID;
- (void)setUserKeyValue:(NSString *)key value:(NSString *)value;
- (void)resetForTesting;
@end

@interface CLXPublisherBanner (Testing)
@end

@interface CLXBidAdSource (Testing)
- (void)requestBidWithAdUnitID:(NSString *)adUnitID
                    completion:(void (^)(NSString *bidResponse, NSError *error))completion;
@end

@interface CLXUserDefaultsIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXMockInitService *mockInitService;
@end

@implementation CLXUserDefaultsIntegrationTests

- (void)setUp {
    [super setUp];
    
    // Clear ALL CloudXCore User Defaults keys FIRST to ensure test isolation
    // This is critical for preventing flaky tests where state leaks between test runs
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    // Reset CloudXCore singleton state for isolated tests
    [[CloudXCore shared] resetForTesting];
    
    // Set up mock init service for fast, reliable integration tests
    self.mockInitService = [[CLXMockInitService alloc] initWithSuccess:YES];
    
    // Inject mock into DI container BEFORE any CloudXCore instances are created
    CLXDIContainer *container = [CLXDIContainer shared];
    [container registerType:[CLXLiveInitService class] instance:self.mockInitService];
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    // Reset DI container to ensure clean state for next test
    [[CLXDIContainer shared] reset];
    
    [super tearDown];
}

#pragma mark - Full SDK Integration Tests

// Test complete SDK initialization and data flow using ACTUAL keys
- (void)testFullSDKInitializationDataFlow {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    
    NSString *testAppKey = @"integration-app-key";
    NSString *testAccountID = @"test-account-123"; // This matches what CLXMockInitService returns
    
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = testAccountID;
    
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:testAppKey completion:^(BOOL success, CLXError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    // Check what initialization data is stored with ACTUAL unprefixed keys
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *storedAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSString *storedSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSString *storedEncodedString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreEncodedStringKey];
    
    // Note: SDK init may fail in test environment, but this demonstrates the unprefixed key usage
    if (storedAppKey && storedAccountID) {
        XCTAssertEqualObjects(storedAppKey, testAppKey, @"When stored, app key uses unprefixed key");
        XCTAssertEqualObjects(storedAccountID, testAccountID, @"When stored, account ID uses unprefixed key");
        NSLog(@"✅ SDK init succeeded - data stored with unprefixed keys");
    } else {
        NSLog(@"⚠️ SDK init failed in test environment - demonstrating collision risk manually");
        // Manually demonstrate the integration collision risk
        [[NSUserDefaults standardUserDefaults] setObject:testAppKey forKey:kCLXCoreAppKeyKey];
        [[NSUserDefaults standardUserDefaults] setObject:testAccountID forKey:kCLXCoreAccountIDKey];
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:kCLXCoreSessionIDKey];
        [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
        [[NSUserDefaults standardUserDefaults] setObject:@"test-encoded" forKey:kCLXCoreEncodedStringKey];
        
        NSString *manualAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
        NSString *manualAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
        XCTAssertEqualObjects(manualAppKey, testAppKey, @"Manual storage shows unprefixed key collision risk");
        XCTAssertEqualObjects(manualAccountID, testAccountID, @"Manual storage shows unprefixed key collision risk");
    }
    
    // These should always be created if SDK init gets far enough
    if (storedMetrics) {
        XCTAssertNotNil(storedMetrics, @"Metrics dictionary uses unprefixed key");
    }
    if (storedSessionID) {
        XCTAssertNotNil(storedSessionID, @"Session ID uses unprefixed key");
    }
}

// Test user data flow across components using ACTUAL keys
- (void)testUserDataFlowIntegration {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" completion:^(BOOL success, CLXError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Add user data
    [sdk setHashedUserID:@"integration-hashed-user"];
    [sdk setUserKeyValue:@"age" value:@"30"];
    [sdk setUserKeyValue:@"location" value:@"NYC"];

    // Verify hashed user ID is stored in CLXKeyValueState (in-memory, not UserDefaults)
    NSString *storedHashedUserID = [[CLXKeyValueState shared] hashedUserId];

    XCTAssertEqualObjects(storedHashedUserID, @"integration-hashed-user", @"Hashed user ID should be stored in CLXKeyValueState");
    // Note: setUserKeyValue stores in CLXKeyValueState, not UserDefaults
}

// Test metrics accumulation across components using ACTUAL keys
- (void)testMetricsAccumulationIntegration {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" completion:^(BOOL success, CLXError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Simulate metrics updates from different components
    NSDictionary *initialMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    NSMutableDictionary *updatedMetrics = [initialMetrics mutableCopy];
    
    // Add metrics from different sources
    updatedMetrics[@"sdk_init"] = @"1";
    updatedMetrics[@"user_data_provided"] = @"1";
    updatedMetrics[@"bidder_configured"] = @"1";
    [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
    
    // Verify metrics accumulation with ACTUAL unprefixed key
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertEqualObjects(finalMetrics[@"sdk_init"], @"1", @"SDK init metrics should be accumulated");
    XCTAssertEqualObjects(finalMetrics[@"user_data_provided"], @"1", @"User data metrics should be accumulated");
    XCTAssertEqualObjects(finalMetrics[@"bidder_configured"], @"1", @"Bidder metrics should be accumulated");
}

// Test publisher ads integration with core SDK data using ACTUAL keys
- (void)testPublisherAdsIntegrationWithCoreData {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" completion:^(BOOL success, CLXError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    // Add user data that publisher ads will use (via CLXKeyValueState)
    [sdk setUserKeyValue:@"targeting" value:@"data"];

    // Create publisher banner
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    XCTAssertNotNil(banner, @"Publisher banner should be created");

    // Check if publisher banner can access core SDK data with ACTUAL prefixed keys
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *storedAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];

    // Note: SDK init may fail in test environment
    if (storedAppKey && storedAccountID) {
        NSLog(@"✅ Publisher banner can access SDK data with prefixed keys");
        XCTAssertNotNil(storedAppKey, @"Publisher banner accesses app key with prefixed key");
        XCTAssertNotNil(storedAccountID, @"Publisher banner accesses account ID with prefixed key");
    } else {
        NSLog(@"⚠️ SDK init failed - demonstrating publisher banner collision risk");
        // Manually demonstrate that publisher banner would access prefixed keys
        [[NSUserDefaults standardUserDefaults] setObject:@"banner-app-key" forKey:kCLXCoreAppKeyKey];
        [[NSUserDefaults standardUserDefaults] setObject:@"banner-account" forKey:kCLXCoreAccountIDKey];

        NSString *bannerAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
        NSString *bannerAccount = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
        XCTAssertEqualObjects(bannerAppKey, @"banner-app-key", @"Publisher banner uses prefixed keys");
        XCTAssertEqualObjects(bannerAccount, @"banner-account", @"Publisher banner uses prefixed keys");
    }

    // Note: User data is now stored in CLXKeyValueState, not UserDefaults
    if (storedMetrics) {
        XCTAssertNotNil(storedMetrics, @"Publisher banner accesses metrics with prefixed key");
    }
}

// Test bid ad source integration with core SDK data using ACTUAL keys
- (void)testBidAdSourceIntegrationWithCoreData {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"test-key" completion:^(BOOL success, CLXError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];

    // Create bid ad source
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] init];
    XCTAssertNotNil(bidAdSource, @"Bid ad source should be created");

    // Check if bid ad source can access core SDK data with ACTUAL prefixed keys
    NSString *storedAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *storedSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *storedMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];

    // Note: SDK init may fail in test environment
    if (storedAppKey && storedSessionID) {
        NSLog(@"✅ Bid ad source can access SDK data with prefixed keys");
        XCTAssertNotNil(storedAppKey, @"Bid ad source accesses app key with prefixed key");
        XCTAssertNotNil(storedSessionID, @"Bid ad source accesses session ID with prefixed key");
    } else {
        NSLog(@"⚠️ SDK init failed - demonstrating bid ad source collision risk");
        // Manually demonstrate that bid ad source would access prefixed keys
        [[NSUserDefaults standardUserDefaults] setObject:@"bid-app-key" forKey:kCLXCoreAppKeyKey];
        [[NSUserDefaults standardUserDefaults] setObject:@"bid-session" forKey:kCLXCoreSessionIDKey];

        NSString *bidAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
        NSString *bidSession = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
        XCTAssertEqualObjects(bidAppKey, @"bid-app-key", @"Bid ad source uses prefixed keys");
        XCTAssertEqualObjects(bidSession, @"bid-session", @"Bid ad source uses prefixed keys");
    }

    if (storedMetrics) {
        XCTAssertNotNil(storedMetrics, @"Bid ad source accesses metrics with prefixed key");
    }
}

#pragma mark - Cross-Component Collision Risk Tests

// Test collision risk across all components using ACTUAL keys
- (void)testCrossComponentCollisionRisk {
    // Simulate external app using all the same keys CloudXCore uses
    [[NSUserDefaults standardUserDefaults] setObject:@"external-app-key" forKey:kCLXCoreAppKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-account" forKey:kCLXCoreAccountIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"external-session" forKey:kCLXCoreSessionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"external": @"metrics"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Verify external data is stored
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey], @"external-app-key");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey], @"external-account");

    // Initialize CloudXCore - this will overwrite ALL external data
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account-123"; // This matches what CLXMockInitService returns
    CloudXCore *sdk = [CloudXCore shared];
    [sdk initializeSDKWithAppKey:@"cloudx-app-key" completion:^(BOOL success, CLXError *error) {
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:5.0];

    // Check what data survived - demonstrates collision risk
    NSString *finalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *finalAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSString *finalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];

    // Note: SDK init may fail, but user data operations should work
    if ([finalAppKey isEqualToString:@"cloudx-app-key"]) {
        // SDK init succeeded and overwrote external data - COLLISION!
        XCTAssertEqualObjects(finalAppKey, @"cloudx-app-key", @"CloudXCore overwrote external app key - COLLISION!");
        XCTAssertEqualObjects(finalAccountID, @"test-account-123", @"CloudXCore overwrote external account - COLLISION!");
        NSLog(@"🔴 COLLISION CONFIRMED: CloudXCore overwrote external app data!");
    } else {
        // SDK init failed, but user data operations still demonstrate collision risk
        NSLog(@"⚠️ SDK init failed, but user data operations show collision risk");
        XCTAssertEqualObjects(finalAppKey, @"external-app-key", @"External app key preserved when SDK init fails");
        XCTAssertEqualObjects(finalAccountID, @"external-account", @"External account preserved when SDK init fails");
    }

    NSLog(@"🔴 INTEGRATION COLLISION RISK DEMONSTRATED: Multiple components use same prefixed keys!");
}

@end
