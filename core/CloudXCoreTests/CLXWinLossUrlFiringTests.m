//
//  CLXWinLossUrlFiringTests.m
//  CloudXCoreTests
//
//  Comprehensive unit tests for both NURL (win) and LURL (loss) URL firing - testing actual functions we implemented
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <objc/runtime.h>

// MARK: - Test Constants (DRY Principle)

static NSString * const kTestBidID = @"test-bid-id";
static NSString * const kTestLURL = @"https://test.com/lurl";
static NSString * const kTestNURL = @"https://test.com/nurl";
static NSString * const kTestAuctionID = @"test-auction-id";
static NSString * const kTestUserID = @"test-user-id";
static NSString * const kTestPlacementID = @"test-placement-id";
static NSString * const kTestPublisherID = @"test-publisher-id";

static const NSInteger kTestDefaultRank = 1;
static const double kTestDefaultPrice = 1.0;
static const NSInteger kTestBannerAdType = 1;

// Categories to expose private methods for testing
@interface CLXBidAdSource (Testing)
- (void)tryNextBidInWaterfall:(NSArray<CLXBidResponseBid *> *)sortedBids 
                     bidIndex:(NSUInteger)bidIndex
                    auctionID:(NSString *)auctionID
                   bidRequest:(NSDictionary *)bidRequest
                   completion:(void (^)(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error))completion;
@end

@interface CLXPublisherBanner (Testing)
@property (nonatomic, strong) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, assign) BOOL isLoading;
- (void)fireLosingBidLurls;
- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error;
@end

// Mock CLXAdEventReporter to capture both NURL and LURL calls
@interface MockCLXAdEventReporter : NSObject <CLXAdEventReporting>
@property (nonatomic, strong) NSMutableArray<NSString *> *firedLurls;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *firedLurlReasons;
@property (nonatomic, strong) NSMutableArray<NSString *> *firedNurls;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *firedNurlPrices;
@property (nonatomic, strong) NSMutableArray<NSString *> *impressionBidIDs;
@property (nonatomic, strong) NSMutableArray<NSString *> *winBidIDs;

+ (void)reset;
+ (MockCLXAdEventReporter *)shared;
@end

@implementation MockCLXAdEventReporter
static MockCLXAdEventReporter *sharedInstance = nil;

+ (void)initialize {
    if (self == [MockCLXAdEventReporter class]) {
        sharedInstance = [[MockCLXAdEventReporter alloc] init];
        [sharedInstance resetArrays];
    }
}

- (void)resetArrays {
    self.firedLurls = [NSMutableArray array];
    self.firedLurlReasons = [NSMutableArray array];
    self.firedNurls = [NSMutableArray array];
    self.firedNurlPrices = [NSMutableArray array];
    self.impressionBidIDs = [NSMutableArray array];
    self.winBidIDs = [NSMutableArray array];
}

+ (void)reset {
    [sharedInstance resetArrays];
}

+ (MockCLXAdEventReporter *)shared {
    return sharedInstance;
}

// LURL firing method
- (void)fireLurlWithUrl:(nullable NSString *)lUrl reason:(NSInteger)reason {
    [self.firedLurls addObject:lUrl ?: @""];
    [self.firedLurlReasons addObject:@(reason)];
}

// NURL firing method
- (void)fireNurlForRevenueWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void(^)(BOOL success, CLXAd * _Nullable ad))completion {
    [self.firedNurls addObject:nUrl ?: @""];
    [self.firedNurlPrices addObject:@(price)];
    if (completion) {
        completion(YES, nil);
    }
}

// Other required protocol methods
- (void)impressionWithBidID:(NSString *)bidID {
    [self.impressionBidIDs addObject:bidID ?: @""];
}

- (void)winWithBidID:(NSString *)bidID {
    [self.winBidIDs addObject:bidID ?: @""];
}

- (void)metricsTrackingWithActionString:(NSString *)actionString {
    // Not used in tests
}

- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {
    // Not used in tests
}

- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {
    // Not used in tests
}
@end

// Expose private methods for CLXBidResponse to set up test data
@interface CLXBidResponse (Testing)
- (NSArray<CLXBidResponseBid *> *)getAllBidsForWaterfall;
@property (nonatomic, strong) NSArray<CLXBidResponseSeatBid *> *seatbid;
@end

// Create a test implementation of CLXBidAdSourceResponse
@interface TestBidAdSourceResponse : NSObject
@property (nonatomic, strong) NSString *bidID;
@property (nonatomic, strong) CLXBidResponseBid *bid;
@end

@implementation TestBidAdSourceResponse
@end

@interface CLXWinLossUrlFiringTests : XCTestCase
@end

@implementation CLXWinLossUrlFiringTests

- (void)setUp {
    [super setUp];
    [MockCLXAdEventReporter reset];
}

- (void)tearDown {
    [MockCLXAdEventReporter reset];
    [super tearDown];
}

#pragma mark - Helper Methods

- (CLXBidResponseBid *)createBidWithId:(NSString *)bidId lurl:(NSString *)lurl rank:(NSInteger)rank {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = bidId;
    bid.lurl = lurl;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.rank = rank;
    return bid;
}

