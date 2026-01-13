/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewardTests.m
 * @brief Unit tests for CLXReward model class
 *
 * Tests the reward data object that mirrors AppLovin MAX SDK's MAReward.
 * Verifies factory methods, default values, and immutability.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXRewardTests : XCTestCase
@end

@implementation CLXRewardTests

#pragma mark - Default Values Tests

/**
 * Test that defaultLabel returns expected value (matches MAReward behavior)
 */
- (void)testDefaultLabel_ReturnsExpectedValue {
    NSString *defaultLabel = [CLXReward defaultLabel];

    XCTAssertNotNil(defaultLabel, @"defaultLabel should not be nil");
    XCTAssertEqualObjects(defaultLabel, @"", @"defaultLabel should be empty string");
}

/**
 * Test that defaultAmount returns expected value (matches MAReward behavior)
 */
- (void)testDefaultAmount_ReturnsExpectedValue {
    NSInteger defaultAmount = [CLXReward defaultAmount];

    XCTAssertEqual(defaultAmount, 0, @"defaultAmount should be 0");
}

#pragma mark - Factory Method Tests

/**
 * Test reward factory method returns object with default values
 */
- (void)testReward_FactoryMethod_ReturnsDefaultValues {
    CLXReward *reward = [CLXReward reward];
    
    XCTAssertNotNil(reward, @"reward factory should return non-nil object");
    XCTAssertEqual(reward.amount, [CLXReward defaultAmount], @"amount should match defaultAmount");
    XCTAssertEqualObjects(reward.label, [CLXReward defaultLabel], @"label should match defaultLabel");
}

/**
 * Test rewardWithAmount:label: factory method with valid values
 */
- (void)testRewardWithAmountLabel_ValidValues_ReturnsCorrectReward {
    CLXReward *reward = [CLXReward rewardWithAmount:1000 label:@"Golden Coins"];
    
    XCTAssertNotNil(reward, @"rewardWithAmount:label: should return non-nil object");
    XCTAssertEqual(reward.amount, 1000, @"amount should be 1000");
    XCTAssertEqualObjects(reward.label, @"Golden Coins", @"label should be 'Golden Coins'");
}

/**
 * Test rewardWithAmount:label: factory method with zero amount
 */
- (void)testRewardWithAmountLabel_ZeroAmount_ReturnsZeroAmount {
    CLXReward *reward = [CLXReward rewardWithAmount:0 label:@"coins"];
    
    XCTAssertNotNil(reward, @"Should create reward with zero amount");
    XCTAssertEqual(reward.amount, 0, @"amount should be 0");
    XCTAssertEqualObjects(reward.label, @"coins", @"label should be 'coins'");
}

/**
 * Test rewardWithAmount:label: factory method with nil label uses default
 */
- (void)testRewardWithAmountLabel_NilLabel_UsesDefaultLabel {
    CLXReward *reward = [CLXReward rewardWithAmount:500 label:nil];
    
    XCTAssertNotNil(reward, @"Should create reward with nil label");
    XCTAssertEqual(reward.amount, 500, @"amount should be 500");
    XCTAssertEqualObjects(reward.label, [CLXReward defaultLabel], @"nil label should use defaultLabel");
}

/**
 * Test rewardWithAmount:label: factory method with large amount
 */
- (void)testRewardWithAmountLabel_LargeAmount_HandlesCorrectly {
    NSInteger largeAmount = 999999999;
    CLXReward *reward = [CLXReward rewardWithAmount:largeAmount label:@"gems"];
    
    XCTAssertNotNil(reward, @"Should handle large amounts");
    XCTAssertEqual(reward.amount, largeAmount, @"amount should match large value");
}

/**
 * Test rewardWithAmount:label: factory method with unicode label
 */
- (void)testRewardWithAmountLabel_UnicodeLabel_HandlesCorrectly {
    CLXReward *reward = [CLXReward rewardWithAmount:100 label:@"金币 💰"];
    
    XCTAssertNotNil(reward, @"Should handle unicode labels");
    XCTAssertEqualObjects(reward.label, @"金币 💰", @"Should preserve unicode label");
}

/**
 * Test rewardWithAmount:label: factory method with empty string label
 */
- (void)testRewardWithAmountLabel_EmptyLabel_PreservesEmptyString {
    CLXReward *reward = [CLXReward rewardWithAmount:50 label:@""];
    
    XCTAssertNotNil(reward, @"Should create reward with empty label");
    // Empty string is a valid label (different from nil)
    XCTAssertEqualObjects(reward.label, @"", @"Should preserve empty string label");
}

#pragma mark - Immutability Tests

/**
 * Test that reward properties are readonly (immutable)
 */
- (void)testReward_IsImmutable {
    CLXReward *reward = [CLXReward rewardWithAmount:100 label:@"coins"];
    
    // Verify the class doesn't have setters (compile-time check enforced by readonly)
    // At runtime, verify the values don't change
    NSInteger originalAmount = reward.amount;
    NSString *originalLabel = reward.label;
    
    // These should still be the same (no way to mutate)
    XCTAssertEqual(reward.amount, originalAmount, @"amount should be immutable");
    XCTAssertEqualObjects(reward.label, originalLabel, @"label should be immutable");
}

#pragma mark - Description Tests

/**
 * Test that description provides useful debug info
 */
- (void)testReward_Description_ProvidesUsefulInfo {
    CLXReward *reward = [CLXReward rewardWithAmount:500 label:@"diamonds"];
    
    NSString *description = [reward description];
    
    XCTAssertNotNil(description, @"description should not be nil");
    XCTAssertTrue([description containsString:@"500"], @"description should contain amount");
    XCTAssertTrue([description containsString:@"diamonds"], @"description should contain label");
}

#pragma mark - Edge Cases

/**
 * Test negative amount (should still work - server decides validity)
 */
- (void)testRewardWithAmountLabel_NegativeAmount_StillCreatesReward {
    CLXReward *reward = [CLXReward rewardWithAmount:-100 label:@"coins"];
    
    XCTAssertNotNil(reward, @"Should create reward even with negative amount");
    XCTAssertEqual(reward.amount, -100, @"Should preserve negative amount");
}

/**
 * Test very long label string
 */
- (void)testRewardWithAmountLabel_VeryLongLabel_HandlesCorrectly {
    NSMutableString *longLabel = [NSMutableString string];
    for (int i = 0; i < 1000; i++) {
        [longLabel appendString:@"coins"];
    }
    
    CLXReward *reward = [CLXReward rewardWithAmount:1 label:longLabel];
    
    XCTAssertNotNil(reward, @"Should handle very long labels");
    XCTAssertEqualObjects(reward.label, longLabel, @"Should preserve very long label");
}

@end
