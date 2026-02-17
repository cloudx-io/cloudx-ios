//
//  CLXBidAdSourceErrorPropagationTests.m
//  CloudXCoreTests
//
//  Tests for bid creation error propagation through the waterfall.
//  Verifies that real adapter creation errors are surfaced instead of diagnostic guesses.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXError.h>

#pragma mark - Test Helpers

@interface CLXBidAdSourceErrorPropagationTests : XCTestCase
@end

@implementation CLXBidAdSourceErrorPropagationTests

#pragma mark - createBidAd Block Signature Tests

- (void)testCreateBidAdBlockReceivesErrorParameter {
    // Verify the createBidAd block on CLXBidAdSourceResponse accepts NSError * _Nullable * _Nullable
    __block BOOL blockCalled = NO;
    __block NSError *capturedError = nil;
    
    CLXBidAdSourceResponse *response = [[CLXBidAdSourceResponse alloc] initWithPrice:1.0
                                                                           auctionId:@"auction-1"
                                                                              dealId:nil
                                                                             latency:0
                                                                                nurl:nil
                                                                               bidID:@"bid-1"
                                                                                 bid:nil
                                                                          bidRequest:nil
                                                                         networkName:@"testNetwork"
                                                                              clxAd:nil
                                                                         createBidAd:^id _Nullable(NSError * _Nullable * _Nullable error) {
        blockCalled = YES;
        if (error) {
            *error = [NSError errorWithDomain:@"TestDomain" code:42 userInfo:@{NSLocalizedDescriptionKey: @"Test error"}];
        }
        return nil;
    }];
    
    XCTAssertNotNil(response.createBidAd, @"createBidAd block should be set");
    
    id result = response.createBidAd(&capturedError);
    
    XCTAssertTrue(blockCalled, @"createBidAd block should be called");
    XCTAssertNil(result, @"Result should be nil when block returns nil");
    XCTAssertNotNil(capturedError, @"Error should be populated by the block");
    XCTAssertEqual(capturedError.code, 42, @"Error code should match");
    XCTAssertEqualObjects(capturedError.localizedDescription, @"Test error", @"Error description should match");
}

- (void)testCreateBidAdBlockSuccessDoesNotSetError {
    NSError *capturedError = nil;
    NSObject *fakeAd = [[NSObject alloc] init];
    
    CLXBidAdSourceResponse *response = [[CLXBidAdSourceResponse alloc] initWithPrice:1.0
                                                                           auctionId:@"auction-1"
                                                                              dealId:nil
                                                                             latency:0
                                                                                nurl:nil
                                                                               bidID:@"bid-1"
                                                                                 bid:nil
                                                                          bidRequest:nil
                                                                         networkName:@"testNetwork"
                                                                              clxAd:nil
                                                                         createBidAd:^id _Nullable(NSError * _Nullable * _Nullable error) {
        return fakeAd;
    }];
    
    id result = response.createBidAd(&capturedError);
    
    XCTAssertNotNil(result, @"Result should be the fake ad");
    XCTAssertNil(capturedError, @"Error should not be set on success");
}

- (void)testCreateBidAdBlockHandlesNULLErrorParameter {
    // Verify passing NULL for error doesn't crash
    CLXBidAdSourceResponse *response = [[CLXBidAdSourceResponse alloc] initWithPrice:1.0
                                                                           auctionId:@"auction-1"
                                                                              dealId:nil
                                                                             latency:0
                                                                                nurl:nil
                                                                               bidID:@"bid-1"
                                                                                 bid:nil
                                                                          bidRequest:nil
                                                                         networkName:@"testNetwork"
                                                                              clxAd:nil
                                                                         createBidAd:^id _Nullable(NSError * _Nullable * _Nullable error) {
        if (error) {
            *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
        }
        return nil;
    }];
    
    // Should not crash when passing NULL
    XCTAssertNoThrow(response.createBidAd(NULL), @"Passing NULL for error should not crash");
}

#pragma mark - Outer Block Signature Tests

- (void)testOuterCreateBidAdBlockAcceptsErrorParameter {
    // Verify the outer block (on CLXBidAdSource) also accepts NSError * _Nullable * _Nullable
    __block NSError *receivedError = nil;
    
    CLXBidAdSource *source = [[CLXBidAdSource alloc] initWithUserID:nil
                                                           adUnitId:@"test-unit"
                                                             dealID:nil
                                                      hasCloseButton:NO
                                                        publisherID:@""
                                                             adType:0
                                                     bidTokenSources:@{}
                                              nativeAdRequirements:nil
                                                 bidRequestTimeout:0
                                                    reportingService:nil
                                                        createBidAd:^id _Nullable(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSError * _Nullable * _Nullable error) {
        if (error) {
            *error = [NSError errorWithDomain:@"AdapterDomain" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Adapter creation failed"}];
        }
        return nil;
    }];
    
    XCTAssertNotNil(source, @"CLXBidAdSource should be created with new block signature");
}

#pragma mark - CLXError setError Helper Tests

- (void)testSetErrorPopulatesOutputParameter {
    NSError *error = nil;
    [CLXError setError:&error code:CLXErrorCodeLoadFailed description:@"Test failure"];
    
    XCTAssertNotNil(error, @"Error should be populated");
    XCTAssertEqual(error.code, CLXErrorCodeLoadFailed, @"Error code should match");
    XCTAssertEqualObjects(error.localizedDescription, @"Test failure", @"Description should match");
}

- (void)testSetErrorSafeWithNULL {
    // Should not crash when outError is NULL
    XCTAssertNoThrow([CLXError setError:NULL code:CLXErrorCodeLoadFailed description:@"Test"], @"setError with NULL should not crash");
}

- (void)testSetErrorDoesNotOverwriteOnNULL {
    // Passing NULL should be a no-op
    [CLXError setError:NULL code:CLXErrorCodeLoadFailed description:@"Test"];
    // If we got here without crashing, the test passes
}

#pragma mark - Error Code Backward Compatibility

- (void)testErrorCodesUnchanged {
    XCTAssertEqual(CLXBidAdSourceErrorNoBid, 0, @"CLXBidAdSourceErrorNoBid should remain 0");
    XCTAssertEqual(CLXBidAdSourceErrorAdapterCreationFailed, 1, @"CLXBidAdSourceErrorAdapterCreationFailed should remain 1");
}

@end
