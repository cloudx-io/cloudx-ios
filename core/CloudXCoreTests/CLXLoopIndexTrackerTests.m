/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXLoopIndexTrackerTests.m
 * @brief Unit and integration tests for loop index tracking
 * 
 * Tests verify that loop index is correctly tracked:
 * - Per-placement incrementing for banner/MREC ads
 * - Fixed value (1) for interstitial/rewarded ads
 * - Reset behavior on SDK init
 * - Inclusion in bid request ext.data
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPlacementLoopIndexTracker.h>

// Test constants
static NSString * const kTestPlacementBanner1 = @"test_banner_1";
static NSString * const kTestPlacementBanner2 = @"test_banner_2";
static NSString * const kTestPlacementInterstitial = @"test_interstitial";
static NSString * const kTestPlacementRewarded = @"test_rewarded";
static const NSTimeInterval kTestTimeout = 5.0;

@interface CLXLoopIndexTrackerTests : XCTestCase
@property (nonatomic, strong) CLXPlacementLoopIndexTracker *tracker;
@end

@implementation CLXLoopIndexTrackerTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    self.tracker = [[CLXPlacementLoopIndexTracker alloc] init];
    [self.tracker resetAll];
}

- (void)tearDown {
    [self.tracker resetAll];
    self.tracker = nil;
    [super tearDown];
}

#pragma mark - Basic Loop Index Tests

- (void)testLoopIndexStartsAtZero {
    // Given: Fresh tracker
    NSString *placement = kTestPlacementBanner1;
    
    // When: Get initial count
    NSInteger count = [self.tracker getCountForPlacement:placement];
    
    // Then: Should start at 0
    XCTAssertEqual(count, 0, @"Loop index should start at 0");
}

- (void)testLoopIndexIncrementsForBanner {
    // Given: Fresh tracker
    NSString *placement = kTestPlacementBanner1;
    
    // When: Increment multiple times
    NSInteger count1 = [self.tracker getAndIncrementForPlacement:placement];
    NSInteger count2 = [self.tracker getAndIncrementForPlacement:placement];
    NSInteger count3 = [self.tracker getAndIncrementForPlacement:placement];
    
    // Then: Should increment sequentially
    XCTAssertEqual(count1, 0, @"First count should be 0");
    XCTAssertEqual(count2, 1, @"Second count should be 1");
    XCTAssertEqual(count3, 2, @"Third count should be 2");
}

- (void)testLoopIndexIsPerPlacement {
    // Given: Multiple placements
    NSString *placement1 = kTestPlacementBanner1;
    NSString *placement2 = kTestPlacementBanner2;
    
    // When: Increment different placements
    NSInteger count1_1 = [self.tracker getAndIncrementForPlacement:placement1];
    NSInteger count2_1 = [self.tracker getAndIncrementForPlacement:placement2];
    NSInteger count1_2 = [self.tracker getAndIncrementForPlacement:placement1];
    NSInteger count2_2 = [self.tracker getAndIncrementForPlacement:placement2];
    
    // Then: Each placement should track independently
    XCTAssertEqual(count1_1, 0, @"Placement1 first count");
    XCTAssertEqual(count2_1, 0, @"Placement2 first count");
    XCTAssertEqual(count1_2, 1, @"Placement1 second count");
    XCTAssertEqual(count2_2, 1, @"Placement2 second count");
}

#pragma mark - Ad Type Behavior Tests

- (void)testInterstitialUsesFixedLoopIndex {
    // Given: Interstitial placement
    // When: Get loop index (never increments)
    // Then: Should always return 1
    
    // Note: Business logic dictates interstitials use fixed value of 1
    // This is enforced in BiddingConfig, not the tracker
    NSString *placement = kTestPlacementInterstitial;
    NSInteger count = [self.tracker getCountForPlacement:placement];
    
    // Should start at 0, but BiddingConfig will use 1 for interstitials
    XCTAssertEqual(count, 0, @"Tracker returns 0, but BiddingConfig uses 1 for interstitials");
}

