/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRetryManagerTests.m
 * @brief Unit tests for CLXRetryManager
 *
 * Tests:
 * - Retry policy configuration (default, aggressive, conservative)
 * - Exponential backoff calculation with jitter
 * - Circuit breaker behavior
 * - Retryable error classification
 *
 * PRINCIPLES:
 * - NO flaky async patterns (no runUntilDate, no sleepForTimeInterval)
 * - Meaningful assertions on actual values (no XCTAssertTrue(YES))
 * - Synchronous where possible, XCTestExpectation where async is required
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXRetryManager.h>
#import <CloudXCore/CLXError.h>

#pragma mark - Test Category for Internal Access

@interface CLXRetryManager (Testing)
// Expose internal state for testing circuit breaker
@property (nonatomic, assign) NSInteger consecutiveFailures;
@property (nonatomic, assign) NSTimeInterval lastFailureTime;
@property (nonatomic, assign) BOOL circuitOpen;

// Internal methods
- (void)handleSuccess;
- (void)handleFailure:(NSError *)error;
- (BOOL)shouldResetCircuitBreaker;
@end

#pragma mark - CLXRetryManagerTests

@interface CLXRetryManagerTests : XCTestCase
@property (nonatomic, strong) CLXRetryManager *subject;
@end

@implementation CLXRetryManagerTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    self.subject = [[CLXRetryManager alloc] init];
}

- (void)tearDown {
    self.subject = nil;
    [super tearDown];
}

#pragma mark - DRY: Factory Methods

- (NSError *)createNetworkTimeoutError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
}

- (NSError *)createConnectionLostError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];
}

- (NSError *)createBadURLError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
}

- (NSError *)createCloudXNetworkError {
    return [CLXError errorWithCode:CLXErrorCodeNetworkError description:@"Network error"];
}

- (NSError *)createCloudXServerError {
    return [CLXError errorWithCode:CLXErrorCodeServerError description:@"Server error"];
}

- (NSError *)createCloudXInvalidRequestError {
    return [CLXError errorWithCode:CLXErrorCodeInvalidRequest description:@"Invalid request"];
}

#pragma mark - MARK: Retry Policy Tests

- (void)testDefaultPolicy_HasCorrectValues {
    CLXRetryPolicy *policy = [CLXRetryPolicy defaultPolicy];
    
    XCTAssertEqual(policy.maxRetries, 3, @"Default policy should have 3 max retries");
    XCTAssertEqual(policy.baseDelay, 1.0, @"Default policy should have 1.0s base delay");
    XCTAssertEqual(policy.maxDelay, 30.0, @"Default policy should have 30.0s max delay");
    XCTAssertEqual(policy.backoffMultiplier, 2.0, @"Default policy should have 2.0 backoff multiplier");
    XCTAssertEqual(policy.jitterFactor, 0.1, @"Default policy should have 0.1 jitter factor");
}

- (void)testAggressivePolicy_HasCorrectValues {
    CLXRetryPolicy *policy = [CLXRetryPolicy aggressivePolicy];
    
    XCTAssertEqual(policy.maxRetries, 5, @"Aggressive policy should have 5 max retries");
    XCTAssertEqual(policy.baseDelay, 0.5, @"Aggressive policy should have 0.5s base delay");
    XCTAssertEqual(policy.maxDelay, 15.0, @"Aggressive policy should have 15.0s max delay");
    XCTAssertEqual(policy.backoffMultiplier, 1.5, @"Aggressive policy should have 1.5 backoff multiplier");
    XCTAssertEqual(policy.jitterFactor, 0.2, @"Aggressive policy should have 0.2 jitter factor");
}

- (void)testConservativePolicy_HasCorrectValues {
    CLXRetryPolicy *policy = [CLXRetryPolicy conservativePolicy];
    
    XCTAssertEqual(policy.maxRetries, 2, @"Conservative policy should have 2 max retries");
    XCTAssertEqual(policy.baseDelay, 2.0, @"Conservative policy should have 2.0s base delay");
    XCTAssertEqual(policy.maxDelay, 60.0, @"Conservative policy should have 60.0s max delay");
    XCTAssertEqual(policy.backoffMultiplier, 3.0, @"Conservative policy should have 3.0 backoff multiplier");
    XCTAssertEqual(policy.jitterFactor, 0.05, @"Conservative policy should have 0.05 jitter factor");
}

