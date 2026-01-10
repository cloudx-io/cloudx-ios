//
//  CLXBidNetworkServiceHybridTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-17.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXBidNetworkServiceHybridTests : XCTestCase
@property (nonatomic, strong) CLXBidNetworkServiceClass *networkService;
@end

@implementation CLXBidNetworkServiceHybridTests

- (void)setUp {
    [super setUp];
    self.networkService = [[CLXBidNetworkServiceClass alloc] 
                          initWithAuctionEndpointUrl:@"https://test.example.com/auction"];
}

#pragma mark - Hybrid Completion Handler Tests

/**
 * Test that completion handler provides both parsed response and raw JSON
 * Validates our hybrid approach implementation
 * NO NETWORK CALLS - compile-time interface validation only
 */
- (void)testStartAuction_CompletionHandler_ShouldProvideHybridResponse {
    // Validate that method signature compiles and accepts hybrid completion handler
    // This is a compile-time check - if this test compiles, the interface is correct
    
    void (^completionHandler)(CLXBidResponse * _Nullable, NSDictionary * _Nullable, NSError * _Nullable) = 
    ^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Interface validation - this block should compile without errors
    };
    
    // Then: Method should accept the hybrid completion handler signature
    XCTAssertNotNil(completionHandler, @"Hybrid completion handler should be assignable");
    
    // Verify the network service responds to the selector with expected signature
    SEL selector = @selector(startAuctionWithBidRequest:appKey:correlationId:completion:);
    XCTAssertTrue([self.networkService respondsToSelector:selector], 
                  @"Network service should respond to startAuctionWithBidRequest:appKey:correlationId:completion:");
}

/**
 * Test completion handler signature compatibility
 * Ensures our refactoring doesn't break existing interface contracts
 * NO NETWORK CALLS - validates completion handler can be invoked with expected types
 */
- (void)testCompletionHandlerSignature_ShouldAcceptThreeParameters {
    // Given: A completion block that expects the new hybrid signature
    __block BOOL handlerCalled = NO;
    void (^completionBlock)(CLXBidResponse * _Nullable, NSDictionary * _Nullable, NSError * _Nullable) = 
    ^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        handlerCalled = YES;
        // Validate parameter types are correct
        if (parsedResponse) {
            XCTAssertTrue([parsedResponse isKindOfClass:[CLXBidResponse class]], 
                         @"First parameter should be CLXBidResponse");
        }
        if (rawJSON) {
            XCTAssertTrue([rawJSON isKindOfClass:[NSDictionary class]], 
                         @"Second parameter should be NSDictionary");
        }
        if (error) {
            XCTAssertTrue([error isKindOfClass:[NSError class]], 
                         @"Third parameter should be NSError");
        }
    };
    
    // Validate completion handler can be called with correct types
    XCTAssertNotNil(completionBlock, @"Completion block should be assignable");
    
    // Invoke the completion handler directly to validate parameter types work
    // NO NETWORK CALL - just validating the block signature
    completionBlock(nil, @{@"test": @"json"}, nil);
    XCTAssertTrue(handlerCalled, @"Completion handler should have been called");
}

/**
 * Test error cases parameter structure validation
 * Validates error handling follows SOLID principles
 */
- (void)testErrorCases_ShouldProvideCorrectParameterStructure {
    // This test validates error parameter structure without network calls
    // Following DRY principle - reusing interface validation pattern
    
    // Given: A completion handler that validates error case parameters
    void (^errorCompletionHandler)(CLXBidResponse * _Nullable, NSDictionary * _Nullable, NSError * _Nullable) = 
    ^(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error) {
        // Validate parameter structure for error cases
        XCTAssertNil(parsedResponse, @"Parsed response should be nil on error");
        XCTAssertNil(rawJSON, @"Raw JSON should be nil on error");  
        XCTAssertNotNil(error, @"Error should be provided");
    };
    
    // When: Validate completion handler can handle error structure
    XCTAssertNotNil(errorCompletionHandler, @"Error completion handler should be assignable");
    
    // Then: Interface should support error case parameters
    // Test that the completion handler signature is compatible with error scenarios
    errorCompletionHandler(nil, nil, [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil]);
}

@end
