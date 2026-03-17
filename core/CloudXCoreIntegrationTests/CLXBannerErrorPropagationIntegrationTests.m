/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerErrorPropagationIntegrationTests.m
 * @brief Integration tests for banner error propagation end-to-end
 *
 * These tests verify that errors from the bid ad source flow through the
 * full async path: requestBannerUpdate → bidAdSource completion → lastBidError
 * storage → continueBannerChain error mapping → delegate callback.
 *
 * The unit tests in CLXPublisherBannerUnitTests verify the mapping logic in
 * isolation (setting lastBidError directly and calling continueBannerChain).
 * These integration tests exercise the real async flow with a mock bid source.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXBidAdSource.h>

#pragma mark - Testing Category

@interface CLXPublisherBanner (IntegrationTesting) <CLXAdapterBannerDelegate>
@property (nonatomic, strong, nullable) id<CLXBidAdSourceProtocol> bidAdSource;
@property (nonatomic, assign) BOOL isLoading;
- (void)requestBannerUpdate;
@end

#pragma mark - Mock Bid Ad Source

@interface MockBidAdSource : NSObject <CLXBidAdSourceProtocol>
@property (nonatomic, strong, nullable) NSError *errorToReturn;
@property (nonatomic, strong, nullable) CLXBidAdSourceResponse *responseToReturn;
@property (nonatomic, assign) BOOL requestBidCalled;
@end

@implementation MockBidAdSource

- (void)requestBidWithAdUnitID:(NSString *)adUnitID
              storedImpressionId:(NSString *)storedImpressionId
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      successWin:(BOOL)successWin
                   correlationId:(NSString *)correlationId
                      completion:(void (^)(CLXBidAdSourceResponse * _Nullable, NSError * _Nullable))completion {
    self.requestBidCalled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(self.responseToReturn, self.errorToReturn);
    });
}

- (nullable CLXBidResponse *)getCurrentBidResponse {
    return nil;
}

@end

#pragma mark - Mock Banner Delegate

@interface IntegrationTestBannerDelegate : NSObject <CLXBannerDelegate>
@property (nonatomic, assign) BOOL failToLoadCalled;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, copy, nullable) void (^failToLoadCallback)(void);
@end

@implementation IntegrationTestBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {}
- (void)didClickAd:(CLXAd *)ad {}
- (void)didExpandAd:(CLXAd *)ad {}
- (void)didCollapseAd:(CLXAd *)ad {}

- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {
    self.failToLoadCalled = YES;
    self.lastError = error;
    if (self.failToLoadCallback) {
        self.failToLoadCallback();
    }
}

@end

#pragma mark - Mock Reporting Service

@interface IntegrationTestReportingService : NSObject <CLXAdEventReporting>
@end

@implementation IntegrationTestReportingService
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
@end

#pragma mark - Mock Banner Factory

@interface IntegrationTestBannerFactory : NSObject <CLXAdapterBannerFactory>
@end

@implementation IntegrationTestBannerFactory

- (nullable id<CLXAdapterBanner>)createWithType:(CLXBannerType)type
                                           adId:(NSString *)adId
                                          bidId:(NSString *)bidId
                                            adm:(NSString *)adm
                                hasClosedButton:(BOOL)hasClosedButton
                                         extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(nullable NSString *)adUnitName
                                       delegate:(id<CLXAdapterBannerDelegate>)delegate {
    return nil;
}

@end

#pragma mark - Test Constants

static NSString * const kIntTestAdUnitId = @"integration-test-banner";
static NSString * const kIntTestUserId = @"test-user";
static NSString * const kIntTestPublisherId = @"test-publisher";

#pragma mark - Test Class

@interface CLXBannerErrorPropagationIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXPublisherBanner *banner;
@property (nonatomic, strong) IntegrationTestBannerDelegate *mockDelegate;
@property (nonatomic, strong) MockBidAdSource *mockBidSource;
@end

@implementation CLXBannerErrorPropagationIntegrationTests

- (void)setUp {
    [super setUp];
    
    self.mockDelegate = [[IntegrationTestBannerDelegate alloc] init];
    self.mockBidSource = [[MockBidAdSource alloc] init];
    
    CLXSDKConfigAdUnit *adUnit = [[CLXSDKConfigAdUnit alloc] init];
    adUnit.id = kIntTestAdUnitId;
    adUnit.bannerRefreshRateMs = 30000;
    
    CLXConfigImpressionModel *impModel = [[CLXConfigImpressionModel alloc] init];
    CLXSettings *settings = [[CLXSettings alloc] init];
    IntegrationTestReportingService *reporting = [[IntegrationTestReportingService alloc] init];
    IntegrationTestBannerFactory *factory = [[IntegrationTestBannerFactory alloc] init];
    
    self.banner = [[CLXPublisherBanner alloc] initWithAdUnit:adUnit
                                                      userID:kIntTestUserId
                                                 publisherID:kIntTestPublisherId
                                    suspendPreloadWhenInvisible:NO
                                                     delegate:self.mockDelegate
                                                   bannerType:CLXBannerTypeW320H50
                                                    impModel:impModel
                                                 adFactories:@{@"testnetwork": factory}
                                              bidTokenSources:@{}
                                          bidRequestTimeout:2.0
                                           reportingService:reporting
                                                    settings:settings];
    
    self.banner.bidAdSource = self.mockBidSource;
}

