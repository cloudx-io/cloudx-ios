//
//  CLXGppConsentTests.m
//  CloudXCoreTests
//
//  Created by CloudX on 2025-09-12.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXGppConsentTests : XCTestCase
@end

@implementation CLXGppConsentTests

#pragma mark - Consent Model Tests

// Test PII removal logic with various opt-out combinations
- (void)testRequiresPiiRemovalLogic {
    // Test sale opt-out active (value = 1)
    CLXGppConsent *saleOptOut = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:@0];
    XCTAssertTrue([saleOptOut requiresPiiRemoval], @"Sale opt-out should require PII removal");
    
    // Test sharing opt-out active (value = 1)
    CLXGppConsent *sharingOptOut = [[CLXGppConsent alloc] initWithSaleOptOut:@0 sharingOptOut:@1];
    XCTAssertTrue([sharingOptOut requiresPiiRemoval], @"Sharing opt-out should require PII removal");
    
    // Test both opt-outs active
    CLXGppConsent *bothOptOut = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:@1];
    XCTAssertTrue([bothOptOut requiresPiiRemoval], @"Both opt-outs should require PII removal");
    
    // Test no opt-outs (value = 0 or 2)
    CLXGppConsent *noOptOut = [[CLXGppConsent alloc] initWithSaleOptOut:@0 sharingOptOut:@2];
    XCTAssertFalse([noOptOut requiresPiiRemoval], @"No opt-outs should not require PII removal");
    
    // Test N/A values (value = 0)
    CLXGppConsent *naValues = [[CLXGppConsent alloc] initWithSaleOptOut:@0 sharingOptOut:@0];
    XCTAssertFalse([naValues requiresPiiRemoval], @"N/A values should not require PII removal");
    
    // Test nil values
    CLXGppConsent *nilValues = [[CLXGppConsent alloc] initWithSaleOptOut:nil sharingOptOut:nil];
    XCTAssertFalse([nilValues requiresPiiRemoval], @"Nil values should not require PII removal");
}

// Test consent initialization and properties
- (void)testConsentInitialization {
    NSNumber *saleOptOut = @1;
    NSNumber *sharingOptOut = @2;
    
    CLXGppConsent *consent = [[CLXGppConsent alloc] initWithSaleOptOut:saleOptOut sharingOptOut:sharingOptOut];
    
    XCTAssertEqualObjects(consent.saleOptOut, saleOptOut, @"Sale opt-out should be set correctly");
    XCTAssertEqualObjects(consent.sharingOptOut, sharingOptOut, @"Sharing opt-out should be set correctly");
    
    // Test default initializer
    CLXGppConsent *defaultConsent = [[CLXGppConsent alloc] init];
    XCTAssertNil(defaultConsent.saleOptOut, @"Default sale opt-out should be nil");
    XCTAssertNil(defaultConsent.sharingOptOut, @"Default sharing opt-out should be nil");
}

// Test consent equality and hashing
- (void)testConsentEqualityAndHashing {
    CLXGppConsent *consent1 = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:@2];
    CLXGppConsent *consent2 = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:@2];
    CLXGppConsent *consent3 = [[CLXGppConsent alloc] initWithSaleOptOut:@2 sharingOptOut:@1];
    
    // Test equality
    XCTAssertEqualObjects(consent1, consent2, @"Consents with same values should be equal");
    XCTAssertNotEqualObjects(consent1, consent3, @"Consents with different values should not be equal");
    
    // Test hash consistency
    XCTAssertEqual([consent1 hash], [consent2 hash], @"Equal consents should have same hash");
    
    // Test self-equality
    XCTAssertEqualObjects(consent1, consent1, @"Consent should equal itself");
    
    // Test nil comparison
    XCTAssertNotEqualObjects(consent1, nil, @"Consent should not equal nil");
    
    // Test different class comparison
    XCTAssertNotEqualObjects(consent1, @"string", @"Consent should not equal different class");
}

// Test consent description for debugging
- (void)testConsentDescription {
    CLXGppConsent *consent = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:@0];
    NSString *description = [consent description];
    
    XCTAssertTrue([description containsString:@"CLXGppConsent"], @"Description should contain class name");
    XCTAssertTrue([description containsString:@"saleOptOut=1"], @"Description should contain sale opt-out value");
    XCTAssertTrue([description containsString:@"sharingOptOut=0"], @"Description should contain sharing opt-out value");
    XCTAssertTrue([description containsString:@"requiresPiiRemoval=1"], @"Description should contain PII removal flag");
}

// Test edge cases for PII removal logic
- (void)testPiiRemovalEdgeCases {
    // Test with various numeric values beyond 0, 1, 2
    CLXGppConsent *highValue = [[CLXGppConsent alloc] initWithSaleOptOut:@99 sharingOptOut:@0];
    XCTAssertFalse([highValue requiresPiiRemoval], @"High numeric values should not trigger PII removal");
    
    // Test with negative values
    CLXGppConsent *negativeValue = [[CLXGppConsent alloc] initWithSaleOptOut:@(-1) sharingOptOut:@0];
    XCTAssertFalse([negativeValue requiresPiiRemoval], @"Negative values should not trigger PII removal");
    
    // Test mixed nil and numeric values
    CLXGppConsent *mixedNil1 = [[CLXGppConsent alloc] initWithSaleOptOut:@1 sharingOptOut:nil];
    XCTAssertTrue([mixedNil1 requiresPiiRemoval], @"Sale opt-out with nil sharing should require PII removal");
    
    CLXGppConsent *mixedNil2 = [[CLXGppConsent alloc] initWithSaleOptOut:nil sharingOptOut:@1];
    XCTAssertTrue([mixedNil2 requiresPiiRemoval], @"Sharing opt-out with nil sale should require PII removal");
}

@end
