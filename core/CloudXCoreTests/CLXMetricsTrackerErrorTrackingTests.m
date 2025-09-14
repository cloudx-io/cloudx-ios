/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTrackerErrorTrackingTests.m
 * @brief Comprehensive unit tests for CLXMetricsTracker+ErrorTracking
 * @details Tests error metric tracking, exception handling, and analytics integration
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXMetricsTracker+ErrorTracking.h>
#import <CloudXCore/CLXErrorMetricType.h>
#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMetricsTrackerErrorTrackingTests : XCTestCase
@property (nonatomic, strong) CLXMetricsTracker *metricsTracker;
@end

@implementation CLXMetricsTrackerErrorTrackingTests

- (void)setUp {
    [super setUp];
    self.metricsTracker = [[CLXMetricsTracker alloc] init];
}

- (void)tearDown {
    self.metricsTracker = nil;
    [super tearDown];
}

#pragma mark - Error Metric Type Tests

/**
 * @brief Test tracking all supported error metric types
 * @discussion Ensures all CLXErrorMetricType values are properly handled
 */
- (void)testTrackError_AllErrorTypes_Success {
    NSArray<NSNumber *> *errorTypes = @[
        @(CLXErrorMetricTypeJSONParsing),
        @(CLXErrorMetricTypeNetworkTimeout),
        @(CLXErrorMetricTypeUserDefaultsAccess),
        @(CLXErrorMetricTypeConfigurationInvalid),
        @(CLXErrorMetricTypeAdapterInitialization),
        @(CLXErrorMetricTypeStringProcessing),
        @(CLXErrorMetricTypeURLConstruction),
        @(CLXErrorMetricTypeBase64Processing)
    ];
    
    for (NSNumber *errorTypeNumber in errorTypes) {
        CLXErrorMetricType errorType = (CLXErrorMetricType)errorTypeNumber.integerValue;
        NSString *placementID = [NSString stringWithFormat:@"test_placement_%ld", (long)errorType];
        NSDictionary *context = @{@"error_type": @(errorType), @"test": @"all_types"};
        
        XCTAssertNoThrow([self.metricsTracker trackError:errorType 
                                             placementID:placementID 
                                                 context:context],
                        @"Tracking error type %ld should not throw", (long)errorType);
    }
}

/**
 * @brief Test error metric type string conversion
 * @discussion Verifies CLXErrorMetricTypeString function works for all types
 */
- (void)testErrorMetricTypeString_AllTypes_ValidStrings {
    NSArray<NSNumber *> *errorTypes = @[
        @(CLXErrorMetricTypeJSONParsing),
        @(CLXErrorMetricTypeNetworkTimeout),
        @(CLXErrorMetricTypeUserDefaultsAccess),
        @(CLXErrorMetricTypeConfigurationInvalid),
        @(CLXErrorMetricTypeAdapterInitialization),
        @(CLXErrorMetricTypeStringProcessing),
        @(CLXErrorMetricTypeURLConstruction),
        @(CLXErrorMetricTypeBase64Processing)
    ];
    
    for (NSNumber *errorTypeNumber in errorTypes) {
        CLXErrorMetricType errorType = (CLXErrorMetricType)errorTypeNumber.integerValue;
        NSString *typeString = CLXErrorMetricTypeString(errorType);
        
        XCTAssertNotNil(typeString, @"Error type string should not be nil for type %ld", (long)errorType);
        XCTAssertTrue(typeString.length > 0, @"Error type string should not be empty for type %ld", (long)errorType);
        XCTAssertFalse([typeString isEqualToString:@"unknown"], @"Error type string should not be 'unknown' for valid type %ld", (long)errorType);
    }
}

#pragma mark - Exception Tracking Tests

/**
 * @brief Test exception tracking with various exception types
 * @discussion Tests tracking of different NSException scenarios
 */