- (void)tearDown {
    [self.banner destroy];
    self.banner = nil;
    self.mockDelegate = nil;
    self.mockBidSource = nil;
    [super tearDown];
}

#pragma mark - CLXError Passthrough Tests

- (void)testHTTP400CLXErrorFlowsEndToEndToDelegate {
    NSString *serverBody = @"Invalid request: placementId does not match minimum length of 1";
    CLXError *httpError = [CLXError errorWithHTTPStatusCode:400 serverMessage:serverBody];
    self.mockBidSource.errorToReturn = httpError;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives HTTP 400 error"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockBidSource.requestBidCalled, @"Bid source should have been called");
    XCTAssertTrue(self.mockDelegate.failToLoadCalled, @"Delegate should receive failure");
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeClientError,
                   @"HTTP 400 should reach delegate as CLXErrorCodeClientError (103)");
    XCTAssertEqualObjects(self.mockDelegate.lastError.localizedFailureReason, serverBody,
                          @"Server body should survive the full async path to the delegate");
}

- (void)testHTTP500CLXErrorFlowsEndToEndToDelegate {
    CLXError *httpError = [CLXError errorWithHTTPStatusCode:500 serverMessage:@"Internal Server Error"];
    self.mockBidSource.errorToReturn = httpError;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives HTTP 500 error"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled);
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeServerError,
                   @"HTTP 500 should reach delegate as CLXErrorCodeServerError (102)");
    XCTAssertEqualObjects(self.mockDelegate.lastError.localizedFailureReason, @"Internal Server Error");
}

#pragma mark - CLXBidAdSource Error Wrapping Tests

- (void)testBidAdSourceNoBidFlowsEndToEndAsNoFill {
    NSError *noBidError = [NSError errorWithDomain:@"CLXBidAdSource"
                                              code:CLXBidAdSourceErrorNoBid
                                          userInfo:@{NSLocalizedDescriptionKey: @"All 3 bid(s) failed to fill"}];
    self.mockBidSource.errorToReturn = noBidError;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives NoFill"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled);
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeNoFill,
                   @"CLXBidAdSourceErrorNoBid should reach delegate as CLXErrorCodeNoFill");
    XCTAssertEqualObjects(self.mockDelegate.lastError.userInfo[NSUnderlyingErrorKey], noBidError,
                          @"Original bid source error should be preserved as underlyingError");
}

- (void)testBidAdSourceAdapterFailureFlowsEndToEndAsLoadFailed {
    NSError *adapterError = [NSError errorWithDomain:@"CLXBidAdSource"
                                                code:CLXBidAdSourceErrorAdapterCreationFailed
                                            userInfo:@{NSLocalizedDescriptionKey: @"Bid 'bid-42': adapter class not found"}];
    self.mockBidSource.errorToReturn = adapterError;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives LoadFailed"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled);
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeLoadFailed,
                   @"Adapter creation failure should reach delegate as CLXErrorCodeLoadFailed");
    XCTAssertTrue([self.mockDelegate.lastError.localizedDescription containsString:@"adapter class not found"]);
}

#pragma mark - Domain Guard Tests

- (void)testForeignDomainCodeZeroDoesNotMatchNoBidEndToEnd {
    NSError *foreignError = [NSError errorWithDomain:@"NSCocoaErrorDomain"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Some Foundation error"}];
    self.mockBidSource.errorToReturn = foreignError;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives LoadFailed not NoFill"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled);
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeLoadFailed,
                   @"Code 0 from a non-CLXBidAdSource domain must NOT be mapped to NoFill");
    XCTAssertEqualObjects(self.mockDelegate.lastError.userInfo[NSUnderlyingErrorKey], foreignError,
                          @"Foreign error should be wrapped as underlyingError");
}

#pragma mark - Nil Response Tests

- (void)testNilResponseAndNilErrorProducesGenericNoFill {
    self.mockBidSource.errorToReturn = nil;
    self.mockBidSource.responseToReturn = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate receives generic NoFill"];
    self.mockDelegate.failToLoadCallback = ^{ [expectation fulfill]; };
    
    [self.banner requestBannerUpdate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTAssertTrue(self.mockDelegate.failToLoadCalled);
    XCTAssertEqual(self.mockDelegate.lastError.code, CLXErrorCodeNoFill,
                   @"Nil response with nil error should produce generic NoFill");
}

@end
