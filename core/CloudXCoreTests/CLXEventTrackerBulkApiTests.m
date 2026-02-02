/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXEventType.h>
#import <CloudXCore/CLXError.h>

// Test constants
static NSString * const kTestEndpoint = @"https://test.example.com/bulk";
static NSString * const kTestEventName = @"SDK_METRICS";
static NSString * const kTestEventValue = @"N/A";
static const NSTimeInterval kValidationTimeout = 0.1;

// Base64 test data containing all special characters that require URL encoding
static NSString * const kBase64WithSpecialChars = @"abc+def/ghi==";

// Marker for double URL encoding - %25 is the URL-encoded form of %
static NSString * const kDoubleEncodingMarker = @"%25";

@interface CLXEventTrackerBulkApiTests : XCTestCase
@property (nonatomic, strong) CLXEventTrackerBulkApiImpl *bulkApi;
@end

@implementation CLXEventTrackerBulkApiTests

#pragma mark - Setup / Teardown

- (void)setUp {
    [super setUp];
    self.bulkApi = [[CLXEventTrackerBulkApiImpl alloc] initWithTimeoutMillis:10000];
}

- (void)tearDown {
    self.bulkApi = nil;
    [super tearDown];
}

#pragma mark - Factory Methods

- (CLXEventAM *)createTestEventWithImpression:(NSString *)impression campaignId:(NSString *)campaignId {
    return [[CLXEventAM alloc] initWithImpression:impression
                                       campaignId:campaignId
                                       eventValue:kTestEventValue
                                        eventName:kTestEventName
                                             type:kTestEventName];
}

- (CLXEventAM *)createSimpleTestEvent {
    return [self createTestEventWithImpression:@"test" campaignId:@"test"];
}

#pragma mark - Input Validation Tests (No Network)

- (void)testSendWithNilEndpoint {
    // Given
    NSArray *items = @[[self createSimpleTestEvent]];
    
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
    
    [self waitForExpectationsWithTimeout:kValidationTimeout handler:nil];
}

- (void)testSendWithEmptyEndpoint {
    // Given
    NSArray *items = @[[self createSimpleTestEvent]];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:@""
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, CLXErrorCodeInternalError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kValidationTimeout handler:nil];
}

- (void)testSendWithEmptyItems {
    // Given
    NSArray *items = @[];
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:kTestEndpoint
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully (no-op)
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kValidationTimeout handler:nil];
}

- (void)testSendWithNilItems {
    // Given
    NSArray *items = nil;
    
    // When
    XCTestExpectation *expectation = [self expectationWithDescription:@"Send completes"];
    
    [self.bulkApi sendToEndpoint:kTestEndpoint
                           items:items
                      completion:^(BOOL success, NSError * _Nullable error) {
        // Then - Should succeed gracefully (no-op)
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kValidationTimeout handler:nil];
}

#pragma mark - Payload Encoding Tests

- (void)testJsonPayload_WithBase64SpecialCharacters_ShouldNotDoubleEncode {
    // Given - Base64 data containing +, /, = characters that require URL encoding
    CLXEventAM *event = [self createTestEventWithImpression:kBase64WithSpecialChars
                                                 campaignId:kBase64WithSpecialChars];
    NSArray *items = @[event];
    
    // When - Build the JSON payload using the same logic as the API
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:items.count];
    for (CLXEventAM *item in items) {
        [jsonArray addObject:[item toDictionary]];
    }
    NSDictionary *requestPayload = @{@"items": jsonArray};
    NSError *error = nil;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:requestPayload options:0 error:&error];
    
    XCTAssertNil(error, @"JSON serialization should not fail");
    XCTAssertNotNil(requestBody, @"Request body should not be nil");
    
    NSString *jsonString = [[NSString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding];
    
    // Then - Verify no double encoding in final JSON payload
    // Double encoding produces %25 (the URL-encoded form of %)
    // e.g., if + is encoded to %2B, double encoding would produce %252B
    XCTAssertNotNil(jsonString, @"JSON string should not be nil");
    XCTAssertFalse([jsonString containsString:kDoubleEncodingMarker],
                   @"Double URL encoding detected - found %%25 marker in JSON payload: %@", jsonString);
}

@end
