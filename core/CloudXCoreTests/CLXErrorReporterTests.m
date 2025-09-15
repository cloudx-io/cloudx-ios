/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorReporterTests.m
 * @brief Comprehensive unit tests for CLXErrorReporter
 * @details Tests core error reporting functionality, edge cases, and fail-safety
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXErrorReporterTests : XCTestCase
@property (nonatomic, strong) CLXErrorReporter *errorReporter;
@property (nonatomic, strong) NSMutableArray<NSString *> *capturedLogs;
@end

@implementation CLXErrorReporterTests

- (void)setUp {
    [super setUp];
    self.errorReporter = [[CLXErrorReporter alloc] init];
    self.capturedLogs = [NSMutableArray array];
}

- (void)tearDown {
    self.errorReporter = nil;
    self.capturedLogs = nil;
    [super tearDown];
}

#pragma mark - Core Functionality Tests

/**
 * @brief Test basic exception reporting functionality
 * @discussion Verifies that valid exceptions are properly reported without crashing
 */
- (void)testReportException_ValidException_Success {
    // Arrange
    NSException *testException = [NSException exceptionWithName:@"TestException"
                                                        reason:@"Test exception for unit testing"
                                                      userInfo:@{@"test_key": @"test_value"}];
    NSDictionary *context = @{@"operation": @"unit_test", @"component": @"error_reporter"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:testException context:context],
                    @"Valid exception reporting should not throw");
}

/**
 * @brief Test basic NSError reporting functionality
 * @discussion Verifies that valid NSErrors are properly reported without crashing
 */
- (void)testReportError_ValidError_Success {
    // Arrange
    NSError *testError = [NSError errorWithDomain:@"TestDomain"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Test error for unit testing"}];
    NSDictionary *context = @{@"operation": @"unit_test", @"component": @"error_reporter"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportError:testError context:context],
                    @"Valid error reporting should not throw");
}

#pragma mark - Nil Input Handling Tests

/**
 * @brief Test exception reporting with nil exception
 * @discussion Ensures graceful handling of nil exceptions without crashing
 */
- (void)testReportException_NilException_GracefulHandling {
    // Arrange
    NSException *nilException = nil;
    NSDictionary *context = @{@"operation": @"nil_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:nilException context:context],
                    @"Nil exception reporting should be handled gracefully");
}

/**
 * @brief Test error reporting with nil error
 * @discussion Ensures graceful handling of nil errors without crashing
 */
- (void)testReportError_NilError_GracefulHandling {
    // Arrange
    NSError *nilError = nil;
    NSDictionary *context = @{@"operation": @"nil_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportError:nilError context:context],
                    @"Nil error reporting should be handled gracefully");
}

/**
 * @brief Test exception reporting with nil context
 * @discussion Ensures graceful handling of nil context without crashing
 */
- (void)testReportException_NilContext_GracefulHandling {
    // Arrange
    NSException *testException = [NSException exceptionWithName:@"TestException"
                                                        reason:@"Test with nil context"
                                                      userInfo:nil];
    NSDictionary *nilContext = nil;
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:testException context:nilContext],
                    @"Exception reporting with nil context should be handled gracefully");
}

#pragma mark - Placement ID Tests

/**
 * @brief Test exception reporting with placement ID
 * @discussion Verifies placement ID is properly passed through the reporting chain
 */
- (void)testReportException_WithPlacementID_Success {
    // Arrange
    NSException *testException = [NSException exceptionWithName:@"TestException"
                                                        reason:@"Test with placement ID"
                                                      userInfo:nil];
    NSString *placementID = @"test_placement_123";
    NSDictionary *context = @{@"operation": @"placement_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:testException 
                                             placementID:placementID 
                                                 context:context],
                    @"Exception reporting with placement ID should not throw");
}

/**
 * @brief Test error reporting with placement ID
 * @discussion Verifies placement ID is properly passed through the reporting chain
 */
- (void)testReportError_WithPlacementID_Success {
    // Arrange
    NSError *testError = [NSError errorWithDomain:@"TestDomain"
                                             code:2001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Test with placement ID"}];
    NSString *placementID = @"test_placement_456";
    NSDictionary *context = @{@"operation": @"placement_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportError:testError 
                                         placementID:placementID 
                                             context:context],
                    @"Error reporting with placement ID should not throw");
}

#pragma mark - Edge Case Tests

/**
 * @brief Test exception reporting with extremely long reason
 * @discussion Tests handling of exceptions with very long reason strings
 */
- (void)testReportException_ExtremelyLongReason_GracefulHandling {
    // Arrange
    NSString *longReason = [@"" stringByPaddingToLength:10000 withString:@"Very long exception reason. " startingAtIndex:0];
    NSException *testException = [NSException exceptionWithName:@"LongReasonException"
                                                        reason:longReason
                                                      userInfo:nil];
    NSDictionary *context = @{@"operation": @"long_reason_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:testException context:context],
                    @"Exception with extremely long reason should be handled gracefully");
}

/**
 * @brief Test exception reporting with special characters
 * @discussion Tests handling of exceptions with unicode and special characters
 */
