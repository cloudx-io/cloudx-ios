//
//  CLXGPPIntegrationTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "CLXUserDefaultsTestHelper.h"

// Test category to expose internal methods for testing
@interface CLXPrivacyService (GPPTesting)
- (BOOL)shouldClearPersonalDataForCompliance; // Test compliance logic without ATT
@end

// Test category for geo service testing
@interface CLXGeoLocationService (GPPTesting)
- (BOOL)isUSUser;
- (BOOL)isCaliforniaUser;
@end

@interface CLXGPPIntegrationTests : XCTestCase
@property (nonatomic, strong) CLXPrivacyService *privacyService;
@property (nonatomic, strong) CLXGeoLocationService *geoService;
@property (nonatomic, strong) CLXConsentProvider *gppProvider;
@end

@implementation CLXGPPIntegrationTests

- (void)setUp {
    [super setUp];
    self.privacyService = [CLXPrivacyService sharedInstance];
    self.geoService = [CLXGeoLocationService shared];
    self.gppProvider = [CLXConsentProvider sharedInstance];
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
}

- (void)tearDown {
    [CLXUserDefaultsTestHelper clearAllCloudXCoreUserDefaultsKeys];
    [super tearDown];
}

#pragma mark - Core Test Cases from QA Requirements

// Test GPP absent should use standard data handling
- (void)testGPPAbsent_ShouldUseStandardDataHandling {
    // Clear all GPP data
    [self.gppProvider setGppString:nil];
    [self.gppProvider setGppSid:nil];
    
    // Set up as US user
    [self setupUSUser];
    
    // Test compliance logic without ATT dependency
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataForCompliance];
    XCTAssertFalse(shouldClear, @"Without GPP data, compliance logic should allow data");
}

// Test GPP CCPA consent should pass allowed personal data
- (void)testGPPCCPAConsent_ShouldPassAllowedPersonalData {
    // Set up GPP string with consent (allow all)
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7, @8]; // US-National and US-CA
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Set up as California user
    [self setupCaliforniaUser];
    
    // Test compliance logic - should allow data with consent
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataForCompliance];
    XCTAssertFalse(shouldClear, @"GPP consent should allow personal data");
}

// Test GPP CCPA opt-out should remove personal data
- (void)testGPPCCPAOptOut_ShouldRemovePersonalData {
    // Set up GPP string with opt-out flags (disallow all)
    NSString *gppString = @"DBABrw~BAAVAAAAAABA.QA~BAUAAABA.QA";
    NSArray *gppSid = @[@7, @8]; // US-National and US-CA
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Set up as California user
    [self setupCaliforniaUser];
    
    // Test compliance logic - should require data clearing with opt-out
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataForCompliance];
    XCTAssertTrue(shouldClear, @"GPP opt-out should require data clearing for California users");
}

// Test GPP Non-US users should have full data with no extra restrictions
- (void)testGPPNonUS_ShouldHaveFullDataNoRestrictions {
    // Set up GPP data (allow all)
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7, @8];
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Set up as non-US user
    [self setupNonUSUser];
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataForCompliance];
    XCTAssertFalse(shouldClear, @"Non-US users should have no additional restrictions");
}

// Test GPP US non-California should use US National consent
- (void)testGPPUSNonCalifornia_ShouldUseUSNationalConsent {
    // Set up GPP with US-National section (allow all)
    NSString *gppString = @"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA";
    NSArray *gppSid = @[@7]; // US-National only
    
    [self.gppProvider setGppString:gppString];
    [self.gppProvider setGppSid:gppSid];
    
    // Set up as US user but not California
    [self setupUSNonCaliforniaUser];
    
    BOOL shouldClear = [self.privacyService shouldClearPersonalDataForCompliance];
    XCTAssertFalse(shouldClear, @"US non-California users without GPP opt-out should allow data");
}

// Test geographic targeting logic
- (void)testGeographicTargeting {
    // Test US user detection
    [self setupUSUser];
    XCTAssertTrue([self.geoService isUSUser], @"Should detect US user correctly");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Non-California US user should not be detected as California");
    
    // Test California user detection
    [self setupCaliforniaUser];
    XCTAssertTrue([self.geoService isUSUser], @"California user should be detected as US user");
    XCTAssertTrue([self.geoService isCaliforniaUser], @"Should detect California user correctly");
    
    // Test non-US user detection
    [self setupNonUSUser];
    XCTAssertFalse([self.geoService isUSUser], @"Should detect non-US user correctly");
    XCTAssertFalse([self.geoService isCaliforniaUser], @"Non-US user should not be detected as California");
}

#pragma mark - Helper Methods

- (void)setupUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"TX"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

- (void)setupCaliforniaUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"CA"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

- (void)setupUSNonCaliforniaUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"USA",
        @"cloudfront-viewer-country-region": @"NY"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

- (void)setupNonUSUser {
    NSDictionary *geoHeaders = @{
        @"cloudfront-viewer-country-iso3": @"CAN",
        @"cloudfront-viewer-country-region": @"ON"
    };
    [[NSUserDefaults standardUserDefaults] setObject:geoHeaders forKey:kCLXCoreRawGeoHeadersKey];
}

@end