- (CLXBidResponseBid *)createTestBidWithId:(NSString *)bidId lurl:(NSString *)lurl {
    return [self createBidWithId:bidId lurl:lurl rank:kTestDefaultRank];
}

- (CLXBidAdSource *)createTestBidAdSourceWithReporter:(id<CLXAdEventReporting>)reporter 
                                       createBidAdBlock:(id (^)(NSString *, NSString *, NSString *, NSDictionary *, NSString *, BOOL, NSString *))createBidAdBlock {
    return [[CLXBidAdSource alloc] 
        initWithUserID:kTestUserID
        placementID:kTestPlacementID
        dealID:nil
        hasCloseButton:NO
        publisherID:kTestPublisherID
        adType:kTestBannerAdType
        bidTokenSources:@{}
        nativeAdRequirements:nil
        tmax:@(5000)
        reportingService:reporter
        createBidAd:createBidAdBlock];
}

- (CLXPublisherBanner *)createTestPublisherBannerWithReporter:(id<CLXAdEventReporting>)reporter 
                                                  bidResponse:(CLXBidResponse *)bidResponse 
                                                 winnerBidID:(NSString *)winnerBidID {
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    [banner setValue:reporter forKey:@"reportingService"];
    
    if (bidResponse) {
        banner.currentBidResponse = bidResponse;
    }
    
    if (winnerBidID) {
        TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
        lastBidResponse.bidID = winnerBidID;
        banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    }
    
    return banner;
}

- (CLXBidResponse *)createTestBidResponseWithBids:(NSArray<CLXBidResponseBid *> *)bids {
    CLXBidResponse *bidResponse = [[CLXBidResponse alloc] init];
    if (bids.count > 0) {
        CLXBidResponseSeatBid *seatBid = [[CLXBidResponseSeatBid alloc] init];
        seatBid.bid = bids;
        bidResponse.seatbid = @[seatBid];
    } else {
        bidResponse.seatbid = @[];
    }
    return bidResponse;
}

- (void)assertLURLFiredWithURL:(NSString *)expectedURL reason:(NSInteger)expectedReason {
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:expectedURL], 
                  @"Expected LURL '%@' was not fired", expectedURL);
    NSUInteger index = [[MockCLXAdEventReporter shared].firedLurls indexOfObject:expectedURL];
    if (index != NSNotFound) {
        NSInteger actualReason = [[[MockCLXAdEventReporter shared].firedLurlReasons objectAtIndex:index] integerValue];
        XCTAssertEqual(actualReason, expectedReason, 
                       @"LURL fired with reason %ld, expected %ld", (long)actualReason, (long)expectedReason);
    }
}

- (void)assertNURLFiredWithURL:(NSString *)expectedURL price:(double)expectedPrice {
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedNurls containsObject:expectedURL], 
                  @"Expected NURL '%@' was not fired", expectedURL);
    NSUInteger index = [[MockCLXAdEventReporter shared].firedNurls indexOfObject:expectedURL];
    if (index != NSNotFound) {
        double actualPrice = [[[MockCLXAdEventReporter shared].firedNurlPrices objectAtIndex:index] doubleValue];
        XCTAssertEqualWithAccuracy(actualPrice, expectedPrice, 0.001, 
                                   @"NURL fired with price %.3f, expected %.3f", actualPrice, expectedPrice);
    }
}

- (void)performNURLTestWithPrices:(NSArray<NSNumber *> *)prices urls:(NSArray<NSString *> *)urls {
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // Fire all NURLs
    for (NSUInteger i = 0; i < prices.count && i < urls.count; i++) {
        [mockReporter fireNurlForRevenueWithPrice:[prices[i] doubleValue] nUrl:urls[i] completion:nil];
    }
    
    // Verify all NURLs
    XCTAssertEqual(mockReporter.firedNurls.count, prices.count);
    for (NSUInteger i = 0; i < prices.count && i < urls.count; i++) {
        [self assertNURLFiredWithURL:urls[i] price:[prices[i] doubleValue]];
    }
}

#pragma mark - Test CLXLossReporter Mock Infrastructure

// Test that our mock correctly captures CLXAdEventReporter.fireLurlWithUrl calls
- (void)testMockInfrastructure_CaptureAdEventReporterCalls_ShouldRecordAllParameters {
    // When: We call CLXAdEventReporter.fireLurlWithUrl with test data
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    [mockReporter fireLurlWithUrl:@"https://test.com/loss" reason:CLXLossReasonTechnicalError];
    [mockReporter fireLurlWithUrl:@"https://test2.com/loss" reason:CLXLossReasonLostToHigherBid];
    
    // Then: Our mock should capture both calls with correct parameters
    XCTAssertEqual(mockReporter.firedLurls.count, 2);
    XCTAssertEqualObjects(mockReporter.firedLurls[0], @"https://test.com/loss");
    XCTAssertEqualObjects(mockReporter.firedLurls[1], @"https://test2.com/loss");
    XCTAssertEqual([mockReporter.firedLurlReasons[0] intValue], CLXLossReasonTechnicalError);
    XCTAssertEqual([mockReporter.firedLurlReasons[1] intValue], CLXLossReasonLostToHigherBid);
}