- (void)testTrackException_VariousExceptions_Success {
    NSArray<NSException *> *testExceptions = @[
        [NSException exceptionWithName:NSRangeException reason:@"Array index out of bounds" userInfo:nil],
        [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid argument passed" userInfo:@{@"arg": @"test"}],
        [NSException exceptionWithName:NSGenericException reason:@"Generic exception occurred" userInfo:nil],
        [NSException exceptionWithName:@"CustomException" reason:@"Custom exception for testing" userInfo:@{@"custom": @"value"}],
        [NSException exceptionWithName:@"" reason:@"Empty name exception" userInfo:nil],
        [NSException exceptionWithName:@"TestException" reason:@"" userInfo:nil],
        [NSException exceptionWithName:@"TestException" reason:nil userInfo:nil]
    ];
    
    for (NSInteger i = 0; i < testExceptions.count; i++) {
        NSException *exception = testExceptions[i];
        NSString *placementID = [NSString stringWithFormat:@"exception_test_%ld", (long)i];
        NSDictionary *context = @{@"test_case": @(i), @"exception_name": exception.name ?: @"nil"};
        
        XCTAssertNoThrow([self.metricsTracker trackException:exception 
                                                 placementID:placementID 
                                                     context:context],
                        @"Exception tracking should not throw for exception %ld", (long)i);
    }
}

/**
 * @brief Test exception tracking with nil exception
 * @discussion Ensures graceful handling of nil exceptions
 */
- (void)testTrackException_NilException_GracefulHandling {
    NSException *nilException = nil;
    NSString *placementID = @"nil_exception_test";
    NSDictionary *context = @{@"test": @"nil_exception"};
    
    XCTAssertNoThrow([self.metricsTracker trackException:nilException 
                                             placementID:placementID 
                                                 context:context],
                    @"Nil exception tracking should be handled gracefully");
}

/**
 * @brief Test exception tracking with complex stack traces
 * @discussion Tests handling of exceptions with extensive call stacks
 */
- (void)testTrackException_ComplexStackTrace_Success {
    // Create an exception with a simulated complex stack trace
    NSException *exception = [NSException exceptionWithName:@"ComplexStackException"
                                                    reason:@"Exception with complex stack trace"
                                                  userInfo:nil];
    
    // Simulate call stack symbols (normally populated by runtime)
    NSArray *mockCallStack = @[
        @"0   CloudXCore    0x000000010000abcd -[CLXBidResponse parseBidResponseFromDictionary:] + 123",
        @"1   CloudXCore    0x000000010000bcde -[CLXBidNetworkService startAuctionWithBidRequest:completion:] + 456",
        @"2   CloudXCore    0x000000010000cdef -[CLXAdManager loadAd] + 789",
        @"3   TestApp       0x000000010000def0 -[ViewController viewDidLoad] + 321",
        @"4   UIKit         0x000000010000ef01 -[UIViewController loadView] + 654"
    ];
    
    // Use runtime reflection to set callStackSymbols (for testing purposes)
    @try {
        [exception setValue:mockCallStack forKey:@"callStackSymbols"];
    } @catch (NSException *e) {
        // If we can't set the call stack, that's okay for this test
    }
    
    NSString *placementID = @"complex_stack_test";
    NSDictionary *context = @{@"test": @"complex_stack_trace"};
    
    XCTAssertNoThrow([self.metricsTracker trackException:exception 
                                             placementID:placementID 
                                                 context:context],
                    @"Exception with complex stack trace should be handled gracefully");
}

#pragma mark - NSError Tracking Tests

/**
 * @brief Test NSError tracking with various error domains
 * @discussion Tests tracking of different NSError scenarios
 */
- (void)testTrackNSError_VariousErrors_Success {
    NSArray<NSError *> *testErrors = @[
        [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey: @"Network timeout"}],
        [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: @"Corrupt file"}],
        [NSError errorWithDomain:@"CLXErrorDomain" code:100 userInfo:@{NSLocalizedDescriptionKey: @"SDK initialization failed"}],
        [NSError errorWithDomain:@"CustomDomain" code:9999 userInfo:@{NSLocalizedDescriptionKey: @"Custom error", @"extra": @"data"}],
        [NSError errorWithDomain:@"" code:0 userInfo:nil],
        [NSError errorWithDomain:@"TestDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @""}]
    ];
    
    for (NSInteger i = 0; i < testErrors.count; i++) {
        NSError *error = testErrors[i];
        NSString *placementID = [NSString stringWithFormat:@"error_test_%ld", (long)i];
        NSDictionary *context = @{@"test_case": @(i), @"error_domain": error.domain ?: @"nil"};
        
        XCTAssertNoThrow([self.metricsTracker trackNSError:error 
                                               placementID:placementID 
                                                   context:context],
                        @"NSError tracking should not throw for error %ld", (long)i);
    }
}