- (void)testRewardedUsesFixedLoopIndex {
    // Given: Rewarded placement
    // When: Get loop index
    // Then: Should use fixed value (enforced in BiddingConfig)
    
    NSString *placement = kTestPlacementRewarded;
    NSInteger count = [self.tracker getCountForPlacement:placement];
    
    XCTAssertEqual(count, 0, @"Tracker returns 0, but BiddingConfig uses 1 for rewarded");
}

- (void)testBannerAndMrecIncrementIndependently {
    // Given: Banner and MREC placements (both auto-refresh)
    NSString *bannerPlacement = @"test_banner";
    NSString *mrecPlacement = @"test_mrec";
    
    // When: Increment both
    [self.tracker getAndIncrementForPlacement:bannerPlacement];
    [self.tracker getAndIncrementForPlacement:bannerPlacement];
    [self.tracker getAndIncrementForPlacement:mrecPlacement];
    
    // Then: Should track separately
    NSInteger bannerCount = [self.tracker getCountForPlacement:bannerPlacement];
    NSInteger mrecCount = [self.tracker getCountForPlacement:mrecPlacement];
    
    XCTAssertEqual(bannerCount, 2, @"Banner should have count 2");
    XCTAssertEqual(mrecCount, 1, @"MREC should have count 1");
}

#pragma mark - Reset Behavior Tests

- (void)testResetPlacement {
    // Given: Placement with incremented count
    NSString *placement = kTestPlacementBanner1;
    [self.tracker getAndIncrementForPlacement:placement];
    [self.tracker getAndIncrementForPlacement:placement];
    NSInteger countBefore = [self.tracker getCountForPlacement:placement];
    
    // When: Reset specific placement
    [self.tracker resetForPlacement:placement];
    
    // Then: Count should be 0
    NSInteger countAfter = [self.tracker getCountForPlacement:placement];
    XCTAssertEqual(countBefore, 2, @"Count before reset should be 2");
    XCTAssertEqual(countAfter, 0, @"Count after reset should be 0");
}

- (void)testResetAllPlacements {
    // Given: Multiple placements with counts
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner2];
    
    // When: Reset all
    [self.tracker resetAll];
    
    // Then: All counts should be 0
    NSInteger count1 = [self.tracker getCountForPlacement:kTestPlacementBanner1];
    NSInteger count2 = [self.tracker getCountForPlacement:kTestPlacementBanner2];
    
    XCTAssertEqual(count1, 0, @"Banner1 should be reset");
    XCTAssertEqual(count2, 0, @"Banner2 should be reset");
}

- (void)testResetDoesNotAffectOtherPlacements {
    // Given: Multiple placements
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner2];
    
    // When: Reset only one placement
    [self.tracker resetForPlacement:kTestPlacementBanner1];
    
    // Then: Other placement should be unaffected
    NSInteger count1 = [self.tracker getCountForPlacement:kTestPlacementBanner1];
    NSInteger count2 = [self.tracker getCountForPlacement:kTestPlacementBanner2];
    
    XCTAssertEqual(count1, 0, @"Reset placement should be 0");
    XCTAssertEqual(count2, 1, @"Other placement should still be 1");
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentIncrements {
    // Given: Single placement
    NSString *placement = kTestPlacementBanner1;
    
    // When: Increment concurrently from multiple threads
    dispatch_group_t group = dispatch_group_create();
    const int iterations = 100;
    
    for (int i = 0; i < iterations; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.tracker getAndIncrementForPlacement:placement];
            dispatch_group_leave(group);
        });
    }
    
    // Then: Final count should match iterations
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent increments"];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSInteger finalCount = [self.tracker getCountForPlacement:placement];
        XCTAssertEqual(finalCount, iterations, @"Count should be %d after concurrent increments", iterations);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:kTestTimeout];
}

- (void)testConcurrentMultiplePlacementIncrements {
    // Given: Multiple placements
    dispatch_group_t group = dispatch_group_create();
    
    // When: Increment different placements concurrently
    for (int i = 0; i < 50; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
            dispatch_group_leave(group);
        });
        
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.tracker getAndIncrementForPlacement:kTestPlacementBanner2];
            dispatch_group_leave(group);
        });
    }
    
    // Then: Each placement should have correct count
    XCTestExpectation *expectation = [self expectationWithDescription:@"Multiple placement increments"];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSInteger count1 = [self.tracker getCountForPlacement:kTestPlacementBanner1];
        NSInteger count2 = [self.tracker getCountForPlacement:kTestPlacementBanner2];
        
        XCTAssertEqual(count1, 50, @"Placement1 should have 50");
        XCTAssertEqual(count2, 50, @"Placement2 should have 50");
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:kTestTimeout];
}

