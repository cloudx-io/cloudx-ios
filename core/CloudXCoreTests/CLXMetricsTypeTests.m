/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsType.h>

@interface CLXMetricsTypeTests : XCTestCase
@end

@implementation CLXMetricsTypeTests

- (void)testNetworkCallTypes {
    // Test all network call types match Android exactly
    XCTAssertEqualObjects(CLXMetricsTypeNetworkSdkInit, @"network_call_sdk_init_req");
    XCTAssertEqualObjects(CLXMetricsTypeNetworkGeoApi, @"network_call_geo_req");
    XCTAssertEqualObjects(CLXMetricsTypeNetworkBidRequest, @"network_call_bid_req");
}

- (void)testMethodCallTypes {
    // Test all method call types match Android exactly
    XCTAssertEqualObjects(CLXMetricsTypeMethodSdkInit, @"method_sdk_init");
    XCTAssertEqualObjects(CLXMetricsTypeMethodCreateBanner, @"method_create_banner");
    XCTAssertEqualObjects(CLXMetricsTypeMethodCreateInterstitial, @"method_create_interstitial");
    XCTAssertEqualObjects(CLXMetricsTypeMethodCreateRewarded, @"method_create_rewarded");
    XCTAssertEqualObjects(CLXMetricsTypeMethodCreateMrec, @"method_create_mrec");
    XCTAssertEqualObjects(CLXMetricsTypeMethodCreateNative, @"method_create_native");
    XCTAssertEqualObjects(CLXMetricsTypeMethodSetHashedUserId, @"method_set_hashed_user_id");
    XCTAssertEqualObjects(CLXMetricsTypeMethodSetUserKeyValues, @"method_set_user_key_values");
    XCTAssertEqualObjects(CLXMetricsTypeMethodSetAppKeyValues, @"method_set_app_key_values");
    XCTAssertEqualObjects(CLXMetricsTypeMethodBannerRefresh, @"method_banner_refresh");
}

- (void)testIsNetworkCallType {
    // Test network call type detection
    XCTAssertTrue([CLXMetricsType isNetworkCallType:CLXMetricsTypeNetworkSdkInit]);
    XCTAssertTrue([CLXMetricsType isNetworkCallType:CLXMetricsTypeNetworkGeoApi]);
    XCTAssertTrue([CLXMetricsType isNetworkCallType:CLXMetricsTypeNetworkBidRequest]);
    
    // Test method calls are not network calls
    XCTAssertFalse([CLXMetricsType isNetworkCallType:CLXMetricsTypeMethodSdkInit]);
    XCTAssertFalse([CLXMetricsType isNetworkCallType:CLXMetricsTypeMethodCreateBanner]);
    
    // Test invalid types
    XCTAssertFalse([CLXMetricsType isNetworkCallType:@"invalid_type"]);
    XCTAssertFalse([CLXMetricsType isNetworkCallType:nil]);
}

- (void)testIsMethodCallType {
    // Test method call type detection
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodSdkInit]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodCreateBanner]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodCreateInterstitial]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodCreateRewarded]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodCreateMrec]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodCreateNative]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodSetHashedUserId]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodSetUserKeyValues]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodSetAppKeyValues]);
    XCTAssertTrue([CLXMetricsType isMethodCallType:CLXMetricsTypeMethodBannerRefresh]);
    
    // Test network calls are not method calls
    XCTAssertFalse([CLXMetricsType isMethodCallType:CLXMetricsTypeNetworkSdkInit]);
    XCTAssertFalse([CLXMetricsType isMethodCallType:CLXMetricsTypeNetworkBidRequest]);
    
    // Test invalid types
    XCTAssertFalse([CLXMetricsType isMethodCallType:@"invalid_type"]);
    XCTAssertFalse([CLXMetricsType isMethodCallType:nil]);
}

- (void)testAllNetworkCallTypes {
    // Test that all network call types are returned
    NSArray<NSString *> *networkTypes = [CLXMetricsType allNetworkCallTypes];
    
    XCTAssertNotNil(networkTypes);
    XCTAssertEqual(networkTypes.count, 3);
    XCTAssertTrue([networkTypes containsObject:CLXMetricsTypeNetworkSdkInit]);
    XCTAssertTrue([networkTypes containsObject:CLXMetricsTypeNetworkGeoApi]);
    XCTAssertTrue([networkTypes containsObject:CLXMetricsTypeNetworkBidRequest]);
}

- (void)testAllMethodCallTypes {
    // Test that all method call types are returned
    NSArray<NSString *> *methodTypes = [CLXMetricsType allMethodCallTypes];
    
    XCTAssertNotNil(methodTypes);
    XCTAssertEqual(methodTypes.count, 10);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodSdkInit]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodCreateBanner]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodCreateInterstitial]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodCreateRewarded]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodCreateMrec]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodCreateNative]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodSetHashedUserId]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodSetUserKeyValues]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodSetAppKeyValues]);
    XCTAssertTrue([methodTypes containsObject:CLXMetricsTypeMethodBannerRefresh]);
}

- (void)testIsValidMetricType {
    // Test valid network types
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeNetworkSdkInit]);
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeNetworkGeoApi]);
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeNetworkBidRequest]);
    
    // Test valid method types
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeMethodSdkInit]);
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeMethodCreateBanner]);
    XCTAssertTrue([CLXMetricsType isValidMetricType:CLXMetricsTypeMethodBannerRefresh]);
    
    // Test invalid types
    XCTAssertFalse([CLXMetricsType isValidMetricType:@"invalid_type"]);
    XCTAssertFalse([CLXMetricsType isValidMetricType:@""]);
    XCTAssertFalse([CLXMetricsType isValidMetricType:nil]);
}

@end
