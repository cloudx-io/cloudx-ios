/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEventAM.h>

@interface CLXEventAMTests : XCTestCase
@end

@implementation CLXEventAMTests

- (void)testEventAMInitialization {
    // Given
    NSString *impression = @"encrypted_impression_data";
    NSString *campaignId = @"campaign_123";
    NSString *eventValue = @"N/A";
    NSString *eventName = @"SDK_METRICS";
    NSString *type = @"SDK_METRICS";
    
    // When
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:impression
                                                    campaignId:campaignId
                                                    eventValue:eventValue
                                                     eventName:eventName
                                                          type:type];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.impression, impression);
    XCTAssertEqualObjects(event.campaignId, campaignId);
    XCTAssertEqualObjects(event.eventValue, eventValue);
    XCTAssertEqualObjects(event.eventName, eventName);
    XCTAssertEqualObjects(event.type, type);
}

- (void)testEventAMToDictionary {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test_impression"
                                                    campaignId:@"test_campaign"
                                                    eventValue:@"test_value"
                                                     eventName:@"test_event"
                                                          type:@"test_type"];
    
    // When
    NSDictionary *dictionary = [event toDictionary];
    
    // Then
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 5);
    XCTAssertEqualObjects(dictionary[@"impression"], @"test_impression");
    XCTAssertEqualObjects(dictionary[@"campaignId"], @"test_campaign");
    XCTAssertEqualObjects(dictionary[@"eventValue"], @"test_value");
    XCTAssertEqualObjects(dictionary[@"eventName"], @"test_event");
    XCTAssertEqualObjects(dictionary[@"type"], @"test_type");
}

- (void)testEventAMDescription {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"very_long_encrypted_impression_data_that_should_be_truncated"
                                                    campaignId:@"campaign_456"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    
    // When
    NSString *description = [event description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"very_long_"]);  // First 10 chars of impression
    XCTAssertFalse([description containsString:@"very_long_encrypted_impression_data_that_should_be_truncated"]); // Full impression should not be there
    XCTAssertTrue([description containsString:@"campaign_456"]);
    XCTAssertTrue([description containsString:@"SDK_METRICS"]);
}

- (void)testEventAMDescriptionWithShortImpression {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"short"
                                                    campaignId:@"camp_789"
                                                    eventValue:@"N/A"
                                                     eventName:@"SDK_METRICS"
                                                          type:@"SDK_METRICS"];
    
    // When
    NSString *description = [event description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"short"]);  // Full short impression should be shown
    XCTAssertTrue([description containsString:@"camp_789"]);
    XCTAssertTrue([description containsString:@"SDK_METRICS"]);
}

- (void)testEventAMWithNilValues {
    // Given/When
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:nil
                                                    campaignId:nil
                                                    eventValue:nil
                                                     eventName:nil
                                                          type:nil];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertNil(event.impression);
    XCTAssertNil(event.campaignId);
    XCTAssertNil(event.eventValue);
    XCTAssertNil(event.eventName);
    XCTAssertNil(event.type);
}

- (void)testEventAMWithEmptyStrings {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@""
                                                    campaignId:@""
                                                    eventValue:@""
                                                     eventName:@""
                                                          type:@""];
    
    // When
    NSDictionary *dictionary = [event toDictionary];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.impression, @"");
    XCTAssertEqualObjects(event.campaignId, @"");
    XCTAssertEqualObjects(event.eventValue, @"");
    XCTAssertEqualObjects(event.eventName, @"");
    XCTAssertEqualObjects(event.type, @"");
    
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"impression"], @"");
    XCTAssertEqualObjects(dictionary[@"campaignId"], @"");
    XCTAssertEqualObjects(dictionary[@"eventValue"], @"");
    XCTAssertEqualObjects(dictionary[@"eventName"], @"");
    XCTAssertEqualObjects(dictionary[@"type"], @"");
}

@end
