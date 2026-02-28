/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXIlrdTracker.h>
#import <CloudXCore/CLXIlrdService.h>
#import "MockCLXIlrdProvider.h"
#import "MockCLXIlrdNetworkService.h"

@interface CLXIlrdTrackerTests : XCTestCase
@property (nonatomic, strong) MockCLXIlrdProvider *mockProvider;
@property (nonatomic, strong) MockCLXIlrdNetworkService *mockNetworkService;
@property (nonatomic, strong) CLXIlrdService *ilrdService;
@property (nonatomic, strong) CLXIlrdTracker *subject;
@end

@implementation CLXIlrdTrackerTests

- (void)setUp {
    [super setUp];
    _mockProvider = [[MockCLXIlrdProvider alloc] init];
    NSDictionary *providers = @{ @(CLXIlrdPlatformAl): _mockProvider };
    _ilrdService = [[CLXIlrdService alloc] initWithProviders:providers];
    _mockNetworkService = [[MockCLXIlrdNetworkService alloc] init];
    _subject = [[CLXIlrdTracker alloc] initWithAppKey:@"test-key"
                                          endpointUrl:@"https://ilrd.example.com"
                                          ilrdService:_ilrdService
                                       networkService:_mockNetworkService];
}

- (void)tearDown {
    [_subject stop];
    _subject = nil;
    [super tearDown];
}

#pragma mark - Start

- (void)testStartSubscribesService {
    // Act
    [_subject start];

    // Assert
    XCTAssertEqual(_mockProvider.subscribeCallCount, 1);
}

- (void)testStartSendsEventsToNetwork {
    // Arrange
    [_subject start];
    NSDictionary *event = @{ @"revenue": @(0.5), @"platform": @"applovin" };

    // Act
    [_mockProvider simulateEvent:event];

    // Wait for async dispatch
    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqual(_mockNetworkService.sendCallCount, 1);
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"revenue"], @(0.5));
    XCTAssertEqualObjects(_mockNetworkService.lastAppKey, @"test-key");
}

- (void)testStartResetsFlagOnFailure {
    // Arrange
    _mockProvider.shouldSucceedSubscribe = NO;

    // Act
    [_subject start];

    // Assert - should be able to start again (flag was reset)
    _mockProvider.shouldSucceedSubscribe = YES;
    [_subject start];
    XCTAssertEqual(_mockProvider.subscribeCallCount, 2);
}

#pragma mark - Stop

- (void)testStopUnsubscribesService {
    // Arrange
    [_subject start];

    // Act
    [_subject stop];

    // Assert
    XCTAssertEqual(_mockProvider.unsubscribeCallCount, 1);
}

- (void)testStopPreventsEventSending {
    // Arrange
    [_subject start];
    [_subject stop];

    NSDictionary *event = @{ @"revenue": @(0.5), @"platform": @"applovin" };

    // Act
    [_mockProvider simulateEvent:event];

    // Wait to verify nothing was sent
    XCTestExpectation *expectation = [self expectationWithDescription:@"no send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqual(_mockNetworkService.sendCallCount, 0);
}

- (void)testDoubleStartDoesNotDoubleSubscribe {
    // Act
    [_subject start];
    [_subject start];

    // Assert
    XCTAssertEqual(_mockProvider.subscribeCallCount, 1);
}

@end
