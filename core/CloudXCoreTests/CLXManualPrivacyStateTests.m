//
//  CLXManualPrivacyStateTests.m
//  CloudXCoreTests
//
//  Created by CloudX Team.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

@interface CLXManualPrivacyStateTests : XCTestCase
@end

@implementation CLXManualPrivacyStateTests

- (void)tearDown {
    [[CLXManualPrivacyState sharedInstance] clear];
    [super tearDown];
}

#pragma mark - Singleton Tests

- (void)testSharedInstance_ReturnsSameObject {
    CLXManualPrivacyState *a = [CLXManualPrivacyState sharedInstance];
    CLXManualPrivacyState *b = [CLXManualPrivacyState sharedInstance];
    XCTAssertEqual(a, b, @"sharedInstance should always return the same object");
}

#pragma mark - Default State

- (void)testDefaultValues_AreNil {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    [state clear]; // ensure clean state
    XCTAssertNil(state.hasUserConsent, @"hasUserConsent should be nil by default");
    XCTAssertNil(state.doNotSell, @"doNotSell should be nil by default");
}

#pragma mark - Set and Get

- (void)testSetHasUserConsent_YES {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.hasUserConsent = @YES;
    XCTAssertEqualObjects(state.hasUserConsent, @YES, @"Should store YES");
}

- (void)testSetHasUserConsent_NO {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.hasUserConsent = @NO;
    XCTAssertEqualObjects(state.hasUserConsent, @NO, @"Should store NO");
}

- (void)testSetHasUserConsent_Nil {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.hasUserConsent = @YES;
    state.hasUserConsent = nil;
    XCTAssertNil(state.hasUserConsent, @"Should allow clearing to nil");
}

- (void)testSetDoNotSell_YES {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.doNotSell = @YES;
    XCTAssertEqualObjects(state.doNotSell, @YES, @"Should store YES");
}

- (void)testSetDoNotSell_NO {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.doNotSell = @NO;
    XCTAssertEqualObjects(state.doNotSell, @NO, @"Should store NO");
}

- (void)testSetDoNotSell_Nil {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.doNotSell = @YES;
    state.doNotSell = nil;
    XCTAssertNil(state.doNotSell, @"Should allow clearing to nil");
}

#pragma mark - Clear

- (void)testClear_ResetsAllValues {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.hasUserConsent = @YES;
    state.doNotSell = @NO;

    [state clear];

    XCTAssertNil(state.hasUserConsent, @"clear should reset hasUserConsent to nil");
    XCTAssertNil(state.doNotSell, @"clear should reset doNotSell to nil");
}

#pragma mark - Independent Properties

- (void)testPropertiesAreIndependent {
    CLXManualPrivacyState *state = [CLXManualPrivacyState sharedInstance];
    state.hasUserConsent = @YES;
    state.doNotSell = @NO;

    XCTAssertEqualObjects(state.hasUserConsent, @YES, @"hasUserConsent should be independent");
    XCTAssertEqualObjects(state.doNotSell, @NO, @"doNotSell should be independent");

    state.hasUserConsent = nil;
    XCTAssertNil(state.hasUserConsent, @"Clearing hasUserConsent should not affect doNotSell");
    XCTAssertEqualObjects(state.doNotSell, @NO, @"doNotSell should remain unchanged");
}

@end