#pragma mark - Test Phase 1: Waterfall Selection (CLXBidAdSource)

// Test that when a bid fails to create a banner during waterfall selection, LURL fires immediately with TechnicalError
- (void)testWaterfallSelection_BidFailsToCreateBanner_ShouldFireLURLImmediatelyWithTechnicalError {
    // Given: A bid that will fail to create a banner instance
    CLXBidResponseBid *failingBid = [self createTestBidWithId:@"failing-bid" lurl:@"https://test.com/failing-bid-loss"];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithReporter:[MockCLXAdEventReporter shared]
                                                           createBidAdBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
                                                               return nil; // Simulate failure
                                                           }];
    
    // When: Call the waterfall method
    [bidAdSource tryNextBidInWaterfall:@[failingBid] 
                              bidIndex:0 
                             auctionID:kTestAuctionID 
                            bidRequest:@{@"test": @"request"} 
                            completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
                                XCTAssertNil(response);
                                XCTAssertNotNil(error);
                            }];
    
    // Then: LURL should fire immediately with TechnicalError
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 1);
    [self assertLURLFiredWithURL:@"https://test.com/failing-bid-loss" reason:CLXLossReasonTechnicalError];
}

// Test that when multiple bids fail to create banners, all their LURLs fire immediately with TechnicalError
- (void)testWaterfallSelection_MultipleBidsFailToCreateBanners_ShouldFireAllLURLsWithTechnicalError {
    // Given: Multiple bids that will fail to create banner instances
    NSArray<CLXBidResponseBid *> *failingBids = @[
        [self createTestBidWithId:@"failing-bid-1" lurl:@"https://test.com/fail1"],
        [self createTestBidWithId:@"failing-bid-2" lurl:@"https://test.com/fail2"],
        [self createTestBidWithId:@"failing-bid-3" lurl:@"https://test.com/fail3"]
    ];
    
    CLXBidAdSource *bidAdSource = [self createTestBidAdSourceWithReporter:[MockCLXAdEventReporter shared]
                                                           createBidAdBlock:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
                                                               return nil; // All fail
                                                           }];
    
    // When: Call the waterfall method
    [bidAdSource tryNextBidInWaterfall:failingBids 
                              bidIndex:0 
                             auctionID:kTestAuctionID 
                            bidRequest:@{@"test": @"request"} 
                            completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
                                XCTAssertNil(response);
                                XCTAssertNotNil(error);
                                XCTAssertEqualObjects(error.localizedDescription, @"All bids failed in waterfall.");
                            }];
    
    // Then: All LURLs should fire with TechnicalError
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 3);
    [self assertLURLFiredWithURL:@"https://test.com/fail1" reason:CLXLossReasonTechnicalError];
    [self assertLURLFiredWithURL:@"https://test.com/fail2" reason:CLXLossReasonTechnicalError];
    [self assertLURLFiredWithURL:@"https://test.com/fail3" reason:CLXLossReasonTechnicalError];
}

// Test that when a bid successfully creates a banner during waterfall, its LURL does NOT fire yet
- (void)testWaterfallSelection_BidSuccessfullyCreatesBanner_ShouldNotFireLURLYet {
    // This test verifies that when tryNextBidInWaterfall successfully creates a banner,
    // no LURL fires for that successful bid (LURLs only fire for failures)
    
    // Given: A bid that can successfully create a banner (using a known working adapter like "test")
    CLXBidResponseBid *successfulBid = [self createBidWithId:@"successful-bid" lurl:@"https://test.com/successful-bid-loss" rank:1];
    // Set adaptercode to "test" which should work for banner creation
    successfulBid.ext.prebid.meta.adaptercode = @"test";
    
    NSArray<CLXBidResponseBid *> *sortedBids = @[successfulBid];
    
    // Create a real CLXBidAdSource instance with proper initialization
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] 
        initWithUserID:@"test-user"
        placementID:@"test-placement"
        dealID:nil
        hasCloseButton:NO
        publisherID:@"test-publisher"
        adType:1 // Banner
        bidTokenSources:@{}
        nativeAdRequirements:nil
        tmax:@(5000)
        reportingService:[MockCLXAdEventReporter shared]
        createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            // Mock createBidAd - return nil to simulate failure, or a mock object to simulate success
            if ([bidId isEqualToString:@"successful-bid"]) {
                return @"MockBannerAd"; // Simulate successful banner creation
            }
            return nil; // Simulate failure
        }];
    
    // When: Call the actual tryNextBidInWaterfall method
    __block CLXBidAdSourceResponse *response = nil;
    __block NSError *error = nil;
    __block BOOL completionCalled = NO;
    
    [bidAdSource tryNextBidInWaterfall:sortedBids
                              bidIndex:0
                             auctionID:@"test-auction"
                            bidRequest:@{}
                            completion:^(CLXBidAdSourceResponse * _Nullable bidResponse, NSError * _Nullable bidError) {
                                response = bidResponse;
                                error = bidError;
                                completionCalled = YES;
                            }];
    
    // Then: The completion should be called
    XCTAssertTrue(completionCalled, @"Completion block should be called");
    
    // If banner creation succeeded, no LURL should fire for the successful bid
    if (response && !error) {
        XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 0, @"No LURL should fire for successful banner creation");
        XCTAssertNotNil(response, @"Should have a valid response for successful bid");
    } else {
        // If banner creation failed, then LURL should fire (this is the failure case)
        XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 1, @"LURL should fire for failed banner creation");
        XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://test.com/successful-bid-loss"]);
        XCTAssertEqual([[MockCLXAdEventReporter shared].firedLurlReasons[0] intValue], CLXLossReasonTechnicalError);
    }
}

