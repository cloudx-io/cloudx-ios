//
//  CLXSDKInitNetworkServiceTests.m
//  CloudXCoreTests
//
//  Tests for SDK initialization network service, specifically tracking array parsing
//  and required field validation (matching Android's strict validation behavior)
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

// Private interface to access internal methods for testing
@interface CLXSDKInitNetworkService (Testing)
- (nullable CLXSDKConfigResponse *)parseSDKConfigFromResponse:(NSDictionary *)response error:(NSError **)outError;
- (CLXSDKConfigRequest *)createRequest;
@end

@interface CLXSDKInitNetworkServiceTests : XCTestCase
@property (nonatomic, strong) CLXSDKInitNetworkService *networkService;
@end

@implementation CLXSDKInitNetworkServiceTests

- (void)setUp {
    [super setUp];
    self.networkService = [[CLXSDKInitNetworkService alloc] init];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

#pragma mark - Test Helpers

/**
 * Returns a valid response with all required fields populated
 * Use this as a base and override specific fields in tests
 */
- (NSMutableDictionary *)validResponse {
    return [@{
        // 1. Identity
        @"accountID": @"CLDX2_dc",
        @"sessionID": @"test-session-123",
        @"appID": @"test-app-123",
        @"accountName": @"TestAccount",
        // 2. Endpoints
        @"auctionEndpointURL": @"https://auction.cloudx.io/bid",
        @"impressionTrackerURL": @"https://tracker.cloudx.io/impression",
        @"winLossNotificationURL": @"https://tracker.cloudx.io/winloss",
        @"geoDataEndpointURL": @"https://geo.cloudx.io",
        // 3. Core Config
        @"bidders": @[
            @{@"networkName": @"admob", @"initData": @{}}
        ],
        @"adUnits": @[
            @{@"id": @"placement-1", @"name": @"test-banner", @"type": @"banner"}
        ],
        // 4. Tracking & Geo
        @"tracking": @[@"bid.price"],
        @"geoHeaders": @[
            @{@"source": @"X-Geo-Country", @"target": @"country"}
        ],
        @"winLossNotificationPayloadConfig": @{@"includePrice": @YES}
    } mutableCopy];
}

#pragma mark - Required Field Validation Tests

/**
 * Test that parsing succeeds with all required fields present
 */
- (void)testParseSDKConfig_AllRequiredFieldsPresent_ShouldSucceed {
    // Given: Response with all required fields
    NSDictionary *response = [self validResponse];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed without error
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqualObjects(config.accountID, @"CLDX2_dc");
    XCTAssertEqualObjects(config.sessionID, @"test-session-123");
}

/**
 * Test missing accountID returns error 205
 */
- (void)testParseSDKConfig_MissingAccountID_ShouldReturnError205 {
    // Given: Response missing accountID
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"accountID"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"accountID"], @"Error should mention accountID");
}

/**
 * Test missing sessionID returns error 205
 */
- (void)testParseSDKConfig_MissingSessionID_ShouldReturnError205 {
    // Given: Response missing sessionID
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"sessionID"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"sessionID"], @"Error should mention sessionID");
}

/**
 * Test missing appID returns error 205 (matches Android which requires appID)
 */
- (void)testParseSDKConfig_MissingAppID_ShouldReturnError205 {
    // Given: Response missing appID
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"appID"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"appID"], @"Error should mention appID");
}

/**
 * Test missing auctionEndpointURL returns error 205
 */
- (void)testParseSDKConfig_MissingAuctionEndpointURL_ShouldReturnError205 {
    // Given: Response missing auctionEndpointURL
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"auctionEndpointURL"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"auctionEndpointURL"], @"Error should mention auctionEndpointURL");
}

/**
 * Test missing impressionTrackerURL returns error 205
 */
- (void)testParseSDKConfig_MissingImpressionTrackerURL_ShouldReturnError205 {
    // Given: Response missing impressionTrackerURL
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"impressionTrackerURL"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"impressionTrackerURL"], @"Error should mention impressionTrackerURL");
}

/**
 * Test missing winLossNotificationURL returns error 205
 */
- (void)testParseSDKConfig_MissingWinLossNotificationURL_ShouldReturnError205 {
    // Given: Response missing winLossNotificationURL
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"winLossNotificationURL"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"winLossNotificationURL"], @"Error should mention winLossNotificationURL");
}

/**
 * Test missing geoDataEndpointURL returns error 205
 */
