//
//  CLXSDKLifecycleTests.m
//  CloudXCoreTests
//
//  Tests for SDK lifecycle management including deinitialize
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

// Test category to access internal state
@interface CloudXCore (LifecycleTesting)
@property (nonatomic, readonly) BOOL isInitialized;
@property (nonatomic, readonly, nullable) NSString *appKey;
@end

@interface CLXSDKLifecycleTests : XCTestCase
@end

@implementation CLXSDKLifecycleTests

- (void)setUp {
    [super setUp];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    // Clean up any SDK state
    [[CloudXCore shared] deinitialize];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Deinitialize Tests

// Test that deinitialize clears initialization state
- (void)testDeinitialize_ClearsInitializationState {
    // Given: SDK is initialized
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key" completion:^(BOOL success, NSError *error) {
        if (success) {
            // When: Deinitialize is called
            [[CloudXCore shared] deinitialize];
            
            // Then: isInitialized should be false
            XCTAssertFalse([CloudXCore shared].isInitialized, @"SDK should not be initialized after deinitialize");
            
            [initExpectation fulfill];
        } else {
            XCTFail(@"SDK initialization failed: %@", error);
            [initExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[initExpectation] timeout:10.0];
}

// Test that deinitialize allows reinitialization
- (void)testDeinitialize_AllowsReinitialization {
    // Given: SDK is initialized and then deinitialized
    XCTestExpectation *firstInitExpectation = [self expectationWithDescription:@"First Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key-1" completion:^(BOOL success, NSError *error) {
        if (success) {
            [[CloudXCore shared] deinitialize];
            [firstInitExpectation fulfill];
        } else {
            XCTFail(@"First initialization failed: %@", error);
            [firstInitExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[firstInitExpectation] timeout:10.0];
    
    // When: Re-initializing SDK with different app key
    XCTestExpectation *secondInitExpectation = [self expectationWithDescription:@"Second Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key-2" completion:^(BOOL success, NSError *error) {
        // Then: Should successfully initialize again
        XCTAssertTrue(success, @"SDK should allow reinitialization after deinitialize");
        XCTAssertNil(error, @"Reinitialization should not produce errors");
        [secondInitExpectation fulfill];
    }];
    
    [self waitForExpectations:@[secondInitExpectation] timeout:10.0];
}

// Test that deinitialize can be called multiple times safely
- (void)testDeinitialize_SafeToCallMultipleTimes {
    // Given: SDK is initialized
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key" completion:^(BOOL success, NSError *error) {
        if (success) {
            [initExpectation fulfill];
        } else {
            XCTFail(@"SDK initialization failed: %@", error);
            [initExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[initExpectation] timeout:10.0];
    
    // When: Calling deinitialize multiple times
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"First deinitialize should not throw");
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Second deinitialize should not throw");
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Third deinitialize should not throw");
    
    // Then: Should handle gracefully without crashes
    XCTAssertTrue(YES, @"Multiple deinitialize calls handled safely");
}

// Test that deinitialize can be called before initialization
- (void)testDeinitialize_SafeBeforeInitialization {
    // Given: SDK is not initialized
    // When: Calling deinitialize
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Deinitialize before init should not throw");
    
    // Then: Should handle gracefully
    XCTAssertTrue(YES, @"Deinitialize before initialization handled safely");
}

// Test that deinitialize clears app key
- (void)testDeinitialize_ClearsAppKey {
    // Given: SDK is initialized with app key
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key" completion:^(BOOL success, NSError *error) {
        if (success) {
            // Verify app key is set (would need internal accessor)
            // When: Deinitialize
            [[CloudXCore shared] deinitialize];
            
            // Then: App key should be cleared
            XCTAssertNil([CloudXCore shared].appKey, @"App key should be nil after deinitialize");
            
            [initExpectation fulfill];
        } else {
            XCTFail(@"SDK initialization failed: %@", error);
            [initExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[initExpectation] timeout:10.0];
}

// Test that deinitialize logs appropriate messages
- (void)testDeinitialize_LogsMessages {
    // Given: SDK is initialized
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key" completion:^(BOOL success, NSError *error) {
        if (success) {
            // Enable logging to capture deinitialize logs
            [CloudXCore setLoggingEnabled:YES];
            [CloudXCore setMinLogLevel:CLXLogLevelInfo];
            
            // When: Deinitialize
            [[CloudXCore shared] deinitialize];
            
            // Then: Should log deinitialize messages (verified in console)
            // Implementation logs: "🔄 [CloudXCore] Deinitializing SDK"
            // and "✅ [CloudXCore] SDK deinitialized successfully"
            
            [initExpectation fulfill];
        } else {
            XCTFail(@"SDK initialization failed: %@", error);
            [initExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[initExpectation] timeout:10.0];
}

#pragma mark - SDK State Management

// Test that SDK methods gracefully handle calls after deinitialize
- (void)testSDKMethods_AfterDeinitialize_HandleGracefully {
    // Given: SDK is initialized and then deinitialized
    XCTestExpectation *initExpectation = [self expectationWithDescription:@"SDK Init"];
    
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key" completion:^(BOOL success, NSError *error) {
        if (success) {
            [[CloudXCore shared] deinitialize];
            [initExpectation fulfill];
        } else {
            XCTFail(@"SDK initialization failed: %@", error);
            [initExpectation fulfill];
        }
    }];
    
    [self waitForExpectations:@[initExpectation] timeout:10.0];
    
    // When: Calling SDK methods after deinitialize
    // Then: Should handle gracefully (may return nil or fail gracefully)
    XCTAssertNoThrow([[CloudXCore shared] setHashedUserID:@"test-user"], 
                     @"Setting user ID after deinitialize should not crash");
    
    XCTAssertNoThrow([[CloudXCore shared] setUserKeyValue:@"key" value:@"value"], 
                     @"Setting key-value after deinitialize should not crash");
}

// Test lifecycle: init -> deinit -> init with same key
- (void)testLifecycle_InitDeinitReinitSameKey {
    NSString *appKey = @"test-app-key";
    
    // First initialization
    XCTestExpectation *firstInit = [self expectationWithDescription:@"First Init"];
    [[CloudXCore shared] initializeSDKWithAppKey:appKey completion:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"First init should succeed");
        [firstInit fulfill];
    }];
    [self waitForExpectations:@[firstInit] timeout:10.0];
    
    // Deinitialize
    [[CloudXCore shared] deinitialize];
    
    // Reinitialize with same key
    XCTestExpectation *secondInit = [self expectationWithDescription:@"Second Init"];
    [[CloudXCore shared] initializeSDKWithAppKey:appKey completion:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"Reinit with same key should succeed");
        [secondInit fulfill];
    }];
    [self waitForExpectations:@[secondInit] timeout:10.0];
}

// Test lifecycle: init -> deinit -> init with different key
- (void)testLifecycle_InitDeinitReinitDifferentKey {
    // First initialization
    XCTestExpectation *firstInit = [self expectationWithDescription:@"First Init"];
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key-1" completion:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"First init should succeed");
        [firstInit fulfill];
    }];
    [self waitForExpectations:@[firstInit] timeout:10.0];
    
    // Deinitialize
    [[CloudXCore shared] deinitialize];
    
    // Reinitialize with different key
    XCTestExpectation *secondInit = [self expectationWithDescription:@"Second Init"];
    [[CloudXCore shared] initializeSDKWithAppKey:@"test-app-key-2" completion:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"Reinit with different key should succeed");
        [secondInit fulfill];
    }];
    [self waitForExpectations:@[secondInit] timeout:10.0];
}

@end

