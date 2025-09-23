/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsConfig.h>

@interface CLXMetricsConfigTests : XCTestCase
@end

@implementation CLXMetricsConfigTests

- (void)testDefaultInitialization {
    // When
    CLXMetricsConfig *config = [[CLXMetricsConfig alloc] init];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.sendIntervalSeconds, 60); // Default like Android
    XCTAssertNil(config.sdkApiCallsEnabled);
    XCTAssertNil(config.networkCallsEnabled);
    XCTAssertNil(config.networkCallsBidReqEnabled);
    XCTAssertNil(config.networkCallsInitSdkReqEnabled);
    XCTAssertNil(config.networkCallsGeoReqEnabled);
}

- (void)testFromDictionaryWithAllValues {
    // Given
    NSDictionary *dictionary = @{
        @"send_interval_seconds": @120,
        @"sdk_api_calls.enabled": @YES,
        @"network_calls.enabled": @YES,
        @"network_calls.bid_req.enabled": @YES,
        @"network_calls.init_sdk_req.enabled": @NO,
        @"network_calls.geo_req.enabled": @YES
    };
    
    // When
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.sendIntervalSeconds, 120);
    XCTAssertEqualObjects(config.sdkApiCallsEnabled, @YES);
    XCTAssertEqualObjects(config.networkCallsEnabled, @YES);
    XCTAssertEqualObjects(config.networkCallsBidReqEnabled, @YES);
    XCTAssertEqualObjects(config.networkCallsInitSdkReqEnabled, @NO);
    XCTAssertEqualObjects(config.networkCallsGeoReqEnabled, @YES);
}

- (void)testFromDictionaryWithPartialValues {
    // Given
    NSDictionary *dictionary = @{
        @"send_interval_seconds": @30,
        @"sdk_api_calls.enabled": @NO
    };
    
    // When
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.sendIntervalSeconds, 30);
    XCTAssertEqualObjects(config.sdkApiCallsEnabled, @NO);
    XCTAssertNil(config.networkCallsEnabled);
    XCTAssertNil(config.networkCallsBidReqEnabled);
    XCTAssertNil(config.networkCallsInitSdkReqEnabled);
    XCTAssertNil(config.networkCallsGeoReqEnabled);
}

- (void)testFromDictionaryWithEmptyDictionary {
    // Given
    NSDictionary *dictionary = @{};
    
    // When
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.sendIntervalSeconds, 60); // Default value
    XCTAssertNil(config.sdkApiCallsEnabled);
    XCTAssertNil(config.networkCallsEnabled);
    XCTAssertNil(config.networkCallsBidReqEnabled);
    XCTAssertNil(config.networkCallsInitSdkReqEnabled);
    XCTAssertNil(config.networkCallsGeoReqEnabled);
}

- (void)testIsSdkApiCallsEnabled {
    // Test enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.sdkApiCallsEnabled = @YES;
    XCTAssertTrue([config1 isSdkApiCallsEnabled]);
    
    // Test disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.sdkApiCallsEnabled = @NO;
    XCTAssertFalse([config2 isSdkApiCallsEnabled]);
    
    // Test nil (default disabled)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.sdkApiCallsEnabled = nil;
    XCTAssertFalse([config3 isSdkApiCallsEnabled]);
}

- (void)testIsNetworkCallsEnabled {
    // Test enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCallsEnabled = @YES;
    XCTAssertTrue([config1 isNetworkCallsEnabled]);
    
    // Test disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCallsEnabled = @NO;
    XCTAssertFalse([config2 isNetworkCallsEnabled]);
    
    // Test nil (default disabled)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCallsEnabled = nil;
    XCTAssertFalse([config3 isNetworkCallsEnabled]);
}

- (void)testIsBidRequestNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCallsEnabled = @YES;
    config1.networkCallsBidReqEnabled = @YES;
    XCTAssertTrue([config1 isBidRequestNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCallsEnabled = @YES;
    config2.networkCallsBidReqEnabled = @NO;
    XCTAssertFalse([config2 isBidRequestNetworkCallsEnabled]);
    
    // Test global disabled but specific enabled
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCallsEnabled = @NO;
    config3.networkCallsBidReqEnabled = @YES;
    XCTAssertFalse([config3 isBidRequestNetworkCallsEnabled]);
    
    // Test both disabled
    CLXMetricsConfig *config4 = [[CLXMetricsConfig alloc] init];
    config4.networkCallsEnabled = @NO;
    config4.networkCallsBidReqEnabled = @NO;
    XCTAssertFalse([config4 isBidRequestNetworkCallsEnabled]);
}

- (void)testIsInitSdkNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCallsEnabled = @YES;
    config1.networkCallsInitSdkReqEnabled = @YES;
    XCTAssertTrue([config1 isInitSdkNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCallsEnabled = @YES;
    config2.networkCallsInitSdkReqEnabled = @NO;
    XCTAssertFalse([config2 isInitSdkNetworkCallsEnabled]);
}

- (void)testIsGeoNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCallsEnabled = @YES;
    config1.networkCallsGeoReqEnabled = @YES;
    XCTAssertTrue([config1 isGeoNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCallsEnabled = @YES;
    config2.networkCallsGeoReqEnabled = @NO;
    XCTAssertFalse([config2 isGeoNetworkCallsEnabled]);
}

- (void)testDescription {
    // Given
    CLXMetricsConfig *config = [[CLXMetricsConfig alloc] init];
    config.sendIntervalSeconds = 90;
    config.sdkApiCallsEnabled = @YES;
    config.networkCallsEnabled = @NO;
    
    // When
    NSString *description = [config description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"90"]);
    XCTAssertTrue([description containsString:@"1"]); // YES as number
    XCTAssertTrue([description containsString:@"0"]); // NO as number
}

@end
