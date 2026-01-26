/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXError.h>

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

#pragma mark - Input Validation Tests (No Network)

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
        // Then - Should fail immediately with validation error (no network call)
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeInternalError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
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
        // Then - Should fail immediately with validation error (no network call)
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeInternalError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testSendWithEmptyItems {
    // Given
    NSArray *items = @[];
    
    // When - This should complete immediately without network call
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@"https://test.example.com/bulk"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully with empty array (early return, no network call)
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testSendWithNilItems {
    // Given
    NSArray *items = nil;
    
    // When - This should complete immediately without network call
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@"https://test.example.com/bulk"
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully with nil items (early return, no network call)
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

@end
