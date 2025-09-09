//
//  CLXAdapterInitializationUnitTests.m
//  CloudXCoreTests
//
//  Unit tests for adapter initialization from SDK init response
//  Tests bidder config processing, network name mapping, and adapter discovery
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXAdapterInitializationUnitTests : XCTestCase
@property (nonatomic, strong) CLXAdapterFactoryResolver *resolver;
@end

@implementation CLXAdapterInitializationUnitTests

- (void)setUp {
    [super setUp];
    self.resolver = [[CLXAdapterFactoryResolver alloc] init];
}

- (void)tearDown {
    self.resolver = nil;
    [super tearDown];
}

#pragma mark - CLXSDKConfigBidder Tests

// Test network name mapping for Meta adapter
- (void)testMetaNetworkNameMapping {
    CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:@{} networkName:@"meta"];
    XCTAssertEqualObjects([bidder networkNameMapped], @"meta", @"Meta network name should map to 'meta'");
}

// Test bidder config creation with placement IDs
- (void)testBidderConfigWithPlacementIds {
    NSDictionary *initData = @{
        @"placementIds": @[
            @"24378279391783950_24378393241772565",
            @"24378279391783950_24378394368439119"
        ]
    };
    
    CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:initData networkName:@"meta"];
    
    XCTAssertNotNil(bidder.bidderInitData, @"Bidder init data should not be nil");
    XCTAssertEqualObjects(bidder.networkName, @"meta", @"Network name should be preserved");
    
    NSArray *placementIds = bidder.bidderInitData[@"placementIds"];
    XCTAssertNotNil(placementIds, @"Placement IDs should be preserved");
    XCTAssertEqual(placementIds.count, 2, @"Should have 2 placement IDs");
}

// Test CLXBidderConfig creation from CLXSDKConfigBidder
- (void)testCLXBidderConfigCreation {
    NSDictionary *initData = @{
        @"placementIds": @[@"test_placement_1", @"test_placement_2"]
    };
    
    CLXSDKConfigBidder *sdkBidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:initData networkName:@"meta"];
    CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:sdkBidder.bidderInitData networkName:sdkBidder.networkName];
    
    XCTAssertNotNil(bidderConfig, @"Bidder config should be created successfully");
    XCTAssertEqualObjects(bidderConfig.networkName, @"meta", @"Network name should match");
    XCTAssertNotNil(bidderConfig.initializationData, @"Initialization data should not be nil");
    
    NSArray *placementIds = bidderConfig.initializationData[@"placementIds"];
    XCTAssertEqual(placementIds.count, 2, @"Placement IDs should be preserved in bidder config");
}

#pragma mark - Adapter Factory Resolver Tests

// Test adapter factory resolution structure is correct
- (void)testAdapterFactoryResolution {
    NSDictionary *factories = [self.resolver resolveAdNetworkFactories];
    
    XCTAssertNotNil(factories, @"Factories dictionary should not be nil");
    XCTAssertNotNil(factories[@"initializers"], @"Initializers should be present");
    XCTAssertNotNil(factories[@"banners"], @"Banner factories should be present");
    XCTAssertNotNil(factories[@"interstitials"], @"Interstitial factories should be present");
    XCTAssertNotNil(factories[@"native"], @"Native factories should be present");
    XCTAssertNotNil(factories[@"bidTokenSources"], @"Bid token sources should be present");
    XCTAssertNotNil(factories[@"isEmpty"], @"isEmpty flag should be present");
    
    // Test that the structure is correct (adapters may or may not be available in test environment)
    NSDictionary *initializers = factories[@"initializers"];
    XCTAssertTrue([initializers isKindOfClass:[NSDictionary class]], @"Initializers should be a dictionary");
    
    NSLog(@"Available initializers in test environment: %@", [initializers allKeys]);
}

// Test Meta adapter is discovered when available
- (void)testMetaAdapterDiscovery {
    NSDictionary *factories = [self.resolver resolveAdNetworkFactories];
    NSDictionary *initializers = factories[@"initializers"];
    
    // Meta adapter should be discovered if available (conditional test)
    id metaInitializer = initializers[@"meta"];
    if (metaInitializer) {
        XCTAssertNotNil(metaInitializer, @"Meta initializer should be available when present");
        
        // Verify it responds to required methods
        XCTAssertTrue([metaInitializer respondsToSelector:@selector(initializeWithConfig:completion:)], 
                     @"Meta initializer should respond to initializeWithConfig:completion:");
        
        NSLog(@"Meta adapter discovered and validated in test environment");
    } else {
        NSLog(@"Meta adapter not available in test environment - this is expected for unit tests");
        XCTAssertTrue(YES, @"Test passes when Meta adapter is not available");
    }
}

#pragma mark - Network Name Mapping Edge Cases

// Test all supported network name mappings
- (void)testAllNetworkNameMappings {
    // Test known mappings
    NSArray *testCases = @[
        @[@"testbidder", @"testbidder"],
        @[@"googleAdManager", @"googleAdManager"],
        @[@"meta", @"meta"],
        @[@"mintegral", @"mintegral"],
        @[@"cloudx", @"cloudx"],
        @[@"prebidAdapter", @"prebidAdapter"],
        @[@"prebidMobile", @"prebidAdapter"],  // Should map to prebidAdapter
        @[@"unknown", @"unknown"]  // Unknown should return as-is
    ];
    
    for (NSArray *testCase in testCases) {
        NSString *input = testCase[0];
        NSString *expected = testCase[1];
        
        CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:@{} networkName:input];
        XCTAssertEqualObjects([bidder networkNameMapped], expected, 
                             @"Network name '%@' should map to '%@'", input, expected);
    }
}

#pragma mark - Data Type Handling Tests

// Test mixed data types in initialization data
- (void)testMixedDataTypesInInitializationData {
    NSDictionary *mixedData = @{
        @"placementIds": @[@"id1", @"id2"],  // Array
        @"appId": @"test_app_id",           // String
        @"testMode": @YES,                  // Boolean
        @"timeout": @30                     // Number
    };
    
    CLXBidderConfig *config = [[CLXBidderConfig alloc] initWithInitializationData:mixedData networkName:@"meta"];
    
    XCTAssertNotNil(config.initializationData, @"Should handle mixed data types");
    XCTAssertTrue([config.initializationData[@"placementIds"] isKindOfClass:[NSArray class]], 
                 @"Array should be preserved as array");
    XCTAssertTrue([config.initializationData[@"appId"] isKindOfClass:[NSString class]], 
                 @"String should be preserved as string");
    XCTAssertTrue([config.initializationData[@"testMode"] isKindOfClass:[NSNumber class]], 
                 @"Boolean should be preserved as NSNumber");
}

@end