/**
 * @brief Test NSError tracking with nil error
 * @discussion Ensures graceful handling of nil NSErrors
 */
- (void)testTrackNSError_NilError_GracefulHandling {
    NSError *nilError = nil;
    NSString *placementID = @"nil_error_test";
    NSDictionary *context = @{@"test": @"nil_error"};
    
    XCTAssertNoThrow([self.metricsTracker trackNSError:nilError 
                                           placementID:placementID 
                                               context:context],
                    @"Nil NSError tracking should be handled gracefully");
}

#pragma mark - Context Handling Tests

/**
 * @brief Test error tracking with various context scenarios
 * @discussion Tests different context dictionary configurations
 */
- (void)testTrackError_VariousContexts_Success {
    CLXErrorMetricType errorType = CLXErrorMetricTypeJSONParsing;
    NSString *placementID = @"context_test";
    
    NSArray<NSDictionary *> *testContexts = @[
        (NSDictionary *)[NSNull null],
        @{},
        @{@"simple": @"value"},
        @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"},
        @{@"number": @123, @"bool": @YES, @"float": @45.67},
        @{@"nested": @{@"level1": @{@"level2": @"deep_value"}}},
        @{@"array": @[@"item1", @"item2", @"item3"]},
        @{@"unicode": @"测试 🚀 العربية", @"emoji": @"🔥💥⚠️"},
        @{@"empty_key": @"", @"empty_value": @"key", @"": @"empty_key_test"},
        @{@"very_long_value": [@"" stringByPaddingToLength:1000 withString:@"long " startingAtIndex:0]}
    ];
    
    for (NSInteger i = 0; i < testContexts.count; i++) {
        id contextObj = testContexts[i];
        NSDictionary *context = [contextObj isKindOfClass:[NSNull class]] ? nil : contextObj;
        
        XCTAssertNoThrow([self.metricsTracker trackError:errorType 
                                             placementID:placementID 
                                                 context:context],
                        @"Error tracking with context %ld should not throw", (long)i);
    }
}

#pragma mark - Placement ID Tests

/**
 * @brief Test error tracking with various placement ID scenarios
 * @discussion Tests different placement ID configurations
 */
- (void)testTrackError_VariousPlacementIDs_Success {
    CLXErrorMetricType errorType = CLXErrorMetricTypeNetworkTimeout;
    NSDictionary *context = @{@"test": @"placement_id_variations"};
    
    NSArray<NSString *> *testPlacementIDs = @[
        (NSString *)[NSNull null],
        @"",
        @"simple_placement",
        @"placement_with_numbers_123",
        @"placement-with-dashes",
        @"placement_with_underscores",
        @"UPPERCASE_PLACEMENT",
        @"MixedCase_Placement_ID",
        @"placement.with.dots",
        @"placement/with/slashes",
        @"placement with spaces",
        @"unicode_placement_测试_🚀",
        [@"" stringByPaddingToLength:500 withString:@"very_long_placement_id_" startingAtIndex:0]
    ];
    
    for (NSInteger i = 0; i < testPlacementIDs.count; i++) {
        id placementObj = testPlacementIDs[i];
        NSString *placementID = [placementObj isKindOfClass:[NSNull class]] ? nil : placementObj;
        
        XCTAssertNoThrow([self.metricsTracker trackError:errorType 
                                             placementID:placementID 
                                                 context:context],
                        @"Error tracking with placement ID %ld should not throw", (long)i);
    }
}

#pragma mark - Performance Tests

/**
 * @brief Test error tracking performance under load
 * @discussion Ensures error tracking doesn't impact performance significantly
 */