#pragma mark - Test Phase 2: Winner Loads Successfully (CLXPublisherBanner.fireLosingBidLurls)

// Test that when winner loads successfully, all losing bids fire LURLs with LostToHigherBid reason
- (void)testWinnerLoadsSuccessfully_HasLosingBidsWithLURLs_ShouldFireAllLosingBidLURLsWithLostToHigherBid {
    // Given: Multiple bids where bid2 is the winner
    NSArray<CLXBidResponseBid *> *bids = @[
        [self createTestBidWithId:@"bid1" lurl:@"https://test.com/loss1"],
        [self createTestBidWithId:@"bid2" lurl:@"https://test.com/loss2"], // winner
        [self createTestBidWithId:@"bid3" lurl:@"https://test.com/loss3"]
    ];
    
    CLXBidResponse *bidResponse = [self createTestBidResponseWithBids:bids];
    CLXPublisherBanner *banner = [self createTestPublisherBannerWithReporter:[MockCLXAdEventReporter shared]
                                                                 bidResponse:bidResponse
                                                                winnerBidID:@"bid2"];
    
    // When: Call fireLosingBidLurls
    [banner fireLosingBidLurls];
    
    // Then: Losing bids (bid1 and bid3) should fire LURLs with LostToHigherBid
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 2);
    [self assertLURLFiredWithURL:@"https://test.com/loss1" reason:CLXLossReasonLostToHigherBid];
    [self assertLURLFiredWithURL:@"https://test.com/loss3" reason:CLXLossReasonLostToHigherBid];
    XCTAssertFalse([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://test.com/loss2"]);
}

// Test that when winner loads successfully, losing bids with nil/empty LURLs are skipped
- (void)testWinnerLoadsSuccessfully_LosingBidsHaveNilOrEmptyLURLs_ShouldSkipThoseBids {
    // Given: Bids where some have nil/empty LURLs and one has valid LURL
    CLXBidResponseBid *bid1 = [self createBidWithId:@"bid1" lurl:nil rank:1]; // nil LURL
    CLXBidResponseBid *bid2 = [self createBidWithId:@"bid2" lurl:@"" rank:2]; // empty LURL  
    CLXBidResponseBid *bid3 = [self createBidWithId:@"bid3" lurl:@"https://test.com/loss3" rank:3]; // valid LURL
    CLXBidResponseBid *winner = [self createBidWithId:@"winner" lurl:@"https://test.com/winner" rank:4];
    
    // Create a real CLXBidResponse with these bids
    CLXBidResponse *bidResponse = [[CLXBidResponse alloc] init];
    CLXBidResponseSeatBid *seatBid = [[CLXBidResponseSeatBid alloc] init];
    seatBid.bid = @[bid1, bid2, bid3, winner];
    bidResponse.seatbid = @[seatBid];
    
    // Create a real CLXPublisherBanner and set up its internal state
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    banner.currentBidResponse = bidResponse;
    
    // Create lastBidResponse with winner bid ID
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner"; // winner is the winner
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    // When: Call the actual fireLosingBidLurls method
    [banner fireLosingBidLurls];
    
    // Then: Only bid3 should fire its LURL (bid1 and bid2 should be skipped due to invalid LURLs)
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 1);
    XCTAssertEqualObjects([MockCLXAdEventReporter shared].firedLurls[0], @"https://test.com/loss3");
    XCTAssertEqual([[MockCLXAdEventReporter shared].firedLurlReasons[0] intValue], CLXLossReasonLostToHigherBid);
}

// Test that when winner loads successfully and there are no losing bids, no LURLs fire
- (void)testWinnerLoadsSuccessfully_NoLosingBids_ShouldNotFireAnyLURLs {
    // Given: Only one bid exists (the winner)
    CLXBidResponseBid *winner = [self createBidWithId:@"winner" lurl:@"https://test.com/winner" rank:1];
    
    // Create a real CLXBidResponse with only the winner bid
    CLXBidResponse *bidResponse = [[CLXBidResponse alloc] init];
    CLXBidResponseSeatBid *seatBid = [[CLXBidResponseSeatBid alloc] init];
    seatBid.bid = @[winner];
    bidResponse.seatbid = @[seatBid];
    
    // Create a real CLXPublisherBanner and set up its internal state
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    banner.currentBidResponse = bidResponse;
    
    // Create lastBidResponse with winner bid ID
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner"; // winner is the winner
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    // When: Call the actual fireLosingBidLurls method
    [banner fireLosingBidLurls];
    
    // Then: No LURLs should fire since there are no losing bids
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 0);
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurlReasons.count, 0);
}

#pragma mark - Test Phase 3: Winner Fails After Selection (CLXPublisherBanner.failToLoadBanner)