- (void)testInitWithPolicy_UsesProvidedPolicy {
    CLXRetryPolicy *customPolicy = [[CLXRetryPolicy alloc] init];
    customPolicy.maxRetries = 10;
    customPolicy.baseDelay = 5.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:customPolicy];
    
    XCTAssertEqual(manager.policy.maxRetries, 10, @"Manager should use provided policy");
    XCTAssertEqual(manager.policy.baseDelay, 5.0, @"Manager should use provided policy");
}

- (void)testInitWithNilPolicy_UsesDefaultPolicy {
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:nil];
    
    XCTAssertEqual(manager.policy.maxRetries, 3, @"Manager with nil policy should use default");
    XCTAssertEqual(manager.policy.baseDelay, 1.0, @"Manager with nil policy should use default");
}

#pragma mark - MARK: Exponential Backoff Tests

- (void)testCalculateDelay_Attempt1_ReturnsBaseDelay {
    // Create policy with no jitter for deterministic testing
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 1.0;
    policy.backoffMultiplier = 2.0;
    policy.jitterFactor = 0.0; // No jitter for deterministic test
    policy.maxDelay = 30.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    NSTimeInterval delay = [manager calculateDelayForAttempt:1];
    
    // With no jitter, delay should be exactly baseDelay
    XCTAssertEqualWithAccuracy(delay, 1.0, 0.01, @"Attempt 1 should return base delay (1.0s)");
}

- (void)testCalculateDelay_Attempt2_ReturnsBaseDelayTimesMultiplier {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 1.0;
    policy.backoffMultiplier = 2.0;
    policy.jitterFactor = 0.0; // No jitter
    policy.maxDelay = 30.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    NSTimeInterval delay = [manager calculateDelayForAttempt:2];
    
    // delay = baseDelay * (multiplier ^ (attempt - 1)) = 1.0 * (2.0 ^ 1) = 2.0
    XCTAssertEqualWithAccuracy(delay, 2.0, 0.01, @"Attempt 2 should return baseDelay * multiplier (2.0s)");
}

- (void)testCalculateDelay_Attempt3_ReturnsExponentialGrowth {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 1.0;
    policy.backoffMultiplier = 2.0;
    policy.jitterFactor = 0.0; // No jitter
    policy.maxDelay = 30.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    NSTimeInterval delay = [manager calculateDelayForAttempt:3];
    
    // delay = baseDelay * (multiplier ^ (attempt - 1)) = 1.0 * (2.0 ^ 2) = 4.0
    XCTAssertEqualWithAccuracy(delay, 4.0, 0.01, @"Attempt 3 should return exponential growth (4.0s)");
}

- (void)testCalculateDelay_ExceedsMaxDelay_CapsAtMaxDelay {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 1.0;
    policy.backoffMultiplier = 2.0;
    policy.jitterFactor = 0.0; // No jitter
    policy.maxDelay = 5.0; // Low max to trigger capping
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    // Attempt 10 would give 1.0 * (2.0 ^ 9) = 512.0, but should cap at 5.0
    NSTimeInterval delay = [manager calculateDelayForAttempt:10];
    
    XCTAssertEqualWithAccuracy(delay, 5.0, 0.01, @"Delay should cap at maxDelay (5.0s)");
}

- (void)testCalculateDelay_WithJitter_AddsVariation {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 10.0; // Use larger base to make jitter more noticeable
    policy.backoffMultiplier = 1.0;
    policy.jitterFactor = 0.2; // 20% jitter
    policy.maxDelay = 30.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    // Run multiple times to verify jitter adds variation
    NSMutableSet<NSNumber *> *delays = [NSMutableSet set];
    for (int i = 0; i < 10; i++) {
        NSTimeInterval delay = [manager calculateDelayForAttempt:1];
        [delays addObject:@(round(delay * 100))]; // Round to centiseconds for comparison
        
        // Delay should be within jitter range: 10.0 +/- (10.0 * 0.2) = 8.0 to 12.0
        XCTAssertGreaterThanOrEqual(delay, 8.0, @"Delay with jitter should be >= baseDelay - jitter");
        XCTAssertLessThanOrEqual(delay, 12.0, @"Delay with jitter should be <= baseDelay + jitter");
    }
    
    // With 20% jitter on 10 runs, we should see some variation
    // (technically could all be same, but extremely unlikely)
    XCTAssertGreaterThan(delays.count, 1, @"Jitter should produce some variation across runs");
}

