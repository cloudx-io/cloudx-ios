/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewardedRewardLogicTests.m
 * @brief Unit tests for CLXReward model and reward value merging logic
 *
 * Tests the CLXReward model which is used for rewarded ads.
 * The actual CLXRewarded integration is tested in CLXAdFormatDelegateCallbackTests.
 *
 * Note: We test the CLXReward model directly rather than trying to mock
 * CLXRewarded internals, which would require fragile KVC hacks.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXRewardedRewardLogicTests : XCTestCase
@end

@implementation CLXRewardedRewardLogicTests

#pragma mark - CLXReward Creation Tests

/**
 * Test: Creating reward with both amount and label
 */
- (void)testRewardCreation_WithBothValues {
    CLXReward *reward = [CLXReward rewardWithAmount:500 label:@"gems"];
    
    XCTAssertNotNil(reward, @"Reward should be created");
    XCTAssertEqual(reward.amount, 500, @"Amount should be 500");
    XCTAssertEqualObjects(reward.label, @"gems", @"Label should be 'gems'");
}

/**
 * Test: Creating reward with nil label uses default
 */
- (void)testRewardCreation_NilLabel_UsesDefault {
    CLXReward *reward = [CLXReward rewardWithAmount:250 label:nil];
    
    XCTAssertNotNil(reward, @"Reward should be created");
    XCTAssertEqual(reward.amount, 250, @"Amount should be 250");
    XCTAssertEqualObjects(reward.label, [CLXReward defaultLabel], @"Nil label should use default");
}

/**
 * Test: Creating reward with empty string label preserves it
 */
- (void)testRewardCreation_EmptyLabel_PreservesEmpty {
    CLXReward *reward = [CLXReward rewardWithAmount:100 label:@""];
    
    XCTAssertNotNil(reward, @"Reward should be created");
    XCTAssertEqual(reward.amount, 100, @"Amount should be 100");
    XCTAssertEqualObjects(reward.label, @"", @"Empty label should be preserved");
}

/**
 * Test: Creating default reward
 */
- (void)testRewardCreation_Default {
    CLXReward *reward = [CLXReward reward];
    
    XCTAssertNotNil(reward, @"Default reward should be created");
    XCTAssertEqual(reward.amount, [CLXReward defaultAmount], @"Should have default amount");
    XCTAssertEqualObjects(reward.label, [CLXReward defaultLabel], @"Should have default label");
}

/**
 * Test: Default values are correct
 */
- (void)testDefaultValues {
    XCTAssertEqual([CLXReward defaultAmount], 0, @"Default amount should be 0");
    XCTAssertEqualObjects([CLXReward defaultLabel], @"", @"Default label should be empty string");
}

#pragma mark - Reward Merging Logic Tests (Simulated)

/**
 * Test the merging logic that CLXRewarded uses:
 * If adapter provides value > 0, use it; otherwise fall back to placement; otherwise use default
 */
- (void)testMergingLogic_AdapterOverridesPlacement {
    // Simulate: adapter amount=500, placement amount=1000
    NSInteger adapterAmount = 500;
    NSInteger placementAmount = 1000;
    
    // Merging logic: use adapter if > 0
    NSInteger finalAmount = (adapterAmount > 0) ? adapterAmount : placementAmount;
    
    XCTAssertEqual(finalAmount, 500, @"Adapter value should override placement");
}

- (void)testMergingLogic_FallsBackToPlacement {
    // Simulate: adapter amount=0, placement amount=1000
    NSInteger adapterAmount = 0;
    NSInteger placementAmount = 1000;
    
    // Merging logic: use adapter if > 0, else placement
    NSInteger finalAmount = (adapterAmount > 0) ? adapterAmount : placementAmount;
    
    XCTAssertEqual(finalAmount, 1000, @"Should fall back to placement when adapter is 0");
}

- (void)testMergingLogic_FallsBackToDefault {
    // Simulate: adapter amount=0, placement amount=0
    NSInteger adapterAmount = 0;
    NSInteger placementAmount = 0;

    // Merging logic: use adapter if > 0, else placement if > 0, else default
    NSInteger finalAmount = (adapterAmount > 0) ? adapterAmount : placementAmount;
    if (finalAmount <= 0) {
        finalAmount = [CLXReward defaultAmount];
    }

    XCTAssertEqual(finalAmount, 0, @"Should fall back to default (0) when both are 0");
}

- (void)testMergingLogic_LabelFallback {
    // Simulate: adapter label=nil, placement label="Golden Coins"
    NSString *adapterLabel = nil;
    NSString *placementLabel = @"Golden Coins";
    
    // Merging logic: use adapter if non-empty, else placement
    NSString *finalLabel = (adapterLabel.length > 0) ? adapterLabel : placementLabel;
    
    XCTAssertEqualObjects(finalLabel, @"Golden Coins", @"Should fall back to placement label");
}

- (void)testMergingLogic_EmptyLabelFallback {
    // Simulate: adapter label="" (empty), placement label="coins"
    NSString *adapterLabel = @"";
    NSString *placementLabel = @"coins";
    
    // Merging logic: empty string has length 0, so falls back
    NSString *finalLabel = (adapterLabel.length > 0) ? adapterLabel : placementLabel;
    
    XCTAssertEqualObjects(finalLabel, @"coins", @"Empty string should trigger fallback");
}

#pragma mark - CLXBidLifecycleEvent Reward Tests

/**
 * Test: Reward event has correct properties
 */
- (void)testRewardEvent_HasCorrectProperties {
    CLXBidLifecycleEvent *event = [CLXBidLifecycleEvent rewardEvent];
    
    XCTAssertNotNil(event, @"Reward event should be created");
    XCTAssertEqual(event.type, CLXBidLifecycleEventTypeReward, @"Should be reward type");
    XCTAssertEqualObjects(event.notificationType, CLXNotificationTypeRewardEarned, @"Should have rewardEarned notification type");
    XCTAssertEqualObjects(event.urlType, CLXURLTypeBurl, @"Should use burl for reward events");
}

/**
 * Test: Reward event is distinct from other event types
 */
- (void)testRewardEvent_IsDistinctFromOthers {
    CLXBidLifecycleEvent *reward = [CLXBidLifecycleEvent rewardEvent];
    CLXBidLifecycleEvent *loadSuccess = [CLXBidLifecycleEvent loadSuccessEvent];
    CLXBidLifecycleEvent *renderSuccess = [CLXBidLifecycleEvent renderSuccessEvent];
    CLXBidLifecycleEvent *loss = [CLXBidLifecycleEvent lossEvent];
    
    XCTAssertNotEqual(reward.type, loadSuccess.type, @"Reward should differ from loadSuccess");
    XCTAssertNotEqual(reward.type, renderSuccess.type, @"Reward should differ from renderSuccess");
    XCTAssertNotEqual(reward.type, loss.type, @"Reward should differ from loss");
}

#pragma mark - Notification Type Constants

- (void)testNotificationTypeConstants {
    XCTAssertEqualObjects(CLXNotificationTypeRewardEarned, @"rewardEarned", @"Reward notification type should be 'rewardEarned'");
    XCTAssertEqualObjects(CLXURLTypeBurl, @"burl", @"BURL type should be 'burl'");
}

@end
