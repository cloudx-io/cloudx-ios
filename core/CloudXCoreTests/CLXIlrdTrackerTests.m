/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXIlrdTracker.h>
#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXAuctionResult.h>
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
                                            accountId:@"test-account"
                                            sessionId:@"test-session"
                                           sdkVersion:@"2.0.0"
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

- (void)testStartSendsEventsWithSdkIdentity {
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
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"accountId"], @"test-account");
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sessionId"], @"test-session");
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"os"], @"ios");
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"sdkVersion"], @"2.0.0");
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

#pragma mark - Auction Correlation

- (void)testNoFillAttachesCxAuctionIdToEvent {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeInterstitial
                                  auctionId:@"auction-123"
                                   adUnitId:@"ad-unit-456"
                                     filled:NO];

    NSDictionary *event = @{ @"revenue": @(0.5), @"platform": @"applovin", @"adFormat": @"interstitial" };

    // Act
    [_mockProvider simulateEvent:event];

    // Wait for async dispatch
    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAuctionId"], @"auction-123");
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAdUnitId"], @"ad-unit-456");
}

- (void)testFillClearsStoredNoFill {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeInterstitial
                                  auctionId:@"auction-123"
                                   adUnitId:@"ad-unit-456"
                                     filled:NO];
    [self postAuctionResultWithAdType:CLXAdTypeInterstitial
                                  auctionId:@"auction-789"
                                   adUnitId:@"ad-unit-789"
                                     filled:YES];

    NSDictionary *event = @{ @"revenue": @(0.5), @"platform": @"applovin", @"adFormat": @"interstitial" };

    // Act
    [_mockProvider simulateEvent:event];

    // Wait for async dispatch
    XCTestExpectation *expectation = [self expectationWithDescription:@"send dispatched"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert - no CX auction fields because fill cleared the no-fill
    XCTAssertNil(_mockNetworkService.lastPayload[@"cxAuctionId"]);
    XCTAssertNil(_mockNetworkService.lastPayload[@"cxAdUnitId"]);
}

- (void)testNoFillConsumedOnceOnly {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeInterstitial
                                  auctionId:@"auction-123"
                                   adUnitId:@"ad-unit-456"
                                     filled:NO];

    NSDictionary *event = @{ @"revenue": @(0.5), @"platform": @"applovin", @"adFormat": @"interstitial" };

    // Act - first event consumes the no-fill
    [_mockProvider simulateEvent:event];

    XCTestExpectation *first = [self expectationWithDescription:@"first send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [first fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAuctionId"], @"auction-123");

    // Act - second event should NOT have auction fields
    [_mockProvider simulateEvent:event];

    XCTestExpectation *second = [self expectationWithDescription:@"second send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [second fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertNil(_mockNetworkService.lastPayload[@"cxAuctionId"]);
}

#pragma mark - Ad Format Mapping

- (void)testNoFillAttachesCxAuctionIdForBanner {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeBanner auctionId:@"auction-ban" adUnitId:@"unit-ban" filled:NO];

    // Act
    [_mockProvider simulateEvent:@{ @"revenue": @(0.1), @"platform": @"applovin", @"adFormat": @"banner" }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [expectation fulfill]; });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAuctionId"], @"auction-ban");
}

- (void)testNoFillAttachesCxAuctionIdForMrec {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeMrec auctionId:@"auction-mrec" adUnitId:@"unit-mrec" filled:NO];

    // Act
    [_mockProvider simulateEvent:@{ @"revenue": @(0.2), @"platform": @"applovin", @"adFormat": @"mrec" }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [expectation fulfill]; });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAuctionId"], @"auction-mrec");
}

- (void)testNoFillAttachesCxAuctionIdForRewarded {
    // Arrange
    [_subject start];
    [self postAuctionResultWithAdType:CLXAdTypeRewarded auctionId:@"auction-rew" adUnitId:@"unit-rew" filled:NO];

    // Act
    [_mockProvider simulateEvent:@{ @"revenue": @(0.3), @"platform": @"applovin", @"adFormat": @"rewarded" }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"send"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [expectation fulfill]; });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Assert
    XCTAssertEqualObjects(_mockNetworkService.lastPayload[@"cxAuctionId"], @"auction-rew");
}

#pragma mark - Helpers

- (void)postAuctionResultWithAdType:(CLXAdType)adType
                          auctionId:(NSString *)auctionId
                           adUnitId:(NSString *)adUnitId
                             filled:(BOOL)filled {
    [[NSNotificationCenter defaultCenter] postNotificationName:CLXAuctionResultNotification
                                                        object:nil
                                                      userInfo:@{
        CLXAuctionResultAdTypeKey: @(adType),
        CLXAuctionResultAuctionIdKey: auctionId,
        CLXAuctionResultAdUnitIdKey: adUnitId,
        CLXAuctionResultFilledKey: @(filled),
    }];
}

@end