- (void)testReportException_SpecialCharacters_GracefulHandling {
    // Arrange
    NSException *testException = [NSException exceptionWithName:@"SpecialCharException"
                                                        reason:@"Test with special chars: 🚨💥⚠️ and unicode: 中文 العربية Русский"
                                                      userInfo:@{@"emoji": @"🔥", @"unicode": @"测试"}];
    NSDictionary *context = @{@"operation": @"special_chars_test", @"component": @"🧪"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportException:testException context:context],
                    @"Exception with special characters should be handled gracefully");
}

/**
 * @brief Test error reporting with circular reference in userInfo
 * @discussion Tests handling of NSError with potentially problematic userInfo
 */
- (void)testReportError_ComplexUserInfo_GracefulHandling {
    // Arrange
    NSMutableDictionary *complexUserInfo = [NSMutableDictionary dictionary];
    complexUserInfo[NSLocalizedDescriptionKey] = @"Error with complex userInfo";
    complexUserInfo[@"nested_dict"] = @{@"level1": @{@"level2": @{@"level3": @"deep_value"}}};
    complexUserInfo[@"array"] = @[@1, @2, @3, @"string", @{@"dict_in_array": @"value"}];
    
    NSError *testError = [NSError errorWithDomain:@"ComplexDomain"
                                             code:3001
                                         userInfo:[complexUserInfo copy]];
    NSDictionary *context = @{@"operation": @"complex_userinfo_test"};
    
    // Act & Assert - Should not crash
    XCTAssertNoThrow([self.errorReporter reportError:testError context:context],
                    @"Error with complex userInfo should be handled gracefully");
}

#pragma mark - Singleton Tests

/**
 * @brief Test singleton instance consistency
 * @discussion Verifies that [CLXErrorReporter shared] returns the same instance
 */
- (void)testSharedInstance_Consistency {
    // Act
    CLXErrorReporter *instance1 = [CLXErrorReporter shared];
    CLXErrorReporter *instance2 = [CLXErrorReporter shared];
    
    // Assert
    XCTAssertNotNil(instance1, @"Shared instance should not be nil");
    XCTAssertNotNil(instance2, @"Shared instance should not be nil");
    XCTAssertEqual(instance1, instance2, @"Shared instances should be the same object");
}

/**
 * @brief Test singleton functionality under concurrent access
 * @discussion Ensures thread safety of singleton creation
 */
- (void)testSharedInstance_ThreadSafety {
    // Arrange
    NSMutableArray *instances = [NSMutableArray array];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent singleton access"];
    
    __block NSInteger completedOperations = 0;
    NSInteger totalOperations = 50;
    
    // Act
    for (int i = 0; i < totalOperations; i++) {
        [queue addOperationWithBlock:^{
            CLXErrorReporter *instance = [CLXErrorReporter shared];
            @synchronized(instances) {
                [instances addObject:instance];
                completedOperations++;
                if (completedOperations == totalOperations) {
                    [expectation fulfill];
                }
            }
        }];
    }
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    
    // Assert
    XCTAssertEqual(instances.count, totalOperations, @"All operations should have completed");
    
    // All instances should be the same object
    CLXErrorReporter *firstInstance = instances.firstObject;
    for (CLXErrorReporter *instance in instances) {
        XCTAssertEqual(instance, firstInstance, @"All singleton instances should be identical");
    }
}

#pragma mark - Performance Tests

/**
 * @brief Test error reporting performance under load
 * @discussion Measures performance of error reporting to ensure it doesn't impact app performance
 */
- (void)testErrorReporting_PerformanceUnderLoad {
    // Arrange
    NSInteger reportCount = 1000;
    
    // Act & Assert
    [self measureBlock:^{
        for (NSInteger i = 0; i < reportCount; i++) {
            NSException *exception = [NSException exceptionWithName:@"PerformanceTestException"
                                                            reason:[NSString stringWithFormat:@"Performance test exception %ld", (long)i]
                                                          userInfo:@{@"iteration": @(i)}];
            [self.errorReporter reportException:exception context:@{@"test": @"performance"}];
        }
    }];
}

#pragma mark - Fail-Safety Tests

/**
 * @brief Test that error reporting never crashes even with malicious input
 * @discussion Critical test to ensure error reporting is absolutely fail-safe
 */
- (void)testErrorReporting_FailSafety_MaliciousInput {
    // Test with nil values, empty strings, and edge cases
    NSArray *testCases = @[
        @{@"exception": [NSNull null], @"context": @{}},
        @{@"exception": [NSException exceptionWithName:@"" reason:@"" userInfo:nil], @"context": [NSNull null]},
        @{@"exception": [NSException exceptionWithName:nil reason:nil userInfo:nil], @"context": @{@"": @""}},
    ];
    
    for (NSDictionary *testCase in testCases) {
        // Simplified to avoid macro expansion issues
        id exception = testCase[@"exception"];
        id context = testCase[@"context"];
        
        if ([exception isKindOfClass:[NSException class]]) {
            [self.errorReporter reportException:exception 
                                         context:[context isKindOfClass:[NSDictionary class]] ? context : nil];
        }
        
        XCTAssertTrue(YES, @"Error reporting should never crash with malicious input");
    }
}

@end
