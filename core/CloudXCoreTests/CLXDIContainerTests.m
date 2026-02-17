/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXDIContainerTests.m
 * @brief Unit tests for the CLXDIContainer switch refactor (silent-failure audit)
 *
 * The audit fixed a shadowed `service` variable across switch cases and added
 * a resolution-failure log. These tests guard the refactored behavior:
 *   1. Singleton caching still works after the switch consolidation
 *   2. Unregistered services return nil (not crash)
 *   3. Reset clears both factories and cache
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXDITestService : NSObject
@property (nonatomic, copy) NSString *name;
@end
@implementation CLXDITestService
@end

@interface CLXDIContainerTests : XCTestCase
@property (nonatomic, strong) CLXDIContainer *container;
@end

@implementation CLXDIContainerTests

- (void)setUp {
    [super setUp];
    self.container = [[CLXDIContainer alloc] init];
}

- (void)tearDown {
    [self.container reset];
    self.container = nil;
    [super tearDown];
}

/// Regression guard: the switch refactor must not break singleton caching
- (void)testSingleton_CachesOnFirstResolve_ReturnsSameInstance {
    CLXDITestService *service = [[CLXDITestService alloc] init];
    [self.container registerType:[CLXDITestService class] instance:service];

    id first = [self.container resolveType:ServiceTypeSingleton class:[CLXDITestService class]];
    id second = [self.container resolveType:ServiceTypeSingleton class:[CLXDITestService class]];

    XCTAssertEqual(first, second, @"Singleton must return the same cached instance");
    XCTAssertEqual(first, service);
}

/// Audit fix: unregistered service returns nil and logs (no crash)
- (void)testResolveUnregistered_ReturnsNil {
    id resolved = [self.container resolveType:ServiceTypeSingleton class:[NSDateFormatter class]];
    XCTAssertNil(resolved, @"Unregistered service must return nil");
}

/// Reset must clear both factories dict and cache dict
- (void)testReset_ClearsRegistrationsAndCache {
    CLXDITestService *service = [[CLXDITestService alloc] init];
    [self.container registerType:[CLXDITestService class] instance:service];
    [self.container resolveType:ServiceTypeSingleton class:[CLXDITestService class]]; // populate cache

    [self.container reset];

    XCTAssertNil([self.container resolveType:ServiceTypeSingleton class:[CLXDITestService class]],
                 @"After reset all services must be nil");
}

@end
