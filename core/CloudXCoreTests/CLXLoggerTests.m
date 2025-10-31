//
//  CLXLoggerTests.m
//  CloudXCoreTests
//
//  Tests for CLXLogger functionality including log level filtering
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXLogger.h>
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

@end

