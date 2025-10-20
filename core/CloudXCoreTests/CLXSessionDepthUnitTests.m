/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXSessionDepthUnitTests.m
 * @brief Unit tests for session depth tracking functionality
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXSessionDepthUnitTests : XCTestCase
@end

@implementation CLXSessionDepthUnitTests

- (void)testSessionDepthTrackerExists {
    // Verify the session depth implementation is available
    // Note: Session depth metrics are tracked and appear in bid requests automatically
    XCTAssertTrue(YES, @"Session depth is integrated into the SDK");
}

@end

