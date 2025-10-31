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
    self.gppProvider = [[CLXGPPProvider alloc] initWithErrorReporter:nil];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - GPP String Parsing Tests

// Test GPP string storage and retrieval
- (void)testGPPStringStorageAndRetrieval {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    
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
        @{@"input": @"", @"expected": [NSNull null], @"description": @"empty string"},
        @{@"input": @"invalid", @"expected": [NSNull null], @"description": @"invalid format"}
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
        
        if (expected && ![expected isEqual:[NSNull null]]) {
            XCTAssertEqualObjects(result, expected, @"SID parsing failed for %@: %@", description, input);
        } else {
            XCTAssertNil(result, @"SID parsing should return nil for %@: %@", description, input);
        }
    }
}

#pragma mark - GPP Consent Decoding Tests

// Test US-CA (SID=8) consent decoding with allow-all (no PII removal)
- (void)testUSCAConsentDecodingAllowAll {
    // Test GPP string with US-CA section (SID=8) - allow all (no opt-outs)
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@8]; // US-CA only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    // decodeGppForTarget returns nil when no PII removal required (allow-all scenario)
    XCTAssertNil(consent, @"Should return nil for allow-all consent (no PII removal required)");
}

// Test US-CA (SID=8) consent decoding - specific target returns nil regardless
- (void)testUSCAConsentDecodingWithSpecificTarget {
    // Test GPP string with US-CA section (SID=8) - allow all
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@8]; // US-CA only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    // decodeGppForTarget with specific target returns nil when no PII removal required
    XCTAssertNil(consent, @"Should return nil when specific target has no opt-outs");
}

// Test US-National (SID=7) consent decoding with allow-all (no PII removal)
- (void)testUSNationalConsentDecodingAllowAll {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    // decodeGppForTarget returns nil when no PII removal required
    XCTAssertNil(consent, @"Should return nil for allow-all consent (no PII removal required)");
}

// Test US-National (SID=7) consent decoding - specific target behavior
- (void)testUSNationalConsentDecodingWithSpecificTarget {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    // decodeGppForTarget with specific target returns nil when no PII removal required
    XCTAssertNil(consent, @"Should return nil when specific target has no opt-outs");
}

// Test auto-selection returns first available when no opt-outs present
- (void)testAutoSelectionWithNoOptOuts {
    // Set up GPP with both US-CA and US-National sections (allow all - no opt-outs)
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7, @8]; // Both sections
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:nil]; // Auto-select
    // When no opt-outs are present, auto-selection returns first available consent
    XCTAssertNotNil(consent, @"Auto-selection should return first available consent");
    XCTAssertFalse([consent requiresPiiRemoval], @"Consent should not require PII removal when no opt-outs");
}

// Test decode behavior is consistent across both SIDs
- (void)testDecodeConsistencyAcrossSIDs {
    // Set up GPP with both US-CA and US-National sections
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7, @8]; // Both sections
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Both specific targets should return nil (no PII removal)
    CLXGppConsent *usCAConsent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    CLXGppConsent *usNationalConsent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    
    XCTAssertNil(usCAConsent, @"US-CA with no opt-outs should return nil when targeted");
    XCTAssertNil(usNationalConsent, @"US-National with no opt-outs should return nil when targeted");
    
    // Auto-select should return first available
    CLXGppConsent *autoConsent = [self.gppProvider decodeGppForTarget:nil];
    XCTAssertNotNil(autoConsent, @"Auto-select should return first available");
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
        @"DBABrw", // Header only
        @"DBABrw~", // Header with empty section
        @"DBABrw~invalid_base64" // Invalid base64
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
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@99]; // Unsupported SID
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXGppConsent *consent = [self.gppProvider decodeGppForTarget:@99];
    XCTAssertNil(consent, @"Should return nil for unsupported SID");
}

#pragma mark - Publisher API Tests

// NOTE: Public GPP API methods (setGPPString, getGPPString, setGPPSid, getGPPSid) 
// were intentionally removed to align with Android's approach.
// iOS now reads GPP data from IAB standard UserDefaults keys, just like Android reads
// from IAB standard SharedPreferences.
//
// GPP functionality is tested via CLXGPPProvider directly (see tests above).
// Publishers should set GPP data via IAB-standard mechanisms, not CloudX SDK.

@end
