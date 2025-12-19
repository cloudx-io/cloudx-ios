/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidLifecycleEventTests.m
 * @brief Unit tests for CLXBidLifecycleEvent
 *
 * Tests lifecycle event factory methods and their properties.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXBidLifecycleEventTests : XCTestCase
@end

@implementation CLXBidLifecycleEventTests

#pragma mark - String Constants Tests

/**
 * Test notification type constants have expected values
 */
- (void)testNotificationTypeConstants_HaveExpectedValues {
    XCTAssertEqualObjects(CLXNotificationTypeLoadSuccess, @"loadSuccess", 
                          @"CLXNotificationTypeLoadSuccess should be 'loadSuccess'");
    XCTAssertEqualObjects(CLXNotificationTypeRenderSuccess, @"renderSuccess", 
                          @"CLXNotificationTypeRenderSuccess should be 'renderSuccess'");
    XCTAssertEqualObjects(CLXNotificationTypeLoss, @"loss", 
                          @"CLXNotificationTypeLoss should be 'loss'");
    XCTAssertEqualObjects(CLXNotificationTypeRewardEarned, @"rewardEarned", 
                          @"CLXNotificationTypeRewardEarned should be 'rewardEarned'");
}

/**
 * Test URL type constants have expected values
 */
- (void)testURLTypeConstants_HaveExpectedValues {
    XCTAssertEqualObjects(CLXURLTypeNurl, @"nurl", @"CLXURLTypeNurl should be 'nurl'");
    XCTAssertEqualObjects(CLXURLTypeBurl, @"burl", @"CLXURLTypeBurl should be 'burl'");
    XCTAssertEqualObjects(CLXURLTypeLurl, @"lurl", @"CLXURLTypeLurl should be 'lurl'");
}

#pragma mark - Factory Method Tests

/**
 * Test loadSuccessEvent factory method
 */
- (void)testLoadSuccessEvent_ReturnsCorrectProperties {
    CLXBidLifecycleEvent *event = [CLXBidLifecycleEvent loadSuccessEvent];
    
    XCTAssertNotNil(event, @"loadSuccessEvent should return non-nil object");
    XCTAssertEqual(event.type, CLXBidLifecycleEventTypeLoadSuccess, @"type should be LoadSuccess");
    XCTAssertEqualObjects(event.notificationType, CLXNotificationTypeLoadSuccess, 
                          @"notificationType should be CLXNotificationTypeLoadSuccess");
    XCTAssertEqualObjects(event.urlType, CLXURLTypeNurl, 
                          @"urlType should be CLXURLTypeNurl for load success");
}

/**
 * Test renderSuccessEvent factory method
 */
- (void)testRenderSuccessEvent_ReturnsCorrectProperties {
    CLXBidLifecycleEvent *event = [CLXBidLifecycleEvent renderSuccessEvent];
    
    XCTAssertNotNil(event, @"renderSuccessEvent should return non-nil object");
    XCTAssertEqual(event.type, CLXBidLifecycleEventTypeRenderSuccess, @"type should be RenderSuccess");
    XCTAssertEqualObjects(event.notificationType, CLXNotificationTypeRenderSuccess, 
                          @"notificationType should be CLXNotificationTypeRenderSuccess");
    XCTAssertEqualObjects(event.urlType, CLXURLTypeBurl, 
                          @"urlType should be CLXURLTypeBurl for render success");
}

/**
 * Test lossEvent factory method
 */
- (void)testLossEvent_ReturnsCorrectProperties {
    CLXBidLifecycleEvent *event = [CLXBidLifecycleEvent lossEvent];
    
    XCTAssertNotNil(event, @"lossEvent should return non-nil object");
    XCTAssertEqual(event.type, CLXBidLifecycleEventTypeLoss, @"type should be Loss");
    XCTAssertEqualObjects(event.notificationType, CLXNotificationTypeLoss, 
                          @"notificationType should be CLXNotificationTypeLoss");
    XCTAssertEqualObjects(event.urlType, CLXURLTypeLurl, 
                          @"urlType should be CLXURLTypeLurl for loss");
}

/**
 * Test rewardEvent factory method
 */
- (void)testRewardEvent_ReturnsCorrectProperties {
    CLXBidLifecycleEvent *event = [CLXBidLifecycleEvent rewardEvent];
    
    XCTAssertNotNil(event, @"rewardEvent should return non-nil object");
    XCTAssertEqual(event.type, CLXBidLifecycleEventTypeReward, @"type should be Reward");
    XCTAssertEqualObjects(event.notificationType, CLXNotificationTypeRewardEarned, 
                          @"notificationType should be CLXNotificationTypeRewardEarned");
    XCTAssertEqualObjects(event.urlType, CLXURLTypeBurl, 
                          @"urlType should be CLXURLTypeBurl for reward (same as render)");
}

#pragma mark - Event Type Enum Tests

/**
 * Test that all event types have distinct values
 */
- (void)testEventTypes_AreDistinct {
    XCTAssertNotEqual(CLXBidLifecycleEventTypeLoadSuccess, CLXBidLifecycleEventTypeRenderSuccess, 
                      @"LoadSuccess and RenderSuccess should have different values");
    XCTAssertNotEqual(CLXBidLifecycleEventTypeLoadSuccess, CLXBidLifecycleEventTypeLoss, 
                      @"LoadSuccess and Loss should have different values");
    XCTAssertNotEqual(CLXBidLifecycleEventTypeLoadSuccess, CLXBidLifecycleEventTypeReward, 
                      @"LoadSuccess and Reward should have different values");
    XCTAssertNotEqual(CLXBidLifecycleEventTypeRenderSuccess, CLXBidLifecycleEventTypeLoss, 
                      @"RenderSuccess and Loss should have different values");
    XCTAssertNotEqual(CLXBidLifecycleEventTypeRenderSuccess, CLXBidLifecycleEventTypeReward, 
                      @"RenderSuccess and Reward should have different values");
    XCTAssertNotEqual(CLXBidLifecycleEventTypeLoss, CLXBidLifecycleEventTypeReward, 
                      @"Loss and Reward should have different values");
}

#pragma mark - URL Type Consistency Tests

/**
 * Test that win events (loadSuccess, renderSuccess, reward) use appropriate URL types
 */
- (void)testWinEvents_UseAppropriateURLTypes {
    // Load success uses nurl (notification URL)
    CLXBidLifecycleEvent *loadSuccess = [CLXBidLifecycleEvent loadSuccessEvent];
    XCTAssertEqualObjects(loadSuccess.urlType, CLXURLTypeNurl, @"Load success should use nurl");
    
    // Render success uses burl (billing URL)
    CLXBidLifecycleEvent *renderSuccess = [CLXBidLifecycleEvent renderSuccessEvent];
    XCTAssertEqualObjects(renderSuccess.urlType, CLXURLTypeBurl, @"Render success should use burl");
    
    // Reward uses burl (billing URL) - same as render since it's a billable event
    CLXBidLifecycleEvent *reward = [CLXBidLifecycleEvent rewardEvent];
    XCTAssertEqualObjects(reward.urlType, CLXURLTypeBurl, @"Reward should use burl (billable event)");
}

/**
 * Test that loss event uses lurl
 */
- (void)testLossEvent_UsesLurl {
    CLXBidLifecycleEvent *loss = [CLXBidLifecycleEvent lossEvent];
    XCTAssertEqualObjects(loss.urlType, CLXURLTypeLurl, @"Loss should use lurl");
}

@end
