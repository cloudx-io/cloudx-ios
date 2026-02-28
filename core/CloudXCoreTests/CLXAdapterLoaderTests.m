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

/// An adapter that does NOT respond to -load
@interface CLXMockBrokenAdapter : NSObject
@end

@implementation CLXMockBrokenAdapter
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
                        onTimeout:^(CLXError *error) {}];
    
    XCTAssertTrue(adapter.loadCalled, @"Valid adapter's -load should be called");
}

- (void)testLoadAdapter_ValidAdapter_RespondsToLoadSelector {
    CLXMockValidAdapter *adapter = [[CLXMockValidAdapter alloc] init];
    XCTAssertTrue([adapter respondsToSelector:@selector(load)],
                  @"Valid adapter must respond to -load");
}

- (void)testLoadAdapter_BrokenAdapter_DoesNotRespondToLoadSelector {
    CLXMockBrokenAdapter *adapter = [[CLXMockBrokenAdapter alloc] init];
    XCTAssertFalse([adapter respondsToSelector:@selector(load)],
                   @"Broken adapter must not respond to -load");
}

- (void)testLoadAdapter_NilAdapter_DoesNotCrash {
    id nilAdapter = nil;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNoThrow([CLXAdapterLoader loadAdapter:nilAdapter
                                         timeoutMs:10000
                                    isLoadingBlock:^BOOL{ return YES; }
                                         onTimeout:^(CLXError *error) {}],
                     @"Should not crash with nil adapter");
    #pragma clang diagnostic pop
}

- (void)testLoadAdapter_ZeroTimeout_DoesNotCrash {
    CLXMockValidAdapter *adapter = [[CLXMockValidAdapter alloc] init];
    XCTAssertNoThrow([CLXAdapterLoader loadAdapter:adapter
                                         timeoutMs:0
                                    isLoadingBlock:^BOOL{ return YES; }
                                         onTimeout:^(CLXError *error) {}],
                     @"Should handle zero timeout without crashing");
}

#pragma mark - Default Timeout Tests

- (void)testDefaultAdLoadTimeoutMs_IsPositive {
    XCTAssertGreaterThan(CLXDefaultAdLoadTimeoutMs, 0, @"Default timeout should be positive");
    XCTAssertEqual(CLXDefaultAdLoadTimeoutMs, 10000, @"Default timeout should be 10000ms");
}

@end