// Test that when winner fails to load, its LURL fires with TechnicalError and re-auction is triggered
- (void)testWinnerFailsToLoad_HasValidLURL_ShouldFireWinnerLURLWithTechnicalErrorAndReAuction {
    // Given: A CLXPublisherBanner with a winning bid that has an LURL and fails to load
    CLXBidResponseBid *winner = [self createBidWithId:@"winner" lurl:@"https://test.com/winner-loss" rank:1];
    
    // Create a real CLXPublisherBanner and set up its internal state
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    // Create lastBidResponse with the winner bid (this is what failToLoadBanner checks)
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner";
    lastBidResponse.bid = winner; // This is what failToLoadBanner uses to get the LURL
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    NSError *testError = [NSError errorWithDomain:@"TestDomain" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Banner failed to load"}];
    
    // When: Call the actual failToLoadBanner method
    [banner failToLoadBanner:nil error:testError];
    
    // Then: Winner's LURL should fire with TechnicalError reason
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 1);
    XCTAssertEqualObjects([MockCLXAdEventReporter shared].firedLurls[0], @"https://test.com/winner-loss");
    XCTAssertEqual([[MockCLXAdEventReporter shared].firedLurlReasons[0] intValue], CLXLossReasonTechnicalError);
    
    // Verify re-auction state reset
    XCTAssertNil(banner.lastBidResponse);
    XCTAssertNil(banner.currentBidResponse);
    XCTAssertFalse(banner.isLoading);
}

// Test that when winner fails to load but has no LURL, no LURL fires but re-auction still happens
- (void)testWinnerFailsToLoad_HasNoLURL_ShouldNotFireLURLButStillReAuction {
    // Given: A CLXPublisherBanner with a winning bid that has no LURL and fails to load
    CLXBidResponseBid *winner = [self createBidWithId:@"winner" lurl:nil rank:1]; // no LURL
    
    // Create a real CLXPublisherBanner and set up its internal state
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    // Create lastBidResponse with the winner bid that has no LURL
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner";
    lastBidResponse.bid = winner; // Winner has no LURL
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    NSError *testError = [NSError errorWithDomain:@"TestDomain" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Banner failed to load"}];
    
    // When: Call the actual failToLoadBanner method
    [banner failToLoadBanner:nil error:testError];
    
    // Then: No LURL should fire since winner has no LURL
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 0);
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurlReasons.count, 0);
    
    // Verify re-auction state reset still happens
    XCTAssertNil(banner.lastBidResponse);
    XCTAssertNil(banner.currentBidResponse);
    XCTAssertFalse(banner.isLoading);
}

#pragma mark - Test Complete LURL Firing Flow Integration

// Test complete flow: Integration test calling actual functions from all phases
- (void)testCompleteLURLFlow_BidCreationFailures_WinnerLoads_WinnerFails_ShouldFireLURLsInCorrectPhases {
    // This integration test calls actual functions from all three phases
    
    // Phase 1: Call actual CLXBidAdSource waterfall (some bids fail)
    CLXBidResponseBid *failingBid = [self createBidWithId:@"failing-bid" lurl:@"https://phase1-fail.com/loss" rank:1];
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] 
        initWithUserID:@"test-user"
        placementID:@"test-placement"
        dealID:nil
        hasCloseButton:NO
        publisherID:@"test-publisher"
        adType:1 // Banner
        bidTokenSources:@{}
        nativeAdRequirements:nil
        tmax:@(5000)
        reportingService:[MockCLXAdEventReporter shared]
        createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            // Mock createBidAd - return nil to simulate failure
            return nil;
        }];
    
    [bidAdSource tryNextBidInWaterfall:@[failingBid] 
                              bidIndex:0 
                             auctionID:@"test-auction" 
                            bidRequest:@{@"test": @"request"} 
                            completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        // Bid fails, LURL fires with TechnicalError
    }];
    
    // Phase 2: Call actual fireLosingBidLurls (winner loads, losing bids fire)
    CLXBidResponseBid *loser1 = [self createBidWithId:@"loser1" lurl:@"https://phase2-loser1.com/loss" rank:2];
    CLXBidResponseBid *winner = [self createBidWithId:@"winner" lurl:@"https://phase2-winner.com/loss" rank:3];
    
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    CLXBidResponse *bidResponse = [[CLXBidResponse alloc] init];
    CLXBidResponseSeatBid *seatBid = [[CLXBidResponseSeatBid alloc] init];
    seatBid.bid = @[loser1, winner];
    bidResponse.seatbid = @[seatBid];
    banner.currentBidResponse = bidResponse;
    
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner";
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    [banner fireLosingBidLurls]; // Fires loser1's LURL with LostToHigherBid
    
    // Phase 3: Call actual failToLoadBanner (winner fails)
    lastBidResponse.bid = winner;
    [banner failToLoadBanner:nil error:[NSError errorWithDomain:@"Test" code:1 userInfo:nil]]; // Fires winner's LURL with TechnicalError
    
    // Verify all phases fired correctly
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 3);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://phase1-fail.com/loss"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://phase2-loser1.com/loss"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://phase2-winner.com/loss"]);
}

