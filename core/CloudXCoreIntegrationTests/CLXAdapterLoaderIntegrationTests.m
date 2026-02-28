/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterLoaderIntegrationTests.m
 * @brief Integration tests for CLXAdapterLoader broken adapter handling
 *
 * These tests were extracted from CLXAdapterLoaderTests.m because they use
 * waitForExpectationsWithTimeout to verify asynchronous onTimeout callbacks,
 * making them integration tests rather than unit tests. The corresponding
 * unit tests remain in CLXAdapterLoaderTests.m.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

#pragma mark - Mock Adapters

/// An adapter that does NOT respond to -load (simulates misconfigured adapter)
@interface CLXMockBrokenAdapter : NSObject
@end

@implementation CLXMockBrokenAdapter
@end

#pragma mark - Test Case

@interface CLXAdapterLoaderIntegrationTests : XCTestCase
@end

@implementation CLXAdapterLoaderIntegrationTests

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

@end
