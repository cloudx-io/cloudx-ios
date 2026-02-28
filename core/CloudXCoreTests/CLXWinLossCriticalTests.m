/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "MockCLXWinLossTracker.h"
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXSDKConfig.h>

// MARK: - Mocks for Integration Tests

@interface MockCLXWinLossNetworkService : NSObject <CLXWinLossNetworkServiceProtocol>
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *sentPayloads;
@property (nonatomic, assign) BOOL shouldFail;
@property (nonatomic, copy) void (^completionBlock)(BOOL success, NSError *error);
@end

@implementation MockCLXWinLossNetworkService
@synthesize sentPayloads = _sentPayloads;
@synthesize shouldFail = _shouldFail;
@synthesize completionBlock = _completionBlock;

- (instancetype)init {
    self = [super init];
    if (self) {
        _sentPayloads = [NSMutableArray array];
        _shouldFail = NO;
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
           endpointUrl:(NSString *)endpointUrl
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.sentPayloads addObject:payload];
    
    if (self.shouldFail) {
        NSError *error = [NSError errorWithDomain:@"com.cloudx.test" code:500 userInfo:nil];
        completion(NO, error);
        if (self.completionBlock) self.completionBlock(NO, error);
    } else {
        completion(YES, nil);
        if (self.completionBlock) self.completionBlock(YES, nil);
    }
}
@end

@interface MockCLXSQLiteDatabase : CLXSQLiteDatabase
@property (nonatomic, strong) NSMutableArray<NSString *> *executedSQLs;
@property (nonatomic, strong) NSMutableArray<NSArray *> *executedParameters;
@property (nonatomic, strong) NSArray<NSDictionary *> *queryResult;
@end

@implementation MockCLXSQLiteDatabase
@synthesize executedSQLs = _executedSQLs;
@synthesize executedParameters = _executedParameters;
@synthesize queryResult = _queryResult;

- (instancetype)initWithDatabaseName:(NSString *)databaseName {
    // Use in-memory database for testing to avoid file artifacts
    self = [super initWithDatabaseName:@":memory:"]; 
    if (self) {
        _executedSQLs = [NSMutableArray array];
        _executedParameters = [NSMutableArray array];
        _queryResult = @[];
    }
    return self;
}

- (BOOL)executeSQL:(NSString *)sql {
    [self.executedSQLs addObject:sql];
    return YES;
}

- (BOOL)executeSQL:(NSString *)sql withParameters:(nullable NSArray *)parameters {
    [self.executedSQLs addObject:sql];
    if (parameters) {
        [self.executedParameters addObject:parameters];
    }
    return YES;
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql {
    [self.executedSQLs addObject:sql];
    // Return a mock result for last_insert_rowid()
    if ([sql containsString:@"last_insert_rowid"]) {
        return @[@{@"last_insert_rowid()": @(123)}];
    }
    return self.queryResult;
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)sql withParameters:(nullable NSArray *)parameters {
    [self.executedSQLs addObject:sql];
    if (parameters) {
        [self.executedParameters addObject:parameters];
    }
    return self.queryResult;
}

- (BOOL)tableExists:(NSString *)tableName {
    return YES;
}
@end

// MARK: - Integration Tests

// Expose private properties for injection and testing
@interface CLXWinLossTracker (IntegrationTesting)
@property (nonatomic, strong) id<CLXWinLossNetworkServiceProtocol> networkService;
@property (nonatomic, strong) CLXSQLiteDatabase *database;
@property (nonatomic, strong) CLXAuctionBidManager *auctionBidManager;

// Expose the private method for synchronous testing
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload
           auctionId:(NSString *)auctionId
               bidId:(NSString *)bidId;
@end

@interface CLXWinLossIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXWinLossTracker *tracker;
@property (nonatomic, strong) MockCLXWinLossNetworkService *mockNetwork;
@property (nonatomic, strong) MockCLXSQLiteDatabase *mockDatabase;
@end

@implementation CLXWinLossIntegrationTests

- (void)setUp {
    [super setUp];
    
    self.mockNetwork = [[MockCLXWinLossNetworkService alloc] init];
    self.mockDatabase = [[MockCLXSQLiteDatabase alloc] initWithDatabaseName:@"test_db"];
    
    self.tracker = [[CLXWinLossTracker alloc] init];
    
    // Configure tracker FIRST
    [self.tracker setAppKey:@"test-app-key"];
    [self.tracker setEndpoint:@"https://test.com/winloss"];
    
    // Inject mocks AFTER configuration (so setEndpoint doesn't overwrite mock)
    self.tracker.networkService = self.mockNetwork;
    self.tracker.database = self.mockDatabase;
    
    // Configure payload mapping
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"url": @"sdk.[bid.nurl|bid.lurl]",
        @"auctionId": @"auctionId",
        @"bidId": @"bidId",
        @"lossReason": @"sdk.lossReasonCode",
        @"price": @"bid.price"
    };
    [self.tracker setConfig:config];
}