- (void)testParseSDKConfig_MissingGeoDataEndpointURL_ShouldReturnError205 {
    // Given: Response missing geoDataEndpointURL
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"geoDataEndpointURL"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"geoDataEndpointURL"], @"Error should mention geoDataEndpointURL");
}

/**
 * Test missing bidders array returns error 205
 */
- (void)testParseSDKConfig_MissingBidders_ShouldReturnError205 {
    // Given: Response missing bidders
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"bidders"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"bidders"], @"Error should mention bidders");
}

/**
 * Test missing networkName in bidder returns error 205
 */
- (void)testParseSDKConfig_MissingNetworkNameInBidder_ShouldReturnError205 {
    // Given: Response with bidder missing networkName
    NSMutableDictionary *response = [self validResponse];
    response[@"bidders"] = @[@{@"initData": @{}}];  // Missing networkName

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"networkName"], @"Error should mention networkName");
}

/**
 * Test missing initData in bidder returns error 205 (matches Android behavior)
 */
- (void)testParseSDKConfig_MissingInitDataInBidder_ShouldReturnError205 {
    // Given: Response with bidder missing initData
    NSMutableDictionary *response = [self validResponse];
    response[@"bidders"] = @[@{@"networkName": @"admob"}];  // Missing initData

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205 (matches Android which requires initData)
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"initData"], @"Error should mention initData");
}

/**
 * Test missing placements array returns error 205
 */
- (void)testParseSDKConfig_MissingPlacements_ShouldReturnError205 {
    // Given: Response missing placements
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"adUnits"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"adUnits"], @"Error should mention placements");
}

/**
 * Test missing id in placement returns error 205
 */
- (void)testParseSDKConfig_MissingIdInPlacement_ShouldReturnError205 {
    // Given: Response with placement missing id
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[@{@"name": @"test", @"type": @"banner"}];  // Missing id

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"adUnits[0].id"], @"Error should mention ad unit id");
}

/**
 * Test missing name in placement returns error 205
 */
- (void)testParseSDKConfig_MissingNameInPlacement_ShouldReturnError205 {
    // Given: Response with placement missing name
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[@{@"id": @"test-id", @"type": @"banner"}];  // Missing name

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"adUnits[0].name"], @"Error should mention ad unit name");
}

/**
 * Test missing type in placement returns error 205
 */
- (void)testParseSDKConfig_MissingTypeInPlacement_ShouldReturnError205 {
    // Given: Response with placement missing type
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[@{@"id": @"test-id", @"name": @"test"}];  // Missing type

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"adUnits[0].type"], @"Error should mention ad unit type");
}

/**
 * Test missing tracking array returns error 205
 */
- (void)testParseSDKConfig_MissingTracking_ShouldReturnError205 {
    // Given: Response missing tracking
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"tracking"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"tracking"], @"Error should mention tracking");
}

/**
 * Test missing geoHeaders array returns error 205
 */
- (void)testParseSDKConfig_MissingGeoHeaders_ShouldReturnError205 {
    // Given: Response missing geoHeaders
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"geoHeaders"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"geoHeaders"], @"Error should mention geoHeaders");
}

/**
 * Test geoHeader with missing source is filtered out (matches Android behavior)
 */
- (void)testParseSDKConfig_MissingSourceInGeoHeader_ShouldFilterOut {
    // Given: Response with geoHeader missing source
    NSMutableDictionary *response = [self validResponse];
    response[@"geoHeaders"] = @[
        @{@"target": @"country"},  // Missing source - should be filtered
        @{@"source": @"X-Geo-Region", @"target": @"region"}  // Valid - should be kept
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed with only valid geoHeader (matches Android filter behavior)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.geoHeaders.count, 1, @"Should have 1 geoHeader after filtering");
    XCTAssertEqualObjects(config.geoHeaders[0].source, @"X-Geo-Region");
}

/**
 * Test geoHeader with missing target is filtered out (matches Android behavior)
 */
- (void)testParseSDKConfig_MissingTargetInGeoHeader_ShouldFilterOut {
    // Given: Response with geoHeader missing target
    NSMutableDictionary *response = [self validResponse];
    response[@"geoHeaders"] = @[
        @{@"source": @"X-Geo-Country"},  // Missing target - should be filtered
        @{@"source": @"X-Geo-Region", @"target": @"region"}  // Valid - should be kept
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed with only valid geoHeader (matches Android filter behavior)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.geoHeaders.count, 1, @"Should have 1 geoHeader after filtering");
    XCTAssertEqualObjects(config.geoHeaders[0].target, @"region");
}

