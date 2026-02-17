/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterLoaderTests.m
 * @brief Unit tests for CLXAdapterLoader centralized adapter loading
 *
 * Tests the fix from the silent-failure audit: when an adapter doesn't
 * respond to -load, CLXAdapterLoader must call onTimeout with an error
 * instead of silently dropping the request.
 *
 * All tests are deterministic and synchronous — no real adapters, no network.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

#pragma mark - Mock Adapters

/// A valid adapter that responds to -load
@interface CLXMockValidAdapter : NSObject
@property (nonatomic, assign) BOOL loadCalled;
@end

@implementation CLXMockValidAdapter
- (void)load {
    self.loadCalled = YES;
}
@end

/// An adapter that does NOT respond to -load (simulates misconfigured adapter)
@interface CLXMockBrokenAdapter : NSObject
@property (nonatomic, assign) BOOL somethingElseCalled;
@end

@implementation CLXMockBrokenAdapter
- (void)somethingElse {
    self.somethingElseCalled = YES;
}
@end

#pragma mark - Test Case

@interface CLXAdapterLoaderTests : XCTestCase
@end

@implementation CLXAdapterLoaderTests

#pragma mark - Valid Adapter Tests

- (void)testLoadAdapter_ValidAdapter_CallsLoad {
    CLXMockValidAdapter *adapter = [[CLXMockValidAdapter alloc] init];
    
    [CLXAdapterLoader loadAdapter:adapter
                        timeoutMs:10000
                   isLoadingBlock:^BOOL{ return YES; }
                        onTimeout:^(CLXError *error) {
        // Should not be called synchronously for valid adapter
    }];
    
    XCTAssertTrue(adapter.loadCalled, @"Valid adapter's -load should be called");
}

#pragma mark - Broken Adapter Tests (Silent Failure Audit)

- (void)testLoadAdapter_BrokenAdapter_CallsOnTimeoutWithError {
    CLXMockBrokenAdapter *adapter = [[CLXMockBrokenAdapter alloc] init];
    
    __block CLXError *receivedError = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"onTimeout called for broken adapter"];
    
    [CLXAdapterLoader loadAdapter:adapter
                        timeoutMs:10000
                   isLoadingBlock:^BOOL{ return YES; }
                        onTimeout:^(CLXError *error) {
        receivedError = error;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertNotNil(receivedError, @"Error should be provided");
    XCTAssertEqual(receivedError.code, CLXErrorCodeAdapterInternalError,
                   @"Error code should be CLXErrorCodeAdapterInternalError (600)");
    XCTAssertTrue([receivedError.localizedDescription containsString:@"CLXMockBrokenAdapter"],
                  @"Error should mention the adapter class name");
}

- (void)testLoadAdapter_BrokenAdapter_ErrorDescriptionContainsLoad {
    CLXMockBrokenAdapter *adapter = [[CLXMockBrokenAdapter alloc] init];
    
    __block CLXError *receivedError = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"onTimeout called"];
    
    [CLXAdapterLoader loadAdapter:adapter
                        timeoutMs:5000
                   isLoadingBlock:^BOOL{ return YES; }
                        onTimeout:^(CLXError *error) {
        receivedError = error;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertTrue([receivedError.localizedDescription containsString:@"-load"],
                  @"Error description should mention the missing -load selector");
}

#pragma mark - Default Timeout Tests

- (void)testDefaultAdLoadTimeoutMs_IsPositive {
    XCTAssertGreaterThan(CLXDefaultAdLoadTimeoutMs, 0, @"Default timeout should be positive");
    XCTAssertEqual(CLXDefaultAdLoadTimeoutMs, 10000, @"Default timeout should be 10000ms");
}

@end
