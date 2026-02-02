/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXEventType.h>

// Test constants - deterministic values for reproducible tests
static NSString * const kTestImpression = @"encrypted_impression_data";
static NSString * const kTestCampaignId = @"campaign_123";
static NSString * const kTestEventValue = @"N/A";
static NSString * const kTestEventName = @"SDK_METRICS";
static NSString * const kTestType = @"SDK_METRICS";

// Base64 test data containing all special characters that require URL encoding
static NSString * const kBase64WithSpecialChars = @"abc+def/ghi==";

// Marker for double URL encoding - %25 is the URL-encoded form of %
static NSString * const kDoubleEncodingMarker = @"%25";

@interface CLXEventAMTests : XCTestCase
@end

@implementation CLXEventAMTests

#pragma mark - Factory Methods

- (CLXEventAM *)createDefaultTestEvent {
    return [[CLXEventAM alloc] initWithImpression:kTestImpression
                                       campaignId:kTestCampaignId
                                       eventValue:kTestEventValue
                                        eventName:kTestEventName
                                             type:kTestType];
}

- (CLXEventAM *)createEventWithImpression:(NSString *)impression campaignId:(NSString *)campaignId {
    return [[CLXEventAM alloc] initWithImpression:impression
                                       campaignId:campaignId
                                       eventValue:kTestEventValue
                                        eventName:kTestEventName
                                             type:kTestType];
}

#pragma mark - Initialization Tests

- (void)testEventAMInitialization {
    // When
    CLXEventAM *event = [self createDefaultTestEvent];
    
    // Then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.impression, kTestImpression);
    XCTAssertEqualObjects(event.campaignId, kTestCampaignId);
    XCTAssertEqualObjects(event.eventValue, kTestEventValue);
    XCTAssertEqualObjects(event.eventName, kTestEventName);
    XCTAssertEqualObjects(event.type, kTestType);
}

/**
 * CRITICAL: toDictionary must match Android's EventBulkRequestToJson format.
 * Android sends exactly 4 fields: eventName, campaignId, type, impression
 * Android does NOT send eventValue - we exclude it to match.
 */
- (void)testEventAMToDictionary_MustMatchAndroidFormat {
    // Given
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"test_impression"
                                                    campaignId:@"test_campaign"
                                                    eventValue:@"test_value"
                                                     eventName:@"test_event"
                                                          type:@"test_type"];
    
    // When
    NSDictionary *dictionary = [event toDictionary];
    
    // Then - Must have exactly 4 fields (Android parity)
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 4, @"Must have exactly 4 fields to match Android EventBulkRequestToJson");
    
    // These 4 fields must exist
    XCTAssertEqualObjects(dictionary[@"eventName"], @"test_event");
    XCTAssertEqualObjects(dictionary[@"campaignId"], @"test_campaign");
    XCTAssertEqualObjects(dictionary[@"type"], @"test_type");
    XCTAssertEqualObjects(dictionary[@"impression"], @"test_impression");
    
    // eventValue must NOT be in dictionary - Android doesn't include it
    XCTAssertNil(dictionary[@"eventValue"], @"eventValue must NOT be serialized - Android doesn't include it");
}

- (void)testEventAMDescription {
    // Given - Use constant for type safety
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"very_long_encrypted_impression_data_that_should_be_truncated"
                                                    campaignId:@"campaign_456"
                                                    eventValue:@"N/A"
                                                     eventName:CLXEventTypePathSDKMetrics
                                                          type:CLXEventTypePathSDKMetrics];
    
    // When
    NSString *description = [event description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"very_long_"]);  // First 10 chars of impression
    XCTAssertFalse([description containsString:@"very_long_encrypted_impression_data_that_should_be_truncated"]); // Full impression should not be there
    XCTAssertTrue([description containsString:@"campaign_456"]);
    XCTAssertTrue([description containsString:CLXEventTypePathSDKMetrics]);
}

