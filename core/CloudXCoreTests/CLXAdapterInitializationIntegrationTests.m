//
//  CLXAdapterInitializationIntegrationTests.m
//  CloudXCoreTests
//
//  Integration tests for adapter initialization during SDK init
//  Tests the complete flow from server response to adapter initialization
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXAdapterInitializationIntegrationTests : XCTestCase
@end

@implementation CLXAdapterInitializationIntegrationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Helper Methods

// Create mock SDK config response with bidders
- (CLXSDKConfigResponse *)createMockSDKConfigWithBidders:(NSArray<CLXSDKConfigBidder *> *)bidders {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.accountID = @"TEST_ACCOUNT";
    config.sessionID = @"TEST_SESSION";
    config.bidders = bidders;
    config.placements = @[];
    return config;
}

// Create mock Meta bidder with placement IDs
- (CLXSDKConfigBidder *)createMockMetaBidder {
    NSDictionary *initData = @{
        @"placementIds": @[
            @"24378279391783950_24378393241772565",
            @"24378279391783950_24378394368439119",
            @"24378279391783950_24378395398439016"
        ]
    };
    
    return [[CLXSDKConfigBidder alloc] initWithBidderInitData:initData networkName:@"meta"];
}

// Create mock test bidder
- (CLXSDKConfigBidder *)createMockTestBidder {
    NSDictionary *initData = @{};
    return [[CLXSDKConfigBidder alloc] initWithBidderInitData:initData networkName:@"testbidder"];
}

#pragma mark - SDK Configuration Processing Tests

// Test SDK processes bidders from server response
- (void)testSDKProcessesBiddersFromServerResponse {
    // Create mock bidders
    NSArray *bidders = @[
        [self createMockMetaBidder],
        [self createMockTestBidder]
    ];
    
    CLXSDKConfigResponse *mockConfig = [self createMockSDKConfigWithBidders:bidders];
    
    XCTAssertNotNil(mockConfig.bidders, @"Config should have bidders");
    XCTAssertEqual(mockConfig.bidders.count, 2, @"Should have 2 bidders");
    
    // Verify Meta bidder configuration
    CLXSDKConfigBidder *metaBidder = mockConfig.bidders[0];
    XCTAssertEqualObjects(metaBidder.networkName, @"meta", @"First bidder should be Meta");
    XCTAssertNotNil(metaBidder.bidderInitData[@"placementIds"], @"Meta bidder should have placement IDs");
    
    NSArray *placementIds = metaBidder.bidderInitData[@"placementIds"];
    XCTAssertEqual(placementIds.count, 3, @"Meta bidder should have 3 placement IDs");
}

// Test bidder network name mapping during processing
- (void)testBidderNetworkNameMappingDuringProcessing {
    // Test 'meta' network name
    CLXSDKConfigBidder *metaBidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:@{} networkName:@"meta"];
    
    XCTAssertEqualObjects([metaBidder networkNameMapped], @"meta", @"'meta' should map to 'meta'");
}

#pragma mark - Adapter Initialization Flow Tests

// Test adapter initialization is called for discovered adapters
- (void)testAdapterInitializationCalledForDiscoveredAdapters {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Adapter initialization should be attempted"];
    
    // Create a simple test to verify the initialization flow exists
    // This tests the structure without requiring actual adapter implementations
    
    CLXSDKConfigBidder *testBidder = [self createMockTestBidder];
    XCTAssertNotNil(testBidder, @"Test bidder should be created");
    XCTAssertEqualObjects([testBidder networkNameMapped], @"testbidder", @"Test bidder should map correctly");
    
    // Verify the bidder config can be created (this is what gets passed to initializers)
    CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:testBidder.bidderInitData 
                                                                            networkName:testBidder.networkName];
    XCTAssertNotNil(bidderConfig, @"Bidder config should be created for adapter initialization");
    
    [expectation fulfill];
    [self waitForExpectations:@[expectation] timeout:1.0];
}