- (void)tearDown {
    self.tracker = nil;
    self.mockNetwork = nil;
    self.mockDatabase = nil;
    [super tearDown];
}

- (void)testTrackWinLoss_Success_ShouldSaveSendAndDelete {
    // Given
    NSString *auctionId = @"auction-1";
    NSString *bidId = @"bid-1";
    NSDictionary *payload = @{@"auctionId": auctionId, @"bidId": bidId};
    
    // When
    // Call trackWinLoss directly to be synchronous
    [self.tracker trackWinLoss:payload auctionId:auctionId bidId:bidId];
    
    // Then
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 1);
    NSDictionary *sentPayload = self.mockNetwork.sentPayloads.firstObject;
    XCTAssertEqualObjects(sentPayload[@"auctionId"], auctionId);
    XCTAssertEqualObjects(sentPayload[@"bidId"], bidId);
    
    // Verify DB interaction (save and delete)
    BOOL hasInsert = NO;
    BOOL hasDelete = NO;
    for (NSString *sql in self.mockDatabase.executedSQLs) {
        if ([sql containsString:@"INSERT INTO"]) hasInsert = YES;
        if ([sql containsString:@"DELETE FROM"]) hasDelete = YES;
    }
    XCTAssertTrue(hasInsert, @"Should insert event into DB before sending");
    XCTAssertTrue(hasDelete, @"Should delete event from DB after successful send");
}

- (void)testTrackWinLoss_NetworkFailure_ShouldKeepInDB {
    // Given
    NSString *auctionId = @"auction-1";
    NSString *bidId = @"bid-1";
    NSDictionary *payload = @{@"auctionId": auctionId, @"bidId": bidId};
    
    self.mockNetwork.shouldFail = YES;
    
    // When
    [self.tracker trackWinLoss:payload auctionId:auctionId bidId:bidId];
    
    // Then
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 1);
    
    // Verify DB interaction (save ONLY, no delete)
    BOOL hasInsert = NO;
    BOOL hasDelete = NO;
    for (NSString *sql in self.mockDatabase.executedSQLs) {
        if ([sql containsString:@"INSERT INTO"]) hasInsert = YES;
        if ([sql containsString:@"DELETE FROM"]) hasDelete = YES;
    }
    XCTAssertTrue(hasInsert, @"Should insert event into DB before sending");
    XCTAssertFalse(hasDelete, @"Should NOT delete event from DB after failed send");
}

- (void)testRetryLogic_ShouldSendCachedEvents {
    // Given
    NSString *cachedPayload = @"{\"auctionId\":\"cached-auction\",\"bidId\":\"cached-bid\"}";
    self.mockDatabase.queryResult = @[
        @{
            @"id": @(1),
            @"auctionId": @"cached-auction",
            @"bidId": @"cached-bid",
            @"payload": cachedPayload,
            @"createdAt": @(1234567890)
        }
    ];
    
    // When
    [self.tracker trySendingPendingWinLossEvents];
    
    // Then
    XCTAssertEqual(self.mockNetwork.sentPayloads.count, 1);
    NSDictionary *payload = self.mockNetwork.sentPayloads.firstObject;
    XCTAssertEqualObjects(payload[@"auctionId"], @"cached-auction");
    
    // Verify DB interaction (delete after success)
    BOOL hasDelete = NO;
    for (NSString *sql in self.mockDatabase.executedSQLs) {
        if ([sql containsString:@"DELETE FROM"]) hasDelete = YES;
    }
    XCTAssertTrue(hasDelete, @"Should delete cached event after successful retry");
}

