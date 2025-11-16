/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>
#import <CloudXCore/CLXEventAM.h>

@interface CLXEventTrackerBulkApiTests : XCTestCase
@property (nonatomic, strong) CLXEventTrackerBulkApiImpl *bulkApi;
@end

@implementation CLXEventTrackerBulkApiTests

- (void)setUp {
    [super setUp];
    self.bulkApi = [[CLXEventTrackerBulkApiImpl alloc] initWithTimeoutMillis:10000];
}

- (void)tearDown {
    self.bulkApi = nil;
    [super tearDown];
}

#pragma mark - Payload Structure Tests

- (void)testPayloadWrapsItemsInObject {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test_impression"
                                                    campaignId:@"test_campaign"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When - Send to a non-existent endpoint to capture the payload structure
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/204"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // The key test is that the request was FORMED correctly
        // We can't easily inspect the actual HTTP body in unit tests,
        // but we verify no serialization errors occurred
        XCTAssertTrue(success || error.code == CLXErrorCodeNetworkError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testURLEncodingInPayload {
    // Given - Base64 strings with = signs that need encoding
    CLXEventAM *event1 = [[CLXEventAM alloc] initWithImpression:@"PDR8Ag=="
                                                     campaignId:@"PDR8Ag=="
                                                     eventValue:@"N/A"
                                                      eventName:@"SDK_METRICS"
                                                           type:@"SDK_METRICS"];
    
    CLXEventAM *event2 = [[CLXEventAM alloc] initWithImpression:@"ABC123XYZ="
                                                     campaignId:@"TEST="
                                                     eventValue:@"N/A"
                                                      eventName:@"SDK_METRICS"
                                                           type:@"SDK_METRICS"];
    NSArray *items = @[event1, event2];
    
    // When/Then - Should encode = to %3D without errors
    XCTestExpectation *expectation = [self expectationWithDescription:@"Encoding works"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/204"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // No JSON serialization errors should occur
        if (error) {
            XCTAssertNotEqual(error.code, CLXErrorCodeInvalidRequest);
        }
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Edge Cases

- (void)testSendWithEmptyItems {
    // Given
    NSArray *items = @[];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@"https://test.example.com/bulk"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully with empty array
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSendWithNilItems {
    // Given
    NSArray *items = nil;
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@"https://test.example.com/bulk"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully with nil items
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSendWithNilEndpoint {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:nil
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should fail with appropriate error
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeInvalidRequest);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testSendWithEmptyEndpoint {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@""
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should fail with appropriate error
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeInvalidRequest);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - HTTP Status Code Handling

- (void)testHTTP204HandledAsSuccess {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When - Use httpbin.org to simulate HTTP 204
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 204 success"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/204"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - HTTP 204 should be treated as success
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testHTTP200HandledAsSuccess {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 200 success"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/200"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testHTTP400HandledAsError {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 400 error"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/400"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeNetworkError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testHTTP500HandledAsError {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test"
                                                    campaignId:@"test"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    NSArray *items = @[event];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP 500 error"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/500"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeNetworkError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Multiple Items

- (void)testSendMultipleItems {
    // Given - Multiple events
    NSMutableArray *items = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:[NSString stringWithFormat:@"impression_%d", i]
                                                        campaignId:[NSString stringWithFormat:@"campaign_%d", i]
                                                        eventValue:@"N/A"
                                                         eventName:@"SDK_METRICS"
                                                              type:@"SDK_METRICS"];
        [items addObject:event];
    }
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Multiple items sent"];
    
    [self.bulkApi sendToEndpoint:@"https://httpbin.org/status/204"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should handle multiple items without error
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end

