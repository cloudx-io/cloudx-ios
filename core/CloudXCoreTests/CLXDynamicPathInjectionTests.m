//
//  CLXDynamicPathInjectionTests.m
//  CloudXCoreTests
//
//  Tests for NSDictionary+DynamicPath category
//  SOLID Principle: Single Responsibility - Tests ONLY dynamic path injection logic
//

#import <XCTest/XCTest.h>
#import <CloudXCore/NSDictionary+DynamicPath.h>

@interface CLXDynamicPathInjectionTests : XCTestCase
@end

@implementation CLXDynamicPathInjectionTests

#pragma mark - Simple Dot Notation Tests

- (void)testSimpleDotNotation_SingleLevel {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json clx_putAtDynamicPath:@"key" value:@"value"];
    
    XCTAssertEqualObjects(json[@"key"], @"value", @"Simple key should be set");
}

- (void)testSimpleDotNotation_TwoLevels {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json clx_putAtDynamicPath:@"user.name" value:@"John"];
    
    XCTAssertNotNil(json[@"user"], @"User object should be created");
    XCTAssertEqualObjects(json[@"user"][@"name"], @"John", @"Nested value should be set");
}

- (void)testSimpleDotNotation_ThreeLevels {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json clx_putAtDynamicPath:@"user.ext.data" value:@{@"age": @"25"}];
    
    XCTAssertNotNil(json[@"user"][@"ext"], @"Nested structure should be created");
    XCTAssertEqualObjects(json[@"user"][@"ext"][@"data"][@"age"], @"25", @"Deep nested value should be set");
}

#pragma mark - Array Wildcard Tests

- (void)testArrayWildcard_AppliesValueToAllElements {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [@[
        [NSMutableDictionary dictionary],
        [NSMutableDictionary dictionary],
        [NSMutableDictionary dictionary]
    ] mutableCopy];
    
    [json clx_putAtDynamicPath:@"imp[*].secure" value:@1];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertEqualObjects(impressions[0][@"secure"], @1, @"First impression should have secure");
    XCTAssertEqualObjects(impressions[1][@"secure"], @1, @"Second impression should have secure");
    XCTAssertEqualObjects(impressions[2][@"secure"], @1, @"Third impression should have secure");
}

- (void)testArrayWildcard_CreatesNestedStructure {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [@[
        [NSMutableDictionary dictionary]
    ] mutableCopy];
    
    [json clx_putAtDynamicPath:@"imp[*].ext.data.custom-key" value:@"1"];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertEqualObjects(impressions[0][@"ext"][@"data"][@"custom-key"], @"1", 
                         @"Should create nested structure in array element");
}

- (void)testArrayWildcard_HandlesEmptyArray {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [NSMutableArray array];
    
    [json clx_putAtDynamicPath:@"imp[*].secure" value:@1];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 1, @"Should create one element in empty array");
    XCTAssertEqualObjects(impressions[0][@"secure"], @1, @"Value should be set");
}

#pragma mark - Array Index Tests

- (void)testArrayIndex_SpecificElement {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [@[
        [NSMutableDictionary dictionary],
        [NSMutableDictionary dictionary]
    ] mutableCopy];
    
    [json clx_putAtDynamicPath:@"imp[1].tagid" value:@"banner-2"];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertNil(impressions[0][@"tagid"], @"First impression should not have tagid");
    XCTAssertEqualObjects(impressions[1][@"tagid"], @"banner-2", @"Second impression should have tagid");
}

- (void)testArrayIndex_AutoExpandsArray {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [NSMutableArray array];
    
    [json clx_putAtDynamicPath:@"imp[2].id" value:@"third"];
    
    NSArray *impressions = json[@"imp"];
    XCTAssertEqual(impressions.count, 3, @"Array should expand to accommodate index");
    XCTAssertEqualObjects(impressions[2][@"id"], @"third", @"Value at index 2 should be set");
}

#pragma mark - Edge Cases

- (void)testEdgeCase_NilPath {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    XCTAssertNoThrow([json clx_putAtDynamicPath:nil value:@"value"], 
                     @"Should handle nil path gracefully");
    XCTAssertEqual(json.count, 0, @"Dictionary should remain empty");
}

- (void)testEdgeCase_EmptyPath {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    XCTAssertNoThrow([json clx_putAtDynamicPath:@"" value:@"value"], 
                     @"Should handle empty path gracefully");
    XCTAssertEqual(json.count, 0, @"Dictionary should remain empty");
}

- (void)testEdgeCase_OverwriteExistingValue {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"user"] = @{@"name": @"Alice"};
    
    [json clx_putAtDynamicPath:@"user.name" value:@"Bob"];
    
    XCTAssertEqualObjects(json[@"user"][@"name"], @"Bob", @"Should overwrite existing value");
}

/**
 * CRITICAL BUG TEST: Verifies that injecting into a path where parent objects are 
 * immutable (NSDictionary vs NSMutableDictionary) preserves existing data.
 *
 * This test reproduces the bug where injecting at "app.ext.data" would wipe out
 * the existing "app.publisher.id" field because the app object was immutable.
 * The fix ensures we create mutableCopy instead of new empty dictionary.
 */
