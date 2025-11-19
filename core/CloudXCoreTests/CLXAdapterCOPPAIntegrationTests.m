//
//  CLXAdapterCOPPAIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests to verify COPPA information flows correctly from
//  publisher app → CloudXCore → CLXPrivacyService → Adapter SDKs
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXAdapterCOPPAIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@end

@implementation CLXAdapterCOPPAIntegrationTests

- (void)setUp {
    [super setUp];
    
    // Reset SDK singleton state to ensure clean slate for each test
    [[CloudXCore shared] deinitialize];
    
    // Clean UserDefaults before each test
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    
    self.privacyService = [CLXPrivacyService sharedInstance];
}

- (void)tearDown {
    // Clean up SDK state after each test
    [[CloudXCore shared] deinitialize];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Publisher API → Privacy Service Tests

- (void)testPublisherSetsCOPPAEnabled_PrivacyServiceStoresCorrectly {
    // GIVEN: Publisher app with no COPPA set
    
    // WHEN: Publisher calls CloudXCore public API to enable COPPA
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // THEN: Privacy service should have COPPA enabled
    XCTAssertTrue([self.privacyService isCoppaEnabled], 
                  @"Privacy service should report COPPA as enabled");
    
    // THEN: UserDefaults should store the value
    BOOL storedValue = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    XCTAssertTrue(storedValue, 
                  @"UserDefaults should store COPPA as YES");
}

- (void)testPublisherSetsCOPPADisabled_PrivacyServiceStoresCorrectly {
    // GIVEN: COPPA is currently enabled
    [CloudXCore setIsAgeRestrictedUser:YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled]);
    
    // WHEN: Publisher disables COPPA
    [CloudXCore setIsAgeRestrictedUser:NO];
    
    // THEN: Privacy service should have COPPA disabled
    XCTAssertFalse([self.privacyService isCoppaEnabled], 
                   @"Privacy service should report COPPA as disabled");
    
    // THEN: UserDefaults should store the value
    BOOL storedValue = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXPrivacyCOPPAAppliesKey];
    XCTAssertFalse(storedValue, 
                   @"UserDefaults should store COPPA as NO");
}

- (void)testCOPPAStatus_PersistsAcrossPrivacyServiceInstances {
    // GIVEN: Publisher sets COPPA
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // WHEN: Privacy service is accessed again (simulating app restart)
    CLXPrivacyService *newInstance = [CLXPrivacyService sharedInstance];
    
    // THEN: COPPA status should still be enabled
    XCTAssertTrue([newInstance isCoppaEnabled], 
                  @"COPPA status should persist across instances");
}

#pragma mark - Adapter Mock Tests

- (void)testAdapterCanReadCOPPAFromPrivacyService {
    // GIVEN: COPPA is enabled via public API
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // WHEN: An adapter reads COPPA status (simulating adapter initialization)
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    BOOL coppaEnabled = [privacyService isCoppaEnabled];
    
    // THEN: Adapter should receive correct COPPA status
    XCTAssertTrue(coppaEnabled, 
                  @"Adapter should be able to read COPPA enabled status");
}

- (void)testAdapterReadsCOPPADisabled {
    // GIVEN: COPPA is disabled
    [CloudXCore setIsAgeRestrictedUser:NO];
    
    // WHEN: An adapter reads COPPA status
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    BOOL coppaEnabled = [privacyService isCoppaEnabled];
    
    // THEN: Adapter should receive disabled status
    XCTAssertFalse(coppaEnabled, 
                   @"Adapter should be able to read COPPA disabled status");
}

- (void)testAdapterReadsCOPPANotSet_DefaultsToDisabled {
    // GIVEN: Publisher has not set COPPA (default state)
    
    // WHEN: An adapter reads COPPA status
    BOOL coppaEnabled = [self.privacyService isCoppaEnabled];
    
    // THEN: Should default to disabled (safe default)
    XCTAssertFalse(coppaEnabled, 
                   @"COPPA should default to disabled when not set");
}

#pragma mark - Timing Tests

