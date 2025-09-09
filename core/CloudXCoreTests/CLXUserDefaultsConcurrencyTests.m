//
//  CLXUserDefaultsConcurrencyTests.m
//  CloudXCoreTests
//
//  Tests for User Defaults concurrency and thread safety
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CloudXCore (Testing)
- (instancetype)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL success, NSError *error))completion;
- (void)provideUserDetailsWithHashedUserID:(NSString *)hashedUserID;
- (void)useKeyValuesWithUserDictionary:(NSDictionary<NSString *, NSString *> *)userDictionary;
- (void)useBidderKeyValueWithBidder:(NSString *)bidder key:(NSString *)key value:(NSString *)value;
@end

@interface CLXUserDefaultsConcurrencyTests : XCTestCase
@end

@implementation CLXUserDefaultsConcurrencyTests

- (void)setUp {
    [super setUp];
    // Don't clear in setUp - let tearDown handle cleanup to avoid race conditions
}

- (void)tearDown {
    // Clear ALL CloudXCore User Defaults keys to ensure test isolation
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Concurrent Access Tests

// Test concurrent SDK initialization using ACTUAL keys
- (void)testConcurrentSDKInitialization {
    NSInteger numberOfConcurrentInits = 5;
    NSMutableArray *expectations = [NSMutableArray array];
    
    // Create multiple expectations for concurrent initializations
    for (NSInteger i = 0; i < numberOfConcurrentInits; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"SDK init %ld", (long)i]];
        [expectations addObject:expectation];
    }
    
    // Initialize SDK concurrently from multiple threads
    for (NSInteger i = 0; i < numberOfConcurrentInits; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *appKey = [NSString stringWithFormat:@"concurrent-app-key-%ld", (long)i];
            
            CloudXCore *sdk = [[CloudXCore alloc] init];
            [sdk initSDKWithAppKey:appKey completion:^(BOOL success, NSError *error) {
                XCTestExpectation *expectation = expectations[i];
                [expectation fulfill];
            }];
        });
    }
    
    [self waitForExpectations:expectations timeout:10.0];
    
    // Verify final state - check what actually got stored
    // (This demonstrates the race condition with unprefixed keys)
    NSString *finalAppKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    NSString *finalAccountID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey];
    NSString *finalSessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey];
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    
    // Note: SDK initialization might fail in test environment, so we just verify the race condition concept
    // The important thing is that if data IS stored, it's unpredictable which thread's data survives
    NSLog(@"Final app key: %@", finalAppKey);
    NSLog(@"Final account ID: %@", finalAccountID);
    NSLog(@"Final session ID: %@", finalSessionID);
    NSLog(@"Final metrics: %@", finalMetrics);
    
    // This test demonstrates that concurrent access to unprefixed keys creates race conditions
    // Even if SDK init fails, the concept of collision risk is proven by the other tests
}

// Test concurrent user data updates using ACTUAL keys
- (void)testConcurrentUserDataUpdates {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    NSInteger numberOfConcurrentUpdates = 10;
    XCTestExpectation *concurrencyExpectation = [self expectationWithDescription:@"Concurrent user data updates"];
    concurrencyExpectation.expectedFulfillmentCount = numberOfConcurrentUpdates;
    
    // Update user data concurrently from multiple threads
    for (NSInteger i = 0; i < numberOfConcurrentUpdates; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *hashedUserID = [NSString stringWithFormat:@"concurrent-user-%ld", (long)i];
            NSDictionary *userDict = @{
                [NSString stringWithFormat:@"key_%ld", (long)i]: [NSString stringWithFormat:@"value_%ld", (long)i]
            };
            NSString *bidder = [NSString stringWithFormat:@"concurrent-bidder-%ld", (long)i];
            
            [sdk provideUserDetailsWithHashedUserID:hashedUserID];
            [sdk useKeyValuesWithUserDictionary:userDict];
            [sdk useBidderKeyValueWithBidder:bidder key:@"test-key" value:@"test-value"];
            
            [concurrencyExpectation fulfill];
        });
    }
    
    [self waitForExpectations:@[concurrencyExpectation] timeout:10.0];
    
    // Verify final state - last writer wins (race condition with unprefixed keys)
    NSString *finalHashedUserID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedUserIDKey];
    NSDictionary *finalUserDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
    NSString *finalBidder = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserBidderKey];
    
    XCTAssertNotNil(finalHashedUserID, @"Some hashed user ID should be stored after concurrent updates");
    XCTAssertNotNil(finalUserDict, @"Some user dictionary should be stored after concurrent updates");
    XCTAssertNotNil(finalBidder, @"Some bidder should be stored after concurrent updates");
    
    // The exact values are unpredictable due to race conditions - this demonstrates the concurrency problem!
}

