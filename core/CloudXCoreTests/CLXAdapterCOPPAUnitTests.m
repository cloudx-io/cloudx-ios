//
//  CLXAdapterCOPPAUnitTests.m
//  CloudXCoreTests
//
//  Unit tests to verify COPPA handling at the CLXPrivacyService level.
//  These tests focus on the core privacy logic that adapters depend on.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXAdapterCOPPAUnitTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@end

@implementation CLXAdapterCOPPAUnitTests

- (void)setUp {
    [super setUp];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    self.privacyService = [CLXPrivacyService sharedInstance];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Core Privacy Service Tests

- (void)testSetIsAgeRestrictedUser_YES_StoresInUserDefaults {
    // WHEN: Setting age-restricted user to YES
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    // THEN: Should be stored in UserDefaults
    BOOL stored = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    XCTAssertTrue(stored, @"COPPA YES should be stored in UserDefaults");
}

- (void)testSetIsAgeRestrictedUser_NO_StoresInUserDefaults {
    // WHEN: Setting age-restricted user to NO
    [self.privacyService setIsAgeRestrictedUser:@NO];
    
    // THEN: Should be stored in UserDefaults as NO
    BOOL stored = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    XCTAssertFalse(stored, @"COPPA NO should be stored in UserDefaults");
}

- (void)testSetIsAgeRestrictedUser_nil_RemovesFromUserDefaults {
    // GIVEN: COPPA was previously set
    [self.privacyService setIsAgeRestrictedUser:@YES];
    XCTAssertNotNil([[NSUserDefaults standardUserDefaults] objectForKey:kCLXPrivacyCOPPAAppliesKey]);
    
    // WHEN: Setting to nil (clearing)
    [self.privacyService setIsAgeRestrictedUser:nil];
    
    // THEN: Should be removed from UserDefaults
    id stored = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXPrivacyCOPPAAppliesKey];
    XCTAssertNil(stored, @"COPPA should be removed from UserDefaults when set to nil");
}

- (void)testIsCoppaEnabled_WhenSet_ReturnsCorrectValue {
    // GIVEN: COPPA is set to YES
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    // WHEN: Checking if COPPA is enabled
    BOOL enabled = [self.privacyService isCoppaEnabled];
    
    // THEN: Should return YES
    XCTAssertTrue(enabled, @"isCoppaEnabled should return YES when COPPA is set");
}

- (void)testIsCoppaEnabled_WhenNotSet_ReturnsFalse {
    // GIVEN: COPPA is not set (default state)
    
    // WHEN: Checking if COPPA is enabled
    BOOL enabled = [self.privacyService isCoppaEnabled];
    
    // THEN: Should return NO (safe default)
    XCTAssertFalse(enabled, @"isCoppaEnabled should return NO when COPPA is not set");
}

- (void)testIsCoppaEnabled_WhenSetToNO_ReturnsFalse {
    // GIVEN: COPPA is explicitly set to NO
    [self.privacyService setIsAgeRestrictedUser:@NO];
    
    // WHEN: Checking if COPPA is enabled
    BOOL enabled = [self.privacyService isCoppaEnabled];
    
    // THEN: Should return NO
    XCTAssertFalse(enabled, @"isCoppaEnabled should return NO when COPPA is set to NO");
}

#pragma mark - UserDefaults Key Tests

- (void)testCOPPAUserDefaultsKey_IsCorrect {
    // Verify the key matches expected CloudX naming convention
    NSString *expectedKey = @"CLXPrivacyCOPPAApplies";
    XCTAssertEqualObjects(kCLXPrivacyCOPPAAppliesKey, expectedKey, 
                         @"COPPA UserDefaults key should match CloudX naming convention");
}

- (void)testCOPPAKey_IsSDKSpecific_NotIABStandard {
    // COPPA is SDK-specific (unlike GDPR/CCPA which use IAB standards)
    // Verify our key doesn't conflict with IAB keys
    XCTAssertFalse([kCLXPrivacyCOPPAAppliesKey hasPrefix:@"IAB"], 
                   @"COPPA key should not use IAB prefix (COPPA is not an IAB standard)");
    XCTAssertTrue([kCLXPrivacyCOPPAAppliesKey hasPrefix:@"CLX"], 
                  @"COPPA key should use CLX prefix for CloudX-specific data");
}

#pragma mark - Adapter Integration Points

- (void)testAdapterCanAccessPrivacyServiceSharedInstance {
    // Verify that adapters can get the shared privacy service instance
    
    // WHEN: Adapter requests shared instance (as they do in their initializers)
    CLXPrivacyService *service = [CLXPrivacyService sharedInstance];
    
    // THEN: Should return valid instance
    XCTAssertNotNil(service, @"Privacy service shared instance should be accessible to adapters");
}

