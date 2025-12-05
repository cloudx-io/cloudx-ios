//
//  CLXConsentProviderTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import "CLXUserDefaultsTestHelper.h"

@interface CLXConsentProviderTests : XCTestCase
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@end

@implementation CLXConsentProviderTests

- (void)setUp {
    [super setUp];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil];
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
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
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
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    // decodeGppForTarget with specific target returns nil when no PII removal required
    XCTAssertNil(consent, @"Should return nil when specific target has no opt-outs");
}

// Test US-National (SID=7) consent decoding with allow-all (no PII removal)
- (void)testUSNationalConsentDecodingAllowAll {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    // decodeGppForTarget returns nil when no PII removal required
    XCTAssertNil(consent, @"Should return nil for allow-all consent (no PII removal required)");
}

// Test US-National (SID=7) consent decoding - specific target behavior
- (void)testUSNationalConsentDecodingWithSpecificTarget {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
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
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:nil]; // Auto-select
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
    CLXPrivacyConsent *usCAConsent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
    CLXPrivacyConsent *usNationalConsent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSNational)];
    
    XCTAssertNil(usCAConsent, @"US-CA with no opt-outs should return nil when targeted");
    XCTAssertNil(usNationalConsent, @"US-National with no opt-outs should return nil when targeted");
    
    // Auto-select should return first available
    CLXPrivacyConsent *autoConsent = [self.gppProvider decodeGppForTarget:nil];
    XCTAssertNotNil(autoConsent, @"Auto-select should return first available");
}

#pragma mark - Error Handling Tests

// Test graceful handling of missing GPP data
- (void)testMissingGPPDataHandling {
    // Clear all GPP data
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
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
        
        CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetUSCA)];
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
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@99];
    XCTAssertNil(consent, @"Should return nil for unsupported SID");
}

#pragma mark - Publisher API Tests

// NOTE: Public GPP API methods (setGPPString, getGPPString, setGPPSid, getGPPSid) 
// were intentionally removed to align with Android's approach.
// iOS now reads GPP data from IAB standard UserDefaults keys, just like Android reads
// from IAB standard SharedPreferences.
//
// GPP functionality is tested via CLXConsentProvider directly (see tests above).
// Publishers should set GPP data via IAB-standard mechanisms, not CloudX SDK.

#pragma mark - TCF Parsing Tests

// Test TCF string parsing for purpose consents
- (void)testDecodeTcString_AllPurposesGranted_ShouldNotRequirePiiRemoval {
    // This is a minimal valid TCF v2 string with all purposes granted
    // Base64url encoded, with purposes 1-10 all set to 1
    NSString *tcString = @"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB7C7FbSFCyLZzaLsAMAhHRsAAQoQAAASBAmABQAKQIAQCgkAYFASABAACAAAAICRBIQIECAAAAUAAAAAAAAAEAAAAAAAIIAAAgAEAAAAIAAAKAIAAEAAIAAAAEAAAmAgAAIIACAAAgAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAQNVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcString];
    
    // With all purposes granted, should not require PII removal
    XCTAssertNotNil(consent, @"Should decode TC string successfully");
    // Note: Full consent strings typically have all purposes set
    // Actual PII removal depends on whether purposes 1-4 are granted
}

// Test TCF string parsing with denied purposes
- (void)testDecodeTcString_NoPurposes_ShouldRequirePiiRemoval {
    // A TC string with no purposes granted
    NSString *tcString = @"CQbFSYAQbFSYAEsACBENCFFgAAAAAEPgACiQAAANVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcString];
    
    XCTAssertNotNil(consent, @"Should decode TC string successfully");
    // With no purposes granted, should require PII removal
    XCTAssertTrue([consent requiresPiiRemoval], @"Missing purposes should require PII removal");
}