- (void)testCalculateDelay_EnsuresMinimumDelay {
    CLXRetryPolicy *policy = [[CLXRetryPolicy alloc] init];
    policy.baseDelay = 0.01; // Very small base delay
    policy.backoffMultiplier = 1.0;
    policy.jitterFactor = 0.5; // High jitter could make delay negative
    policy.maxDelay = 30.0;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:policy];
    
    // Even with aggressive jitter, delay should never go below 0.1
    for (int i = 0; i < 20; i++) {
        NSTimeInterval delay = [manager calculateDelayForAttempt:1];
        XCTAssertGreaterThanOrEqual(delay, 0.1, @"Delay should have minimum of 0.1s");
    }
}

#pragma mark - MARK: Circuit Breaker Tests

- (void)testCircuitBreaker_ClosedByDefault {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSDictionary *diagnostics = [manager diagnostics];
    
    XCTAssertEqualObjects(diagnostics[@"circuitOpen"], @NO, @"Circuit breaker should be closed by default");
    XCTAssertEqualObjects(diagnostics[@"consecutiveFailures"], @0, @"Should have 0 consecutive failures initially");
}

- (void)testCircuitBreaker_OpensAfter5ConsecutiveFailures {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Simulate 5 consecutive failures using internal method
    for (int i = 0; i < 5; i++) {
        [manager handleFailure:error];
    }
    
    NSDictionary *diagnostics = [manager diagnostics];
    XCTAssertEqualObjects(diagnostics[@"circuitOpen"], @YES, @"Circuit should open after 5 consecutive failures");
    XCTAssertEqualObjects(diagnostics[@"consecutiveFailures"], @5, @"Should track 5 consecutive failures");
}

- (void)testCircuitBreaker_StaysClosedWith4Failures {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Simulate 4 consecutive failures
    for (int i = 0; i < 4; i++) {
        [manager handleFailure:error];
    }
    
    NSDictionary *diagnostics = [manager diagnostics];
    XCTAssertEqualObjects(diagnostics[@"circuitOpen"], @NO, @"Circuit should remain closed with 4 failures");
    XCTAssertEqualObjects(diagnostics[@"consecutiveFailures"], @4, @"Should track 4 consecutive failures");
}

- (void)testCircuitBreaker_ResetsOnSuccess {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Simulate 3 failures
    for (int i = 0; i < 3; i++) {
        [manager handleFailure:error];
    }
    
    // Then a success
    [manager handleSuccess];
    
    NSDictionary *diagnostics = [manager diagnostics];
    XCTAssertEqualObjects(diagnostics[@"circuitOpen"], @NO, @"Circuit should be closed after success");
    XCTAssertEqualObjects(diagnostics[@"consecutiveFailures"], @0, @"Consecutive failures should reset on success");
}

- (void)testCircuitBreaker_ResetsAfter60Seconds {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Open the circuit
    for (int i = 0; i < 5; i++) {
        [manager handleFailure:error];
    }
    
    XCTAssertEqualObjects([manager diagnostics][@"circuitOpen"], @YES, @"Circuit should be open");
    
    // Manually set lastFailureTime to 61 seconds ago to simulate time passing
    // (This uses KVC to access internal state - acceptable for testing)
    NSTimeInterval oldTime = [[NSDate date] timeIntervalSince1970] - 61;
    [manager setValue:@(oldTime) forKey:@"lastFailureTime"];
    
    // shouldResetCircuitBreaker should now return YES
    BOOL shouldReset = [manager shouldResetCircuitBreaker];
    XCTAssertTrue(shouldReset, @"Circuit breaker should reset after 60 seconds");
}

