//
//  CLXPrivacyConsentResolverTests.m
//  CloudXCoreTests
//
//  Created by CloudX Team.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXPrivacyConsentResolverTests : XCTestCase

@property (nonatomic, strong) CLXConsentProvider *provider;
@property (nonatomic, strong) NSUserDefaults *testDefaults;
@property (nonatomic, copy) NSString *testSuiteName;

@end

@implementation CLXPrivacyConsentResolverTests

- (void)setUp {
    [super setUp];
    self.testSuiteName = [[NSUUID UUID] UUIDString];
    self.testDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.testSuiteName];
    self.provider = [[CLXConsentProvider alloc] initWithErrorReporter:nil userDefaults:self.testDefaults];
}

- (void)tearDown {
    [self.testDefaults removePersistentDomainForName:self.testSuiteName];
    self.testDefaults = nil;
    self.testSuiteName = nil;
    [super tearDown];
}

#pragma mark - resolveIabGdprConsent

- (void)testResolveIabGdprConsent_NoSignals_ReturnsNil {
    NSNumber *result = [CLXPrivacyConsentResolver resolveIabGdprConsent:self.provider];
    XCTAssertNil(result, @"Should return nil when no IAB signals available");
}

- (void)testResolveIabGdprConsent_LegacyTCF_ReturnsResult {
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults setObject:@"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB" forKey:@"IABTCF_TCString"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabGdprConsent:self.provider];
    XCTAssertNotNil(result, @"Should resolve from legacy TCF");
}

- (void)testResolveIabGdprConsent_GdprAppliesFalse_ReturnsNil {
    [self.testDefaults setInteger:0 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabGdprConsent:self.provider];
    XCTAssertNil(result, @"Should return nil when gdprApplies is false");
}

- (void)testResolveIabGdprConsent_GdprAppliesTrueButNoTcString_ReturnsNil {
    [self.testDefaults setInteger:1 forKey:@"IABTCF_gdprApplies"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabGdprConsent:self.provider];
    XCTAssertNil(result, @"Should return nil when gdprApplies but no TC string");
}

- (void)testResolveIabGdprConsent_DoesNotFallBackToManual {
    // Verify that the resolver does NOT include manual fallback
    NSNumber *result = [CLXPrivacyConsentResolver resolveIabGdprConsent:self.provider];
    XCTAssertNil(result, @"IAB-only resolver should return nil, not fall back to manual");
}

#pragma mark - resolveIabUsPrivacyDoNotSell

- (void)testResolveIabUsPrivacyDoNotSell_NoString_ReturnsNil {
    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertNil(result, @"Should return nil when no US Privacy string");
}

- (void)testResolveIabUsPrivacyDoNotSell_OptOutY_ReturnsYES {
    [self.testDefaults setObject:@"1NYN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertEqualObjects(result, @YES, @"Should return YES for opt-out Y");
}

- (void)testResolveIabUsPrivacyDoNotSell_OptOutLowercaseY_ReturnsYES {
    [self.testDefaults setObject:@"1NyN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertEqualObjects(result, @YES, @"Should return YES for opt-out lowercase y");
}

- (void)testResolveIabUsPrivacyDoNotSell_NoOptOutN_ReturnsNO {
    [self.testDefaults setObject:@"1YNN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertEqualObjects(result, @NO, @"Should return NO for no opt-out N");
}

- (void)testResolveIabUsPrivacyDoNotSell_NoOptOutLowercaseN_ReturnsNO {
    [self.testDefaults setObject:@"1YnN" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertEqualObjects(result, @NO, @"Should return NO for no opt-out lowercase n");
}

- (void)testResolveIabUsPrivacyDoNotSell_Dash_ReturnsNil {
    [self.testDefaults setObject:@"1--N" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertNil(result, @"Should return nil for dash (not applicable)");
}

- (void)testResolveIabUsPrivacyDoNotSell_TooShort_ReturnsNil {
    [self.testDefaults setObject:@"1Y" forKey:@"IABUSPrivacy_String"];
    [self.testDefaults synchronize];

    NSNumber *result = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:self.testDefaults];
    XCTAssertNil(result, @"Should return nil when string too short");
}

@end