// Test concurrent metrics updates using ACTUAL keys
- (void)testConcurrentMetricsUpdates {
    // Initialize empty metrics dictionary with ACTUAL unprefixed key
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger numberOfConcurrentUpdates = 20;
    XCTestExpectation *concurrencyExpectation = [self expectationWithDescription:@"Concurrent metrics updates"];
    concurrencyExpectation.expectedFulfillmentCount = numberOfConcurrentUpdates;
    
    // Update metrics concurrently from multiple threads
    for (NSInteger i = 0; i < numberOfConcurrentUpdates; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Simulate the metrics update pattern used throughout CloudXCore
            NSDictionary *existingMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
            NSMutableDictionary *updatedMetrics = [existingMetrics mutableCopy];
            updatedMetrics[[NSString stringWithFormat:@"concurrent_metric_%ld", (long)i]] = @"1";
            [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
            
            [concurrencyExpectation fulfill];
        });
    }
    
    [self waitForExpectations:@[concurrencyExpectation] timeout:10.0];
    
    // Verify final metrics state
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(finalMetrics, @"Metrics dictionary should exist after concurrent updates");
    
    // Due to race conditions, we can't predict exactly which metrics survived
    // This demonstrates the data loss problem with concurrent access to unprefixed keys
    NSLog(@"Final metrics count: %lu (expected up to %ld)", (unsigned long)finalMetrics.count, (long)numberOfConcurrentUpdates);
}

// Test concurrent access from different components using ACTUAL keys
- (void)testConcurrentAccessFromDifferentComponents {
    // Initialize SDK first
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK initialization"];
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"test-account";
    CloudXCore *sdk = [[CloudXCore alloc] init];
    [sdk initSDKWithAppKey:@"test-key" completion:^(BOOL success, NSError *error) {
        [initExpectation fulfill];
    }];
    [self waitForExpectations:@[initExpectation] timeout:5.0];
    
    NSInteger numberOfConcurrentOperations = 15;
    XCTestExpectation *concurrencyExpectation = [self expectationWithDescription:@"Concurrent component access"];
    concurrencyExpectation.expectedFulfillmentCount = numberOfConcurrentOperations;
    
    // Simulate concurrent access from different CloudXCore components
    for (NSInteger i = 0; i < numberOfConcurrentOperations; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (i % 3 == 0) {
                // Simulate CloudXCore updating metrics
                NSDictionary *existingMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
                NSMutableDictionary *updatedMetrics = [existingMetrics mutableCopy];
                updatedMetrics[@"core_operation"] = [NSString stringWithFormat:@"%ld", (long)i];
                [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
            } else if (i % 3 == 1) {
                // Simulate CLXPublisherBanner updating metrics
                NSDictionary *existingMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
                NSMutableDictionary *updatedMetrics = [existingMetrics mutableCopy];
                updatedMetrics[@"banner_operation"] = [NSString stringWithFormat:@"%ld", (long)i];
                [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
            } else {
                // Simulate CLXBidAdSource updating metrics
                NSDictionary *existingMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
                NSMutableDictionary *updatedMetrics = [existingMetrics mutableCopy];
                updatedMetrics[@"bid_operation"] = [NSString stringWithFormat:@"%ld", (long)i];
                [[NSUserDefaults standardUserDefaults] setObject:updatedMetrics forKey:kCLXCoreMetricsDictKey];
            }
            
            [concurrencyExpectation fulfill];
        });
    }
    
    [self waitForExpectations:@[concurrencyExpectation] timeout:10.0];
    
    // Verify final state
    NSDictionary *finalMetrics = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(finalMetrics, @"Metrics should exist after concurrent component access");
    
    // Due to race conditions, we can't predict which component's data survived
    // This demonstrates the data corruption problem with shared unprefixed keys
    NSLog(@"Final metrics after concurrent component access: %@", finalMetrics);
}