- (void)testEventAMDescriptionWithShortImpression {
    // Given - Use constant for type safety
    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:@"short"
                                                    campaignId:@"camp_789"
                                                    eventValue:@"N/A"
                                                     eventName:CLXEventTypePathSDKMetrics
                                                          type:CLXEventTypePathSDKMetrics];
    
    // When
    NSString *description = [event description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"short"]);  // Full short impression should be shown
    XCTAssertTrue([description containsString:@"camp_789"]);
    XCTAssertTrue([description containsString:CLXEventTypePathSDKMetrics]);
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

    // Then - Object properties should be stored
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.impression, @"");
    XCTAssertEqualObjects(event.campaignId, @"");
    XCTAssertEqualObjects(event.eventValue, @"");  // Property exists but not serialized
    XCTAssertEqualObjects(event.eventName, @"");
    XCTAssertEqualObjects(event.type, @"");

    // Dictionary should have exactly 4 fields (Android parity)
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 4, @"Must have exactly 4 fields");
    XCTAssertEqualObjects(dictionary[@"eventName"], @"");
    XCTAssertEqualObjects(dictionary[@"campaignId"], @"");
    XCTAssertEqualObjects(dictionary[@"type"], @"");
    XCTAssertEqualObjects(dictionary[@"impression"], @"");
    XCTAssertNil(dictionary[@"eventValue"], @"eventValue must NOT be in dictionary");
}

/**
 * CRITICAL: Base64 strings must be URL-encoded for backend compatibility.
 * The backend (cloudx-tracker) calls URLDecoder.decode() before Base64 decoding.
 * Without URL encoding, '+' becomes space and corrupts the data.
 *
 * Base64 special characters that need encoding:
 *   '+' -> '%2B'
 *   '/' -> '%2F'
 *   '=' -> '%3D'
 */
- (void)testToDictionary_URLEncodesBase64SpecialCharacters {
    // Given - Base64 strings containing all special characters
    NSString *impressionWithSpecialChars = @"abc+def/ghi=";
    NSString *campaignIdWithSpecialChars = @"xyz+123/456==";

    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:impressionWithSpecialChars
                                                    campaignId:campaignIdWithSpecialChars
                                                    eventValue:@"N/A"
                                                     eventName:@"sdkmetricenc"
                                                          type:@"sdkmetricenc"];

    // When
    NSDictionary *dictionary = [event toDictionary];

    // Then - Special characters must be URL-encoded
    XCTAssertEqualObjects(dictionary[@"impression"], @"abc%2Bdef%2Fghi%3D",
        @"impression must URL-encode + -> %%2B, / -> %%2F, = -> %%3D");
    XCTAssertEqualObjects(dictionary[@"campaignId"], @"xyz%2B123%2F456%3D%3D",
        @"campaignId must URL-encode + -> %%2B, / -> %%2F, = -> %%3D");

    // eventName and type should NOT be URL-encoded (they're not Base64)
    XCTAssertEqualObjects(dictionary[@"eventName"], @"sdkmetricenc");
    XCTAssertEqualObjects(dictionary[@"type"], @"sdkmetricenc");
}

/**
 * Verify that alphanumeric characters in Base64 are NOT encoded.
 */
- (void)testToDictionary_DoesNotEncodeAlphanumericCharacters {
    // Given - Base64 string with only alphanumeric characters
    NSString *alphanumericBase64 = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    CLXEventAM *event = [[CLXEventAM alloc] initWithImpression:alphanumericBase64
                                                    campaignId:alphanumericBase64
                                                    eventValue:@"N/A"
                                                     eventName:@"sdkmetricenc"
                                                          type:@"sdkmetricenc"];

    // When
    NSDictionary *dictionary = [event toDictionary];

    // Then - Alphanumeric characters should pass through unchanged
    XCTAssertEqualObjects(dictionary[@"impression"], alphanumericBase64,
        @"Alphanumeric characters should not be encoded");
    XCTAssertEqualObjects(dictionary[@"campaignId"], alphanumericBase64,
        @"Alphanumeric characters should not be encoded");
}

#pragma mark - Base64 URL Encoding Tests

- (void)testToDictionary_WithBase64SpecialCharacters_ShouldNotDoubleEncode {
    // Given - Base64 data containing +, /, and = characters that require URL encoding
    CLXEventAM *event = [self createEventWithImpression:kBase64WithSpecialChars
                                             campaignId:kBase64WithSpecialChars];
    
    // When
    NSDictionary *dictionary = [event toDictionary];
    
    // Then - Verify no double encoding
    // Double encoding produces %25 (the URL-encoded form of %)
    // e.g., %2B would become %252B if encoded twice
    NSString *impression = dictionary[@"impression"];
    NSString *campaignId = dictionary[@"campaignId"];
    
    XCTAssertNotNil(impression, @"impression should not be nil");
    XCTAssertNotNil(campaignId, @"campaignId should not be nil");
    XCTAssertFalse([impression containsString:kDoubleEncodingMarker],
                   @"Double encoding detected in impression - found %%25 marker in: %@", impression);
    XCTAssertFalse([campaignId containsString:kDoubleEncodingMarker],
                   @"Double encoding detected in campaignId - found %%25 marker in: %@", campaignId);
}

@end
