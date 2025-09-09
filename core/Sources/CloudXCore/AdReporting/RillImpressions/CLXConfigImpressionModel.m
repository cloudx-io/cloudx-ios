#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>

@implementation CLXConfigImpressionModel

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
                                    userKeyValues:(NSString *)userKeyValues; {
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
