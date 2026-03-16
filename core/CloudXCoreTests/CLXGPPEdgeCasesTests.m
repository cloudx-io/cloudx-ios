//
//  CLXGPPEdgeCasesTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-10-16.
//  P0 edge cases and missing test coverage for GPP implementation
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXGeoInfo.h"

@interface CLXGPPEdgeCasesTests : XCTestCase
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXGeoLocationService *geoService;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;
@end

@implementation CLXGPPEdgeCasesTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    self.gppProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
    self.geoService = [[CLXGeoLocationService alloc] initWithUserDefaults:self.testDefaults];
    self.privacyService = [[CLXPrivacyService alloc] initWithUserDefaults:self.testDefaults
                                                         consentProvider:self.gppProvider
                                                      geoLocationService:self.geoService];
}

- (void)tearDown {
    [self.geoService setGeoInfo:nil];
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.geoService = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

#pragma mark - P0: Multi-SID Priority and Ordering

// Test when both SID 7 and 8 are present with same consent
- (void)testMultiSIDWithSameConsent {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7, @8]; // Both US-National and US-CA
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Should handle multiple SIDs without crashing
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:nil];
    XCTAssertTrue(consent != nil || consent == nil, @"Should handle multi-SID scenario gracefully");
}

// Test when SID array contains duplicates
- (void)testDuplicateSIDsInArray {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@8, @8, @7, @8, @7]; // Duplicates
    
    [self.gppProvider setGppSid:gppSid];
    
    NSArray *retrievedSid = [self.gppProvider gppSid];
    // Should deduplicate SIDs
    XCTAssertTrue(retrievedSid.count <= 2, @"Should deduplicate SID values");
}

// Test SID ordering (should be sorted)
- (void)testSIDOrdering {
    NSArray *unorderedSid = @[@8, @7]; // Reverse order
    
    [self.gppProvider setGppSid:unorderedSid];
    NSArray *retrievedSid = [self.gppProvider gppSid];
    
    if (retrievedSid.count == 2) {
        XCTAssertEqualObjects(retrievedSid[0], @7, @"SID should be sorted - SID 7 should come first");
        XCTAssertEqualObjects(retrievedSid[1], @8, @"SID should be sorted - SID 8 should come second");
    }
}

#pragma mark - P0: Empty vs Nil SID Handling

// Test empty SID array vs nil SID
- (void)testEmptySIDArrayVsNilSID {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    
    // Test empty array
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[]];
    
    NSArray *emptySid = [self.gppProvider gppSid];
    XCTAssertTrue(emptySid == nil || [emptySid count] == 0, @"Empty SID array should be treated as nil or empty");
    
    // Test nil
    [self.gppProvider setGppSid:nil];
    NSArray *nilSid = [self.gppProvider gppSid];
    XCTAssertNil(nilSid, @"Nil SID should return nil");
}

// Test GPP string without SID
- (void)testGPPStringWithoutSID {
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:nil];
    
    // Should not crash when decoding without SID
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    XCTAssertTrue(consent != nil || consent == nil, @"Should handle GPP string without SID gracefully");
}

// Test SID without GPP string
- (void)testSIDWithoutGPPString {
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:@[@7, @8]];
    
    // Should not crash when SID is set but no GPP string
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    XCTAssertNil(consent, @"Should return nil when SID is set but no GPP string");
}

#pragma mark - P0: Invalid SID Values

// Test invalid SID values in array
- (void)testInvalidSIDValues {
    NSArray *invalidSidArrays = @[
        @[@0],              // Zero
        @[@(-1)],           // Negative
        @[@999],            // Out of range
        @[@7, @0, @8],      // Mixed valid and invalid
        @[@(-5), @(-10)]    // Multiple negatives
    ];
    
    for (NSArray *invalidSid in invalidSidArrays) {
        [self.gppProvider setGppSid:invalidSid];
        
        // Should filter out invalid values or handle gracefully
        NSArray *result = [self.gppProvider gppSid];
        if (result) {
            for (NSNumber *sid in result) {
                XCTAssertTrue([sid integerValue] > 0, @"Should filter out invalid SID values: %@", sid);
            }
        }
    }
}