- (void)testCritical_PreservesExistingDataWhenParentIsImmutable {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Simulate bid request structure where convertApplicationToJSON returns [json copy] (immutable)
    json[@"app"] = @{
        @"id": @"app-123",
        @"bundle": @"com.example.app",
        @"publisher": @{
            @"id": @"publisher-456"
        }
    };
    
    // Inject at app.ext.data - this should NOT wipe out the existing app data
    [json clx_putAtDynamicPath:@"app.ext.data" value:@{@"version": @"1.0.0"}];
    
    // CRITICAL: Verify existing data is preserved
    XCTAssertEqualObjects(json[@"app"][@"id"], @"app-123", 
                         @"CRITICAL: app.id must be preserved after injection");
    XCTAssertEqualObjects(json[@"app"][@"bundle"], @"com.example.app", 
                         @"CRITICAL: app.bundle must be preserved after injection");
    XCTAssertEqualObjects(json[@"app"][@"publisher"][@"id"], @"publisher-456", 
                         @"CRITICAL: app.publisher.id must be preserved after injection");
    
    // And the new data should be there too
    XCTAssertEqualObjects(json[@"app"][@"ext"][@"data"][@"version"], @"1.0.0", 
                         @"Injected data should be present");
}

- (void)testCritical_PreservesExistingDataInNestedImmutableStructure {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Deeply nested immutable structure
    json[@"app"] = @{
        @"publisher": @{
            @"id": @"pub-789",
            @"ext": @{
                @"prebid": @{
                    @"parentAccount": @"parent-123"
                }
            }
        }
    };
    
    // Inject at app.ext.data - should not affect publisher subtree
    [json clx_putAtDynamicPath:@"app.ext.data" value:@{@"test": @"value"}];
    
    XCTAssertEqualObjects(json[@"app"][@"publisher"][@"id"], @"pub-789", 
                         @"Publisher ID must be preserved");
    XCTAssertEqualObjects(json[@"app"][@"publisher"][@"ext"][@"prebid"][@"parentAccount"], @"parent-123", 
                         @"Nested prebid data must be preserved");
    XCTAssertEqualObjects(json[@"app"][@"ext"][@"data"][@"test"], @"value", 
                         @"Injected data should be present");
}

- (void)testCritical_PreservesExistingDataInImmutableArray {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Immutable array with immutable dictionary elements
    json[@"user"] = @{
        @"ext": @{
            @"eids": @[@{@"source": @"existing.source", @"uids": @[@{@"id": @"existing-id"}]}]
        }
    };
    
    // Inject a new EID - should preserve existing
    NSDictionary *newEid = @{@"source": @"new.source", @"uids": @[@{@"id": @"new-id"}]};
    [json clx_putAtDynamicPath:@"user.ext.eids[*]" value:newEid];
    
    // The wildcard replaces all elements, so the new value should be there
    XCTAssertNotNil(json[@"user"][@"ext"][@"eids"], @"EIDs array should exist");
    XCTAssertEqual([json[@"user"][@"ext"][@"eids"] count], 1, @"Should have one element");
}

- (void)testEdgeCase_ComplexNestedPath {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"bid"] = [@{@"seatbid": [@[[NSMutableDictionary dictionary]] mutableCopy]} mutableCopy];
    
    [json clx_putAtDynamicPath:@"bid.seatbid[0].bid" value:@[@{@"id": @"123"}]];
    
    XCTAssertEqualObjects(json[@"bid"][@"seatbid"][0][@"bid"][0][@"id"], @"123", 
                         @"Should handle complex nested paths");
}

#pragma mark - Real-World OpenRTB Paths

- (void)testRealWorld_UserExtData {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *userData = @{@"age": @"25", @"interest": @"gaming"};
    
    [json clx_putAtDynamicPath:@"user.ext.data" value:userData];
    
    XCTAssertEqualObjects(json[@"user"][@"ext"][@"data"][@"age"], @"25", 
                         @"User key-values should be at correct path");
}

- (void)testRealWorld_AppExtData {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *appData = @{@"version": @"1.2.3", @"platform": @"ios"};
    
    [json clx_putAtDynamicPath:@"app.ext.data" value:appData];
    
    XCTAssertEqualObjects(json[@"app"][@"ext"][@"data"][@"version"], @"1.2.3", 
                         @"App key-values should be at correct path");
}

- (void)testRealWorld_ImpressionCustomKey {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"imp"] = [@[[NSMutableDictionary dictionary]] mutableCopy];
    
    [json clx_putAtDynamicPath:@"imp[*].ext.data.custom-key" value:@"3"];
    
    XCTAssertEqualObjects(json[@"imp"][0][@"ext"][@"data"][@"custom-key"], @"3", 
                         @"Custom key should be at correct path");
}

- (void)testRealWorld_UserExtEids {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *eid = @{
        @"source": @"com.example.app",
        @"uids": @[@{@"id": @"hashed-123", @"atype": @3}]
    };
    
    [json clx_putAtDynamicPath:@"user.ext.eids[*]" value:eid];
    
    XCTAssertEqualObjects(json[@"user"][@"ext"][@"eids"][0][@"source"], @"com.example.app", 
                         @"External IDs should be at correct path");
}

@end