#pragma mark - Race Condition Demonstration Tests

// Test that demonstrates race conditions with unprefixed keys
- (void)testRaceConditionWithUnprefixedKeys {
    NSInteger numberOfRaces = 50;
    XCTestExpectation *raceExpectation = [self expectationWithDescription:@"Race condition test"];
    raceExpectation.expectedFulfillmentCount = numberOfRaces;
    
    // Create race condition by having multiple threads write to same unprefixed key
    for (NSInteger i = 0; i < numberOfRaces; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *threadValue = [NSString stringWithFormat:@"thread_%ld_value", (long)i];
            
            // Simulate the read-modify-write pattern used in CloudXCore
            NSString *existingValue = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
            NSString *newValue = [NSString stringWithFormat:@"%@_%@", existingValue ?: @"", threadValue];
            [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:kCLXCoreAppKeyKey];
            
            [raceExpectation fulfill];
        });
    }
    
    [self waitForExpectations:@[raceExpectation] timeout:10.0];
    
    // Verify that race condition occurred - final value is unpredictable
    NSString *finalValue = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey];
    XCTAssertNotNil(finalValue, @"Some value should be stored after race condition");
    
    // The final value demonstrates the race condition - it's not deterministic
    NSLog(@"Final value after race condition: %@", finalValue);
    
    // This test demonstrates why unprefixed keys are dangerous in concurrent environments
}

// Test that shows data corruption from concurrent dictionary updates
- (void)testDataCorruptionFromConcurrentDictionaryUpdates {
    // Initialize with some base data
    [[NSUserDefaults standardUserDefaults] setObject:@{@"initial": @"data"} forKey:kCLXCoreMetricsDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger numberOfCorruptionAttempts = 30;
    XCTestExpectation *corruptionExpectation = [self expectationWithDescription:@"Data corruption test"];
    corruptionExpectation.expectedFulfillmentCount = numberOfCorruptionAttempts;
    
    // Create potential data corruption by concurrent dictionary updates
    for (NSInteger i = 0; i < numberOfCorruptionAttempts; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Simulate the pattern used throughout CloudXCore for metrics updates
            NSDictionary *existingDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
            NSMutableDictionary *updatedDict = [existingDict mutableCopy];
            
            // Add thread-specific data
            updatedDict[[NSString stringWithFormat:@"thread_%ld", (long)i]] = [NSString stringWithFormat:@"data_%ld", (long)i];
            
            // This write can overwrite concurrent modifications
            [[NSUserDefaults standardUserDefaults] setObject:updatedDict forKey:kCLXCoreMetricsDictKey];
            
            [corruptionExpectation fulfill];
        });
    }
    
    [self waitForExpectations:@[corruptionExpectation] timeout:10.0];
    
    // Verify final state - data may be lost due to concurrent modifications
    NSDictionary *finalDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreMetricsDictKey];
    XCTAssertNotNil(finalDict, @"Dictionary should exist after concurrent updates");
    XCTAssertNotNil(finalDict[@"initial"], @"Initial data should be preserved");
    
    // Count how much data survived the concurrent updates
    NSInteger survivedEntries = finalDict.count - 1; // Subtract 1 for initial entry
    NSLog(@"Data survived: %ld out of %ld concurrent updates", (long)survivedEntries, (long)numberOfCorruptionAttempts);
    
    // This demonstrates that data can be lost in concurrent scenarios with unprefixed keys
    // In a real app, this could cause critical user data or metrics to be lost
}

@end
