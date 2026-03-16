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
    XCTAssertNil(config.sdkAPICalls);
    XCTAssertNil(config.networkCalls);
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
    XCTAssertEqualObjects(config.sdkAPICalls.enabled, @YES);
    XCTAssertEqualObjects(config.networkCalls.enabled, @YES);
    XCTAssertEqualObjects(config.networkCalls.bidReq.enabled, @YES);
    XCTAssertEqualObjects(config.networkCalls.sdkInitRequest.enabled, @NO);
    XCTAssertEqualObjects(config.networkCalls.geoReq.enabled, @YES);
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
    XCTAssertEqualObjects(config.sdkAPICalls.enabled, @NO);
    XCTAssertNil(config.networkCalls);
}

- (void)testFromDictionaryWithEmptyDictionary {
    // Given
    NSDictionary *dictionary = @{};
    
    // When
    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:dictionary];
    
    // Then
    XCTAssertNotNil(config);
    XCTAssertEqual(config.sendIntervalSeconds, 60); // Default value
    XCTAssertNil(config.sdkAPICalls);
    XCTAssertNil(config.networkCalls);
}

- (void)testIsSdkApiCallsEnabled {
    // Test enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    config1.sdkAPICalls.enabled = @YES;
    XCTAssertTrue([config1 isSdkApiCallsEnabled]);
    
    // Test disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    config2.sdkAPICalls.enabled = @NO;
    XCTAssertFalse([config2 isSdkApiCallsEnabled]);
    
    // Test nil (default disabled)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    XCTAssertFalse([config3 isSdkApiCallsEnabled]);
}

- (void)testIsNetworkCallsEnabled {
    // Test enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    XCTAssertTrue([config1 isNetworkCallsEnabled]);
    
    // Test disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @NO;
    XCTAssertFalse([config2 isNetworkCallsEnabled]);
    
    // Test nil (default disabled)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    XCTAssertFalse([config3 isNetworkCallsEnabled]);
}

- (void)testIsBidRequestNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.bidReq.enabled = @YES;
    XCTAssertTrue([config1 isBidRequestNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.bidReq.enabled = @NO;
    XCTAssertFalse([config2 isBidRequestNetworkCallsEnabled]);
    
    // Test sub-config only checks its own flag (global check is in tracker)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config3.networkCalls.enabled = @NO;
    config3.networkCalls.bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config3.networkCalls.bidReq.enabled = @YES;
    XCTAssertTrue([config3 isBidRequestNetworkCallsEnabled]);

    // Test specific disabled
    CLXMetricsConfig *config4 = [[CLXMetricsConfig alloc] init];
    config4.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config4.networkCalls.enabled = @NO;
    config4.networkCalls.bidReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config4.networkCalls.bidReq.enabled = @NO;
    XCTAssertFalse([config4 isBidRequestNetworkCallsEnabled]);
}

- (void)testIsSdkInitNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.sdkInitRequest = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.sdkInitRequest.enabled = @YES;
    XCTAssertTrue([config1 isSdkInitNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.sdkInitRequest = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.sdkInitRequest.enabled = @NO;
    XCTAssertFalse([config2 isSdkInitNetworkCallsEnabled]);
}

- (void)testIsGeoNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.geoReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.geoReq.enabled = @YES;
    XCTAssertTrue([config1 isGeoNetworkCallsEnabled]);
    
    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.geoReq = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.geoReq.enabled = @NO;
    XCTAssertFalse([config2 isGeoNetworkCallsEnabled]);
}

- (void)testIsAdapterInitNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.adapterInit = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.adapterInit.enabled = @YES;
    XCTAssertTrue([config1 isAdapterInitNetworkCallsEnabled]);

    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.adapterInit = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.adapterInit.enabled = @NO;
    XCTAssertFalse([config2 isAdapterInitNetworkCallsEnabled]);

    // Test nil sub-config (disabled by default)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config3.networkCalls.enabled = @YES;
    XCTAssertFalse([config3 isAdapterInitNetworkCallsEnabled]);
}

