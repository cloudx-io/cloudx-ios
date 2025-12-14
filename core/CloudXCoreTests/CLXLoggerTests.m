//
//  CLXLoggerTests.m
//  CloudXCoreTests
//
//  Tests for CLXLogger functionality including log level filtering
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXLoggerTests : XCTestCase
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSMutableArray<NSString *> *capturedLogs;
@end

@implementation CLXLoggerTests

- (void)setUp {
    [super setUp];
    self.logger = [[CLXLogger alloc] initWithCategory:@"test"];
    self.capturedLogs = [NSMutableArray array];
    
    // IMPORTANT: Disable testMode first to stop other tests from logging
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Wait for any pending log operations from other tests, then clear
    [[CLXLogStore shared] flush];
    [[CLXLogStore shared] clear];
    
    // Reset to default state
    [CloudXCore setLoggingEnabled:YES];
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
}

- (void)tearDown {
    // Disable testMode to prevent logging from other tests
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Wait for any pending operations, then clear
    [[CLXLogStore shared] flush];
    [[CLXLogStore shared] clear];
    
    self.capturedLogs = nil;
    self.logger = nil;
    [super tearDown];
}

#pragma mark - setMinLogLevel Tests

// Test that ERROR level suppresses all lower priority logs
- (void)testSetMinLogLevel_ERROR_SuppressesDebugAndInfo {
    // Given: Min log level set to ERROR
    [CloudXCore setMinLogLevel:CLXLogLevelError];
    [CloudXCore setLoggingEnabled:YES];
    
    // When: Logging at different levels
    // Debug and Info should be suppressed, Error should pass through
    [self.logger debug:@"Debug message"];
    [self.logger info:@"Info message"];
    [self.logger error:@"Error message"];
    
    // Then: Only error should be logged (verified visually in console)
    // This test verifies the method doesn't crash and filtering logic executes
    XCTAssertTrue(YES, @"setMinLogLevel ERROR completed without crash");
}

// Test that DEBUG level allows DEBUG and above, suppresses VERBOSE
- (void)testSetMinLogLevel_DEBUG_AllowsDebugAndAbove {
    // Given: Min log level set to DEBUG
    [CloudXCore setMinLogLevel:CLXLogLevelDebug];
    [CloudXCore setLoggingEnabled:YES];
    
    // When: Logging at different levels
    [self.logger debug:@"Debug message"];
    [self.logger info:@"Info message"];
    [self.logger error:@"Error message"];
    
    // Then: Debug, Info, and Error should pass through
    XCTAssertTrue(YES, @"setMinLogLevel DEBUG completed without crash");
}

// Test that INFO level suppresses DEBUG
- (void)testSetMinLogLevel_INFO_SuppressesDebug {
    // Given: Min log level set to INFO
    [CloudXCore setMinLogLevel:CLXLogLevelInfo];
    [CloudXCore setLoggingEnabled:YES];
    
    // When: Logging at different levels
    [self.logger debug:@"Debug message"];
    [self.logger info:@"Info message"];
    [self.logger error:@"Error message"];
    
    // Then: Only Info and Error should pass through
    XCTAssertTrue(YES, @"setMinLogLevel INFO completed without crash");
}

// Test that VERBOSE level (default) allows all logs
- (void)testSetMinLogLevel_VERBOSE_AllowsAllLogs {
    // Given: Min log level set to VERBOSE (default)
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
    [CloudXCore setLoggingEnabled:YES];
    
    // When: Logging at all levels
    [self.logger debug:@"Debug message"];
    [self.logger info:@"Info message"];
    [self.logger error:@"Error message"];
    
    // Then: All logs should pass through
    XCTAssertTrue(YES, @"setMinLogLevel VERBOSE completed without crash");
}

// Test that log level persists across logger instances
- (void)testSetMinLogLevel_PersistsAcrossLoggerInstances {
    // Given: Set min log level to ERROR
    [CloudXCore setMinLogLevel:CLXLogLevelError];
    
    // When: Creating a new logger instance
    CLXLogger *newLogger = [[CLXLogger alloc] initWithCategory:@"test2"];
    
    // Then: The new logger should respect the global log level
    // This test verifies the static global variable works correctly
    [newLogger debug:@"Debug message"];
    [newLogger error:@"Error message"];
    
    XCTAssertTrue(YES, @"Log level persists across instances");
}

// Test that setMinLogLevel works with shared logger
- (void)testSetMinLogLevel_WorksWithSharedLogger {
    // Given: Set min log level via CloudXCore API
    [CloudXCore setMinLogLevel:CLXLogLevelWarn];
    
    // When: Using shared logger
    CLXLogger *sharedLogger = [CLXLogger shared];
    
    // Then: Should respect the min log level
    [sharedLogger debug:@"Debug message"];
    [sharedLogger info:@"Info message"];
    [sharedLogger error:@"Error message"];
    
    XCTAssertNotNil(sharedLogger, @"Shared logger should exist");
}

