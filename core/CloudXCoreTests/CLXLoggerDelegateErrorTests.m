//
//  CLXLoggerDelegateErrorTests.m
//  CloudXCoreTests
//

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXError.h>

static NSString *const kTestModeKey = @"CLXCore_testMode";

@interface CLXLoggerDelegateErrorTests : XCTestCase
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXLoggerDelegateErrorTests

- (void)setUp {
    [super setUp];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kTestModeKey];
    [[CLXLogStore shared] clear];
    self.logger = [[CLXLogger alloc] initWithCategory:@"test"];
    [self.logger setMinLogLevel:CLXLogLevelVerbose];
}

- (void)tearDown {
    [[CLXLogStore shared] clear];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTestModeKey];
    self.logger = nil;
    [super tearDown];
}

#pragma mark - Helpers

- (NSString *)lastStoredMessage {
    [[CLXLogStore shared] flush];
    NSArray<CLXLogEntry *> *entries = [[CLXLogStore shared] allEntries];
    return entries.firstObject.message;
}

#pragma mark - Tests

- (void)testAllFieldsPresent_IncludesAllLabels {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed description:@"No fill"];

    [self.logger logDelegateError:@"❌ Interstitial didFailToLoadAd"
                       adUnitName:@"main_interstitial"
                         adUnitId:@"abc123"
                      networkName:@"TestNetwork"
                            error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"Ad Unit: main_interstitial"]);
    XCTAssertTrue([message containsString:@"Ad Unit ID: abc123"]);
    XCTAssertTrue([message containsString:@"Bidder: TestNetwork"]);
    XCTAssertTrue([message containsString:@"Error:"], @"Should contain error label");
    XCTAssertTrue([message containsString:@"No fill"]);
}

- (void)testNilNetworkName_OmitsBidderLine {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed description:@"No bids received"];

    [self.logger logDelegateError:@"❌ Interstitial didFailToLoadAd"
                       adUnitName:@"main_interstitial"
                         adUnitId:@"abc123"
                      networkName:nil
                            error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"Ad Unit: main_interstitial"]);
    XCTAssertTrue([message containsString:@"Ad Unit ID: abc123"]);
    XCTAssertFalse([message containsString:@"Bidder:"], @"Bidder line should be omitted when networkName is nil");
    XCTAssertTrue([message containsString:@"No bids received"]);
}

- (void)testNilAdUnitFields_OmitsAdUnitLines {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed description:@"Timeout"];

    [self.logger logDelegateError:@"❌ Rewarded didFailToLoadAd"
                       adUnitName:nil
                         adUnitId:nil
                      networkName:@"TestNetwork"
                            error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertFalse([message containsString:@"Ad Unit:"], @"Ad Unit line should be omitted when adUnitName is nil");
    XCTAssertFalse([message containsString:@"Ad Unit ID:"], @"Ad Unit ID line should be omitted when adUnitId is nil");
    XCTAssertTrue([message containsString:@"Bidder: TestNetwork"]);
    XCTAssertTrue([message containsString:@"Timeout"]);
}

- (void)testNilError_ShowsNullError {
    [self.logger logDelegateError:@"❌ Interstitial didFailToDisplayAd"
                       adUnitName:@"test_unit"
                         adUnitId:@"xyz789"
                      networkName:@"TestNetwork"
                            error:nil];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"Error: (null)"], @"Nil error should show '(null)'");
}

- (void)testErrorWithNonZeroCode_IncludesCodeLine {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterDisplayFailed description:@"Display failed"];

    [self.logger logDelegateError:@"❌ Interstitial didFailToDisplayAd"
                       adUnitName:@"test_unit"
                         adUnitId:@"abc123"
                      networkName:@"TestNetwork"
                            error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"Code:"], @"Non-zero error code should include Code line");
}

#pragma mark - Forwarding (convenience method)

- (void)testConvenienceMethod_ForwardsToContextMethod {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed description:@"Timeout"];

    [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"❌ Banner didFailToLoadAd"], @"Callback name should be present");
    XCTAssertTrue([message containsString:@"Error: Timeout"], @"Error description should be present");
    XCTAssertFalse([message containsString:@"Ad Unit:"], @"No ad unit context should appear when forwarding with nils");
    XCTAssertFalse([message containsString:@"Ad Unit ID:"], @"No ad unit ID should appear when forwarding with nils");
    XCTAssertFalse([message containsString:@"Bidder:"], @"No bidder should appear when forwarding with nils");
}

- (void)testConvenienceMethod_NilError {
    [self.logger logDelegateError:@"❌ Banner didFailToLoadAd" error:nil];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"Error: (null)"], @"Nil error should show (null) via forwarding");
}

- (void)testAllFieldsNil_OnlyCallbackAndError {
    CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed description:@"No bids"];

    [self.logger logDelegateError:@"❌ Rewarded didFailToLoadAd"
                       adUnitName:nil
                         adUnitId:nil
                      networkName:nil
                            error:error];

    NSString *message = [self lastStoredMessage];
    XCTAssertTrue([message containsString:@"❌ Rewarded didFailToLoadAd"], @"Callback name should be present");
    XCTAssertTrue([message containsString:@"Error: No bids"], @"Error should be present");
    XCTAssertFalse([message containsString:@"Ad Unit:"], @"No ad unit context when all fields nil");
    XCTAssertFalse([message containsString:@"Bidder:"], @"No bidder when all fields nil");
}

@end
