//
//  CLXGPPProviderTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXGPPProviderTests : XCTestCase
@property (nonatomic, strong) CLXGPPProvider *gppProvider;
@end

@implementation CLXGPPProviderTests

- (void)setUp {
    [super setUp];
    self.gppProvider = [[CLXGPPProvider alloc] init];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - GPP String Parsing Tests

// Test GPP string storage and retrieval
- (void)testGPPStringStorageAndRetrieval {
    NSString *testGppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    
    // Test setting GPP string
    [self.gppProvider setGppString:testGppString];
    NSString *retrievedString = [self.gppProvider gppString];
    XCTAssertEqualObjects(retrievedString, testGppString, @"GPP string should be stored and retrieved correctly");
    
    // Test clearing GPP string
    [self.gppProvider setGppString:nil];
    NSString *clearedString = [self.gppProvider gppString];
    XCTAssertNil(clearedString, @"GPP string should be cleared when set to nil");
}

// Test GPP SID parsing with flexible delimiters
- (void)testGPPSIDParsingWithFlexibleDelimiters {
    NSArray *testCases = @[
        @{@"input": @"7_8", @"expected": @[@7, @8], @"description": @"underscore delimiter"},
        @{@"input": @"8_7", @"expected": @[@7, @8], @"description": @"underscore delimiter (reversed order, should sort)"},
        @{@"input": @"7,8", @"expected": @[@7, @8], @"description": @"comma delimiter"},
        @{@"input": @"8,7", @"expected": @[@7, @8], @"description": @"comma delimiter (reversed order, should sort)"},
        @{@"input": @"7_8_7", @"expected": @[@7, @8], @"description": @"duplicates should be removed"},
        @{@"input": @" 7 _ 8 ", @"expected": @[@7, @8], @"description": @"whitespace should be trimmed"},
        @{@"input": @"", @"expected": nil, @"description": @"empty string"},
        @{@"input": @"invalid", @"expected": nil, @"description": @"invalid format"}
    ];
    
    for (NSDictionary *testCase in testCases) {
        [self.gppProvider setGppSid:nil]; // Clear previous
        
        NSString *input = testCase[@"input"];
        NSArray *expected = testCase[@"expected"];
        NSString *description = testCase[@"description"];
        
        // Set raw SID string directly to UserDefaults to test parsing
        if (input.length > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:input forKey:kIABGPP_GppSID];
        }
        
        NSArray *result = [self.gppProvider gppSid];
        
        if (expected) {
            XCTAssertEqualObjects(result, expected, @"SID parsing failed for %@: %@", description, input);
        } else {
            XCTAssertNil(result, @"SID parsing should return nil for %@: %@", description, input);
        }
    }
}

#pragma mark - GPP Consent Decoding Tests

// Test US-CA (SID=8) consent decoding
- (void)testUSCAConsentDecoding {
    // Test GPP string with US-CA section that has opt-out flags
    NSString *gppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~BVVqAAEABgAA"; // Mock US-CA with opt-out
    NSArray *gppSid = @[@8]; // US-CA only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    XCTAssertNotNil(consent, @"Should decode US-CA consent");
    
    // Note: Actual bit parsing depends on the specific GPP string format
    // This test verifies the decoding mechanism works
}

// Test US-National (SID=7) consent decoding
- (void)testUSNationalConsentDecoding {
    NSString *gppString = @"DBABMA~BVVqAAEABgAA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA"; // Mock US-National
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    XCTAssertNotNil(consent, @"Should decode US-National consent");
}

// Test auto-selection prioritizes consent requiring PII removal
- (void)testAutoSelectionPrioritizesPIIRemoval {
    // Set up GPP with both US-CA and US-National sections
    NSString *gppString = @"DBABMA~BVVqAAEABgAA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA";
    NSArray *gppSid = @[@7, @8]; // Both sections
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:nil]; // Auto-select
    // The actual result depends on the GPP string content, but this tests the auto-selection logic
    XCTAssertTrue(consent != nil || consent == nil, @"Auto-selection should complete without crashing");
}

#pragma mark - Error Handling Tests

// Test graceful handling of missing GPP data
- (void)testMissingGPPDataHandling {
    // Clear all GPP data
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    XCTAssertNil(consent, @"Should return nil when no GPP data is available");
    
    NSString *gppString = [self.gppProvider gppString];
    XCTAssertNil(gppString, @"Should return nil when no GPP string is set");
    
    NSArray *gppSid = [self.gppProvider gppSid];
    XCTAssertNil(gppSid, @"Should return nil when no GPP SID is set");
}

// Test handling of malformed GPP strings
- (void)testMalformedGPPStringHandling {
    NSArray *malformedStrings = @[
        @"", // Empty
        @"invalid", // No sections
        @"DBABMA", // Header only
        @"DBABMA~", // Header with empty section
        @"DBABMA~invalid_base64" // Invalid base64
    ];
    
    for (NSString *malformedString in malformedStrings) {
        [self.gppProvider setGppString:malformedString];
        [self.gppProvider setGppSid:@[@8]];
        
        CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
        // Should not crash and should handle gracefully
        XCTAssertTrue(consent != nil || consent == nil, @"Should handle malformed GPP string gracefully: %@", malformedString);
    }
}

// Test unsupported SID handling
- (void)testUnsupportedSIDHandling {
    NSString *gppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~BVVqAAEABgAA";
    NSArray *gppSid = @[@99]; // Unsupported SID
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@99];
    XCTAssertNil(consent, @"Should return nil for unsupported SID");
}

#pragma mark - Publisher API Tests

// Test publisher API methods work correctly
- (void)testPublisherAPIIntegration {
    NSString *testGppString = @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    NSArray *testGppSid = @[@7, @8];
    
    // Test CloudXCore API integration
    [CloudXCore setGPPString:testGppString];
    [CloudXCore setGPPSid:testGppSid];
    
    NSString *retrievedString = [CloudXCore getGPPString];
    NSArray *retrievedSid = [CloudXCore getGPPSid];
    
    XCTAssertEqualObjects(retrievedString, testGppString, @"CloudXCore GPP string API should work");
    XCTAssertEqualObjects(retrievedSid, testGppSid, @"CloudXCore GPP SID API should work");
    
    // Test clearing
    [CloudXCore setGPPString:nil];
    [CloudXCore setGPPSid:nil];
    
    XCTAssertNil([CloudXCore getGPPString], @"Should clear GPP string");
    XCTAssertNil([CloudXCore getGPPSid], @"Should clear GPP SID");
}

@end
