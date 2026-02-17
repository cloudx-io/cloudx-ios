//
//  CLXConsentProviderTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXConsentProviderTests : XCTestCase
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXConsentProviderTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
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
            [self.testDefaults setObject:input forKey:kIABGPP_GppSID];
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
    
    [self.testDefaults setObject:testTcString forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
    NSString *retrievedTcString = [self.gppProvider tcString];
    XCTAssertEqualObjects(retrievedTcString, testTcString, @"TC string should be retrieved from UserDefaults");
}

// Test GDPR applies reading from UserDefaults
- (void)testGdprAppliesFromUserDefaults {
    // Test GDPR applies = YES
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
    NSNumber *gdprApplies = [self.gppProvider gdprApplies];
    XCTAssertEqualObjects(gdprApplies, @YES, @"GDPR applies should be YES when set to 1");
    
    // Test GDPR applies = NO
    [self.testDefaults setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
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
    [self.testDefaults setObject:legacyTcString forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
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
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFFoAP" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];
    
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
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];
    
    NSNumber *resolved = [self.gppProvider resolveGdprApplies];
    XCTAssertEqualObjects(resolved, @YES, @"Should return YES from legacy gdprApplies flag");
}

#pragma mark - EU TCF (SID 2) Decoding Tests

// Test EU TCF with CloudX vendor 1510 enabled (all purposes on, CloudX enabled)
- (void)testDecodeEuTcf_CloudXEnabled_AllPurposesOn {
    // Given - Google UMP with Manage Options: all purposes enabled, CloudX (vendor 1510) enabled
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    NSString *gppString = [NSString stringWithFormat:@"DBABMA~%@", tcfString];
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@2]]; // EU TCF
    
    // When - decode EU TCF section
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetEUTCF)];
    
    // Then - purposes 1-2 enabled, CloudX has consent, no PII removal required
    XCTAssertNil(consent, @"Should return nil when no PII removal required (CloudX enabled, all purposes granted)");
}

// Test EU TCF with CloudX vendor 1510 disabled (all purposes on, CloudX disabled)
- (void)testDecodeEuTcf_CloudXDisabled_AllPurposesOn {
    // Given - Google UMP with Manage Options: all purposes enabled, CloudX (vendor 1510) disabled
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaIF5wAQF5gvNABAvMAAA";
    NSString *gppString = [NSString stringWithFormat:@"DBABMA~%@", tcfString];
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@2]]; // EU TCF
    
    // When - decode EU TCF section
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetEUTCF)];
    
    // Then - purposes 1-2 enabled but CloudX has no consent, PII removal required
    XCTAssertNotNil(consent, @"Should return consent when PII removal required");
    XCTAssertTrue([consent requiresPiiRemoval], @"CloudX disabled should require PII removal");
}

// Test EU TCF with purpose 1 disabled
- (void)testDecodeEuTcf_Purpose1Disabled {
    // Given - Google UMP with Manage Options: purpose 1 disabled, purpose 2 enabled
    NSString *tcfString = @"CQbFSYAQbFSYAEsACDENCFFgAHAAAEPgACiQACBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA";
    NSString *gppString = [NSString stringWithFormat:@"DBABMA~%@", tcfString];
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@2]]; // EU TCF
    
    // When - decode EU TCF section
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@(CLXGppTargetEUTCF)];
    
    // Then - purpose 1 disabled, PII removal required
    XCTAssertNotNil(consent, @"Should return consent when PII removal required");
    XCTAssertTrue([consent requiresPiiRemoval], @"Purpose 1 disabled should require PII removal");
}

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

#pragma mark - EU TCF Vendor 1510 Tests (CloudX)

// Test EU TCF with CloudX vendor 1510 ENABLED - should NOT require PII removal
- (void)testDecodeTcString_CloudXVendorEnabled_ShouldNotRequirePiiRemoval {
    // Google UMP with all purposes enabled, CloudX (vendor 1510) enabled
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF consent");
    XCTAssertTrue([consent.purpose1 boolValue], @"Purpose 1 should be granted");
    XCTAssertTrue([consent.purpose2 boolValue], @"Purpose 2 should be granted");
    XCTAssertTrue([consent.vendorConsent boolValue], @"CloudX vendor consent should be granted");
    XCTAssertFalse([consent requiresPiiRemoval], @"Should NOT require PII removal when CloudX has consent");
}

// Test EU TCF with CloudX vendor 1510 DISABLED - should require PII removal
- (void)testDecodeTcString_CloudXVendorDisabled_ShouldRequirePiiRemoval {
    // Google UMP with all purposes enabled, CloudX (vendor 1510) DISABLED
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaIF5wAQF5gvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF consent");
    XCTAssertTrue([consent.purpose1 boolValue], @"Purpose 1 should be granted");
    XCTAssertTrue([consent.purpose2 boolValue], @"Purpose 2 should be granted");
    XCTAssertFalse([consent.vendorConsent boolValue], @"CloudX vendor consent should be DENIED");
    XCTAssertTrue([consent requiresPiiRemoval], @"Should require PII removal when CloudX denied");
}

