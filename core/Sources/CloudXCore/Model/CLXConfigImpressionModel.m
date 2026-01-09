#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>

// Default test group name constant
NSString * const CLXConfigImpressionModelDefaultTestGroupName = @"RandomTest";

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
        _testGroupName = [CLXConfigImpressionModelDefaultTestGroupName copy];
    }
    return self;
}

- (instancetype)initWithSDKConfig:(CLXSDKConfigResponse *)sdkConfig
                        auctionID:(NSString *)auctionID
                    testGroupName:(nullable NSString *)testGroupName {
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
        
        // Use provided test group name or default
        _testGroupName = [testGroupName copy] ?: [CLXConfigImpressionModelDefaultTestGroupName copy];
    }
    return self;
}

@end 