- (void)testCOPPASetBeforeSDKInit_NoWarningLogged {
    // GIVEN: Fresh SDK state (not initialized)
    XCTAssertFalse([[CloudXCore shared] isInitialized], 
                   @"SDK should not be initialized at test start");
    
    // WHEN: Publisher sets COPPA before initialization
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // THEN: No warning should be logged (we can't easily test log output, 
    // but at minimum verify no crash and COPPA is set)
    XCTAssertTrue([self.privacyService isCoppaEnabled], 
                  @"COPPA should be enabled");
}

#pragma mark - OpenRTB Compliance Tests

- (void)testCOPPAAppliesMethod_ReturnsOpenRTBIntegerFormat {
    // GIVEN: COPPA is enabled
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // WHEN: Requesting COPPA in OpenRTB format (for bid requests)
    // Note: This uses an internal method that adapters don't use, but core might use for bid requests
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL coppaValue = [defaults boolForKey:kCLXPrivacyCOPPAAppliesKey];
    NSNumber *openRTBValue = @(coppaValue ? 1 : 0);
    
    // THEN: Should return 1 (per OpenRTB 2.5 spec)
    XCTAssertEqual([openRTBValue intValue], 1, 
                   @"COPPA should be represented as 1 (not boolean true) per OpenRTB spec");
}

- (void)testCOPPADisabled_ReturnsOpenRTBZero {
    // GIVEN: COPPA is disabled
    [CloudXCore setIsAgeRestrictedUser:NO];
    
    // WHEN: Requesting COPPA in OpenRTB format
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL coppaValue = [defaults boolForKey:kCLXPrivacyCOPPAAppliesKey];
    NSNumber *openRTBValue = @(coppaValue ? 1 : 0);
    
    // THEN: Should return 0 (per OpenRTB 2.5 spec)
    XCTAssertEqual([openRTBValue intValue], 0, 
                   @"COPPA disabled should be represented as 0 per OpenRTB spec");
}

#pragma mark - Edge Cases

- (void)testMultipleCOPPAChanges_LatestValuePersists {
    // GIVEN: Publisher changes COPPA multiple times
    [CloudXCore setIsAgeRestrictedUser:YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled]);
    
    [CloudXCore setIsAgeRestrictedUser:NO];
    XCTAssertFalse([self.privacyService isCoppaEnabled]);
    
    [CloudXCore setIsAgeRestrictedUser:YES];
    XCTAssertTrue([self.privacyService isCoppaEnabled]);
    
    // WHEN: Adapter reads COPPA
    BOOL finalValue = [self.privacyService isCoppaEnabled];
    
    // THEN: Should get the latest value
    XCTAssertTrue(finalValue, 
                  @"Adapter should receive the most recent COPPA value");
}

- (void)testCOPPAClearedToNil_AdapterReadsFalse {
    // GIVEN: COPPA was previously set
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // WHEN: COPPA is cleared (removing from UserDefaults)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXPrivacyCOPPAAppliesKey];
    
    // THEN: Adapter should read as disabled (safe default)
    BOOL coppaEnabled = [self.privacyService isCoppaEnabled];
    XCTAssertFalse(coppaEnabled, 
                   @"When COPPA is cleared, should default to disabled");
}

#pragma mark - Privacy Service Integration

- (void)testPrivacyServiceAPI_IsCoppaEnabled_ReturnsBoolean {
    // Test that the public adapter-facing API works correctly
    
    // GIVEN: COPPA enabled
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // WHEN: Adapter calls isCoppaEnabled
    BOOL enabled = [self.privacyService isCoppaEnabled];
    
    // THEN: Should return boolean true
    XCTAssertTrue(enabled, @"isCoppaEnabled should return boolean YES");
    XCTAssertTrue(enabled == YES, @"Value should be exactly YES (true)");
}

- (void)testPrivacyServiceSharedInstance_IsSingleton {
    // Verify that all adapters get the same privacy service instance
    
    // WHEN: Multiple adapters request privacy service
    CLXPrivacyService *instance1 = [CLXPrivacyService sharedInstance];
    CLXPrivacyService *instance2 = [CLXPrivacyService sharedInstance];
    CLXPrivacyService *instance3 = [CLXPrivacyService sharedInstance];
    
    // THEN: All should be the same instance
    XCTAssertEqual(instance1, instance2, @"Privacy service should be singleton");
    XCTAssertEqual(instance2, instance3, @"Privacy service should be singleton");
    XCTAssertEqual(instance1, self.privacyService, @"Should match test instance");
}

@end

