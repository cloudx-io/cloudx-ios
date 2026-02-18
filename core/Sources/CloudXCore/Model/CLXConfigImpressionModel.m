#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>

@implementation CLXConfigImpressionModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with test/mock values for testing purposes
        _sessionID = @"test-session-id";
        _auctionID = [[NSUUID UUID] UUIDString];
        _impressionTrackerURL = @"https://test-tracker.cloudx.io/t";  // Test URL
        _organizationID = @"TEST_ORG";
        _accountID = @"TEST_ACCOUNT";
        _sdkConfig = nil; // No SDK config in test mode
    }
    return self;
}

- (instancetype)initWithSDKConfig:(CLXSDKConfigResponse *)sdkConfig
                        auctionID:(NSString *)auctionID {
    NSParameterAssert(sdkConfig);
    NSParameterAssert(auctionID);

    self = [super init];
    if (self) {
        _sdkConfig = sdkConfig;

        // Extract values from SDK config response only - no fallbacks
        _sessionID = [sdkConfig.sessionID copy] ?: @"";
        _auctionID = [auctionID copy];
        _impressionTrackerURL = [sdkConfig.impressionTrackerURL copy] ?: @"";
        _organizationID = [sdkConfig.organizationID copy] ?: @"";
        _accountID = [sdkConfig.accountID copy] ?: @"";
    }
    return self;
}

@end