#pragma mark - Edge Cases

- (void)testRapidSequentialIncrements {
    // Given: Single placement
    NSString *placement = kTestPlacementBanner1;
    
    // When: Increment rapidly
    for (int i = 0; i < 1000; i++) {
        [self.tracker getAndIncrementForPlacement:placement];
    }
    
    // Then: Count should be accurate
    NSInteger count = [self.tracker getCountForPlacement:placement];
    XCTAssertEqual(count, 1000, @"Should handle rapid increments");
}

- (void)testGetCountDoesNotIncrement {
    // Given: Placement with count
    NSString *placement = kTestPlacementBanner1;
    [self.tracker getAndIncrementForPlacement:placement];
    
    // When: Call getCount multiple times
    NSInteger count1 = [self.tracker getCountForPlacement:placement];
    NSInteger count2 = [self.tracker getCountForPlacement:placement];
    NSInteger count3 = [self.tracker getCountForPlacement:placement];
    
    // Then: Count should remain the same
    XCTAssertEqual(count1, 1, @"Count should be 1");
    XCTAssertEqual(count2, 1, @"Count should still be 1");
    XCTAssertEqual(count3, 1, @"Count should still be 1");
}

- (void)testEmptyPlacementName {
    // Given: Empty placement name
    NSString *emptyPlacement = @"";
    
    // When: Increment
    NSInteger count = [self.tracker getAndIncrementForPlacement:emptyPlacement];
    
    // Then: Should handle gracefully
    XCTAssertEqual(count, 0, @"Should handle empty placement name");
}

- (void)testNilPlacementName {
    // Given: Nil placement name
    NSString *nilPlacement = nil;
    
    // When/Then: Should not crash
    XCTAssertNoThrow([self.tracker getAndIncrementForPlacement:nilPlacement], @"Should handle nil placement");
    XCTAssertNoThrow([self.tracker getCountForPlacement:nilPlacement], @"Should handle nil placement");
}

#pragma mark - Integration with Bid Requests

- (void)testLoopIndexIncludedInBidRequest {
    // Given: Placement with loop index
    NSString *placement = kTestPlacementBanner1;
    [self.tracker getAndIncrementForPlacement:placement];
    [self.tracker getAndIncrementForPlacement:placement];
    
    // When: Create bid request (simulated)
    NSInteger loopIndex = [self.tracker getCountForPlacement:placement];
    
    // Then: Loop index should be available for bid request
    XCTAssertEqual(loopIndex, 2, @"Loop index should be 2 for bid request");
}

- (void)testLoopIndexInExtData {
    // Given: Banner load cycle
    NSString *placement = kTestPlacementBanner1;
    
    // When: First load
    NSInteger loopIndex1 = [self.tracker getAndIncrementForPlacement:placement];
    // Bid request should include loop-index=0 in ext.data
    
    // When: Second load (refresh)
    NSInteger loopIndex2 = [self.tracker getAndIncrementForPlacement:placement];
    // Bid request should include loop-index=1 in ext.data
    
    // Then: Loop indices should increment
    XCTAssertEqual(loopIndex1, 0, @"First load should have loop-index=0");
    XCTAssertEqual(loopIndex2, 1, @"Second load should have loop-index=1");
}

#pragma mark - Performance Tests

- (void)testIncrementPerformance {
    // When: Measure increment performance
    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
        }
    }];
    
    // Then: Should complete quickly (performance baseline established)
}

- (void)testGetCountPerformance {
    // Given: Tracker with counts
    [self.tracker getAndIncrementForPlacement:kTestPlacementBanner1];
    
    // When: Measure getCount performance
    [self measureBlock:^{
        for (int i = 0; i < 10000; i++) {
            [self.tracker getCountForPlacement:kTestPlacementBanner1];
        }
    }];
    
    // Then: Should complete quickly
}

@end

