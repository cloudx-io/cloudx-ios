//
//  CLXBidAdSourceThreadSafetyTests.m
//  CloudXCoreTests
//
//  Unit tests verifying thread-safe dictionary writes in
//  makeNetworkNameTokenDictWithCompletion: when multiple adapter
//  token callbacks fire concurrently on different threads.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidTokenSource.h>

#pragma mark - Test Category

@interface CLXBidAdSource (Testing)
- (void)makeNetworkNameTokenDictWithCompletion:(void (^)(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *networkNameTokenDict))completion;
@end

#pragma mark - Mock Token Source

@interface CLXConcurrentMockTokenSource : NSObject <CLXBidTokenSource>
@property (nonatomic, copy) NSString *adapterName;
@end

@implementation CLXConcurrentMockTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *token = @{@"token": [NSString stringWithFormat:@"tok_%@", self.adapterName]};
        completion(token, nil);
    });
}

@end

#pragma mark - Mock Error Token Source

@interface CLXErrorMockTokenSource : NSObject <CLXBidTokenSource>
@end

@implementation CLXErrorMockTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
        completion(nil, error);
    });
}

@end

#pragma mark - Mock Reporting Service

@interface CLXBidAdSourceThreadSafetyReportingService : NSObject <CLXAdEventReporting>
@end

@implementation CLXBidAdSourceThreadSafetyReportingService
- (void)metricsTrackingWithActionString:(NSString *)actionString {}
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {}
- (void)geoTrackingWithURLString:(NSString *)fullURL extras:(NSDictionary<NSString *, NSString *> *)extras {}
@end

#pragma mark - Helper

static CLXBidAdSource *createBidSourceWithTokenSources(NSDictionary<NSString *, id<CLXBidTokenSource>> *sources) {
    CLXBidAdSourceThreadSafetyReportingService *reporting = [[CLXBidAdSourceThreadSafetyReportingService alloc] init];
    return [[CLXBidAdSource alloc] initWithUserID:@"test"
                                         adUnitId:@"unit"
                                           dealID:nil
                                    hasCloseButton:NO
                                      publisherID:@"pub"
                                           adType:0
                                   bidTokenSources:sources
                            nativeAdRequirements:nil
                               bidRequestTimeout:2.0
                                  reportingService:reporting
                                      createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *,NSString *> *extras, NSString * _Nullable burl, BOOL hasClose, NSString *network, NSError *__autoreleasing _Nullable * _Nullable error) {
        return nil;
    }];
}

#pragma mark - Tests

@interface CLXBidAdSourceThreadSafetyTests : XCTestCase
@end

@implementation CLXBidAdSourceThreadSafetyTests

- (void)testConcurrentTokenCallbacksReturnAllTokens {
    NSUInteger const adapterCount = 10;

    NSMutableDictionary<NSString *, id<CLXBidTokenSource>> *sources = [NSMutableDictionary dictionary];
    for (NSUInteger j = 0; j < adapterCount; j++) {
        NSString *name = [NSString stringWithFormat:@"adapter_%lu", (unsigned long)j];
        CLXConcurrentMockTokenSource *source = [[CLXConcurrentMockTokenSource alloc] init];
        source.adapterName = name;
        sources[name] = source;
    }

    CLXBidAdSource *bidSource = createBidSourceWithTokenSources(sources);
    XCTestExpectation *exp = [self expectationWithDescription:@"All tokens collected"];

    [bidSource makeNetworkNameTokenDictWithCompletion:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *result) {
        XCTAssertEqual(result.count, adapterCount);
        for (NSUInteger j = 0; j < adapterCount; j++) {
            NSString *name = [NSString stringWithFormat:@"adapter_%lu", (unsigned long)j];
            XCTAssertNotNil(result[name], @"Missing token for %@", name);
        }
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEmptySourcesReturnsEmptyDictionary {
    CLXBidAdSource *bidSource = createBidSourceWithTokenSources(@{});
    XCTestExpectation *exp = [self expectationWithDescription:@"Empty sources"];

    [bidSource makeNetworkNameTokenDictWithCompletion:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *result) {
        XCTAssertEqual(result.count, 0);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSingleSourceReturnsCorrectToken {
    CLXConcurrentMockTokenSource *source = [[CLXConcurrentMockTokenSource alloc] init];
    source.adapterName = @"solo";

    CLXBidAdSource *bidSource = createBidSourceWithTokenSources(@{@"solo": source});
    XCTestExpectation *exp = [self expectationWithDescription:@"Single source"];

    [bidSource makeNetworkNameTokenDictWithCompletion:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *result) {
        XCTAssertEqual(result.count, 1);
        XCTAssertEqualObjects(result[@"solo"][@"token"], @"tok_solo");
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testErrorSourcesAreExcludedFromResult {
    CLXConcurrentMockTokenSource *goodSource = [[CLXConcurrentMockTokenSource alloc] init];
    goodSource.adapterName = @"good";
    CLXErrorMockTokenSource *badSource = [[CLXErrorMockTokenSource alloc] init];

    CLXBidAdSource *bidSource = createBidSourceWithTokenSources(@{
        @"good": goodSource,
        @"bad": badSource
    });

    XCTestExpectation *exp = [self expectationWithDescription:@"Mixed sources"];

    [bidSource makeNetworkNameTokenDictWithCompletion:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *result) {
        XCTAssertEqual(result.count, 1);
        XCTAssertNotNil(result[@"good"]);
        XCTAssertNil(result[@"bad"]);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