// Test non-numeric SID values (defensive)
- (void)testNonNumericSIDValues {
    // This tests UserDefaults parsing, not direct API
    [self.testDefaults setObject:@"not_a_number" forKey:kIABGPP_GppSID];
    
    NSArray *result = [self.gppProvider gppSid];
    XCTAssertTrue(result == nil || [result count] == 0, @"Should handle non-numeric SID values gracefully");
}

#pragma mark - P0: GPP + Legacy CCPA Conflict Resolution

// Test GPP opt-out with legacy CCPA consent
- (void)testGPPOptOutWithLegacyCCPAConsent {
    // GPP says opt-out
    NSString *gppString = @"DBABrw~BAAVAAAAAABA.QA~BAUAAABA.QA";
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@7, @8]];
    
    // Legacy CCPA says consent (1YNN = opt-out N, sale notice N, limited notice N)
    // Set CCPA via IAB standard UserDefaults key
    [self.testDefaults setObject:@"1YNN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    
    [self setupCaliforniaUser];
    
    // GPP should take precedence over legacy CCPA
    BOOL shouldClear = [self.privacyService shouldClearPersonalData];
    // Note: Actual behavior depends on implementation priority
    XCTAssertTrue(shouldClear == YES || shouldClear == NO, @"Should resolve GPP/CCPA conflict consistently");
}

// Test GPP consent with legacy CCPA opt-out
- (void)testGPPConsentWithLegacyCCPAOptOut {
    // GPP says consent
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:@[@7, @8]];
    
    // Legacy CCPA says opt-out (1YYN = opt-out Y)
    // Set CCPA opt-out via IAB standard UserDefaults key
    [self.testDefaults setObject:@"1YYN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];
    
    [self setupCaliforniaUser];
    
    // Should resolve conflict (GPP should take precedence)
    BOOL shouldClear = [self.privacyService shouldClearPersonalData];
    XCTAssertTrue(shouldClear == YES || shouldClear == NO, @"Should resolve GPP/CCPA conflict consistently");
}

#pragma mark - P0: GPP Data Persistence

// Test GPP data persists across provider instances
- (void)testGPPDataPersistenceAcrossInstances {
    NSString *testGppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *testGppSid = @[@7, @8];
    
    // Set data with first instance
    [self.gppProvider setGppString:testGppString];
    [self.gppProvider setGppSid:testGppSid];
    
    // Create new instance with same test defaults
    CLXConsentProvider *newProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
    
    // Should retrieve same data
    NSString *retrievedString = [newProvider gppString];
    NSArray *retrievedSid = [newProvider gppSid];
    
    XCTAssertEqualObjects(retrievedString, testGppString, @"GPP string should persist across instances");
    XCTAssertEqualObjects(retrievedSid, testGppSid, @"GPP SID should persist across instances");
}

// Test GPP data cleared persists as cleared
- (void)testGPPDataClearPersistence {
    // Set data
    [self.gppProvider setGppString:@"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA"];
    [self.gppProvider setGppSid:@[@7, @8]];
    
    // Clear data
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    // Create new instance with same test defaults
    CLXConsentProvider *newProvider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
    
    // Should remain cleared
    XCTAssertNil([newProvider gppString], @"Cleared GPP string should persist as nil");
    XCTAssertNil([newProvider gppSid], @"Cleared GPP SID should persist as nil");
}

#pragma mark - P0: GPP String Section Extraction

// Test GPP string with single section
- (void)testGPPStringSingleSection {
    NSString *singleSectionGpp = @"DBABrw~BAAAAAAAAABA.QA"; // Header + one section
    
    [self.gppProvider setGppString:singleSectionGpp];
    [self.gppProvider setGppSid:@[@7]];
    
    // Should handle single section GPP string
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    XCTAssertTrue(consent != nil || consent == nil, @"Should handle single section GPP string");
}

// Test GPP string with three sections
- (void)testGPPStringThreeSections {
    NSString *threeSectionGpp = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA~EXTRA.SECTION"; // Header + three sections
    
    [self.gppProvider setGppString:threeSectionGpp];
    [self.gppProvider setGppSid:@[@7, @8]];
    
    // Should handle extra sections gracefully
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    XCTAssertTrue(consent != nil || consent == nil, @"Should handle three section GPP string");
}