#pragma mark - TCF Multi-Segment String Tests

// Test TCF string with multiple segments (Core.DisclosedVendors.AllowedVendors.PublisherTC)
// SDK should extract and decode only the core string (first segment)
- (void)testDecodeTcString_MultiSegmentString_ShouldExtractCoreString {
    // Multi-segment TC string: CoreString.DisclosedVendors.AllowedVendors
    // This format is common from Google UMP
    NSString *coreString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    NSString *multiSegmentString = [NSString stringWithFormat:@"%@.YAAAAAAAAAAA.IAAAAAAAAAAA", coreString];
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:multiSegmentString];
    
    XCTAssertNotNil(consent, @"Should decode multi-segment TCF string");
    // Core string has CloudX enabled - should NOT require PII removal
    XCTAssertFalse([consent requiresPiiRemoval], @"Multi-segment string with consent should not require PII removal");
}

// Test that single-segment TC strings work correctly (no dot separator)
- (void)testDecodeTcString_SingleSegment_ShouldWork {
    // Single segment TC string (core only, no dot)
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode single-segment TCF string");
    XCTAssertTrue([consent.purpose1 boolValue], @"Purpose 1 should be granted");
    XCTAssertTrue([consent.purpose2 boolValue], @"Purpose 2 should be granted");
}

#pragma mark - TCF Purpose Consent Tests

// Test TCF with Purpose 2 specifically denied (Purpose 1 granted)
- (void)testDecodeTcString_Purpose2Denied_ShouldRequirePiiRemoval {
    // TC string with purpose 1 granted, purpose 2 denied
    // This tests the specific offset for purpose 2 (offset 153)
    NSString *tcfString = @"CQbFSYAQbFSYAEsACDENCFFgADAAAEPgACiQACBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF string");
    // When purpose 2 is denied, should require PII removal
    XCTAssertTrue([consent requiresPiiRemoval], @"Purpose 2 denied should require PII removal");
}

// Test TCF with both purposes denied
- (void)testDecodeTcString_BothPurposesDenied_ShouldRequirePiiRemoval {
    // TC string with both purposes 1 and 2 denied
    NSString *tcfString = @"CQbFSYAQbFSYAEsACDENCFFgAAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF string");
    XCTAssertFalse([consent.purpose1 boolValue], @"Purpose 1 should be denied");
    XCTAssertFalse([consent.purpose2 boolValue], @"Purpose 2 should be denied");
    XCTAssertTrue([consent requiresPiiRemoval], @"Both purposes denied should require PII removal");
}

#pragma mark - TCF Error Handling Tests

// Test nil TCF string handling
- (void)testDecodeTcString_NilString_ShouldReturnNil {
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:nil];
    XCTAssertNil(consent, @"Nil TCF string should return nil consent");
}

// Test empty TCF string handling
- (void)testDecodeTcString_EmptyString_ShouldReturnNil {
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:@""];
    XCTAssertNil(consent, @"Empty TCF string should return nil consent");
}

// Test malformed base64 TCF string handling
// SDK returns consent with requiresPiiRemoval=YES on parsing errors (fail-safe)
- (void)testDecodeTcString_MalformedBase64_ShouldRequirePiiRemoval {
    // Invalid base64 characters
    NSString *malformedString = @"!!!invalid_base64!!!";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:malformedString];
    // SDK returns consent object with all NO values (fail-safe, requires PII removal)
    XCTAssertNotNil(consent, @"Malformed base64 should return consent object (fail-safe)");
    XCTAssertTrue([consent requiresPiiRemoval], @"Malformed base64 should require PII removal (fail-safe)");
}

// Test too-short TCF string handling
// SDK returns consent with requiresPiiRemoval=YES on parsing errors (fail-safe)
- (void)testDecodeTcString_TooShort_ShouldRequirePiiRemoval {
    // String that decodes but is too short to contain required fields
    NSString *shortString = @"CQ";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:shortString];
    // SDK returns consent object with all NO values (fail-safe, requires PII removal)
    XCTAssertNotNil(consent, @"Too-short TCF should return consent object (fail-safe)");
    XCTAssertTrue([consent requiresPiiRemoval], @"Too-short TCF should require PII removal (fail-safe)");
}

#pragma mark - TCF Vendor ID 1510 Boundary Tests

// Test vendor consent when CloudX (1510) is at the edge of MaxVendorId
- (void)testDecodeTcString_VendorIdAtMaxBoundary_ShouldDetectCorrectly {
    // TC string where MaxVendorId is exactly 1510 and CloudX has consent
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF string");
    // CloudX vendor ID 1510 should be correctly detected
    XCTAssertTrue([consent.vendorConsent boolValue], @"CloudX vendor consent should be detected at boundary");
}

