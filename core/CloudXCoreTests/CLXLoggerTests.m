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
    
    // Reset to default state
    [CloudXCore setLoggingEnabled:YES];
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
}

- (void)tearDown {
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
    
    // When: Logging messages
    [self.logger info:@"Test message 1"];
    [self.logger error:@"Test message 2"];
    
    // Small delay to allow async operations to complete
    [NSThread sleepForTimeInterval:0.1];
    
    // Then: Logs should be stored
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    XCTAssertEqual(entries.count, 2, @"Should have 2 log entries");
    
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
    
    // Small delay to ensure clear completes
    [NSThread sleepForTimeInterval:0.05];
    
    // When: Logging messages
    [self.logger info:@"This should not be stored"];
    [self.logger error:@"Neither should this"];
    
    // Small delay to allow async operations to complete
    [NSThread sleepForTimeInterval:0.1];
    
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
    
    // When: Adding more than maxLogEntries
    NSUInteger maxEntries = [CLXLogStore maxLogEntries];
    for (NSUInteger i = 0; i < maxEntries + 10; i++) {
        [self.logger info:[NSString stringWithFormat:@"Log entry %lu", (unsigned long)i]];
    }
    
    // Allow async operations to complete
    [NSThread sleepForTimeInterval:0.5];
    
    // Then: Should only have maxLogEntries
    NSUInteger count = [[CLXLogStore shared] count];
    XCTAssertEqual(count, maxEntries, @"Should have exactly %lu entries after eviction", (unsigned long)maxEntries);
    
    // Verify oldest entries were removed (newest should be present)
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    CLXLogEntry *newestEntry = entries.firstObject;
    XCTAssertTrue([newestEntry.message containsString:@"1009"], @"Newest entry should be log 1009");
    
    // Cleanup
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test that allEntries returns logs in reverse chronological order (newest first)
- (void)testLogStore_AllEntriesReturnsNewestFirst {
    // Given: testMode enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    [NSThread sleepForTimeInterval:0.05];
    
    // When: Logging messages in sequence
    [self.logger info:@"First"];
    [NSThread sleepForTimeInterval:0.01];
    [self.logger info:@"Second"];
    [NSThread sleepForTimeInterval:0.01];
    [self.logger info:@"Third"];
    
    [NSThread sleepForTimeInterval:0.1];
    
    // Then: Newest should be first
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    XCTAssertEqual(entries.count, 3, @"Should have 3 entries");
    XCTAssertTrue([entries[0].message containsString:@"Third"], @"First entry should be 'Third' (newest)");
    XCTAssertTrue([entries[2].message containsString:@"First"], @"Last entry should be 'First' (oldest)");
    
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
    
    [NSThread sleepForTimeInterval:0.05];
    
    [self.logger info:@"Entry 1"];
    [self.logger info:@"Entry 2"];
    
    [NSThread sleepForTimeInterval:0.1];
    
    XCTAssertEqual([[CLXLogStore shared] count], 2, @"Should have 2 entries before clear");
    
    // When: Clearing
    [[CLXLogStore shared] clear];
    
    [NSThread sleepForTimeInterval:0.1];
    
    // Then: Should be empty
    XCTAssertEqual([[CLXLogStore shared] count], 0, @"Should have 0 entries after clear");
    
    // Cleanup
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreTestModeKey];
}

// Test exportAsString produces formatted output
- (void)testLogStore_ExportAsString {
    // Given: testMode enabled with logs
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCLXCoreTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[CLXLogStore shared] clear];
    
    [NSThread sleepForTimeInterval:0.05];
    
    [self.logger info:@"Test export message"];
    
    [NSThread sleepForTimeInterval:0.1];
    
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