- (void)testAdapterCanReadCOPPAViaIsCoppaEnabled {
    // Test the public adapter-facing API
    
    // GIVEN: Various COPPA states
    NSArray *testCases = @[
        @{@"coppa": @YES, @"expected": @YES},
        @{@"coppa": @NO, @"expected": @NO},
        @{@"coppa": [NSNull null], @"expected": @NO}  // nil case
    ];
    
    for (NSDictionary *testCase in testCases) {
        // WHEN: Setting COPPA and reading via adapter API
        id coppaValue = testCase[@"coppa"];
        if ([coppaValue isKindOfClass:[NSNull class]]) {
            [self.privacyService setIsAgeRestrictedUser:nil];
        } else {
            [self.privacyService setIsAgeRestrictedUser:coppaValue];
        }
        
        BOOL result = [self.privacyService isCoppaEnabled];
        BOOL expected = [testCase[@"expected"] boolValue];
        
        // THEN: Should match expected value
        XCTAssertEqual(result, expected, 
                      @"isCoppaEnabled should return %@ for COPPA=%@", 
                      expected ? @"YES" : @"NO", coppaValue);
    }
}

#pragma mark - Data Type Tests

- (void)testCOPPAStoredAsBoolean_ReadableAsInteger {
    // OpenRTB spec requires COPPA as integer (0 or 1), but iOS stores as BOOL
    // Verify conversion works correctly
    
    // GIVEN: COPPA is set to YES
    [self.privacyService setIsAgeRestrictedUser:@YES];
    
    // WHEN: Reading as boolean and converting to integer
    BOOL boolValue = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    NSInteger intValue = boolValue ? 1 : 0;
    
    // THEN: Should convert correctly to OpenRTB format
    XCTAssertEqual(intValue, 1, @"COPPA YES should convert to integer 1 for OpenRTB");
    
    // GIVEN: COPPA is set to NO
    [self.privacyService setIsAgeRestrictedUser:@NO];
    
    // WHEN: Reading and converting
    boolValue = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    intValue = boolValue ? 1 : 0;
    
    // THEN: Should be 0
    XCTAssertEqual(intValue, 0, @"COPPA NO should convert to integer 0 for OpenRTB");
}

#pragma mark - Concurrent Access Tests

- (void)testCOPPACanBeSetAndReadConcurrently {
    // Verify thread safety for adapters that might initialize on background threads
    
    XCTestExpectation *writeExpectation = [self expectationWithDescription:@"Write COPPA"];
    XCTestExpectation *readExpectation = [self expectationWithDescription:@"Read COPPA"];
    
    // WHEN: Setting and reading COPPA from different threads
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.privacyService setIsAgeRestrictedUser:@YES];
        [writeExpectation fulfill];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Small delay to ensure write happens first
        [NSThread sleepForTimeInterval:0.1];
        BOOL enabled = [self.privacyService isCoppaEnabled];
        XCTAssertTrue(enabled, @"Should be able to read COPPA from background thread");
        [readExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - State Transition Tests

- (void)testCOPPAStateTransitions {
    // Test all possible state transitions
    
    // Not Set → Enabled
    XCTAssertFalse([self.privacyService isCoppaEnabled], @"Initial state should be disabled");
    [self.privacyService setIsAgeRestrictedUser:@YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled], @"Should transition to enabled");
    
    // Enabled → Disabled
    [self.privacyService setIsAgeRestrictedUser:@NO];
    XCTAssertFalse([self.privacyService isCoppaEnabled], @"Should transition to disabled");
    
    // Disabled → Enabled
    [self.privacyService setIsAgeRestrictedUser:@YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled], @"Should transition back to enabled");
    
    // Enabled → Cleared
    [self.privacyService setIsAgeRestrictedUser:nil];
    XCTAssertFalse([self.privacyService isCoppaEnabled], @"Should transition to disabled when cleared");
}

#pragma mark - Documentation Compliance Tests

- (void)testPublicAPI_MatchesDocumentation {
    // Verify the public API works as documented in CloudXCoreAPI.h
    
    // Documentation states: "Set whether user is age-restricted (COPPA)"
    // with parameter "YES if user is age-restricted (under 13), NO otherwise"
    
    // Test: Setting YES for age-restricted user
    [CloudXCore setIsAgeRestrictedUser:YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled], 
                  @"Setting YES should enable COPPA per API documentation");
    
    // Test: Setting NO for non-age-restricted user
    [CloudXCore setIsAgeRestrictedUser:NO];
    XCTAssertFalse([self.privacyService isCoppaEnabled], 
                   @"Setting NO should disable COPPA per API documentation");
}

@end

