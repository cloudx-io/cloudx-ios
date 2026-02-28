/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXIlrdService.h>
#import "MockCLXIlrdProvider.h"

@interface CLXIlrdServiceTests : XCTestCase
@end

@implementation CLXIlrdServiceTests

#pragma mark - Subscribe

- (void)testSubscribeCallsProviders {
    // Arrange
    MockCLXIlrdProvider *provider = [[MockCLXIlrdProvider alloc] init];
    NSDictionary *providers = @{ @(CLXIlrdPlatformAl): provider };
    CLXIlrdService *subject = [[CLXIlrdService alloc] initWithProviders:providers];

    // Act
    NSError *error = nil;
    BOOL result = [subject subscribeWithError:&error];

    // Assert
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertEqual(provider.subscribeCallCount, 1);
}

- (void)testSubscribeReturnsFalseWhenNoProviders {
    // Arrange
    NSDictionary *providers = @{};
    CLXIlrdService *subject = [[CLXIlrdService alloc] initWithProviders:providers];

    // Act
    NSError *error = nil;
    BOOL result = [subject subscribeWithError:&error];

    // Assert
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)testSubscribeReturnsFalseWhenAllProvidersFail {
    // Arrange
    MockCLXIlrdProvider *provider = [[MockCLXIlrdProvider alloc] init];
    provider.shouldSucceedSubscribe = NO;
    NSDictionary *providers = @{ @(CLXIlrdPlatformAl): provider };
    CLXIlrdService *subject = [[CLXIlrdService alloc] initWithProviders:providers];

    // Act
    NSError *error = nil;
    BOOL result = [subject subscribeWithError:&error];

    // Assert
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

#pragma mark - Event Forwarding

- (void)testEventsForwardedFromProviderToServiceCallback {
    // Arrange
    MockCLXIlrdProvider *provider = [[MockCLXIlrdProvider alloc] init];
    NSDictionary *providers = @{ @(CLXIlrdPlatformAl): provider };
    CLXIlrdService *subject = [[CLXIlrdService alloc] initWithProviders:providers];

    __block NSDictionary *receivedEvent = nil;
    [subject setEventCallback:^(NSDictionary<NSString *, id> *event) {
        receivedEvent = event;
    }];

    NSError *error = nil;
    [subject subscribeWithError:&error];

    NSDictionary *testEvent = @{ @"revenue": @(0.5), @"platform": @"applovin" };

    // Act
    [provider simulateEvent:testEvent];

    // Assert
    XCTAssertNotNil(receivedEvent);
    XCTAssertEqualObjects(receivedEvent[@"revenue"], @(0.5));
    XCTAssertEqualObjects(receivedEvent[@"platform"], @"applovin");
}

#pragma mark - Unsubscribe

- (void)testUnsubscribeCallsProviders {
    // Arrange
    MockCLXIlrdProvider *provider = [[MockCLXIlrdProvider alloc] init];
    NSDictionary *providers = @{ @(CLXIlrdPlatformAl): provider };
    CLXIlrdService *subject = [[CLXIlrdService alloc] initWithProviders:providers];

    // Act
    [subject unsubscribe];

    // Assert
    XCTAssertEqual(provider.unsubscribeCallCount, 1);
}

@end
