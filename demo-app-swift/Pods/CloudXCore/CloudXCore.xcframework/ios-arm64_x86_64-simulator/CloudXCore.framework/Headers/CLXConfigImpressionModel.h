#import <Foundation/Foundation.h>

@class CLXSDKConfigResponse;

NS_ASSUME_NONNULL_BEGIN

@interface CLXConfigImpressionModel : NSObject

@property (nonatomic, readonly, copy) NSString *sessionID;
@property (nonatomic, readonly, copy) NSString *auctionID;
@property (nonatomic, readonly, copy) NSString *impressionTrackerURL;
@property (nonatomic, readonly, copy) NSString *organizationID;
@property (nonatomic, readonly, copy) NSString *accountID;
@property (nonatomic, readonly, strong, nullable) CLXSDKConfigResponse *sdkConfig;
@property (nonatomic, readonly, copy) NSString *testGroupName;
@property (nonatomic, readonly, copy, nullable) NSString *appKeyValues;
@property (nonatomic, readonly, copy, nullable) NSString *eids;
@property (nonatomic, readonly, copy, nullable) NSString *placementLoopIndex;
@property (nonatomic, readonly, copy, nullable) NSString *userKeyValues;

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
                    userKeyValues:(NSString *)userKeyValues;

@end

NS_ASSUME_NONNULL_END 
