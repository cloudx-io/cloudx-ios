//
//  CLXAdapterPrivacyForwarderTests.m
//  CloudXCoreTests
//
//  Created by CloudX Team.
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CloudXCore.h>

// Mock handler for testing
@interface CLXMockPrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@property (nonatomic, strong, nullable) CLXAdapterPrivacySettings *lastSettings;
@property (nonatomic, assign) NSInteger updateCount;
@end

@implementation CLXMockPrivacyHandler

- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings {
    self.lastSettings = settings;
    self.updateCount++;
}

@end

@interface CLXAdapterPrivacyForwarderTests : XCTestCase
@end

@implementation CLXAdapterPrivacyForwarderTests

- (void)tearDown {
    [[CLXManualPrivacyState sharedInstance] clear];
    [super tearDown];
}

#pragma mark - Singleton

- (void)testSharedInstance_ReturnsSameObject {
    CLXAdapterPrivacyForwarder *a = [CLXAdapterPrivacyForwarder sharedInstance];
    CLXAdapterPrivacyForwarder *b = [CLXAdapterPrivacyForwarder sharedInstance];
    XCTAssertEqual(a, b, @"sharedInstance should always return the same object");
}

#pragma mark - Push Settings

- (void)testPushCurrentPrivacySettings_DoesNotCrash {
    // Ensure pushCurrentPrivacySettings doesn't crash even with no handlers
    CLXAdapterPrivacyForwarder *forwarder = [CLXAdapterPrivacyForwarder sharedInstance];
    XCTAssertNoThrow([forwarder pushCurrentPrivacySettings], @"pushCurrentPrivacySettings should not crash");
}

- (void)testPushCurrentPrivacySettings_WithManualState {
    [[CLXManualPrivacyState sharedInstance] setHasUserConsent:@YES];
    [[CLXManualPrivacyState sharedInstance] setDoNotSell:@NO];

    CLXAdapterPrivacyForwarder *forwarder = [CLXAdapterPrivacyForwarder sharedInstance];
    XCTAssertNoThrow([forwarder pushCurrentPrivacySettings], @"Should push settings with manual state");
}

#pragma mark - Stop

- (void)testStop_DoesNotCrash {
    CLXAdapterPrivacyForwarder *forwarder = [CLXAdapterPrivacyForwarder sharedInstance];
    XCTAssertNoThrow([forwarder stop], @"stop should not crash");
}

- (void)testStop_CanBeCalledMultipleTimes {
    CLXAdapterPrivacyForwarder *forwarder = [CLXAdapterPrivacyForwarder sharedInstance];
    XCTAssertNoThrow([forwarder stop], @"First stop should not crash");
    XCTAssertNoThrow([forwarder stop], @"Second stop should not crash");
}

#pragma mark - CLXAdapterPrivacySettings Model

- (void)testPrivacySettings_InitWithAllValues {
    CLXAdapterPrivacySettings *settings = [[CLXAdapterPrivacySettings alloc] initWithHasUserConsent:@YES
                                                                                         doNotSell:@NO
                                                                               manualHasUserConsent:@YES
                                                                                     manualDoNotSell:@NO];
    XCTAssertEqualObjects(settings.hasUserConsent, @YES);
    XCTAssertEqualObjects(settings.doNotSell, @NO);
    XCTAssertEqualObjects(settings.manualHasUserConsent, @YES);
    XCTAssertEqualObjects(settings.manualDoNotSell, @NO);
}

- (void)testPrivacySettings_InitWithNilValues {
    CLXAdapterPrivacySettings *settings = [[CLXAdapterPrivacySettings alloc] initWithHasUserConsent:nil
                                                                                         doNotSell:nil
                                                                               manualHasUserConsent:nil
                                                                                     manualDoNotSell:nil];
    XCTAssertNil(settings.hasUserConsent);
    XCTAssertNil(settings.doNotSell);
    XCTAssertNil(settings.manualHasUserConsent);
    XCTAssertNil(settings.manualDoNotSell);
}

- (void)testPrivacySettings_ManualFieldsIndependentOfResolved {
    CLXAdapterPrivacySettings *settings = [[CLXAdapterPrivacySettings alloc] initWithHasUserConsent:@YES
                                                                                         doNotSell:@YES
                                                                               manualHasUserConsent:nil
                                                                                     manualDoNotSell:nil];
    XCTAssertEqualObjects(settings.hasUserConsent, @YES);
    XCTAssertEqualObjects(settings.doNotSell, @YES);
    XCTAssertNil(settings.manualHasUserConsent);
    XCTAssertNil(settings.manualDoNotSell);
}

#pragma mark - Mock Handler

- (void)testMockHandler_ReceivesSettings {
    CLXMockPrivacyHandler *handler = [[CLXMockPrivacyHandler alloc] init];
    CLXAdapterPrivacySettings *settings = [[CLXAdapterPrivacySettings alloc] initWithHasUserConsent:@YES
                                                                                         doNotSell:@NO
                                                                               manualHasUserConsent:@YES
                                                                                     manualDoNotSell:@NO];
    [handler updatePrivacySettings:settings];
    XCTAssertEqual(handler.updateCount, 1);
    XCTAssertEqualObjects(handler.lastSettings.hasUserConsent, @YES);
    XCTAssertEqualObjects(handler.lastSettings.doNotSell, @NO);
    XCTAssertEqualObjects(handler.lastSettings.manualHasUserConsent, @YES);
    XCTAssertEqualObjects(handler.lastSettings.manualDoNotSell, @NO);
}

@end
