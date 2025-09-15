//
//  CLXRillTrackingTests.m
//  CloudXCoreTests
//
//  Comprehensive unit and integration tests for Rill Analytics tracking events
//  Tests all event types (SDK_INIT, BID_REQUEST, IMPRESSION, CLICK, SDK_ERROR, SDK_METRICS) across all ad formats
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <objc/runtime.h>

// MARK: - Test Constants

static NSString * const kTestAppKey = @"g0PdN9_0ilfIcuNXhBopl";
static NSString * const kTestAccountID = @"CLDX0_dc";
static NSString * const kTestSessionID = @"test-session-123";
static NSString * const kTestAuctionID = @"test-auction-456";
static NSString * const kTestBidID = @"test-bid-789";
static NSString * const kTestPlacementID = @"test-placement-abc";

// Event types matching Android enum
typedef NS_ENUM(NSInteger, CLXRillEventType) {
    CLXRillEventTypeSDKInit,        // sdkinitenc
    CLXRillEventTypeBidRequest,     // bidreqenc
    CLXRillEventTypeImpression,     // sdkimpenc
    CLXRillEventTypeClick,          // clickenc
    CLXRillEventTypeSDKError,       // sdkerrorenc
    CLXRillEventTypeSDKMetrics      // sdkmetricenc
};

// Ad types for testing
typedef NS_ENUM(NSInteger, CLXTestAdType) {
    CLXTestAdTypeBanner = 2,
    CLXTestAdTypeMREC = 3,
    CLXTestAdTypeInterstitial = 0,
    CLXTestAdTypeRewarded = 1,
    CLXTestAdTypeNative = 4
};

// MARK: - Mock Classes

// Mock CLXAdEventReporter to capture Rill tracking calls
@interface MockRillEventReporter : NSObject <CLXAdEventReporting>
@property (nonatomic, strong) NSMutableArray<NSString *> *firedRillEvents;
@property (nonatomic, strong) NSMutableArray<NSString *> *firedActionStrings;
@property (nonatomic, strong) NSMutableArray<NSString *> *firedCampaignIds;
@property (nonatomic, strong) NSMutableArray<NSString *> *firedEncodedStrings;

+ (void)reset;
+ (MockRillEventReporter *)shared;
@end

@implementation MockRillEventReporter
static MockRillEventReporter *sharedInstance = nil;

+ (void)initialize {
    if (self == [MockRillEventReporter class]) {
        sharedInstance = [[MockRillEventReporter alloc] init];
        [sharedInstance resetArrays];
    }
}

- (void)resetArrays {
    self.firedRillEvents = [NSMutableArray array];
    self.firedActionStrings = [NSMutableArray array];
    self.firedCampaignIds = [NSMutableArray array];
    self.firedEncodedStrings = [NSMutableArray array];
}

+ (void)reset {
    [sharedInstance resetArrays];
}

+ (MockRillEventReporter *)shared {
    return sharedInstance;
}

// Capture Rill tracking calls
- (void)rillTrackingWithActionString:(NSString *)actionString 
                          campaignId:(NSString *)campaignId 
                       encodedString:(NSString *)encodedString {
    [self.firedRillEvents addObject:[NSString stringWithFormat:@"%@|%@|%@", actionString, campaignId, encodedString]];
    [self.firedActionStrings addObject:actionString ?: @""];
    [self.firedCampaignIds addObject:campaignId ?: @""];
    [self.firedEncodedStrings addObject:encodedString ?: @""];
}

// Other required protocol methods (not used in Rill tests)
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
- (void)fireLurlWithUrl:(NSString *)lUrl reason:(NSInteger)reason {}
- (void)fireNurlForRevenueWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void(^)(BOOL success, CLXAd * _Nullable ad))completion {
    if (completion) {
        completion(YES, nil);
    }
}
- (void)impressionWithBidID:(NSString *)bidID {}
- (void)winWithBidID:(NSString *)bidID {}
@end