- (void)testErrorTracking_PerformanceUnderLoad {
    NSInteger trackingCount = 1000;
    CLXErrorMetricType errorType = CLXErrorMetricTypeJSONParsing;
    
    [self measureBlock:^{
        for (NSInteger i = 0; i < trackingCount; i++) {
            NSString *placementID = [NSString stringWithFormat:@"perf_test_%ld", (long)i];
            NSDictionary *context = @{@"iteration": @(i), @"test": @"performance"};
            
            [self.metricsTracker trackError:errorType placementID:placementID context:context];
        }
    }];
}

/**
 * @brief Test concurrent error tracking
 * @discussion Ensures thread safety of error tracking operations
 */
- (void)testErrorTracking_ConcurrentAccess_ThreadSafety {
    NSInteger operationCount = 100;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent error tracking"];
    
    __block NSInteger completedOperations = 0;
    
    for (NSInteger i = 0; i < operationCount; i++) {
        [queue addOperationWithBlock:^{
            CLXErrorMetricType errorType = (CLXErrorMetricType)(i % 8); // Cycle through error types
            NSString *placementID = [NSString stringWithFormat:@"concurrent_test_%ld", (long)i];
            NSDictionary *context = @{@"thread_test": @(i), @"operation": @"concurrent"};
            
            [self.metricsTracker trackError:errorType placementID:placementID context:context];
            
            @synchronized(self) {
                completedOperations++;
                if (completedOperations == operationCount) {
                    [expectation fulfill];
                }
            }
        }];
    }
    
    [self waitForExpectations:@[expectation] timeout:10.0];
    XCTAssertEqual(completedOperations, operationCount, @"All concurrent operations should complete");
}

#pragma mark - Fail-Safety Tests

/**
 * @brief Test that error tracking never crashes with malicious input
 * @discussion Critical test to ensure error tracking is absolutely fail-safe
 */
- (void)testErrorTracking_FailSafety_MaliciousInput {
    // Test extreme values and edge cases
    NSArray *maliciousInputs = @[
        @{@"type": @(999), @"placement": [NSNull null], @"context": @"not_a_dict"},
        @{@"type": @(-1), @"placement": @"", @"context": [NSNull null]},
        @{@"type": @(CLXErrorMetricTypeJSONParsing), @"placement": [NSNull null], @"context": @{}}
    ];
    
    for (NSDictionary *input in maliciousInputs) {
        // Simplified to avoid macro expansion issues
        CLXErrorMetricType type = [input[@"type"] integerValue];
        id placement = input[@"placement"];
        id context = input[@"context"];
        
        NSString *placementID = nil;
        if ([placement isKindOfClass:[NSString class]]) {
            placementID = placement;
        } else if (![placement isKindOfClass:[NSNull class]]) {
            placementID = placement; // Keep non-nil, non-string values as-is for testing
        }
        
        NSDictionary *contextDict = nil;
        if ([context isKindOfClass:[NSDictionary class]]) {
            contextDict = context;
        }
        
        XCTAssertNoThrow([self.metricsTracker trackError:type placementID:placementID context:contextDict],
                        @"Error tracking should never crash with malicious input");
    }
}

/**
 * @brief Test error tracking behavior during memory pressure
 * @discussion Simulates low memory conditions to test robustness
 */
- (void)testErrorTracking_MemoryPressure_Robustness {
    // Simulate memory pressure by creating large objects
    NSMutableArray *memoryPressure = [NSMutableArray array];
    
    @try {
        // Create memory pressure
        for (NSInteger i = 0; i < 1000; i++) {
            NSString *largeString = [@"" stringByPaddingToLength:10000 withString:@"memory_pressure " startingAtIndex:0];
            [memoryPressure addObject:largeString];
        }
        
        // Test error tracking under memory pressure
        for (NSInteger i = 0; i < 100; i++) {
            CLXErrorMetricType errorType = CLXErrorMetricTypeJSONParsing;
            NSString *placementID = [NSString stringWithFormat:@"memory_test_%ld", (long)i];
            NSDictionary *context = @{@"memory_pressure": @YES, @"iteration": @(i)};
            
            XCTAssertNoThrow([self.metricsTracker trackError:errorType 
                                                 placementID:placementID 
                                                     context:context],
                            @"Error tracking should work under memory pressure");
        }
    } @finally {
        // Clean up memory pressure
        [memoryPressure removeAllObjects];
    }
}

@end