/**
 * Test missing winLossNotificationPayloadConfig returns error 205
 */
- (void)testParseSDKConfig_MissingWinLossPayloadConfig_ShouldReturnError205 {
    // Given: Response missing winLossNotificationPayloadConfig
    NSMutableDictionary *response = [self validResponse];
    [response removeObjectForKey:@"winLossNotificationPayloadConfig"];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"winLossNotificationPayloadConfig"], @"Error should mention winLossNotificationPayloadConfig");
}

/**
 * Test auctionEndpointURL as object format with missing default returns error 205
 */
- (void)testParseSDKConfig_AuctionEndpointObjectMissingDefault_ShouldReturnError205 {
    // Given: Response with auctionEndpointURL as object but missing default
    NSMutableDictionary *response = [self validResponse];
    response[@"auctionEndpointURL"] = @{@"test": @[]};  // Missing default

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"auctionEndpointURL.default"], @"Error should mention auctionEndpointURL.default");
}

/**
 * Test empty string for required field returns error 205
 */
- (void)testParseSDKConfig_EmptyAccountID_ShouldReturnError205 {
    // Given: Response with empty accountID
    NSMutableDictionary *response = [self validResponse];
    response[@"accountID"] = @"";  // Empty string

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
    XCTAssertTrue([error.localizedDescription containsString:@"accountID"], @"Error should mention accountID");
}

/**
 * Test nil response returns error 205
 */
- (void)testParseSDKConfig_NilResponse_ShouldReturnError205 {
    // Given: nil response
    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:nil error:&error];

    // Then: Should fail with error 205
    XCTAssertNil(config, @"Config should be nil");
    XCTAssertNotNil(error, @"Error should not be nil");
    XCTAssertEqual(error.code, CLXErrorCodeInvalidResponse, @"Error code should be CLXErrorCodeInvalidResponse (105)");
}

#pragma mark - Tracking Array Parsing Tests

/**
 * Test that tracking array is correctly parsed from SDK init response
 * Validates our fix for missing tracking array parsing
 */
- (void)testParseSDKConfig_ShouldParseTrackingArray {
    // Given: SDK init response with tracking array
    NSMutableDictionary *response = [self validResponse];
    response[@"tracking"] = @[
        @"bid.ext.prebid.meta.adaptercode",
        @"bid.w",
        @"bid.h",
        @"bid.dealid",
        @"bid.creativeId"
    ];
    response[@"organizationID"] = @"CLDX2";  // Optional field

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should parse all fields including tracking array
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqualObjects(config.accountID, @"CLDX2_dc", @"Should parse account ID");
    XCTAssertEqualObjects(config.organizationID, @"CLDX2", @"Should parse organization ID");
    XCTAssertEqualObjects(config.sessionID, @"test-session-123", @"Should parse session ID");
    XCTAssertEqualObjects(config.geoDataEndpointURL, @"https://geo.cloudx.io", @"Should parse geo endpoint URL");

    // Most importantly: verify tracking array is parsed
    XCTAssertNotNil(config.tracking, @"Tracking array should be parsed");
    XCTAssertEqual(config.tracking.count, 5, @"Should parse all 5 tracking fields");
    XCTAssertEqualObjects(config.tracking[0], @"bid.ext.prebid.meta.adaptercode", @"First field should be bidder field");
    XCTAssertEqualObjects(config.tracking[1], @"bid.w", @"Second field should be width");
    XCTAssertEqualObjects(config.tracking[2], @"bid.h", @"Third field should be height");
}

/**
 * Test SDK config parsing with empty tracking array
 */
- (void)testParseSDKConfig_EmptyTrackingArray_ShouldSucceed {
    // Given: SDK init response with empty tracking array
    NSMutableDictionary *response = [self validResponse];
    response[@"tracking"] = @[];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should handle empty array gracefully (empty is valid, just not missing)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertNotNil(config.tracking, @"Tracking array should be present");
    XCTAssertEqual(config.tracking.count, 0, @"Tracking array should be empty");
}

#pragma mark - Placement Reward Configuration Tests

/**
 * Test parsing of rewarded placement with reward configuration
 * Validates the demo-rewarded-1 placement format from server
 */
