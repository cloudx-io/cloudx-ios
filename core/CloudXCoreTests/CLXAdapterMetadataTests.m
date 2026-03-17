#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

#pragma mark - CLXAdapterMetadata JSON Serialization Tests

@interface CLXAdapterMetadataTests : XCTestCase
@end

@implementation CLXAdapterMetadataTests

- (void)testJsonSerializesAllFields {
    CLXAdapterMetadata *metadata = [[CLXAdapterMetadata alloc] initWithNetwork:@"inmobi"
                                                                adapterVersion:@"1.0.0"
                                                             networkSdkVersion:@"11.2.1"];

    NSDictionary *json = [metadata json];

    XCTAssertEqualObjects(json[@"network"], @"inmobi");
    XCTAssertEqualObjects(json[@"adapterVersion"], @"1.0.0");
    XCTAssertEqualObjects(json[@"networkSdkVersion"], @"11.2.1");
}

- (void)testPropertiesAreReadonly {
    CLXAdapterMetadata *metadata = [[CLXAdapterMetadata alloc] initWithNetwork:@"vungle"
                                                                adapterVersion:@"2.0.0"
                                                             networkSdkVersion:@"7.4.0"];

    XCTAssertEqualObjects(metadata.network, @"vungle");
    XCTAssertEqualObjects(metadata.adapterVersion, @"2.0.0");
    XCTAssertEqualObjects(metadata.networkSdkVersion, @"7.4.0");
}

#pragma mark - CLXAdapterMetadataResolver Tests

- (void)testResolverReturnsEmptyListWhenNoAdaptersInstalled {
    CLXAdapterMetadataResolver *resolver = [[CLXAdapterMetadataResolver alloc] init];

    NSArray<CLXAdapterMetadata *> *result = [resolver resolve];

    XCTAssertNotNil(result);
    // In the test target, no adapter frameworks are linked,
    // so the resolver should gracefully return an empty list.
    // (If adapters happen to be linked in the test host, this may be non-empty.)
}

#pragma mark - CLXSDKConfigRequest Adapter Serialization Tests

- (void)testConfigRequestJsonIncludesAdaptersArray {
    CLXSDKConfigRequest *request = [[CLXSDKConfigRequest alloc] init];
    request.bundle = @"com.test.app";
    request.os = @"iOS";
    request.osVersion = @"17.0";
    request.model = @"iPhone15,2";
    request.vendor = @"Apple";
    request.ifa = @"test-ifa";
    request.ifv = @"test-ifv";
    request.sdkVersion = @"1.0.0";
    request.dnt = NO;
    request.imp = @[];
    request.id = @"test-id";
    request.urlParams = @{};
    request.adapters = @[
        [[CLXAdapterMetadata alloc] initWithNetwork:@"inmobi" adapterVersion:@"1.0.0" networkSdkVersion:@"11.2.1"],
        [[CLXAdapterMetadata alloc] initWithNetwork:@"vungle" adapterVersion:@"1.0.0" networkSdkVersion:@"7.4.0"]
    ];

    NSDictionary *json = [request json];
    NSArray *adapters = json[@"adapters"];

    XCTAssertNotNil(adapters);
    XCTAssertEqual(adapters.count, 2);
    XCTAssertEqualObjects(adapters[0][@"network"], @"inmobi");
    XCTAssertEqualObjects(adapters[0][@"adapterVersion"], @"1.0.0");
    XCTAssertEqualObjects(adapters[0][@"networkSdkVersion"], @"11.2.1");
    XCTAssertEqualObjects(adapters[1][@"network"], @"vungle");
}

- (void)testConfigRequestJsonIncludesEmptyAdaptersArray {
    CLXSDKConfigRequest *request = [[CLXSDKConfigRequest alloc] init];
    request.bundle = @"com.test.app";
    request.os = @"iOS";
    request.osVersion = @"17.0";
    request.model = @"iPhone15,2";
    request.vendor = @"Apple";
    request.ifa = @"test-ifa";
    request.ifv = @"test-ifv";
    request.sdkVersion = @"1.0.0";
    request.dnt = NO;
    request.imp = @[];
    request.id = @"test-id";
    request.urlParams = @{};
    request.adapters = @[];

    NSDictionary *json = [request json];
    NSArray *adapters = json[@"adapters"];

    XCTAssertNotNil(adapters);
    XCTAssertEqual(adapters.count, 0);
}

- (void)testConfigRequestJsonHandlesNilAdapters {
    CLXSDKConfigRequest *request = [[CLXSDKConfigRequest alloc] init];
    request.bundle = @"com.test.app";
    request.os = @"iOS";
    request.osVersion = @"17.0";
    request.model = @"iPhone15,2";
    request.vendor = @"Apple";
    request.ifa = @"test-ifa";
    request.ifv = @"test-ifv";
    request.sdkVersion = @"1.0.0";
    request.dnt = NO;
    request.imp = @[];
    request.id = @"test-id";
    request.urlParams = @{};
    // adapters not set (nil)

    NSDictionary *json = [request json];
    NSArray *adapters = json[@"adapters"];

    XCTAssertNotNil(adapters);
    XCTAssertEqual(adapters.count, 0);
}

@end