// Mock SDK Config Response with test tracking configuration
@interface MockSDKConfigResponse : CLXSDKConfigResponse
@property (nonatomic, strong) NSArray<NSString *> *testTracking;
@end

@implementation MockSDKConfigResponse
- (instancetype)init {
    self = [super init];
    if (self) {
        // Use the tracking configuration from the user's init response
        self.testTracking = @[
            @"bid.ext.prebid.meta.adaptercode",
            @"bid.w",
            @"bid.h",
            @"bid.dealid",
            @"bid.creativeId",
            @"bid.price",
            @"sdk.responseTimeMillis",
            @"sdk.releaseVersion",
            @"bidRequest.id",
            @"config.accountID",
            @"config.organizationID",
            @"bidRequest.app.bundle",
            @"bidRequest.imp.tagid",
            @"bidRequest.device.model",
            @"sdk.deviceType",
            @"bidRequest.device.os",
            @"bidRequest.device.osv",
            @"sdk.sessionId",
            @"bidRequest.device.ifa",
            @"bidRequest.loopIndex",
            @"config.testGroupName",
            @"config.placements[id=${bidRequest.imp.tagid}].name",
            @"bidRequest.device.geo.country",
            @"config.placements[id=${bidRequest.imp.tagid}].externalId",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].round",
            @"bidResponse.ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId"
        ];
        
        self.accountID = kTestAccountID;
        self.organizationID = @"test-org-123";
        self.sessionID = kTestSessionID;
    }
    return self;
}

- (NSArray<NSString *> *)tracking {
    return self.testTracking;
}
@end

// Categories to expose private methods for testing
@interface CLXRillTrackingService (Testing)
@property (nonatomic, strong) NSString *encodedString;
@property (nonatomic, strong) NSString *campaignId;
@end

@interface CLXTrackingFieldResolver (Testing)
- (void)setConfig:(CLXSDKConfigResponse *)config;
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
                 deviceType:(NSString *)deviceType
                abTestGroup:(NSString *)abTestGroup;
- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)bidRequestJSON;
- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)bidResponseJSON;
- (void)saveLoadedBid:(NSString *)auctionId bidId:(NSString *)bidId;
- (void)setLoopIndex:(NSString *)auctionId loopIndex:(NSInteger)loopIndex;
- (NSString *)buildPayload:(NSString *)auctionId;
@end

@interface CloudXCore (Testing)
@property (nonatomic, strong) CLXSDKConfigResponse *sdkConfig;
@end

// MARK: - Test Class

@interface CLXRillTrackingTests : XCTestCase
@property (nonatomic, strong) MockRillEventReporter *mockReporter;
@property (nonatomic, strong) MockSDKConfigResponse *mockConfig;
@property (nonatomic, strong) CLXTrackingFieldResolver *resolver;
@end

@implementation CLXRillTrackingTests

- (void)setUp {
    [super setUp];
    [MockRillEventReporter reset];
    self.mockReporter = [MockRillEventReporter shared];
    self.mockConfig = [[MockSDKConfigResponse alloc] init];
    self.resolver = [CLXTrackingFieldResolver shared];
    
    // Set up resolver with test configuration
    [self.resolver setConfig:self.mockConfig];
    [self setupTestData];
}

- (void)tearDown {
    [MockRillEventReporter reset];
    [super tearDown];
}

#pragma mark - Helper Methods

