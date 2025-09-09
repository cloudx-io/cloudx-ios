//
//  CLXBidNetworkServiceImplementationTests.m
//  CloudXCoreTests
//
//  Unit tests for CLXBidNetworkServiceImplementation focusing on impression ID generation
//  Tests OpenRTB compliance for unique impression IDs and proper field mapping
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Test constants
static NSString * const kTestAdUnitID = @"metaBanner";
static NSString * const kTestStoredImpressionID = @"oDzq2hxuhvtD6xgdXk2G8";
static NSString * const kTestPublisherID = @"test-publisher";
static NSString * const kTestUserID = @"test-user";
static const double kTestBidFloor = 0.01;
static const NSInteger kTestBannerAdType = 1;

@interface CLXBidNetworkServiceImplementationTests : XCTestCase
@property (nonatomic, strong) CLXBidNetworkServiceImplementation *bidNetworkService;
@end

@implementation CLXBidNetworkServiceImplementationTests

- (void)setUp {
    [super setUp];
    self.bidNetworkService = [[CLXBidNetworkServiceImplementation alloc] init];
}

- (void)tearDown {
    self.bidNetworkService = nil;
    [super tearDown];
}

// Test that impression ID is unique and follows UUID format
- (void)testImpressionIDIsUniqueUUID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bid request created"];
    
    [self.bidNetworkService createBidRequestWithAdUnitID:kTestAdUnitID
                                      storedImpressionId:kTestStoredImpressionID
                                                  adType:kTestBannerAdType
                                                  dealID:nil
                                                bidFloor:kTestBidFloor
                                             publisherID:kTestPublisherID
                                                  userID:kTestUserID
                                             adapterInfo:nil
                                    nativeAdRequirements:nil
                                                    tmax:nil
                                                impModel:nil
                                              completion:^(id bidRequest, NSError *error) {
        XCTAssertNil(error, @"Bid request should not have error");
        XCTAssertNotNil(bidRequest, @"Bid request should not be nil");
        
        NSDictionary *imp = [bidRequest[@"imp"] firstObject];
        XCTAssertNotNil(imp, @"Impression should exist");
        
        NSString *impId = imp[@"id"];
        XCTAssertNotNil(impId, @"Impression ID should not be nil");
        
        // Verify UUID format (36 characters with hyphens)
        XCTAssertEqual(impId.length, 36, @"Impression ID should be 36 characters (UUID format)");
        XCTAssertTrue([impId containsString:@"-"], @"Impression ID should contain hyphens (UUID format)");
        
        // Verify it's different from stored impression ID
        XCTAssertNotEqualObjects(impId, kTestStoredImpressionID, @"Impression ID should be unique, not the stored impression ID");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

// Test that tagid correctly maps to ad unit ID
- (void)testTagIDMapsToAdUnitID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bid request created"];
    
    [self.bidNetworkService createBidRequestWithAdUnitID:kTestAdUnitID
                                      storedImpressionId:kTestStoredImpressionID
                                                  adType:kTestBannerAdType
                                                  dealID:nil
                                                bidFloor:kTestBidFloor
                                             publisherID:kTestPublisherID
                                                  userID:kTestUserID
                                             adapterInfo:nil
                                    nativeAdRequirements:nil
                                                    tmax:nil
                                                impModel:nil
                                              completion:^(id bidRequest, NSError *error) {
        XCTAssertNil(error, @"Bid request should not have error");
        
        NSDictionary *imp = [bidRequest[@"imp"] firstObject];
        NSString *tagId = imp[@"tagid"];
        
        XCTAssertNotNil(tagId, @"Tag ID should not be nil");
        XCTAssertEqualObjects(tagId, kTestAdUnitID, @"Tag ID should match ad unit ID");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

// Test that impression IDs are unique across multiple requests
- (void)testImpressionIDUniquenessAcrossRequests {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"First bid request"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Second bid request"];
    
    __block NSString *firstImpId = nil;
    __block NSString *secondImpId = nil;
    
    // Create first request
    [self.bidNetworkService createBidRequestWithAdUnitID:kTestAdUnitID
                                      storedImpressionId:kTestStoredImpressionID
                                                  adType:kTestBannerAdType
                                                  dealID:nil
                                                bidFloor:kTestBidFloor
                                             publisherID:kTestPublisherID
                                                  userID:kTestUserID
                                             adapterInfo:nil
                                    nativeAdRequirements:nil
                                                    tmax:nil
                                                impModel:nil
                                              completion:^(id bidRequest, NSError *error) {
        XCTAssertNil(error, @"First bid request should not have error");
        
        NSDictionary *imp = [bidRequest[@"imp"] firstObject];
        firstImpId = imp[@"id"];
        
        [expectation1 fulfill];
    }];
    
    // Create second request
    [self.bidNetworkService createBidRequestWithAdUnitID:kTestAdUnitID
                                      storedImpressionId:kTestStoredImpressionID
                                                  adType:kTestBannerAdType
                                                  dealID:nil
                                                bidFloor:kTestBidFloor
                                             publisherID:kTestPublisherID
                                                  userID:kTestUserID
                                             adapterInfo:nil
                                    nativeAdRequirements:nil
                                                    tmax:nil
                                                impModel:nil
                                              completion:^(id bidRequest, NSError *error) {
        XCTAssertNil(error, @"Second bid request should not have error");
        
        NSDictionary *imp = [bidRequest[@"imp"] firstObject];
        secondImpId = imp[@"id"];
        
        [expectation2 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:5.0];
    
    // Verify impression IDs are different
    XCTAssertNotNil(firstImpId, @"First impression ID should not be nil");
    XCTAssertNotNil(secondImpId, @"Second impression ID should not be nil");
    XCTAssertNotEqualObjects(firstImpId, secondImpId, @"Impression IDs should be unique across requests");
}

// Test that stored impression ID is preserved in ext.prebid.storedimpression
- (void)testStoredImpressionIDPreservedInExt {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bid request created"];
    
    [self.bidNetworkService createBidRequestWithAdUnitID:kTestAdUnitID
                                      storedImpressionId:kTestStoredImpressionID
                                                  adType:kTestBannerAdType
                                                  dealID:nil
                                                bidFloor:kTestBidFloor
                                             publisherID:kTestPublisherID
                                                  userID:kTestUserID
                                             adapterInfo:nil
                                    nativeAdRequirements:nil
                                                    tmax:nil
                                                impModel:nil
                                              completion:^(id bidRequest, NSError *error) {
        XCTAssertNil(error, @"Bid request should not have error");
        
        NSDictionary *imp = [bidRequest[@"imp"] firstObject];
        NSDictionary *storedImpression = imp[@"ext"][@"prebid"][@"storedimpression"][@"storedimpression"];
        
        XCTAssertNotNil(storedImpression, @"Stored impression should exist in ext");
        XCTAssertEqualObjects(storedImpression[@"id"], kTestStoredImpressionID, @"Stored impression ID should be preserved");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