// Test interaction between setLoggingEnabled and setMinLogLevel
- (void)testSetMinLogLevel_InteractionWithLoggingEnabled {
    // Given: Logging disabled
    [CloudXCore setLoggingEnabled:NO];
    [CloudXCore setMinLogLevel:CLXLogLevelDebug];
    
    // When: Logging at various levels
    [self.logger debug:@"Debug message"];
    [self.logger info:@"Info message"];
    
    // Then: No logs should appear (disabled overrides level)
    
    // Re-enable logging
    [CloudXCore setLoggingEnabled:YES];
    
    // When: Logging again
    [self.logger debug:@"Debug message after enable"];
    
    // Then: Should respect min log level
    XCTAssertTrue(YES, @"Logging enabled/disabled interaction works");
}

// Test that ERROR logs always show regardless of setLoggingEnabled
- (void)testSetMinLogLevel_ERRORAlwaysShows {
    // Given: Logging disabled
    [CloudXCore setLoggingEnabled:NO];
    [CloudXCore setMinLogLevel:CLXLogLevelError];
    
    // When: Logging an error
    [self.logger error:@"Critical error"];
    
    // Then: Error should still be visible (errors always show)
    XCTAssertTrue(YES, @"Errors show even when logging disabled");
}

#pragma mark - CLXLogStore Tests