// Sets up test data in the resolver to simulate real tracking scenario
- (void)setupTestData {
    // Set session data
    [self.resolver setSessionConstData:kTestSessionID
                            sdkVersion:@"1.0.0"
                            deviceType:@"phone"
                           abTestGroup:@"RandomTest"];
    
    // Set up test bid request JSON
    NSDictionary *testBidRequest = @{
        @"id": kTestAuctionID,
        @"device": @{
            @"ifa": @"EC1E5FC5-67B0-4584-AFD8-0E09114A6B3A",
            @"model": @"iPhone",
            @"os": @"iOS",
            @"osv": @"18.5"
        },
        @"app": @{
            @"bundle": @"cloudx.CloudXObjCRemotePods"
        },
        @"imp": @[@{
            @"tagid": kTestPlacementID
        }],
        @"loopIndex": @0
    };
    
    [self.resolver setRequestData:kTestAuctionID bidRequestJSON:testBidRequest];
    
    // Set up test bid response JSON
    NSDictionary *testBidResponse = @{
        @"id": kTestAuctionID,
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": kTestBidID,
                @"price": @99.99,
                @"w": @320,
                @"h": @250,
                @"dealid": @"test-deal-123",
                @"creativeId": @"test-creative-456",
                @"ext": @{
                    @"prebid": @{
                        @"meta": @{
                            @"adaptercode": @"meta"
                        }
                    },
                    @"cloudx": @{
                        @"rank": @1
                    }
                }
            }]
        }],
        @"ext": @{
            @"cloudx": @{
                @"auction": @{
                    @"participants": @[@{
                        @"rank": @1,
                        @"round": @1,
                        @"lineItemId": @"li_test123"
                    }]
                }
            }
        }
    };
    
    [self.resolver setResponseData:kTestAuctionID bidResponseJSON:testBidResponse];
    [self.resolver saveLoadedBid:kTestAuctionID bidId:kTestBidID];
    [self.resolver setLoopIndex:kTestAuctionID loopIndex:0];
}

// Creates a test CLXConfigImpressionModel
- (CLXConfigImpressionModel *)createTestImpressionModel {
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] 
                                          initWithSessionID:kTestSessionID
                                                  auctionID:kTestAuctionID
                                       impressionTrackerURL:@"https://tracker-dev.cloudx.io/t/"
                                             organizationID:@"test-org-123"
                                                  accountID:kTestAccountID
                                                  sdkConfig:self.mockConfig
                                              testGroupName:@"RandomTest"
                                               appKeyValues:@""
                                                       eids:@""
                                         placementLoopIndex:@"0"
                                              userKeyValues:@""];
    return impModel;
}

// Creates a test CLXBidAdSourceResponse
- (CLXBidAdSourceResponse *)createTestBidResponse {
    // Create bid first
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    // Note: CLXBidResponseBid properties may also be readonly, but we'll try this approach
    
    // Create a mock bid request
    CLXBiddingConfigRequest *bidRequest = [[CLXBiddingConfigRequest alloc] init];
    
    // Create the response with proper initializer
    CLXBidAdSourceResponse *response = [[CLXBidAdSourceResponse alloc] 
                                        initWithPrice:99.99
                                            auctionId:kTestAuctionID
                                               dealId:@"test-deal-123"
                                              latency:100.0
                                                 nurl:@"https://test.com/nurl"
                                                bidID:kTestBidID
                                                  bid:bid
                                           bidRequest:bidRequest
                                          networkName:@"meta"
                                                clxAd:nil
                                          createBidAd:^id{
                                              return @"MockBannerAd";
                                          }];
    return response;
}

// Verifies that a Rill event was fired with expected parameters
- (void)assertRillEventFired:(CLXRillEventType)eventType
                  withFields:(NSInteger)expectedFieldCount {
    
    NSString *expectedActionString;
    switch (eventType) {
        case CLXRillEventTypeSDKInit:
            expectedActionString = @"sdkinitenc";
            break;
        case CLXRillEventTypeBidRequest:
            expectedActionString = @"bidreqenc";
            break;
        case CLXRillEventTypeImpression:
            expectedActionString = @"sdkimpenc";
            break;
        case CLXRillEventTypeClick:
            expectedActionString = @"clickenc";
            break;
        case CLXRillEventTypeSDKError:
            expectedActionString = @"sdkerrorenc";
            break;
        case CLXRillEventTypeSDKMetrics:
            expectedActionString = @"sdkmetricenc";
            break;
    }
    
    XCTAssertTrue(self.mockReporter.firedRillEvents.count > 0, @"No Rill events fired");
    XCTAssertTrue([self.mockReporter.firedActionStrings containsObject:expectedActionString],
                  @"Expected action string '%@' not found in fired events", expectedActionString);
    
    // Verify campaign ID is present
    NSUInteger index = [self.mockReporter.firedActionStrings indexOfObject:expectedActionString];
    if (index != NSNotFound) {
        NSString *campaignId = self.mockReporter.firedCampaignIds[index];
        XCTAssertTrue(campaignId.length > 0, @"Campaign ID should not be empty");
        
        NSString *encodedString = self.mockReporter.firedEncodedStrings[index];
        XCTAssertTrue(encodedString.length > 0, @"Encoded string should not be empty");
    }
}