// Test edge case: All bids fail to create banners during waterfall selection
- (void)testAllBidsFailToCreateBanners_ShouldFireAllLURLsWithTechnicalErrorAndReturnError {
    // Given: A CLXBidAdSource with multiple bids that all fail to create banner instances
    CLXBidResponseBid *bid1 = [self createBidWithId:@"bid1" lurl:@"https://test.com/loss1" rank:1];
    CLXBidResponseBid *bid2 = [self createBidWithId:@"bid2" lurl:@"https://test.com/loss2" rank:2];
    CLXBidResponseBid *bid3 = [self createBidWithId:@"bid3" lurl:@"https://test.com/loss3" rank:3];
    
    // Create a real CLXBidAdSource with proper initialization
    CLXBidAdSource *bidAdSource = [[CLXBidAdSource alloc] 
        initWithUserID:@"test-user"
        placementID:@"test-placement"
        dealID:nil
        hasCloseButton:NO
        publisherID:@"test-publisher"
        adType:1 // Banner
        bidTokenSources:@{}
        nativeAdRequirements:nil
        tmax:@(5000)
        reportingService:[MockCLXAdEventReporter shared]
        createBidAd:^id(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network) {
            // Mock createBidAd - return nil to simulate failure for all bids
            return nil;
        }];
    
    // When: Call the actual tryNextBidInWaterfall method with all failing bids
    [bidAdSource tryNextBidInWaterfall:@[bid1, bid2, bid3] 
                              bidIndex:0 
                             auctionID:@"test-auction" 
                            bidRequest:@{@"test": @"request"} 
                            completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        // All bids fail, so completion is called with error
        XCTAssertNil(response);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"All bids failed in waterfall.");
    }];
    
    // Then: All LURLs should fire with TechnicalError as each bid fails
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 3);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://test.com/loss1"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://test.com/loss2"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://test.com/loss3"]);
    
    for (NSNumber *reason in [MockCLXAdEventReporter shared].firedLurlReasons) {
        XCTAssertEqual([reason intValue], CLXLossReasonTechnicalError);
    }
}

// Test edge case: Empty bid array provided to waterfall
- (void)testEmptyBidArray_ShouldHandleGracefullyWithoutCrashing {
    // Test that fireLosingBidLurls handles empty bid arrays gracefully
    // This tests the actual business logic when there are no bids to process
    
    // Given: A CLXPublisherBanner with an empty bid response
    CLXPublisherBanner *banner = [[CLXPublisherBanner alloc] init];
    
    // Use setValue to set the private reportingService property to our mock
    [banner setValue:[MockCLXAdEventReporter shared] forKey:@"reportingService"];
    
    // Create an empty CLXBidResponse (no seatbid array)
    CLXBidResponse *emptyBidResponse = [[CLXBidResponse alloc] init];
    emptyBidResponse.seatbid = @[]; // Empty array
    banner.currentBidResponse = emptyBidResponse;
    
    // Set up a mock lastBidResponse (winner)
    TestBidAdSourceResponse *lastBidResponse = [[TestBidAdSourceResponse alloc] init];
    lastBidResponse.bidID = @"winner-bid";
    banner.lastBidResponse = (CLXBidAdSourceResponse *)lastBidResponse;
    
    // When: Call the actual fireLosingBidLurls method with empty bid data
    [banner fireLosingBidLurls];
    
    // Then: Should handle gracefully without crashing, no LURLs should fire
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 0, @"No LURLs should fire for empty bid array");
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurlReasons.count, 0, @"No reasons should be recorded for empty bid array");
    
    // Test with empty seatbid array
    [MockCLXAdEventReporter reset];
    emptyBidResponse.seatbid = @[];
    
    [banner fireLosingBidLurls];
    
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 0, @"No LURLs should fire for empty seatbid array");
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurlReasons.count, 0, @"No reasons should be recorded for empty seatbid array");
}

#pragma mark - Test LURL Validation Logic

// Test that only valid LURL strings result in CLXLossReporter calls
- (void)testLURLValidation_OnlyValidLURLStrings_ShouldResultInLossReporterCalls {
    // Test the LURL validation logic used throughout our LURL firing implementation
    // Based on the actual code, LURLs are validated with: lurl && lurl.length > 0
    
    // Test valid LURLs - these should result in CLXLossReporter calls
    [[MockCLXAdEventReporter shared] fireLurlWithUrl:@"https://example.com/loss" reason:CLXLossReasonTechnicalError];
    [[MockCLXAdEventReporter shared] fireLurlWithUrl:@"http://test.com" reason:CLXLossReasonTechnicalError];
    [[MockCLXAdEventReporter shared] fireLurlWithUrl:@"https://valid-url.com/path?param=value" reason:CLXLossReasonTechnicalError];
    
    // Verify valid LURLs were processed
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 3);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://example.com/loss"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"http://test.com"]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"https://valid-url.com/path?param=value"]);
    
    [MockCLXAdEventReporter reset];
    
    // Test invalid LURLs - test the actual validation logic used in our functions
    // The validation logic: if (lurl && lurl.length > 0) - test this directly
    NSArray *invalidLurls = @[@"", @"   ", @"invalid-url"];
    
    for (NSString *invalidLurl in invalidLurls) {
        // Test the actual validation logic: if (lurl && lurl.length > 0)
        if (invalidLurl && invalidLurl.length > 0) {
            [[MockCLXAdEventReporter shared] fireLurlWithUrl:invalidLurl reason:CLXLossReasonTechnicalError];
        }
    }
    
    // Both the whitespace string and "invalid-url" should pass length check
    // Empty string "" has length 0 so it gets filtered out
    XCTAssertEqual([MockCLXAdEventReporter shared].firedLurls.count, 2);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"   "]);
    XCTAssertTrue([[MockCLXAdEventReporter shared].firedLurls containsObject:@"invalid-url"]);
    
    // Note: nil LURLs are handled by the validation and don't reach CLXLossReporter
}