- (void)testParseSDKConfig_RewardedPlacement_ShouldParseRewardFields {
    // Given: SDK init response with rewarded placement containing reward config
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[
        @{
            @"id": @"um9Ek08ScJBWuzSMTyW3b",
            @"name": @"demo-rewarded-1",
            @"bidResponseTimeoutMs": @1000,
            @"adLoadTimeoutMs": @3000,
            @"type": @"rewarded",
            @"rewardAmount": @1000,
            @"rewardCurrency": @"Golden Coins",
            @"rewardCallbackUrl": @"https://httpbin.org/post"
        }
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should parse placement with reward fields
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.adUnits.count, 1, @"Should have 1 placement");

    CLXSDKConfigAdUnit *placement = config.adUnits.firstObject;
    XCTAssertEqualObjects(placement.id, @"um9Ek08ScJBWuzSMTyW3b", @"Should parse placement ID");
    XCTAssertEqualObjects(placement.name, @"demo-rewarded-1", @"Should parse placement name");
    XCTAssertEqual(placement.type, SDKConfigAdTypeRewarded, @"Should parse placement type as rewarded");
    XCTAssertEqual(placement.bidResponseTimeoutMs, 1000, @"Should parse bid timeout");
    XCTAssertEqual(placement.adLoadTimeoutMs, 3000, @"Should parse ad load timeout");

    // Verify reward fields
    XCTAssertEqual(placement.rewardAmount, 1000, @"Should parse rewardAmount");
    XCTAssertEqualObjects(placement.rewardCurrency, @"Golden Coins", @"Should parse rewardCurrency");
    XCTAssertEqualObjects(placement.rewardCallbackUrl, @"https://httpbin.org/post", @"Should parse rewardCallbackUrl");
}

/**
 * Test parsing of rewarded placement without optional reward fields
 */
- (void)testParseSDKConfig_RewardedPlacementWithoutRewardConfig_ShouldUseDefaults {
    // Given: SDK init response with rewarded placement but no reward config
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[
        @{
            @"id": @"test-rewarded-id",
            @"name": @"test-rewarded",
            @"type": @"rewarded"
            // No rewardAmount, rewardCurrency, or rewardCallbackUrl
        }
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should use default values for missing reward fields
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.adUnits.count, 1, @"Should have 1 placement");

    CLXSDKConfigAdUnit *placement = config.adUnits.firstObject;
    XCTAssertEqual(placement.type, SDKConfigAdTypeRewarded, @"Should parse placement type as rewarded");
    XCTAssertEqual(placement.rewardAmount, 0, @"Default rewardAmount should be 0");
    XCTAssertNil(placement.rewardCurrency, @"Default rewardCurrency should be nil");
    XCTAssertNil(placement.rewardCallbackUrl, @"Default rewardCallbackUrl should be nil");
}

/**
 * Test parsing of non-rewarded placement ignores reward fields
 */
- (void)testParseSDKConfig_NonRewardedPlacement_ShouldNotHaveRewardFields {
    // Given: SDK init response with interstitial placement
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[
        @{
            @"id": @"test-interstitial-id",
            @"name": @"test-interstitial",
            @"type": @"interstitial"
        }
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should have default/empty reward values (not applicable for non-rewarded)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.adUnits.count, 1, @"Should have 1 placement");

    CLXSDKConfigAdUnit *placement = config.adUnits.firstObject;
    XCTAssertEqual(placement.type, SDKConfigAdTypeInterstitial, @"Should parse placement type as interstitial");
    XCTAssertEqual(placement.rewardAmount, 0, @"Non-rewarded placement should have rewardAmount 0");
    XCTAssertNil(placement.rewardCurrency, @"Non-rewarded placement should have nil rewardCurrency");
    XCTAssertNil(placement.rewardCallbackUrl, @"Non-rewarded placement should have nil rewardCallbackUrl");
}

/**
 * Test parsing multiple placements including rewarded with reward config
 */
- (void)testParseSDKConfig_MultiplePlacements_ShouldParseAllWithRewardFields {
    // Given: SDK init response with multiple placement types
    NSMutableDictionary *response = [self validResponse];
    response[@"adUnits"] = @[
        @{
            @"id": @"banner-id",
            @"name": @"demo-banner",
            @"type": @"banner"
        },
        @{
            @"id": @"rewarded-id",
            @"name": @"demo-rewarded",
            @"type": @"rewarded",
            @"rewardAmount": @500,
            @"rewardCurrency": @"gems"
        },
        @{
            @"id": @"interstitial-id",
            @"name": @"demo-interstitial",
            @"type": @"interstitial"
        }
    ];

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should parse all placements correctly
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqual(config.adUnits.count, 3, @"Should have 3 placements");

    // Find rewarded placement
    CLXSDKConfigAdUnit *rewardedPlacement = nil;
    for (CLXSDKConfigAdUnit *p in config.adUnits) {
        if (p.type == SDKConfigAdTypeRewarded) {
            rewardedPlacement = p;
            break;
        }
    }

    XCTAssertNotNil(rewardedPlacement, @"Should find rewarded placement");
    XCTAssertEqual(rewardedPlacement.rewardAmount, 500, @"Should parse rewardAmount");
    XCTAssertEqualObjects(rewardedPlacement.rewardCurrency, @"gems", @"Should parse rewardCurrency");
}