- (void)testCircuitBreaker_DoesNotResetBefore60Seconds {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Open the circuit
    for (int i = 0; i < 5; i++) {
        [manager handleFailure:error];
    }
    
    // Set lastFailureTime to 30 seconds ago (within the 60s window)
    NSTimeInterval recentTime = [[NSDate date] timeIntervalSince1970] - 30;
    [manager setValue:@(recentTime) forKey:@"lastFailureTime"];
    
    BOOL shouldReset = [manager shouldResetCircuitBreaker];
    XCTAssertFalse(shouldReset, @"Circuit breaker should NOT reset before 60 seconds");
}

- (void)testReset_ClearsCircuitBreakerState {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Open the circuit
    for (int i = 0; i < 5; i++) {
        [manager handleFailure:error];
    }
    
    XCTAssertEqualObjects([manager diagnostics][@"circuitOpen"], @YES, @"Circuit should be open");
    
    // Reset
    [manager reset];
    
    // Wait a tiny bit for async reset to complete (reset uses dispatch_async internally)
    XCTestExpectation *expectation = [self expectationWithDescription:@"Reset completes"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectations:@[expectation] timeout:1.0];
    
    NSDictionary *diagnostics = [manager diagnostics];
    XCTAssertEqualObjects(diagnostics[@"circuitOpen"], @NO, @"Circuit should be closed after reset");
    XCTAssertEqualObjects(diagnostics[@"consecutiveFailures"], @0, @"Failures should be cleared after reset");
}

#pragma mark - MARK: Retryable Error Classification Tests

- (void)testIsRetryableError_NilError_ReturnsNO {
    BOOL retryable = [self.subject isRetryableError:nil];
    XCTAssertFalse(retryable, @"Nil error should not be retryable");
}

- (void)testIsRetryableError_NetworkError_ReturnsYES {
    NSError *error = [self createCloudXNetworkError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"CLXErrorCodeNetworkError should be retryable");
}

- (void)testIsRetryableError_ServerError_ReturnsYES {
    NSError *error = [self createCloudXServerError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"CLXErrorCodeServerError should be retryable");
}

- (void)testIsRetryableError_InvalidRequest_ReturnsNO {
    NSError *error = [self createCloudXInvalidRequestError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertFalse(retryable, @"CLXErrorCodeInvalidRequest should NOT be retryable");
}

- (void)testIsRetryableError_NSURLErrorTimedOut_ReturnsYES {
    NSError *error = [self createNetworkTimeoutError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"NSURLErrorTimedOut should be retryable");
}

- (void)testIsRetryableError_NSURLErrorCannotConnectToHost_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"NSURLErrorCannotConnectToHost should be retryable");
}

- (void)testIsRetryableError_NSURLErrorNetworkConnectionLost_ReturnsYES {
    NSError *error = [self createConnectionLostError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"NSURLErrorNetworkConnectionLost should be retryable");
}

- (void)testIsRetryableError_NSURLErrorNotConnectedToInternet_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"NSURLErrorNotConnectedToInternet should be retryable");
}

- (void)testIsRetryableError_NSURLErrorDNSLookupFailed_ReturnsYES {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorDNSLookupFailed userInfo:nil];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"NSURLErrorDNSLookupFailed should be retryable");
}

- (void)testIsRetryableError_NSURLErrorBadURL_ReturnsNO {
    NSError *error = [self createBadURLError];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertFalse(retryable, @"NSURLErrorBadURL should NOT be retryable");
}

- (void)testIsRetryableError_NSURLErrorUnsupportedURL_ReturnsNO {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnsupportedURL userInfo:nil];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertFalse(retryable, @"NSURLErrorUnsupportedURL should NOT be retryable");
}

- (void)testIsRetryableError_UnknownErrorDomain_ReturnsYES {
    // Unknown error domains default to retryable (fail-safe)
    NSError *error = [NSError errorWithDomain:@"com.unknown.domain" code:123 userInfo:nil];
    BOOL retryable = [self.subject isRetryableError:error];
    XCTAssertTrue(retryable, @"Unknown error domain should default to retryable");
}

#pragma mark - MARK: shouldAttemptRetry Tests

- (void)testShouldAttemptRetry_RetryableError_ReturnsYES {
    NSError *error = [self createNetworkTimeoutError];
    BOOL shouldRetry = [self.subject shouldAttemptRetry:error attemptCount:1];
    XCTAssertTrue(shouldRetry, @"Should attempt retry for retryable error");
}

