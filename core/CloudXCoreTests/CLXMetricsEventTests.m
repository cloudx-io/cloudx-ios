/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsEvent.h>

@interface CLXMetricsEventTests : XCTestCase
@end

@implementation CLXMetricsEventTests

- (void)testMetricsEventInitialization {
    // Given
    NSString *eventId = @"test-event-id";
    NSString *metricName = @"method_create_banner";
    NSInteger counter = 5;
    NSInteger totalLatency = 1500;
    NSString *sessionId = @"test-session-id";
    NSString *auctionId = @"test-auction-id";
    
    // When
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:eventId
                                                           metricName:metricName
                                                              counter:counter
                                                         totalLatency:totalLatency
                                                            sessionId:sessionId
                                                            auctionId:auctionId];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.eventId, eventId);
    XCTAssertEqualObjects(event.metricName, metricName);
    XCTAssertEqual(event.counter, counter);
    XCTAssertEqual(event.totalLatency, totalLatency);
    XCTAssertEqualObjects(event.sessionId, sessionId);
    XCTAssertEqualObjects(event.auctionId, auctionId);
}

- (void)testMetricsEventFromDictionary {
    // Given
    NSDictionary *dictionary = @{
        @"id": @"test-event-id",
        @"metricName": @"network_call_bid_req",
        @"counter": @3,
        @"totalLatency": @750,
        @"sessionId": @"test-session-id",
        @"auctionId": @"test-auction-id"
    };
    
    // When
    CLXMetricsEvent *event = [CLXMetricsEvent fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.eventId, @"test-event-id");
    XCTAssertEqualObjects(event.metricName, @"network_call_bid_req");
    XCTAssertEqual(event.counter, 3);
    XCTAssertEqual(event.totalLatency, 750);
    XCTAssertEqualObjects(event.sessionId, @"test-session-id");
    XCTAssertEqualObjects(event.auctionId, @"test-auction-id");
}

- (void)testMetricsEventFromDictionaryWithMissingValues {
    // Given
    NSDictionary *dictionary = @{
        @"metricName": @"method_create_interstitial"
    };
    
    // When
    CLXMetricsEvent *event = [CLXMetricsEvent fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.eventId, @"");
    XCTAssertEqualObjects(event.metricName, @"method_create_interstitial");
    XCTAssertEqual(event.counter, 0);
    XCTAssertEqual(event.totalLatency, 0);
    XCTAssertEqualObjects(event.sessionId, @"");
    XCTAssertEqualObjects(event.auctionId, @"");
}

- (void)testMetricsEventToDictionary {
    // Given
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:@"test-id"
                                                           metricName:@"method_create_rewarded"
                                                              counter:2
                                                         totalLatency:500
                                                            sessionId:@"session-123"
                                                            auctionId:@"auction-456"];
    
    // When
    NSDictionary *dictionary = [event toDictionary];
    
    // Then
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"id"], @"test-id");
    XCTAssertEqualObjects(dictionary[@"metricName"], @"method_create_rewarded");
    XCTAssertEqualObjects(dictionary[@"counter"], @2);
    XCTAssertEqualObjects(dictionary[@"totalLatency"], @500);
    XCTAssertEqualObjects(dictionary[@"sessionId"], @"session-123");
    XCTAssertEqualObjects(dictionary[@"auctionId"], @"auction-456");
}

- (void)testMetricsEventDescription {
    // Given
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:@"test-id"
                                                           metricName:@"method_create_native"
                                                              counter:1
                                                         totalLatency:100
                                                            sessionId:@"session-789"
                                                            auctionId:@"auction-101"];
    
    // When
    NSString *description = [event description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"test-id"]);
    XCTAssertTrue([description containsString:@"method_create_native"]);
    XCTAssertTrue([description containsString:@"1"]);
    XCTAssertTrue([description containsString:@"100"]);
    XCTAssertTrue([description containsString:@"session-789"]);
}

@end