@end

/**
 * @brief P0 CRITICAL Tests for Win/Loss Event System
 *
 * Tests the 5 fields resolved by CLXWinLossFieldResolver:
 * - notificationType (payloadKey match)
 * - bid (payloadKey match → rawJSON)
 * - source / sdk.sdk (fieldPath match → "sdk")
 * - error / sdk.error (fieldPath match → structured error dict)
 * - lossReasonCode / sdk.lossReasonCode (fieldPath match → NSNumber)
 *
 * All other fields (deviceTypeCode, auctionId, country, etc.) delegate to
 * CLXTrackingFieldResolver and are tested in its own test suite.
 */
@interface CLXWinLossCriticalTests : XCTestCase
@property (nonatomic, strong) MockCLXWinLossTracker *mockTracker;
@end

@implementation CLXWinLossCriticalTests

- (void)setUp {
    [super setUp];

    self.mockTracker = [[MockCLXWinLossTracker alloc] init];
    [CLXWinLossTracker setSharedInstanceForTesting:self.mockTracker];

    // Configure with WinLoss-specific fields only
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]",
        @"lossReasonCode": @"sdk.lossReasonCode",
        @"source": @"sdk.sdk",
        @"error": @"sdk.error"
    };
    [[CLXWinLossTracker shared] setConfig:config];
    [[CLXWinLossTracker shared] setEndpoint:@"https://test.com/winloss"];
    [[CLXWinLossTracker shared] setAppKey:@"test-app-key"];
}

- (void)tearDown {
    [CLXWinLossTracker resetSharedInstance];
    [super tearDown];
}

#pragma mark - sendEvent API

/**
 * Verify sendEvent has the correct 6-param signature (including error:)
 */
- (void)testP0_SendEventAPI_HasCorrectSignature {
    XCTAssertTrue([[CLXWinLossTracker shared] respondsToSelector:@selector(sendEvent:bidId:event:lossReason:winnerBidPrice:error:)],
                 @"sendEvent API must include error: parameter");
}

#pragma mark - notificationType (payloadKey match)

/**
 * Verify LOAD_SUCCESS event produces notificationType=loadSuccess
 */
- (void)testP0_LoadSuccessEvent_NotificationType {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"test-bid";
    bid.price = 3.75;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"test-bid"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0
                                     error:nil];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertEqualObjects(payload[@"notificationType"], @"loadSuccess");
    XCTAssertEqualObjects(payload[@"source"], @"sdk");
}

/**
 * Verify LOSS event produces notificationType=loss with lossReasonCode
 */
- (void)testP0_LossEvent_NotificationTypeAndLossReason {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"losing-bid";
    bid.price = 2.50;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"losing-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:5.00
                                     error:nil];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertEqualObjects(payload[@"notificationType"], @"loss");
    XCTAssertEqualObjects(payload[@"lossReasonCode"], @(102));
    XCTAssertEqualObjects(payload[@"source"], @"sdk");
}

#pragma mark - bid (payloadKey match → rawJSON)

/**
 * Verify bid payloadKey returns bid.rawJSON (original server JSON)
 */