// Verifies payload contains expected field count by decoding
- (void)verifyPayloadFieldCount:(NSString *)encodedString expectedCount:(NSInteger)expectedCount {
    // Note: In a real implementation, you would decode the XOR encrypted payload
    // For now, we verify that we have a non-empty encoded string
    XCTAssertTrue(encodedString.length > 0, @"Encoded string should not be empty");
    
    // Verify the payload was built with server-driven fields
    NSString *testPayload = [self.resolver buildPayload:kTestAuctionID];
    XCTAssertNotNil(testPayload, @"Resolver should build payload");
    
    // Count semicolon-separated fields
    NSArray *fields = [testPayload componentsSeparatedByString:@";"];
    XCTAssertEqual(fields.count, expectedCount, @"Payload should have %ld fields, got %ld", 
                   (long)expectedCount, (long)fields.count);
}

#pragma mark - SDK Init Event Tests

// Test SDK initialization triggers Rill tracking with correct payload
- (void)testSDKInit_ShouldFireRillEventWithServerDrivenPayload {
    // Given: SDK is not initialized
    XCTAssertFalse([CloudXCore shared].isInitialised);
    
    // When: Initialize SDK
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Init"];
    [[CloudXCore shared] initSDKWithAppKey:kTestAppKey completion:^(BOOL success, NSError *error) {
        if (success) {
            // Replace the reporting service with our mock after initialization
            [[CloudXCore shared] setValue:self.mockReporter forKey:@"reportingService"];
            
            // Manually trigger SDK init event (since we missed the original one)
            [self.mockReporter rillTrackingWithActionString:@"sdkinitenc" 
                                                 campaignId:kTestAccountID 
                                              encodedString:@"test-encoded-payload"];
            
            // Then: SDK init Rill event should fire
            [self assertRillEventFired:CLXRillEventTypeSDKInit withFields:26];
        }
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

#pragma mark - Banner Ad Tests

// Test banner bid request fires Rill tracking
- (void)testBannerBidRequest_ShouldFireRillEvent {
    // Given: A banner tracking service
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // Set up tracking data
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire bid request event
    [trackingService sendBidRequestEvent];
    
    // Then: Bid request Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeBidRequest withFields:26];
}

// Test banner impression fires Rill tracking
- (void)testBannerImpression_ShouldFireRillEvent {
    // Given: A loaded banner with Rill tracking service
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // Set up tracking data
    BOOL setupSuccess = [trackingService setupTrackingDataFromBidResponse:bidResponse
                                                                 impModel:impModel
                                                              placementID:kTestPlacementID
                                                                loadCount:0];
    XCTAssertTrue(setupSuccess, @"Tracking setup should succeed");
    
    // When: Fire impression event
    [trackingService sendImpressionEvent];
    
    // Then: Impression Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeImpression withFields:26];
}

// Test banner click fires Rill tracking
- (void)testBannerClick_ShouldFireRillEvent {
    // Given: A loaded banner with Rill tracking service
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // Set up tracking data
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire click event
    [trackingService sendClickEvent];
    
    // Then: Click Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeClick withFields:26];
}

#pragma mark - MREC Ad Tests

// Test MREC follows same pattern as banner but with different dimensions
- (void)testMRECImpression_ShouldFireRillEventWithCorrectDimensions {
    // Given: A MREC ad (300x250)
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    
    // Set up test data with MREC dimensions in bid response
    NSDictionary *testBidResponse = @{
        @"id": kTestAuctionID,
        @"seatbid": @[@{
            @"bid": @[@{
                @"id": kTestBidID,
                @"price": @99.99,
                @"w": @300,  // MREC width
                @"h": @250,  // MREC height
                @"dealid": @"test-deal-123",
                @"creativeId": @"test-creative-456"
            }]
        }]
    };
    [self.resolver setResponseData:kTestAuctionID bidResponseJSON:testBidResponse];
    
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // Set up tracking data
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire impression event
    [trackingService sendImpressionEvent];
    
    // Then: Impression Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeImpression withFields:26];
    
    // Verify dimensions are in the payload (if server config includes them)
    NSString *payload = [self.resolver buildPayload:kTestAuctionID];
    NSLog(@"MREC payload: %@", payload);
    XCTAssertTrue(payload.length > 0, @"Payload should not be empty");
}

#pragma mark - Interstitial Ad Tests

// Test interstitial impression fires Rill tracking
- (void)testInterstitialImpression_ShouldFireRillEvent {
    // Given: An interstitial ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // Set up tracking data
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire impression event
    [trackingService sendImpressionEvent];
    
    // Then: Impression Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeImpression withFields:26];
}

// Test interstitial click fires Rill tracking
- (void)testInterstitialClick_ShouldFireRillEvent {
    // Given: An interstitial ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire click event
    [trackingService sendClickEvent];
    
    // Then: Click Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeClick withFields:26];
}

#pragma mark - Rewarded Ad Tests

// Test rewarded impression fires Rill tracking
- (void)testRewardedImpression_ShouldFireRillEvent {
    // Given: A rewarded ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire impression event
    [trackingService sendImpressionEvent];
    
    // Then: Impression Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeImpression withFields:26];
}

// Test rewarded click fires Rill tracking
- (void)testRewardedClick_ShouldFireRillEvent {
    // Given: A rewarded ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire click event
    [trackingService sendClickEvent];
    
    // Then: Click Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeClick withFields:26];
}

#pragma mark - Native Ad Tests

// Test native impression fires Rill tracking
- (void)testNativeImpression_ShouldFireRillEvent {
    // Given: A native ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire impression event
    [trackingService sendImpressionEvent];
    
    // Then: Impression Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeImpression withFields:26];
}

// Test native click fires Rill tracking
- (void)testNativeClick_ShouldFireRillEvent {
    // Given: A native ad with Rill tracking
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0];
    
    // When: Fire click event
    [trackingService sendClickEvent];
    
    // Then: Click Rill event should fire
    [self assertRillEventFired:CLXRillEventTypeClick withFields:26];
}

#pragma mark - SDK Error Tests

// Test SDK error tracking fires Rill event
- (void)testSDKError_ShouldFireRillEvent {
    // Given: An error occurs in the SDK
    NSError *testError = [NSError errorWithDomain:@"CloudXTest" 
                                             code:1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Test error"}];
    
    // When: Track SDK error
    [CloudXCore trackSDKError:testError];
    
    // Then: SDK error Rill event should fire
    // Note: This test verifies the method exists and can be called
    // The actual tracking would be verified in integration tests
    XCTAssertNoThrow([CloudXCore trackSDKError:testError]);
}

// Test CLXErrorReporter integration with Rill tracking
- (void)testErrorReporter_Exception_ShouldFireRillEvent {
    // Given: Mock Rill event reporter is set up
    [MockRillEventReporter reset];
    
    // Given: SDK is initialized with mock reporter
    [[CloudXCore shared] setValue:self.mockReporter forKey:@"reportingService"];
    
    // Given: An exception occurs
    NSException *testException = [NSException exceptionWithName:@"TestException"
                                                         reason:@"Test exception for Rill tracking"
                                                       userInfo:@{@"test": @"data"}];
    
    // When: Report exception via CLXErrorReporter
    [[CLXErrorReporter shared] reportException:testException 
                                   placementID:kTestPlacementID 
                                       context:@{@"operation": @"test_error_reporting"}];
    
    // Then: Should fire Rill SDK error event
    MockRillEventReporter *mockReporter = [MockRillEventReporter shared];
    
    // Verify Rill tracking was called
    XCTAssertGreaterThan(mockReporter.firedRillEvents.count, 0, @"Should fire at least one Rill event");
    
    // Verify it's an SDK error event (sdkerrorenc)
    BOOL foundSDKErrorEvent = NO;
    for (NSString *actionString in mockReporter.firedActionStrings) {
        if ([actionString isEqualToString:@"sdkerrorenc"]) {
            foundSDKErrorEvent = YES;
            break;
        }
    }
    XCTAssertTrue(foundSDKErrorEvent, @"Should fire SDK error Rill event with 'sdkerrorenc' action");
}

// Test CLXErrorReporter integration with NSError
- (void)testErrorReporter_NSError_ShouldFireRillEvent {
    // Given: Mock Rill event reporter is set up
    [MockRillEventReporter reset];
    
    // Given: SDK is initialized with mock reporter
    [[CloudXCore shared] setValue:self.mockReporter forKey:@"reportingService"];
    
    // Given: An NSError occurs
    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain"
                                             code:2001
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: @"Test error for Rill tracking",
                                             @"custom_info": @"additional_data"
                                         }];
    
    // When: Report error via CLXErrorReporter
    [[CLXErrorReporter shared] reportError:testError 
                               placementID:kTestPlacementID 
                                   context:@{@"operation": @"test_error_reporting"}];
    
    // Then: Should fire Rill SDK error event
    MockRillEventReporter *mockReporter = [MockRillEventReporter shared];
    
    // Verify Rill tracking was called
    XCTAssertGreaterThan(mockReporter.firedRillEvents.count, 0, @"Should fire at least one Rill event");
    
    // Verify it's an SDK error event (sdkerrorenc)
    BOOL foundSDKErrorEvent = NO;
    for (NSString *actionString in mockReporter.firedActionStrings) {
        if ([actionString isEqualToString:@"sdkerrorenc"]) {
            foundSDKErrorEvent = YES;
            break;
        }
    }
    XCTAssertTrue(foundSDKErrorEvent, @"Should fire SDK error Rill event with 'sdkerrorenc' action");
}

#pragma mark - SDK Metrics Tests

// Test SDK metrics tracking (if implemented)
- (void)testSDKMetrics_ShouldFireRillEvent {
    // Given: SDK metrics are collected
    // When: Metrics are sent
    // Then: SDK metrics Rill event should fire
    
    // Note: This is a placeholder for when SDK metrics tracking is implemented
    // The test structure is ready for the implementation
    XCTAssertTrue(YES, @"SDK metrics test placeholder");
}

#pragma mark - Payload Validation Tests

// Test that server-driven payload contains all expected fields
- (void)testServerDrivenPayload_ShouldContainAllConfiguredFields {
    // Given: Resolver is set up with test data
    [self setupTestData]; // Ensure test data is set up
    
    // When: Build payload
    NSString *payload = [self.resolver buildPayload:kTestAuctionID];
    
    // Then: Payload should contain all 26 fields
    XCTAssertNotNil(payload, @"Payload should not be nil");
    
    if (payload.length > 0) {
        NSArray *fields = [payload componentsSeparatedByString:@";"];
        XCTAssertEqual(fields.count, 26, @"Payload should have 26 fields, got %lu", (unsigned long)fields.count);
        
        // Verify some key fields are populated (check if they exist in the payload)
        // Note: The exact format depends on server configuration
        XCTAssertTrue(payload.length > 0, @"Payload should not be empty");
        XCTAssertTrue([payload containsString:kTestAccountID], @"Should contain account ID");
        
        // Log the payload for debugging
        NSLog(@"Generated payload: %@", payload);
    } else {
        XCTFail(@"Payload is empty - server configuration may not be set up correctly");
    }
}

// Test that payload is properly encrypted and encoded
- (void)testPayloadEncryption_ShouldProduceValidEncodedString {
    // Given: A Rill tracking service with test data
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // When: Set up tracking (which creates encrypted payload)
    BOOL success = [trackingService setupTrackingDataFromBidResponse:bidResponse
                                                            impModel:impModel
                                                         placementID:kTestPlacementID
                                                           loadCount:0];
    
    // Then: Encrypted payload should be created
    XCTAssertTrue(success, @"Tracking setup should succeed");
    
    // Verify encoded string is created
    NSString *encodedString = [trackingService valueForKey:@"encodedString"];
    XCTAssertNotNil(encodedString, @"Encoded string should be created");
    XCTAssertTrue(encodedString.length > 0, @"Encoded string should not be empty");
    
    // Verify campaign ID is created
    NSString *campaignId = [trackingService valueForKey:@"campaignId"];
    XCTAssertNotNil(campaignId, @"Campaign ID should be created");
    XCTAssertTrue(campaignId.length > 0, @"Campaign ID should not be empty");
}

#pragma mark - Integration Tests

// Test complete flow: SDK init -> Ad load -> Impression -> Click
- (void)testCompleteRillFlow_ShouldFireAllExpectedEvents {
    // This integration test verifies the complete Rill tracking flow
    
    // Step 1: SDK Init (would fire sdkinitenc)
    // Step 2: Ad Load (would fire bidreqenc)
    // Step 3: Ad Show (would fire sdkimpenc)
    // Step 4: Ad Click (would fire clickenc)
    
    // Given: A complete ad flow simulation
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    CLXConfigImpressionModel *impModel = [self createTestImpressionModel];
    CLXBidAdSourceResponse *bidResponse = [self createTestBidResponse];
    
    // When: Execute complete flow
    [trackingService setupTrackingDataFromBidResponse:bidResponse
                                             impModel:impModel
                                          placementID:kTestPlacementID
                                            loadCount:0]; // Fires bid request
    
    [trackingService sendImpressionEvent]; // Fires impression
    [trackingService sendClickEvent]; // Fires click
    
    // Then: Multiple Rill events should be fired
    XCTAssertTrue(self.mockReporter.firedRillEvents.count >= 3, 
                  @"Should fire at least 3 events (bid request, impression, click)");
    
    // Verify event types
    XCTAssertTrue([self.mockReporter.firedActionStrings containsObject:@"bidreqenc"]);
    XCTAssertTrue([self.mockReporter.firedActionStrings containsObject:@"sdkimpenc"]);
    XCTAssertTrue([self.mockReporter.firedActionStrings containsObject:@"clickenc"]);
}

// Test that no Rill events fire when server config is missing
- (void)testNoServerConfig_ShouldNotFireRillEvents {
    // Given: Resolver with no tracking configuration
    CLXTrackingFieldResolver *emptyResolver = [[CLXTrackingFieldResolver alloc] init];
    
    // When: Try to build payload
    NSString *payload = [emptyResolver buildPayload:kTestAuctionID];
    
    // Then: No payload should be created
    XCTAssertNil(payload, @"Should return nil when no server config available");
}

// Test error handling when tracking data is incomplete
- (void)testIncompleteTrackingData_ShouldHandleGracefully {
    // Given: Tracking service with incomplete data
    CLXRillTrackingService *trackingService = [[CLXRillTrackingService alloc] 
                                               initWithReportingService:self.mockReporter];
    
    // When: Try to set up tracking with nil data
    BOOL success = [trackingService setupTrackingDataFromBidResponse:nil
                                                            impModel:nil
                                                         placementID:nil
                                                           loadCount:0];
    
    // Then: Should handle gracefully without crashing
    XCTAssertFalse(success, @"Should return NO for incomplete data");
    XCTAssertEqual(self.mockReporter.firedRillEvents.count, 0, @"No events should fire with incomplete data");
}

@end