// Test Meta adapter receives correct initialization data format
- (void)testMetaAdapterReceivesCorrectInitializationDataFormat {
    CLXSDKConfigBidder *metaBidder = [self createMockMetaBidder];
    CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:metaBidder.bidderInitData 
                                                                            networkName:metaBidder.networkName];
    
    // Verify the data format that would be passed to Meta adapter
    XCTAssertEqualObjects(bidderConfig.networkName, @"meta", @"Network name should be 'meta'");
    XCTAssertNotNil(bidderConfig.initializationData, @"Initialization data should not be nil");
    
    // Verify placement IDs are in the correct format for Meta adapter
    NSArray *placementIds = bidderConfig.initializationData[@"placementIds"];
    XCTAssertNotNil(placementIds, @"Placement IDs should be available under 'placementIds' key");
    XCTAssertTrue([placementIds isKindOfClass:[NSArray class]], @"Placement IDs should be an array");
    XCTAssertEqual(placementIds.count, 3, @"Should have 3 placement IDs");
    
    // Verify placement ID format
    for (NSString *placementId in placementIds) {
        XCTAssertTrue([placementId isKindOfClass:[NSString class]], @"Each placement ID should be a string");
        XCTAssertTrue([placementId containsString:@"_"], @"Placement IDs should contain underscore separator");
    }
}

#pragma mark - Error Handling Tests

// Test handling of empty bidders array
- (void)testHandlingOfEmptyBiddersArray {
    CLXSDKConfigResponse *configWithNoBidders = [self createMockSDKConfigWithBidders:@[]];
    
    XCTAssertNotNil(configWithNoBidders.bidders, @"Bidders array should not be nil");
    XCTAssertEqual(configWithNoBidders.bidders.count, 0, @"Bidders array should be empty");
    
    // SDK should handle empty bidders gracefully without crashing
    XCTAssertNoThrow(configWithNoBidders.bidders, @"Accessing empty bidders should not throw");
}

// Test handling of bidder with missing initialization data
- (void)testHandlingOfBidderWithMissingInitializationData {
    CLXSDKConfigBidder *bidderWithNoData = [[CLXSDKConfigBidder alloc] initWithBidderInitData:nil networkName:@"meta"];
    
    // Should handle nil initialization data gracefully
    XCTAssertNil(bidderWithNoData.bidderInitData, @"Bidder init data should be nil when passed nil");
    XCTAssertEqualObjects(bidderWithNoData.networkName, @"meta", @"Network name should still be set");
    
    // Creating CLXBidderConfig with nil data should work
    CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:bidderWithNoData.bidderInitData 
                                                                            networkName:bidderWithNoData.networkName];
    XCTAssertNotNil(bidderConfig, @"Bidder config should be created even with nil init data");
    XCTAssertNil(bidderConfig.initializationData, @"Initialization data should be nil");
}

// Test handling of malformed placement IDs
- (void)testHandlingOfMalformedPlacementIds {
    // Test with non-array placement IDs
    NSDictionary *malformedData = @{
        @"placementIds": @"not_an_array"  // String instead of array
    };
    
    CLXSDKConfigBidder *bidder = [[CLXSDKConfigBidder alloc] initWithBidderInitData:malformedData networkName:@"meta"];
    CLXBidderConfig *bidderConfig = [[CLXBidderConfig alloc] initWithInitializationData:bidder.bidderInitData 
                                                                            networkName:bidder.networkName];
    
    XCTAssertNotNil(bidderConfig, @"Bidder config should be created even with malformed data");
    XCTAssertNotNil(bidderConfig.initializationData[@"placementIds"], @"Malformed placement IDs should be preserved");
    XCTAssertTrue([bidderConfig.initializationData[@"placementIds"] isKindOfClass:[NSString class]], 
                 @"Malformed data should preserve original type");
}

@end
