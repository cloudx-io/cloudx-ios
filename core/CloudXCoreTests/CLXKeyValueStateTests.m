//
//  CLXKeyValueStateTests.m
//  CloudXCoreTests
//
//  Tests for CLXKeyValueState singleton
//  SOLID Principle: Single Responsibility - Tests ONLY state management logic
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXKeyValueState.h>

@interface CLXKeyValueStateTests : XCTestCase
@property (nonatomic, strong) CLXKeyValueState *state;
@end

@implementation CLXKeyValueStateTests

- (void)setUp {
    [super setUp];
    self.state = [CLXKeyValueState shared];
    [self.state clearAllKeyValues]; // Start fresh
}

- (void)tearDown {
    [self.state clearAllKeyValues]; // Clean up
    [super tearDown];
}

#pragma mark - Singleton Tests

- (void)testSingleton_ReturnsSameInstance {
    CLXKeyValueState *state1 = [CLXKeyValueState shared];
    CLXKeyValueState *state2 = [CLXKeyValueState shared];
    
    XCTAssertEqual(state1, state2, @"Should return same singleton instance");
}

#pragma mark - User Key-Value Tests

- (void)testUserKeyValue_SetAndRetrieve {
    [self.state setUserKeyValue:@"age" value:@"25"];
    
    XCTAssertEqualObjects(self.state.userKeyValues[@"age"], @"25", 
                         @"User key-value should be stored");
}

- (void)testUserKeyValue_SetMultiple {
    [self.state setUserKeyValue:@"age" value:@"25"];
    [self.state setUserKeyValue:@"gender" value:@"male"];
    [self.state setUserKeyValue:@"interest" value:@"gaming"];
    
    XCTAssertEqual(self.state.userKeyValues.count, 3, @"Should store multiple user key-values");
    XCTAssertEqualObjects(self.state.userKeyValues[@"interest"], @"gaming", 
                         @"All values should be retrievable");
}

- (void)testUserKeyValue_OverwriteExisting {
    [self.state setUserKeyValue:@"age" value:@"25"];
    [self.state setUserKeyValue:@"age" value:@"30"];
    
    XCTAssertEqualObjects(self.state.userKeyValues[@"age"], @"30", 
                         @"Should overwrite existing value");
}

#pragma mark - App Key-Value Tests

- (void)testAppKeyValue_SetAndRetrieve {
    [self.state setAppKeyValue:@"version" value:@"1.2.3"];
    
    XCTAssertEqualObjects(self.state.appKeyValues[@"version"], @"1.2.3", 
                         @"App key-value should be stored");
}

- (void)testAppKeyValue_SetMultiple {
    [self.state setAppKeyValue:@"version" value:@"1.2.3"];
    [self.state setAppKeyValue:@"platform" value:@"ios"];
    [self.state setAppKeyValue:@"build" value:@"debug"];
    
    XCTAssertEqual(self.state.appKeyValues.count, 3, @"Should store multiple app key-values");
}

- (void)testAppKeyValue_IndependentFromUserKeyValues {
    [self.state setUserKeyValue:@"age" value:@"25"];
    [self.state setAppKeyValue:@"version" value:@"1.2.3"];
    
    XCTAssertEqual(self.state.userKeyValues.count, 1, @"User KVs should be independent");
    XCTAssertEqual(self.state.appKeyValues.count, 1, @"App KVs should be independent");
    XCTAssertNotEqualObjects(self.state.userKeyValues, self.state.appKeyValues, 
                            @"User and app KVs should be separate");
}

#pragma mark - Clear Tests

- (void)testClearAllKeyValues_RemovesAllData {
    [self.state setUserKeyValue:@"age" value:@"25"];
    [self.state setUserKeyValue:@"gender" value:@"male"];
    [self.state setAppKeyValue:@"version" value:@"1.2.3"];
    [self.state setAppKeyValue:@"platform" value:@"ios"];
    self.state.hashedUserId = @"hashed-123";
    
    [self.state clearAllKeyValues];
    
    XCTAssertEqual(self.state.userKeyValues.count, 0, @"User KVs should be cleared");
    XCTAssertEqual(self.state.appKeyValues.count, 0, @"App KVs should be cleared");
    XCTAssertNil(self.state.hashedUserId, @"Hashed user ID should be cleared");
}

#pragma mark - Hashed User ID Tests

- (void)testHashedUserId_SetAndRetrieve {
    self.state.hashedUserId = @"abc123hashed";
    
    XCTAssertEqualObjects(self.state.hashedUserId, @"abc123hashed", 
                         @"Hashed user ID should be stored");
}

- (void)testHashedUserId_CanBeNil {
    self.state.hashedUserId = @"abc123hashed";
    self.state.hashedUserId = nil;
    
    XCTAssertNil(self.state.hashedUserId, @"Hashed user ID should accept nil");
}

#pragma mark - Edge Cases

- (void)testEdgeCase_NilKey {
    XCTAssertNoThrow([self.state setUserKeyValue:nil value:@"value"], 
                     @"Should handle nil key gracefully");
    XCTAssertNoThrow([self.state setAppKeyValue:nil value:@"value"], 
                     @"Should handle nil key gracefully");
}

- (void)testEdgeCase_NilValue {
    XCTAssertNoThrow([self.state setUserKeyValue:@"key" value:nil], 
                     @"Should handle nil value gracefully");
    XCTAssertNoThrow([self.state setAppKeyValue:@"key" value:nil], 
                     @"Should handle nil value gracefully");
}

- (void)testEdgeCase_EmptyStringKey {
    [self.state setUserKeyValue:@"" value:@"value"];
    
    // Should either store or ignore gracefully
    XCTAssertNoThrow([self.state clearAllKeyValues], @"Should handle empty string key");
}

- (void)testEdgeCase_EmptyStringValue {
    [self.state setUserKeyValue:@"key" value:@""];
    
    XCTAssertEqualObjects(self.state.userKeyValues[@"key"], @"", 
                         @"Should allow empty string values");
}

#pragma mark - Data Isolation Tests

- (void)testDataIsolation_UserKVsDoNotAffectAppKVs {
    [self.state setUserKeyValue:@"shared_key" value:@"user_value"];
    [self.state setAppKeyValue:@"shared_key" value:@"app_value"];
    
    XCTAssertEqualObjects(self.state.userKeyValues[@"shared_key"], @"user_value", 
                         @"User KV should not be affected");
    XCTAssertEqualObjects(self.state.appKeyValues[@"shared_key"], @"app_value", 
                         @"App KV should not be affected");
}

#pragma mark - State Persistence Across Calls

- (void)testStatePersistence_ValuesPersistAcrossMultipleAccesses {
    [self.state setUserKeyValue:@"age" value:@"25"];
    
    // Access multiple times
    NSString *value1 = self.state.userKeyValues[@"age"];
    NSString *value2 = self.state.userKeyValues[@"age"];
    CLXKeyValueState *sameInstance = [CLXKeyValueState shared];
    NSString *value3 = sameInstance.userKeyValues[@"age"];
    
    XCTAssertEqualObjects(value1, @"25", @"Value should persist");
    XCTAssertEqualObjects(value2, @"25", @"Value should persist");
    XCTAssertEqualObjects(value3, @"25", @"Value should persist across singleton access");
}

@end