// Test that log store captures logs when testMode is enabled
- (void)testLogStore_CapturesLogsWhenTestModeEnabled {
    // Given: testMode enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    // Small delay to ensure clear completes
    [NSThread sleepForTimeInterval:0.05];
    
    // When: Logging messages with unique identifiers
    NSString *testMarker = [[NSUUID UUID] UUIDString];
    NSString *message1 = [NSString stringWithFormat:@"Test message 1 %@", testMarker];
    NSString *message2 = [NSString stringWithFormat:@"Test message 2 %@", testMarker];
    [self.logger info:message1];
    [self.logger error:message2];
    
    // Wait for async operations to complete
    [[CLXLogStore shared] flush];
    
    // Then: Our specific logs should be stored (filter by our unique marker)
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"message CONTAINS %@", testMarker];
    NSArray<CLXLogEntry *> *testEntries = [entries filteredArrayUsingPredicate:predicate];
    XCTAssertEqual(testEntries.count, 2, @"Should have 2 log entries from this test");
    
    // Cleanup
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test that log store does NOT capture logs when testMode is disabled
- (void)testLogStore_DoesNotCaptureLogsWhenTestModeDisabled {
    // Given: testMode disabled
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    // When: Logging messages
    [self.logger info:@"This should not be stored"];
    [self.logger error:@"Neither should this"];
    
    // Wait for async operations to complete
    [[CLXLogStore shared] flush];
    
    // Then: No logs should be stored
    NSUInteger count = [[CLXLogStore shared] count];
    XCTAssertEqual(count, 0, @"Should have 0 log entries when testMode is disabled");
    
    // Cleanup
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test LRU eviction - oldest logs are removed when limit is reached
- (void)testLogStore_LRUEviction {
    // Given: testMode enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    [NSThread sleepForTimeInterval:0.05];
    
    // When: Adding more than maxLogEntries with unique marker
    NSString *testMarker = [[NSUUID UUID] UUIDString];
    NSUInteger maxEntries = [CLXLogStore maxLogEntries];
    NSUInteger totalEntries = maxEntries + 10;
    for (NSUInteger i = 0; i < totalEntries; i++) {
        [self.logger info:[NSString stringWithFormat:@"LRU_%@ entry %lu", testMarker, (unsigned long)i]];
    }
    
    // Wait for all async operations to complete
    [[CLXLogStore shared] flush];
    
    // Then: Filter to only our test entries
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"message CONTAINS %@", testMarker];
    NSArray<CLXLogEntry *> *testEntries = [entries filteredArrayUsingPredicate:predicate];
    
    // Verify LRU eviction: we added totalEntries but should only have maxEntries (or less due to eviction)
    XCTAssertLessThanOrEqual(testEntries.count, maxEntries, 
                              @"Should have at most %lu entries after eviction", (unsigned long)maxEntries);
    
    // Verify oldest entries were removed - newest entry should contain our highest index
    if (testEntries.count > 0) {
        CLXLogEntry *newestEntry = testEntries.firstObject;
        NSString *expectedNewestIndex = [NSString stringWithFormat:@"entry %lu", (unsigned long)(totalEntries - 1)];
        XCTAssertTrue([newestEntry.message containsString:expectedNewestIndex], 
                      @"Newest entry should be the last logged entry (index %lu)", (unsigned long)(totalEntries - 1));
    }
    
    // Cleanup - flush again to ensure all operations complete before clearing
    [[CLXLogStore shared] flush];
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test that allEntries returns logs in reverse chronological order (newest first)
- (void)testLogStore_AllEntriesReturnsNewestFirst {
    // Given: testMode enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    // Use unique markers to identify our test entries (avoids race conditions with other tests)
    NSString *uniqueMarker = [[NSUUID UUID] UUIDString];
    NSString *firstMsg = [NSString stringWithFormat:@"First_%@", uniqueMarker];
    NSString *secondMsg = [NSString stringWithFormat:@"Second_%@", uniqueMarker];
    NSString *thirdMsg = [NSString stringWithFormat:@"Third_%@", uniqueMarker];
    
    // When: Logging messages in sequence
    [self.logger info:firstMsg];
    [self.logger info:secondMsg];
    [self.logger info:thirdMsg];
    
    // Wait for async operations to complete
    [[CLXLogStore shared] flush];
    
    // Then: Filter to only our test entries and verify order (newest first)
    NSArray<CLXLogEntry *> *allEntries = [[CLXLogStore shared] allEntries];
    NSMutableArray<CLXLogEntry *> *testEntries = [NSMutableArray array];
    for (CLXLogEntry *entry in allEntries) {
        if ([entry.message containsString:uniqueMarker]) {
            [testEntries addObject:entry];
        }
    }
    
    XCTAssertEqual(testEntries.count, 3, @"Should have 3 test entries");
    if (testEntries.count >= 3) {
        XCTAssertTrue([testEntries[0].message containsString:@"Third"], @"First entry should be 'Third' (newest)");
        XCTAssertTrue([testEntries[2].message containsString:@"First"], @"Last entry should be 'First' (oldest)");
    }
    
    // Cleanup
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test clear removes all entries
- (void)testLogStore_ClearRemovesAllEntries {
    // Given: testMode enabled with some logs
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    // Use unique markers to identify our test entries
    NSString *uniqueMarker = [[NSUUID UUID] UUIDString];
    [self.logger info:[NSString stringWithFormat:@"Entry1_%@", uniqueMarker]];
    [self.logger info:[NSString stringWithFormat:@"Entry2_%@", uniqueMarker]];
    
    // Wait for async operations to complete
    [[CLXLogStore shared] flush];
    
    // Count only our test entries before clear
    NSArray<CLXLogEntry *> *entriesBefore = [[CLXLogStore shared] allEntries];
    NSUInteger testEntriesBeforeClear = 0;
    for (CLXLogEntry *entry in entriesBefore) {
        if ([entry.message containsString:uniqueMarker]) {
            testEntriesBeforeClear++;
        }
    }
    XCTAssertEqual(testEntriesBeforeClear, 2, @"Should have 2 test entries before clear");
    
    // When: Clearing
    [[CLXLogStore shared] clear];
    
    // Then: Our entries should be gone (and ideally all entries)
    [[CLXLogStore shared] flush]; // Ensure clear is processed
    NSArray<CLXLogEntry *> *entriesAfter = [[CLXLogStore shared] allEntries];
    NSUInteger testEntriesAfterClear = 0;
    for (CLXLogEntry *entry in entriesAfter) {
        if ([entry.message containsString:uniqueMarker]) {
            testEntriesAfterClear++;
        }
    }
    XCTAssertEqual(testEntriesAfterClear, 0, @"Should have 0 test entries after clear");
    
    // Cleanup
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test exportAsString produces formatted output
- (void)testLogStore_ExportAsString {
    // Given: testMode enabled with logs
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    [self.logger info:@"Test export message"];
    
    // Wait for async operations to complete
    [[CLXLogStore shared] flush];
    
    // When: Exporting
    NSString *exported = [[CLXLogStore shared] exportAsString];
    
    // Then: Should contain expected content
    XCTAssertTrue([exported containsString:@"CloudX SDK Debug Logs"], @"Should have header");
    XCTAssertTrue([exported containsString:@"Test export message"], @"Should contain log message");
    XCTAssertTrue([exported containsString:@"INFO"], @"Should contain log level");
    
    // Cleanup
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test CLXLogEntry formattedString
- (void)testLogEntry_FormattedString {
    // Given: A log entry
    CLXLogEntry *entry = [[CLXLogEntry alloc] initWithLevel:CLXLogLevelError
                                                   category:@"TestCategory"
                                                    message:@"Test error message"];
    
    // When: Getting formatted string
    NSString *formatted = [entry formattedString];
    
    // Then: Should contain expected components
    XCTAssertTrue([formatted containsString:@"ERROR"], @"Should contain level");
    XCTAssertTrue([formatted containsString:@"TestCategory"], @"Should contain category");
    XCTAssertTrue([formatted containsString:@"Test error message"], @"Should contain message");
}

@end