- (void)testShouldAttemptRetry_NonRetryableError_ReturnsNO {
    NSError *error = [self createBadURLError];
    BOOL shouldRetry = [self.subject shouldAttemptRetry:error attemptCount:1];
    XCTAssertFalse(shouldRetry, @"Should NOT attempt retry for non-retryable error");
}

- (void)testShouldAttemptRetry_CircuitOpen_ReturnsNO {
    CLXRetryManager *manager = [[CLXRetryManager alloc] init];
    NSError *error = [self createNetworkTimeoutError];
    
    // Open the circuit
    for (int i = 0; i < 5; i++) {
        [manager handleFailure:error];
    }
    
    // Even with retryable error, should return NO when circuit is open
    BOOL shouldRetry = [manager shouldAttemptRetry:error attemptCount:1];
    XCTAssertFalse(shouldRetry, @"Should NOT attempt retry when circuit breaker is open");
}

#pragma mark - MARK: Diagnostics Tests

- (void)testDiagnostics_ReturnsExpectedStructure {
    NSDictionary *diagnostics = [self.subject diagnostics];
    
    XCTAssertNotNil(diagnostics[@"consecutiveFailures"], @"Diagnostics should include consecutiveFailures");
    XCTAssertNotNil(diagnostics[@"lastFailureTime"], @"Diagnostics should include lastFailureTime");
    XCTAssertNotNil(diagnostics[@"circuitOpen"], @"Diagnostics should include circuitOpen");
    XCTAssertNotNil(diagnostics[@"policy"], @"Diagnostics should include policy");
    
    NSDictionary *policyDiag = diagnostics[@"policy"];
    XCTAssertNotNil(policyDiag[@"maxRetries"], @"Policy diagnostics should include maxRetries");
    XCTAssertNotNil(policyDiag[@"baseDelay"], @"Policy diagnostics should include baseDelay");
    XCTAssertNotNil(policyDiag[@"maxDelay"], @"Policy diagnostics should include maxDelay");
    XCTAssertNotNil(policyDiag[@"backoffMultiplier"], @"Policy diagnostics should include backoffMultiplier");
    XCTAssertNotNil(policyDiag[@"jitterFactor"], @"Policy diagnostics should include jitterFactor");
}

#pragma mark - MARK: Execute Operation Tests

- (void)testExecuteOperation_Success_CallsCompletionWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Operation completes"];
    
    [self.subject executeOperation:^(void (^completion)(BOOL, NSError *)) {
        // Simulate successful operation
        completion(YES, nil);
    } completion:^(BOOL finalSuccess, NSError *finalError, NSInteger attemptCount) {
        XCTAssertTrue(finalSuccess, @"Should report success");
        XCTAssertNil(finalError, @"Should have no error on success");
        XCTAssertEqual(attemptCount, 1, @"Should complete on first attempt");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testExecuteOperation_Failure_CallsCompletionWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Operation fails"];
    
    // Use a policy with 0 retries to fail immediately
    CLXRetryPolicy *noRetryPolicy = [[CLXRetryPolicy alloc] init];
    noRetryPolicy.maxRetries = 1;
    noRetryPolicy.baseDelay = 0.01;
    
    CLXRetryManager *manager = [[CLXRetryManager alloc] initWithPolicy:noRetryPolicy];
    
    [manager executeOperation:^(void (^completion)(BOOL, NSError *)) {
        // Simulate failed operation with non-retryable error
        completion(NO, [self createBadURLError]);
    } completion:^(BOOL finalSuccess, NSError *finalError, NSInteger attemptCount) {
        XCTAssertFalse(finalSuccess, @"Should report failure");
        XCTAssertNotNil(finalError, @"Should have error on failure");
        XCTAssertEqual(attemptCount, 1, @"Should fail on first attempt (non-retryable error)");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testExecuteOperation_NilOperation_CallsCompletionWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Nil operation fails"];
    
    [self.subject executeOperation:nil completion:^(BOOL finalSuccess, NSError *finalError, NSInteger attemptCount) {
        XCTAssertFalse(finalSuccess, @"Should report failure for nil operation");
        XCTAssertNotNil(finalError, @"Should have error for nil operation");
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
