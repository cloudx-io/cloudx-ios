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
        _appKeyValues = @"app.ext.data";
        _eids = @"user.ext.eids[*]";
        _placementLoopIndex = @"imp[*].ext.data.loop-index";
        _userKeyValues = @"user.ext.data";
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
        
        // Extract key-value paths from SDK config
        _appKeyValues = [sdkConfig.keyValuePaths.appKeyValues copy];
        _eids = [sdkConfig.keyValuePaths.eids copy];
        _placementLoopIndex = [sdkConfig.keyValuePaths.placementLoopIndex copy];
        _userKeyValues = [sdkConfig.keyValuePaths.userKeyValues copy];
    }
    return self;
}

- (instancetype)initWithSessionID:(NSString *)sessionID
                        auctionID:(NSString *)auctionID
             impressionTrackerURL:(NSString *)impressionTrackerURL
                   organizationID:(NSString *)organizationID
                        accountID:(NSString *)accountID
                        sdkConfig:(nullable CLXSDKConfigResponse *)sdkConfig
                    testGroupName:(NSString *)testGroupName
                     appKeyValues:(NSString *)appKeyValues
                             eids:(NSString *)eids
               placementLoopIndex:(NSString *)placementLoopIndex
                    userKeyValues:(NSString *)userKeyValues {
    self = [super init];
    if (self) {
        _sessionID = [sessionID copy];
        _auctionID = [auctionID copy];
        _impressionTrackerURL = [impressionTrackerURL copy];
        _organizationID = [organizationID copy];
        _accountID = [accountID copy];
        _sdkConfig = sdkConfig;
        _testGroupName = [testGroupName copy];
        _appKeyValues = [appKeyValues copy];
        _eids = [eids copy];
        _placementLoopIndex = [placementLoopIndex copy];
        _userKeyValues = [userKeyValues copy];
    }
    return self;
}

@end 
