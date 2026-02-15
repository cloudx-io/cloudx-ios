# Test Determinism Rules

This document defines the criteria for categorizing tests as deterministic (kept) or non-deterministic (removed).

## Goal

All tests in CI must be 100% deterministic - they pass or fail based solely on code correctness, not timing, network conditions, or external factors.

## Non-Deterministic Patterns (Tests Removed)

A test is considered **non-deterministic** and should be removed if it contains ANY of:

### Pattern 1: Expectation Waits
```objc
waitForExpectationsWithTimeout:
waitForExpectations:timeout:
```
These depend on timing and can fail intermittently in CI environments with variable CPU load.

### Pattern 2: Delayed Execution
```objc
dispatch_after(
dispatch_async(  // in test method body
```
Async execution in tests introduces race conditions.

### Pattern 3: Explicit Sleeps
```objc
[NSThread sleepForTimeInterval:]
sleep(
```
Hard-coded delays are environment-dependent and will fail in slower CI runners.

### Pattern 4: RunLoop Spinning
```objc
[[NSRunLoop currentRunLoop] runUntilDate:]
```
Polling-based waits are timing-sensitive.

### Pattern 5: Real Network/External Calls
```objc
httpbin.org
[NSURLSession sharedSession]  // in test, not in mock
```
Real network calls fail when networks are slow or unavailable.

## Deterministic Patterns (Tests Kept)

Tests should use:

- **Synchronous assertions**: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil`, etc.
- **Synchronous mocks**: Mocks that call callbacks immediately (e.g., `self.mockService.synchronous = YES`)
- **Direct method calls**: Test input → function → verify output
- **No external dependencies**: All dependencies mocked/injected

## File Categories

### Delete Entire File
- Any file named `*IntegrationTests.m`
- Any file where >50% of tests have async patterns

### Surgical Removal
- Files with mostly deterministic tests but a few async methods
- Remove only the non-deterministic test methods

## Rationale

Tests that pass locally but fail in CI provide negative value - they:
1. Waste developer time investigating false failures
2. Erode trust in the test suite
3. Block legitimate PRs from merging

A smaller suite of reliable tests is more valuable than a large suite of flaky tests.