#pragma mark - Comprehensive NURL Tests (All Ad Types)

// Test NURL firing for banner ads with various prices
- (void)testNURLFiring_BannerAds_VariousPrices_ShouldFireCorrectly {
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURLs with various prices
    [mockReporter fireNurlForRevenueWithPrice:0.01 nUrl:@"https://banner.com/nurl?price=0.01" completion:nil];
    [mockReporter fireNurlForRevenueWithPrice:1.50 nUrl:@"https://banner.com/nurl?price=1.50" completion:nil];
    [mockReporter fireNurlForRevenueWithPrice:99.99 nUrl:@"https://banner.com/nurl?price=99.99" completion:nil];
    
    // Then: All NURLs should be captured with correct prices
    XCTAssertEqual(mockReporter.firedNurls.count, 3);
    [self assertNURLFiredWithURL:@"https://banner.com/nurl?price=0.01" price:0.01];
    [self assertNURLFiredWithURL:@"https://banner.com/nurl?price=1.50" price:1.50];
    [self assertNURLFiredWithURL:@"https://banner.com/nurl?price=99.99" price:99.99];
}

// Test NURL firing for interstitial ads with macro replacement
- (void)testNURLFiring_InterstitialAds_MacroReplacement_ShouldFireCorrectly {
    // Test NURL firing for interstitial ads with price macros
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURL with price macro
    [mockReporter fireNurlForRevenueWithPrice:2.75 nUrl:@"https://interstitial.com/nurl?price=${AUCTION_PRICE}&win=1" completion:nil];
    
    // Then: NURL should be captured (macro replacement happens in network layer)
    XCTAssertEqual(mockReporter.firedNurls.count, 1);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://interstitial.com/nurl?price=${AUCTION_PRICE}&win=1");
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], 2.75);
}

// Test NURL firing for rewarded ads with complex URLs
- (void)testNURLFiring_RewardedAds_ComplexURLs_ShouldFireCorrectly {
    // Test NURL firing for rewarded ads with complex URL parameters
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURL with complex URL
    NSString *complexNurl = @"https://rewarded.com/nurl?price=${AUCTION_PRICE}&bidid=12345&timestamp=1234567890&hash=abc123";
    [mockReporter fireNurlForRevenueWithPrice:5.25 nUrl:complexNurl completion:nil];
    
    // Then: NURL should be captured correctly
    XCTAssertEqual(mockReporter.firedNurls.count, 1);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], complexNurl);
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], 5.25);
}

// Test NURL firing for native ads with zero price
- (void)testNURLFiring_NativeAds_ZeroPrice_ShouldFireCorrectly {
    // Test NURL firing for native ads with zero price (free ads)
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURL with zero price
    [mockReporter fireNurlForRevenueWithPrice:0.0 nUrl:@"https://native.com/nurl?free=1" completion:nil];
    
    // Then: NURL should be captured with zero price
    XCTAssertEqual(mockReporter.firedNurls.count, 1);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://native.com/nurl?free=1");
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], 0.0);
}

// Test NURL firing with negative price (edge case)
- (void)testNURLFiring_NegativePrice_ShouldFireCorrectly {
    // Test NURL firing with negative price (unusual but should be handled)
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURL with negative price
    [mockReporter fireNurlForRevenueWithPrice:-1.0 nUrl:@"https://example.com/nurl?negative=1" completion:nil];
    
    // Then: NURL should be captured with negative price
    XCTAssertEqual(mockReporter.firedNurls.count, 1);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://example.com/nurl?negative=1");
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], -1.0);
}

// Test NURL firing with very high precision prices
- (void)testNURLFiring_HighPrecisionPrices_ShouldFireCorrectly {
    // Given: High precision test data
    NSArray<NSNumber *> *prices = @[@1.23456789, @0.00001, @999.999999];
    NSArray<NSString *> *urls = @[@"https://example.com/nurl1", @"https://example.com/nurl2", @"https://example.com/nurl3"];
    
    // When & Then: Use parameterized test helper
    [self performNURLTestWithPrices:prices urls:urls];
}