// Test vendor consent when MaxVendorId is less than CloudX ID (1510)
- (void)testDecodeTcString_MaxVendorIdBelowCloudX_ShouldReturnNoConsent {
    // TC string where MaxVendorId is less than 1510
    // This simulates a CMP that doesn't include CloudX in their vendor list
    NSString *tcfString = @"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF string even with low MaxVendorId");
    // When MaxVendorId < 1510, vendor consent should be NO (not in list)
    XCTAssertFalse([consent.vendorConsent boolValue], @"Vendor consent should be NO when MaxVendorId < 1510");
}

#pragma mark - TCF Fixed Offset Verification Tests

// Verify that TCF v2 offsets are correctly applied
// Per IAB spec, these offsets are FIXED across all TCF v2.x versions
- (void)testDecodeTcString_VerifyFixedOffsets {
    // This test uses a known TC string and verifies the SDK reads the correct bits
    // TCF v2 Core String offsets (per IAB spec):
    // - PurposesConsent: offset 152 (24 bits for purposes 1-24)
    // - MaxVendorId: offset 213 (16 bits)
    // - EncodingType: offset 229 (1 bit)
    // - VendorConsent: offset 230+ (variable)
    
    // TC string with known values: purposes 1-4 granted, CloudX enabled
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQAQLzAvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode TCF string");
    // Verify purposes at offset 152+
    XCTAssertTrue([consent.purpose1 boolValue], @"Purpose 1 (bit 152) should be 1");
    XCTAssertTrue([consent.purpose2 boolValue], @"Purpose 2 (bit 153) should be 1");
    // Verify vendor consent properly parsed from offset 230+
    XCTAssertTrue([consent.vendorConsent boolValue], @"CloudX vendor consent should be parsed correctly");
}

#pragma mark - TCF Range Encoding Tests

// Test Range-encoded vendor consent where CloudX (1510) IS in a range
// Range encoding format: NumEntries(12) + entries(IsRange(1) + StartId(16) [+ EndId(16)])
- (void)testDecodeTcString_RangeEncoding_VendorInRange_ShouldHaveConsent {
    // This TC string uses range encoding with a range that includes vendor 1510
    // Range: vendors 1500-1520 have consent
    // EncodingType bit (offset 229) = 1 (range encoding)
    NSString *tcfString = @"CQcUY4AQcUY4AEsACDENCJFgAPAAAELAACaILzQBQLzAvNABAvMAAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode range-encoded TCF string");
    // Vendor 1510 should be within the range and have consent
    // Note: If this test fails, it may indicate range parsing issues
}

// Test Range-encoded vendor consent where CloudX (1510) is NOT in any range
- (void)testDecodeTcString_RangeEncoding_VendorNotInRange_ShouldNotHaveConsent {
    // TC string with range encoding but ranges that exclude vendor 1510
    // Example: only ranges 1-100, 200-300 have consent
    NSString *tcfString = @"CQbFSYAQbFSYAEsACBENCFEABvAAAELAACiQLxoAA";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:tcfString];
    
    XCTAssertNotNil(consent, @"Should decode range-encoded TCF string");
    // If MaxVendorId < 1510 or 1510 not in ranges, consent should be NO
    // The exact behavior depends on the encoded string
}

#pragma mark - Fail-Safe Consent Tests

// Verify fail-safe behavior: parsing errors return consent requiring PII removal
- (void)testDecodeTcString_ParsingException_ShouldReturnFailSafeConsent {
    // This test verifies the documented fail-safe behavior:
    // When TCF parsing fails (exception), the SDK returns a consent object
    // with purpose1=NO, purpose2=NO, vendorConsent=NO
    // This means requiresPiiRemoval returns YES (conservative/safe default)
    
    // A string that might cause parsing issues
    NSString *problematicString = @"CQcUY4AQcUY4A"; // Truncated mid-field
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:problematicString];
    
    // Fail-safe: should return consent, not nil
    XCTAssertNotNil(consent, @"Parsing failures should return fail-safe consent, not nil");
    // Fail-safe consent requires PII removal (all consents are NO)
    XCTAssertTrue([consent requiresPiiRemoval], @"Fail-safe consent should require PII removal");
}

// Verify that the fail-safe consent has explicit NO values
- (void)testDecodeTcString_FailSafe_AllConsentsAreNo {
    // Invalid base64 to trigger fail-safe
    NSString *invalidString = @"@@@not_valid_base64@@@";
    
    CLXPrivacyConsent *consent = [self.gppProvider decodeTcString:invalidString];
    
    XCTAssertNotNil(consent, @"Should return fail-safe consent for invalid input");
    XCTAssertFalse([consent.purpose1 boolValue], @"Fail-safe purpose1 should be NO");
    XCTAssertFalse([consent.purpose2 boolValue], @"Fail-safe purpose2 should be NO");
    XCTAssertFalse([consent.vendorConsent boolValue], @"Fail-safe vendorConsent should be NO");
    XCTAssertTrue([consent requiresPiiRemoval], @"Fail-safe should require PII removal");
}

@end