- (void)testIsAdapterLoadNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.adapterLoad = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.adapterLoad.enabled = @YES;
    XCTAssertTrue([config1 isAdapterLoadNetworkCallsEnabled]);

    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.adapterLoad = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.adapterLoad.enabled = @NO;
    XCTAssertFalse([config2 isAdapterLoadNetworkCallsEnabled]);

    // Test sub-config only checks its own flag (global check is in tracker)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config3.networkCalls.enabled = @NO;
    config3.networkCalls.adapterLoad = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config3.networkCalls.adapterLoad.enabled = @YES;
    XCTAssertTrue([config3 isAdapterLoadNetworkCallsEnabled]);

    // Test nil sub-config (disabled by default)
    CLXMetricsConfig *config4 = [[CLXMetricsConfig alloc] init];
    config4.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config4.networkCalls.enabled = @YES;
    XCTAssertFalse([config4 isAdapterLoadNetworkCallsEnabled]);
}

- (void)testIsAdapterErrorNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.adapterError = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.adapterError.enabled = @YES;
    XCTAssertTrue([config1 isAdapterErrorNetworkCallsEnabled]);

    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.adapterError = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.adapterError.enabled = @NO;
    XCTAssertFalse([config2 isAdapterErrorNetworkCallsEnabled]);

    // Test nil sub-config (disabled by default)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config3.networkCalls.enabled = @YES;
    XCTAssertFalse([config3 isAdapterErrorNetworkCallsEnabled]);
}

- (void)testIsTimeToFirstAdNetworkCallsEnabled {
    // Test both global and specific enabled
    CLXMetricsConfig *config1 = [[CLXMetricsConfig alloc] init];
    config1.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config1.networkCalls.enabled = @YES;
    config1.networkCalls.timeToFirstAd = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config1.networkCalls.timeToFirstAd.enabled = @YES;
    XCTAssertTrue([config1 isTimeToFirstAdNetworkCallsEnabled]);

    // Test global enabled but specific disabled
    CLXMetricsConfig *config2 = [[CLXMetricsConfig alloc] init];
    config2.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config2.networkCalls.enabled = @YES;
    config2.networkCalls.timeToFirstAd = [[CLXMetricsConfigNetworkSubConfig alloc] init];
    config2.networkCalls.timeToFirstAd.enabled = @NO;
    XCTAssertFalse([config2 isTimeToFirstAdNetworkCallsEnabled]);

    // Test nil sub-config (disabled by default)
    CLXMetricsConfig *config3 = [[CLXMetricsConfig alloc] init];
    config3.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config3.networkCalls.enabled = @YES;
    XCTAssertFalse([config3 isTimeToFirstAdNetworkCallsEnabled]);
}

- (void)testFromDictionaryWithNestedNetworkSubConfigs {
    NSDictionary *dictionary = @{
        @"sendIntervalSeconds": @60,
        @"sdkAPICalls": @{@"enabled": @YES},
        @"networkCalls": @{
            @"enabled": @YES,
            @"bidReq": @{@"enabled": @YES},
            @"initSdkReq": @{@"enabled": @YES},
            @"geoReq": @{@"enabled": @YES},
            @"adapterInit": @{@"enabled": @YES},
            @"adapterLoad": @{@"enabled": @YES},
            @"adapterError": @{@"enabled": @NO},
            @"timeToFirstAd": @{@"enabled": @YES}
        }
    };

    CLXMetricsConfig *config = [CLXMetricsConfig fromDictionary:dictionary];

    XCTAssertTrue([config isNetworkCallsEnabled]);
    XCTAssertTrue([config isBidRequestNetworkCallsEnabled]);
    XCTAssertTrue([config isSdkInitNetworkCallsEnabled]);
    XCTAssertTrue([config isGeoNetworkCallsEnabled]);
    XCTAssertTrue([config isAdapterInitNetworkCallsEnabled]);
    XCTAssertTrue([config isAdapterLoadNetworkCallsEnabled]);
    XCTAssertFalse([config isAdapterErrorNetworkCallsEnabled]);
    XCTAssertTrue([config isTimeToFirstAdNetworkCallsEnabled]);
}

- (void)testDescription {
    // Given
    CLXMetricsConfig *config = [[CLXMetricsConfig alloc] init];
    config.sendIntervalSeconds = 90;
    config.sdkAPICalls = [[CLXMetricsConfigSDKAPICalls alloc] init];
    config.sdkAPICalls.enabled = @YES;
    config.networkCalls = [[CLXMetricsConfigNetworkCalls alloc] init];
    config.networkCalls.enabled = @NO;
    
    // When
    NSString *description = [config description];
    
    // Then
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"90"]);
}

@end