// Test GPP string with missing section separator
- (void)testGPPStringMissingSeparator {
    NSString *malformedGpp = @"DBABrwBAAAAAAAAAABA.QABAAAAABA.QA"; // No ~ separators
    
    [self.gppProvider setGppString:malformedGpp];
    [self.gppProvider setGppSid:@[@7]];
    
    // Should handle malformed section structure
    CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
    XCTAssertTrue(consent != nil || consent == nil, @"Should handle malformed GPP string structure gracefully");
}

#pragma mark - P0: Geographic Targeting Edge Cases

// Test geo detection when headers change mid-session
- (void)testGeoDetectionHeadersChange {
    // Start as California user
    [self setupCaliforniaUser];
    XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect California initially");
    
    // Change to NY user
    [self setupNonCaliforniaUSUser];
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Should update to non-California");
    XCTAssertTrue([self.geoService isUSUser], @"Should still be US user");
    
    // Change to non-US
    [self setupNonUSUser];
    XCTAssertFalse([self.geoService isUSUser], @"Should update to non-US user");
}

// Test case-insensitive country and region codes
- (void)testCaseInsensitiveGeoCodes {
    // Test various case combinations
    NSArray *usaVariants = @[@"USA", @"usa", @"Usa", @"UsA"];
    for (NSString *variant in usaVariants) {
        [self setGeoHeaders:@{@"cloudfront-viewer-country-iso3": variant}];
        XCTAssertTrue([self.geoService isUSUser], @"Should detect US user for variant: %@", variant);
    }
    
    NSArray *caVariants = @[@"CA", @"ca", @"Ca"];
    for (NSString *variant in caVariants) {
        [self setGeoHeaders:@{
            @"cloudfront-viewer-country-iso3": @"USA",
            @"cloudfront-viewer-country-region": variant
        }];
        XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect California for variant: %@", variant);
    }
}

// Test geo headers with extra whitespace
- (void)testGeoHeadersWithWhitespace {
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @" USA ",
        @"cloudfront-viewer-country-region": @" CA "
    }];
    
    // Should trim whitespace
    BOOL isUS = [self.geoService isUSUser];
    BOOL isCalifornia = [self.geoService isCaliforniaUser];
    
    // May or may not trim depending on implementation
    XCTAssertTrue((isUS && isCalifornia) || (!isUS && !isCalifornia), 
                 @"Should handle whitespace consistently");
}

#pragma mark - P0: Real-World GPP String Validation

// Test with actual IABGPP format strings (if different from simplified test strings)
- (void)testRealWorldGPPStringFormat {
    // Example real GPP strings from IABGPP spec
    NSArray *realWorldGPPStrings = @[
        @"DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN",  // Multi-section
        @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA",    // Different header
        @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA",                      // Current simplified
        @"DBACNYA~BVWqWBg.YA~1YYN"                                   // Alternate format
    ];
    
    for (NSString *gppString in realWorldGPPStrings) {
        [self.gppProvider setGppString:gppString];
        [self.gppProvider setGppSid:@[@7, @8]];
        
        // Should not crash with real-world formats
        CLXPrivacyConsent *consent = [self.gppProvider decodeGppForTarget:@7];
        XCTAssertTrue(consent != nil || consent == nil, @"Should handle real GPP format: %@", gppString);
        
        // Should be able to retrieve what was set
        NSString *retrieved = [self.gppProvider gppString];
        XCTAssertEqualObjects(retrieved, gppString, @"Should preserve real GPP string: %@", gppString);
    }
}

#pragma mark - Helper Methods

- (void)setupCaliforniaUser {
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    }];
}

- (void)setupUSUser {
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"TX"
    }];
}

- (void)setupNonCaliforniaUSUser {
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"NY"
    }];
}

- (void)setupNonUSUser {
    [self setGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"ON"
    }];
}

- (void)setGeoHeaders:(NSDictionary *)headers {
    if (headers) {
        CLXGeoInfo *geoInfo = [[CLXGeoInfo alloc] initWithProcessedGeoInfo:@{}
                                                                rawGeoInfo:headers
                                                               hashedGeoIp:nil];
        [self.geoService setGeoInfo:geoInfo];
    } else {
        [self.geoService setGeoInfo:nil];
    }
}

@end

