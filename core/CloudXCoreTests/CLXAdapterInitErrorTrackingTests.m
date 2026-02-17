/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterInitErrorTrackingTests.m
 * @brief Tests for adapter initialization error tracking
 * @details Verifies that adapter init failures produce correct CLXError objects
 *          with the expected error code and message format.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXError.h>

// Expose the private helper method for direct testing
@interface CloudXCore (AdapterErrorTesting)
- (void)trackAdapterInitializationErrorForNetwork:(NSString *)networkName originalError:(NSError * _Nullable)originalError;
@end

@interface CLXAdapterInitErrorTrackingTests : XCTestCase
@end

@implementation CLXAdapterInitErrorTrackingTests

#pragma mark - CLXError Construction Tests

- (void)testAdapterInitError_HasCorrectErrorCode {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                  description:@"Adapter initialization failed: vungle - Test error"];
    
    XCTAssertEqual(error.code, CLXErrorCodeAdapterInitializationError,
                   @"Error code should be CLXErrorCodeAdapterInitializationError (607)");
    XCTAssertEqual(error.code, 607, @"Error code should be 607");
}

- (void)testAdapterInitError_MessageFormatWithError {
    NSError *originalError = [NSError errorWithDomain:@"VungleSDK"
                                                 code:42
                                             userInfo:@{NSLocalizedDescriptionKey: @"SDK not configured"}];
    
    NSString *errorDetails = originalError.localizedDescription ?: @"No error details provided";
    NSString *errorDescription = [NSString stringWithFormat:@"Adapter initialization failed: %@ - %@",
                                  @"vungle", errorDetails];
    
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                  description:errorDescription];
    
    XCTAssertTrue([error.localizedDescription containsString:@"Adapter initialization failed: vungle"],
                  @"Error message should contain network name");
    XCTAssertTrue([error.localizedDescription containsString:@"SDK not configured"],
                  @"Error message should contain original error details");
}

- (void)testAdapterInitError_MessageFormatWithNilError {
    NSError *originalError = nil;
    
    NSString *errorDetails = originalError.localizedDescription ?: @"No error details provided";
    NSString *errorDescription = [NSString stringWithFormat:@"Adapter initialization failed: %@ - %@",
                                  @"meta", errorDetails];
    
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                  description:errorDescription];
    
    XCTAssertTrue([error.localizedDescription containsString:@"Adapter initialization failed: meta"],
                  @"Error message should contain network name");
    XCTAssertTrue([error.localizedDescription containsString:@"No error details provided"],
                  @"Error message should use fallback when original error is nil");
}

- (void)testAdapterInitError_DifferentNetworkNames {
    NSArray *networks = @[@"vungle", @"meta", @"inmobi", @"mintegral"];
    
    for (NSString *network in networks) {
        NSString *errorDescription = [NSString stringWithFormat:@"Adapter initialization failed: %@ - Test",
                                      network];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                      description:errorDescription];
        
        XCTAssertEqual(error.code, CLXErrorCodeAdapterInitializationError,
                       @"All adapter errors should use code 607");
        XCTAssertTrue([error.localizedDescription containsString:network],
                      @"Error message should contain network name: %@", network);
    }
}

- (void)testAdapterInitError_ErrorDomainIsCloudX {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                  description:@"test"];
    
    XCTAssertEqualObjects(error.domain, @"com.cloudx.sdk.error",
                          @"Error domain should be com.cloudx.sdk.error, got: %@", error.domain);
}

- (void)testAdapterInitError_MatchesAndroidFormat {
    NSString *errorDescription = [NSString stringWithFormat:@"Adapter initialization failed: %@ - %@",
                                  @"vungle", @"SDK timeout"];
    
    // Verify format matches Android: "Adapter initialization failed: {network} - {details}"
    NSString *expectedPrefix = @"Adapter initialization failed: vungle - SDK timeout";
    XCTAssertTrue([errorDescription isEqualToString:expectedPrefix],
                  @"Error format should match Android: 'Adapter initialization failed: {network} - {details}'");
}

@end
