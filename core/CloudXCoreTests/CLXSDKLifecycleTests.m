//
//  CLXSDKLifecycleTests.m
//  CloudXCoreTests
//
//  Tests for SDK lifecycle management including deinitialize
//
//  NOTE: These tests focus on deinitialize logic without making network calls.
//  Full integration tests with real initialization should use valid test credentials
//  or mock network layers.
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

#pragma mark - Deinitialize Tests (No Network Calls)

// Test that deinitialize can be called before initialization
- (void)testDeinitialize_SafeBeforeInitialization {
    // Given: SDK is not initialized
    // When: Calling deinitialize
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Deinitialize before init should not throw");
    
    // Then: SDK should still not be initialized
    XCTAssertFalse([CloudXCore shared].isInitialized, @"SDK should remain uninitialized");
}

// Test that deinitialize can be called multiple times safely
- (void)testDeinitialize_SafeToCallMultipleTimes {
    // When: Calling deinitialize multiple times without initialization
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"First deinitialize should not throw");
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Second deinitialize should not throw");
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Third deinitialize should not throw");
    
    // Then: Should handle gracefully without crashes
    XCTAssertFalse([CloudXCore shared].isInitialized, @"SDK should still not be initialized");
}

// Test that deinitialize logs appropriate messages
- (void)testDeinitialize_LogsMessages {
    // Given: Logging is enabled
    [CloudXCore setLoggingEnabled:YES];
    [CloudXCore setMinLogLevel:CLXLogLevelInfo];
    
    // When: Deinitialize is called (even without initialization)
    XCTAssertNoThrow([[CloudXCore shared] deinitialize], @"Deinitialize should not throw");
    
    // Then: Should log deinitialize messages (verified in console)
    // Implementation logs: "🔄 [CloudXCore] Deinitializing SDK"
    // and "✅ [CloudXCore] SDK deinitialized successfully"
    // This test verifies no crash occurs - log messages are verified manually
}

#pragma mark - SDK State Management (No Network Calls)

// Test that SDK methods gracefully handle calls after deinitialize
- (void)testSDKMethods_AfterDeinitialize_HandleGracefully {
    // Given: SDK is deinitialized (never initialized)
    [[CloudXCore shared] deinitialize];
    
    // When: Calling SDK methods after deinitialize
    // Then: Should handle gracefully (may return nil or fail gracefully)
    XCTAssertNoThrow([[CloudXCore shared] setHashedUserID:@"test-user"], 
                     @"Setting user ID after deinitialize should not crash");
    
    XCTAssertNoThrow([[CloudXCore shared] setUserKeyValue:@"key" value:@"value"], 
                     @"Setting key-value after deinitialize should not crash");
    
    XCTAssertNoThrow([CloudXCore setIsAgeRestrictedUser:YES], 
                     @"Setting COPPA after deinitialize should not crash");
}

// NOTE: Initialization tests with invalid keys have been removed as they
// require network calls. These should be in integration tests, not unit tests.
// Unit tests should only test logic that can be verified without network I/O.

@end