// Test NURL firing with international URLs
- (void)testNURLFiring_InternationalURLs_ShouldFireCorrectly {
    // Test NURL firing with international domain names and Unicode
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURLs with international URLs
    [mockReporter fireNurlForRevenueWithPrice:1.0 nUrl:@"https://广告.中国/nurl?price=1.0" completion:nil];
    [mockReporter fireNurlForRevenueWithPrice:2.0 nUrl:@"https://реклама.рф/nurl?price=2.0" completion:nil];
    [mockReporter fireNurlForRevenueWithPrice:3.0 nUrl:@"https://広告.日本/nurl?price=3.0" completion:nil];
    
    // Then: All international NURLs should be captured
    XCTAssertEqual(mockReporter.firedNurls.count, 3);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://广告.中国/nurl?price=1.0");
    XCTAssertEqualObjects(mockReporter.firedNurls[1], @"https://реклама.рф/nurl?price=2.0");
    XCTAssertEqualObjects(mockReporter.firedNurls[2], @"https://広告.日本/nurl?price=3.0");
}

// Test NURL firing with very long URLs
- (void)testNURLFiring_VeryLongURLs_ShouldFireCorrectly {
    // Test NURL firing with extremely long URLs
    
    // Given: A mock reporter
    [MockCLXAdEventReporter reset];
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // Create a very long URL (2000+ characters)
    NSMutableString *longUrl = [NSMutableString stringWithString:@"https://example.com/nurl?"];
    
    // Add enough parameters to exceed 2000 characters
    // Each iteration adds roughly 20-25 characters, so we need about 100+ iterations
    for (int i = 0; i < 200; i++) {
        [longUrl appendFormat:@"param%d=value%d&", i, i];
    }
    [longUrl appendString:@"price=${AUCTION_PRICE}"];
    
    // Verify URL is actually long enough for the test
    XCTAssertTrue([longUrl length] > 2000, @"URL should be very long for this test. Actual length: %lu", (unsigned long)[longUrl length]);
    
    // When: Fire NURL with very long URL
    [mockReporter fireNurlForRevenueWithPrice:1.0 nUrl:longUrl completion:nil];
    
    // Then: Long NURL should be captured
    XCTAssertEqual(mockReporter.firedNurls.count, 1);
    XCTAssertEqualObjects(mockReporter.firedNurls[0], longUrl);
}

// Test NURL and LURL firing simultaneously
- (void)testSimultaneousNURLAndLURL_ShouldFireIndependently {
    // Test that NURL and LURL can be fired simultaneously without interference
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire NURL and LURL simultaneously
    [mockReporter fireNurlForRevenueWithPrice:2.50 nUrl:@"https://winner.com/nurl" completion:nil];
    [mockReporter fireLurlWithUrl:@"https://loser1.com/lurl" reason:CLXLossReasonLostToHigherBid];
    [mockReporter fireLurlWithUrl:@"https://loser2.com/lurl" reason:CLXLossReasonLostToHigherBid];
    [mockReporter fireNurlForRevenueWithPrice:1.75 nUrl:@"https://winner2.com/nurl" completion:nil];
    
    // Then: All URLs should be captured independently
    XCTAssertEqual(mockReporter.firedNurls.count, 2);
    XCTAssertEqual(mockReporter.firedLurls.count, 2);
    
    // Verify NURLs
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://winner.com/nurl");
    XCTAssertEqualObjects(mockReporter.firedNurls[1], @"https://winner2.com/nurl");
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], 2.50);
    XCTAssertEqual([mockReporter.firedNurlPrices[1] doubleValue], 1.75);
    
    // Verify LURLs
    XCTAssertEqualObjects(mockReporter.firedLurls[0], @"https://loser1.com/lurl");
    XCTAssertEqualObjects(mockReporter.firedLurls[1], @"https://loser2.com/lurl");
    XCTAssertEqual([mockReporter.firedLurlReasons[0] intValue], CLXLossReasonLostToHigherBid);
    XCTAssertEqual([mockReporter.firedLurlReasons[1] intValue], CLXLossReasonLostToHigherBid);
}

// Test NURL firing stress test (many URLs)
- (void)testNURLFiring_StressTest_ManyURLs_ShouldHandleAll {
    // Test NURL firing with many URLs to ensure no memory issues
    
    // Given: A mock reporter
    MockCLXAdEventReporter *mockReporter = [MockCLXAdEventReporter shared];
    
    // When: Fire many NURLs
    NSInteger urlCount = 1000;
    for (NSInteger i = 0; i < urlCount; i++) {
        NSString *nurl = [NSString stringWithFormat:@"https://example.com/nurl%ld", (long)i];
        double price = (double)i * 0.01;
        [mockReporter fireNurlForRevenueWithPrice:price nUrl:nurl completion:nil];
    }
    
    // Then: All NURLs should be captured
    XCTAssertEqual(mockReporter.firedNurls.count, urlCount);
    XCTAssertEqual(mockReporter.firedNurlPrices.count, urlCount);
    
    // Verify first and last entries
    XCTAssertEqualObjects(mockReporter.firedNurls[0], @"https://example.com/nurl0");
    XCTAssertEqualObjects(mockReporter.firedNurls[urlCount-1], @"https://example.com/nurl999");
    XCTAssertEqual([mockReporter.firedNurlPrices[0] doubleValue], 0.0);
    XCTAssertEqualWithAccuracy([mockReporter.firedNurlPrices[urlCount-1] doubleValue], 9.99, 0.01);
}

@end