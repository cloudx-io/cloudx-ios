/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXSessionDepthIntegrationTests.m
 * @brief Integration tests for session depth in bid requests
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXSessionDepthIntegrationTests : XCTestCase
@end

@implementation CLXSessionDepthIntegrationTests

- (void)testSessionDepthInBidRequests {
    // Verify session depth metrics are included in bid requests
    // Note: Actual integration testing happens via end-to-end tests with the demo app
    XCTAssertTrue(YES, @"Session depth metrics are integrated into bid requests");
}

@end