- (void)testP0_BidField_ReturnsRawJSON {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"bid": @"seatbid[0].bid[0]",
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]"
    };
    [[CLXWinLossTracker shared] setConfig:config];

    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"bid-123";
    bid.price = 3.50;
    bid.rawJSON = @{
        @"id": @"bid-123",
        @"price": @(3.50),
        @"adm": @"<html>ad markup</html>",
        @"w": @(320),
        @"h": @(50),
        @"ext": @{
            @"origbidcpm": @(3.50),
            @"cloudx": @{@"rank": @(1)},
            @"prebid": @{@"meta": @{@"adaptercode": @"meta"}}
        }
    };

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"bid-123"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0
                                     error:nil];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;

    id bidField = payload[@"bid"];
    XCTAssertNotNil(bidField, @"Payload must contain 'bid' field");
    XCTAssertTrue([bidField isKindOfClass:[NSDictionary class]], @"'bid' must be dictionary");

    NSDictionary *bidDict = (NSDictionary *)bidField;
    XCTAssertEqualObjects(bidDict[@"id"], @"bid-123");
    XCTAssertEqual([bidDict[@"price"] doubleValue], 3.50);
    XCTAssertNotNil(bidDict[@"ext"][@"cloudx"], @"ext.cloudx must be preserved in rawJSON");
}

#pragma mark - sdk.lossReasonCode (fieldPath match → NSNumber)

/**
 * Verify lossReasonCode is always NSNumber, not string
 */
- (void)testP0_LossReasonCode_IsNumeric {
    CLXSDKConfigResponse *config = [[CLXSDKConfigResponse alloc] init];
    config.winLossNotificationURL = @"https://test.com/winloss";
    config.winLossNotificationPayloadConfig = @{
        @"lossReasonCode": @"sdk.lossReasonCode",
        @"notificationType": @"sdk.[loadSuccess|renderSuccess|loss]"
    };
    [[CLXWinLossTracker shared] setConfig:config];

    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"losing-bid";
    bid.price = 2.0;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"losing-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonLostToHigherBid)
                            winnerBidPrice:5.0
                                     error:nil];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;

    id lossReasonCodeField = payload[@"lossReasonCode"];
    XCTAssertNotNil(lossReasonCodeField, @"Must contain 'lossReasonCode'");
    XCTAssertTrue([lossReasonCodeField isKindOfClass:[NSNumber class]], @"Must be NSNumber");
    XCTAssertFalse([lossReasonCodeField isKindOfClass:[NSString class]], @"Must NOT be string");
    XCTAssertEqual([lossReasonCodeField integerValue], 102);
}

#pragma mark - sdk.error (fieldPath match → structured dict)

/**
 * Verify sdk.error returns structured error dict when error is provided
 */
- (void)testP0_SdkError_ReturnsStructuredDict {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"failed-bid";
    bid.price = 1.0;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];

    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                  description:@"Adapter timed out"];

    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"failed-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0
                                     error:error];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;

    id errorField = payload[@"error"];
    XCTAssertNotNil(errorField, @"Must contain 'error' field when error is provided");
    XCTAssertTrue([errorField isKindOfClass:[NSDictionary class]], @"error must be dictionary");

    NSDictionary *errorDict = (NSDictionary *)errorField;
    XCTAssertNotNil(errorDict[@"code"], @"error.code must be present");
    XCTAssertNotNil(errorDict[@"message"], @"error.message must be present");
}

/**
 * Verify sdk.error is excluded when no error is provided
 */
- (void)testP0_SdkError_ExcludedWhenNil {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"winning-bid";
    bid.price = 3.0;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];
    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"winning-bid"
                                     event:[CLXBidLifecycleEvent loadSuccessEvent]
                                lossReason:nil
                            winnerBidPrice:-1.0
                                     error:nil];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;
    XCTAssertNil(payload[@"error"], @"error field must be excluded when no error");
}

#pragma mark - sdk.error exact value verification

/**
 * Verify CLXErrorCodeAdapterInternalError serializes to exact code string and message.
 * This is the error code used when bid adapter creation fails in the waterfall.
 */