#pragma mark - Session Endpoint URL Parsing Tests

/**
 * Test that sessionEndpointURL is parsed when present
 */
- (void)testParseSDKConfig_WithSessionEndpointURL_ShouldParse {
    // Given: Response with sessionEndpointURL
    NSMutableDictionary *response = [self validResponse];
    response[@"sessionEndpointURL"] = @"https://session.cloudx.io/session";

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should parse sessionEndpointURL
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertEqualObjects(config.sessionEndpointURL, @"https://session.cloudx.io/session",
                          @"Should parse sessionEndpointURL");
}

/**
 * Test that missing sessionEndpointURL does not cause failure (optional field)
 */
- (void)testParseSDKConfig_MissingSessionEndpointURL_ShouldSucceedWithNil {
    // Given: Response without sessionEndpointURL
    NSMutableDictionary *response = [self validResponse];
    // sessionEndpointURL is not set

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed with nil sessionEndpointURL
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertNil(config.sessionEndpointURL, @"sessionEndpointURL should be nil when not in response");
}

/**
 * Test that empty sessionEndpointURL is treated as absent
 */
- (void)testParseSDKConfig_EmptySessionEndpointURL_ShouldBeNil {
    // Given: Response with empty sessionEndpointURL
    NSMutableDictionary *response = [self validResponse];
    response[@"sessionEndpointURL"] = @"";

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed with nil sessionEndpointURL (empty string filtered out)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertNil(config.sessionEndpointURL, @"sessionEndpointURL should be nil for empty string");
}

/**
 * Test that non-string sessionEndpointURL is ignored
 */
- (void)testParseSDKConfig_NonStringSessionEndpointURL_ShouldBeNil {
    // Given: Response with non-string sessionEndpointURL
    NSMutableDictionary *response = [self validResponse];
    response[@"sessionEndpointURL"] = @12345;  // Number instead of string

    // When: Parse SDK config
    NSError *error = nil;
    CLXSDKConfigResponse *config = [self.networkService parseSDKConfigFromResponse:response error:&error];

    // Then: Should succeed with nil sessionEndpointURL (type check filters it out)
    XCTAssertNotNil(config, @"Config should be parsed");
    XCTAssertNil(error, @"Error should be nil");
    XCTAssertNil(config.sessionEndpointURL, @"sessionEndpointURL should be nil for non-string value");
}

#pragma mark - Bundle Override Tests

- (void)testCreateRequest_UsesBundleOverrideWhenPresent {
    NSString *overrideBundle = @"io.cloudx.override.bundle";
    [[NSUserDefaults standardUserDefaults] setObject:overrideBundle forKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CLXSDKConfigRequest *request = [self.networkService createRequest];

    XCTAssertEqualObjects(request.bundle, overrideBundle, @"init request bundle must honor override");
}

- (void)testCreateRequest_UsesSystemBundleWhenNoOverride {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreBundleConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CLXSDKConfigRequest *request = [self.networkService createRequest];
    NSString *expectedBundle = [CLXSystemInformation shared].appBundleIdentifier;

    XCTAssertEqualObjects(request.bundle, expectedBundle, @"init request should use system bundle when override is absent");
}

#pragma mark - Adapter Metadata Tests

- (void)testCreateRequest_PopulatesAdaptersArray {
    CLXSDKConfigRequest *request = [self.networkService createRequest];

    XCTAssertNotNil(request.adapters, @"adapters should not be nil");
    // In the test target no adapter frameworks are linked, so this should be empty
}

- (void)testCreateRequest_AdaptersIncludedInJson {
    CLXSDKConfigRequest *request = [self.networkService createRequest];
    NSDictionary *json = [request json];

    XCTAssertNotNil(json[@"adapters"], @"JSON should include adapters key");
    XCTAssertTrue([json[@"adapters"] isKindOfClass:[NSArray class]], @"adapters should be an array");
}

@end