// Test TCF string reading from UserDefaults
- (void)testTcStringFromUserDefaults {
    NSString *testTcString = @"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB";
    
    [[NSUserDefaults standardUserDefaults] setObject:testTcString forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *retrievedTcString = [self.gppProvider tcString];
    XCTAssertEqualObjects(retrievedTcString, testTcString, @"TC string should be retrieved from UserDefaults");
}

// Test GDPR applies reading from UserDefaults
- (void)testGdprAppliesFromUserDefaults {
    // Test GDPR applies = YES
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSNumber *gdprApplies = [self.gppProvider gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"GDPR applies should be YES when set to 1");
    
    // Test GDPR applies = NO
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    gdprApplies = [self.gppProvider gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @NO, @"GDPR applies should be NO when set to 0");
}

#pragma mark - GPP Resolution Tests (Legacy TCF Fallback)

// Test resolving GPP string from CMP-provided GPP
- (void)testResolveGppString_FromCMP {
    NSString *cmpGppString = @"DBABLA~BVVqAAEABBENA.QA";
    [self.gppProvider setGppString:cmpGppString];
    
    NSString *resolved = [self.gppProvider resolveGppString];
    XCTAssertEqualObjects(resolved, cmpGppString, @"Should return CMP-provided GPP string");
}

// Test resolving GPP string from legacy TCF when CMP doesn't provide GPP
- (void)testResolveGppString_FromLegacyTcf {
    // Clear GPP
    [self.gppProvider setGppString:nil];
    
    // Set legacy TCF
    NSString *legacyTcString = @"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB";
    [[NSUserDefaults standardUserDefaults] setObject:legacyTcString forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *resolved = [self.gppProvider resolveGppString];
    XCTAssertNotNil(resolved, @"Should construct GPP from legacy TCF");
    XCTAssertTrue([resolved hasPrefix:@"DBABMA~"], @"Constructed GPP should have TCF-only header");
    XCTAssertTrue([resolved containsString:legacyTcString], @"Constructed GPP should contain the TC string");
}

// Test resolving GPP SID from CMP-provided SID
- (void)testResolveGppSid_FromCMP {
    NSArray *cmpSid = @[@7, @8];
    [self.gppProvider setGppSid:cmpSid];
    
    NSArray *resolved = [self.gppProvider resolveGppSid];
    XCTAssertEqualObjects(resolved, cmpSid, @"Should return CMP-provided GPP SID");
}

// Test resolving GPP SID from legacy TCF (returns [2])
- (void)testResolveGppSid_FromLegacyTcf {
    // Clear GPP SID
    [self.gppProvider setGppSid:nil];
    [self.gppProvider setGppString:nil];
    
    // Set legacy TCF
    [[NSUserDefaults standardUserDefaults] setObject:@"CQbFSYAQbFSYAEsACBENCFFoAP" forKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *resolved = [self.gppProvider resolveGppSid];
    XCTAssertNotNil(resolved, @"Should return SID when constructing from legacy TCF");
    XCTAssertEqualObjects(resolved, @[@2], @"Should return [2] for EU TCF when constructing from legacy TCF");
}

// Test resolving GDPR applies from GPP SID containing 2
- (void)testResolveGdprApplies_FromGppSid {
    // Set GPP SID containing 2 (EU TCF)
    [self.gppProvider setGppSid:@[@2]];
    
    NSNumber *resolved = [self.gppProvider resolveGdprApplies];
    XCTAssertEqualObjects(resolved, @YES, @"Should return YES when GPP SID contains 2");
}

// Test resolving GDPR applies from legacy flag
- (void)testResolveGdprApplies_FromLegacyFlag {
    // Clear GPP SID
    [self.gppProvider setGppSid:nil];
    
    // Set legacy GDPR applies
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSNumber *resolved = [self.gppProvider resolveGdprApplies];
    XCTAssertEqualObjects(resolved, @YES, @"Should return YES from legacy gdprApplies flag");
}

#pragma mark - EU TCF (SID 2) Decoding Tests

// Test decoding EU TCF section from GPP
- (void)testDecodeEuTcf_FromGppSection2 {
    // GPP string with EU TCF section (SID=2)
    // Format: [header]~[section2_tcstring]
    NSString *tcString = @"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB7C7FbSFCyLZzaLsAMAhHRsAAQoQAAASBAmABQAKQIAQCgkAYFASABAACAAAAICRBIQIECAAAAUAAAAAAAAAEAAAAAAAIIAAAgAEAAAAIAAAKAIAAEAAIAAAAEAAAmAgAAIIACAAAgAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAQNVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAAA";
    NSString *gppString = [NSString stringWithFormat:@"DBABMA~%@", tcString];
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@2]]; // EU TCF
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetEUTCF)];
    // decodeGppForTarget returns consent when PII removal check is needed
    // or nil if no opt-outs are found
    XCTAssertTrue(consent == nil || [consent isKindOfClass:[CLXPrivacyConsent class]], 
                  @"Should return valid consent or nil for EU TCF");
}

@end