- (void)testP0_SdkError_AdapterInternalError_ExactCodeAndMessage {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"failed-bid";
    bid.price = 1.0;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];

    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                  description:@"Bid 'bid-123': adm is empty or nil"];

    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"failed-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0
                                     error:error];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;

    NSDictionary *errorDict = payload[@"error"];
    XCTAssertNotNil(errorDict, @"error field must be present");
    XCTAssertEqualObjects(errorDict[@"code"], @"ADAPTER_INTERNAL_ERROR",
                         @"CLXErrorCodeAdapterInternalError must serialize to 'ADAPTER_INTERNAL_ERROR'");
    XCTAssertEqualObjects(errorDict[@"message"], @"Bid 'bid-123': adm is empty or nil",
                         @"Error message must pass through exactly");
}

/**
 * Verify different error codes produce their respective code strings
 */
- (void)testP0_SdkError_DifferentCodes_ProduceCorrectStrings {
    // Test CLXErrorCodeAdapterLoadTimeout
    CLXBidResponseBid *bid1 = [[CLXBidResponseBid alloc] init];
    bid1.id = @"bid-timeout";
    bid1.price = 1.0;

    [[CLXWinLossTracker shared] addBid:@"auction-1" bid:bid1];

    CLXError *timeoutError = [CLXError errorWithCode:CLXErrorCodeAdapterLoadTimeout
                                         description:@"Adapter load timed out after 10s"];

    [[CLXWinLossTracker shared] sendEvent:@"auction-1"
                                     bidId:@"bid-timeout"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonTimeout)
                            winnerBidPrice:-1.0
                                     error:timeoutError];

    // Test CLXErrorCodeAdapterNoFill
    CLXBidResponseBid *bid2 = [[CLXBidResponseBid alloc] init];
    bid2.id = @"bid-nofill";
    bid2.price = 2.0;

    [[CLXWinLossTracker shared] addBid:@"auction-2" bid:bid2];

    CLXError *noFillError = [CLXError errorWithCode:CLXErrorCodeAdapterNoFill
                                        description:@"No fill from adapter"];

    [[CLXWinLossTracker shared] sendEvent:@"auction-2"
                                     bidId:@"bid-nofill"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonNoFill)
                            winnerBidPrice:-1.0
                                     error:noFillError];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 2);

    NSDictionary *timeoutPayload = self.mockTracker.allPayloadsSent[0];
    XCTAssertEqualObjects(timeoutPayload[@"error"][@"code"], @"ADAPTER_LOAD_TIMEOUT");
    XCTAssertEqualObjects(timeoutPayload[@"error"][@"message"], @"Adapter load timed out after 10s");

    NSDictionary *noFillPayload = self.mockTracker.allPayloadsSent[1];
    XCTAssertEqualObjects(noFillPayload[@"error"][@"code"], @"ADAPTER_NO_FILL");
    XCTAssertEqualObjects(noFillPayload[@"error"][@"message"], @"No fill from adapter");
}

/**
 * Verify sdk.error and sdk.lossReasonCode coexist correctly in the same payload
 */
- (void)testP0_SdkError_CoexistsWithLossReasonCode {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"failed-bid";
    bid.price = 1.5;

    [[CLXWinLossTracker shared] addBid:@"test-auction" bid:bid];

    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                  description:@"missing crid"];

    [[CLXWinLossTracker shared] sendEvent:@"test-auction"
                                     bidId:@"failed-bid"
                                     event:[CLXBidLifecycleEvent lossEvent]
                                lossReason:@(CLXLossReasonInternalError)
                            winnerBidPrice:-1.0
                                     error:error];

    XCTAssertEqual(self.mockTracker.allPayloadsSent.count, 1);
    NSDictionary *payload = self.mockTracker.allPayloadsSent.firstObject;

    // Both fields must be present
    XCTAssertNotNil(payload[@"error"], @"sdk.error must be present");
    XCTAssertNotNil(payload[@"lossReasonCode"], @"sdk.lossReasonCode must be present");
    XCTAssertEqualObjects(payload[@"lossReasonCode"], @(CLXLossReasonInternalError));
    XCTAssertEqualObjects(payload[@"notificationType"], @"loss");
    XCTAssertEqualObjects(payload[@"error"][@"code"], @"ADAPTER_INTERNAL_ERROR");
    XCTAssertEqualObjects(payload[@"error"][@"message"], @"missing crid");
}

@end
