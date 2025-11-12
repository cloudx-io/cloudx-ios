#import <Foundation/Foundation.h>

@class CLXSDKConfigResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 * Default test group name used when no specific test group is configured
 */
extern NSString * const CLXConfigImpressionModelDefaultTestGroupName;

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

/**
 * Creates a CLXConfigImpressionModel from SDK configuration response
 * @param sdkConfig The SDK configuration response containing environment-specific values
 * @param auctionID The unique auction identifier for this impression
 * @param testGroupName Optional test group name (uses default if nil)
 * @return Configured impression model instance
 */
- (instancetype)initWithSDKConfig:(CLXSDKConfigResponse *)sdkConfig
                        auctionID:(NSString *)auctionID
                    testGroupName:(nullable NSString *)testGroupName;

/**
 * Convenience initializer for testing purposes - creates instance with mock values
 * @return Test impression model instance with default values
 */
- (instancetype)init;

/**
 * Legacy initializer - deprecated, use initWithSDKConfig:auctionID:testGroupName: instead
 */
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
                    userKeyValues:(NSString *)userKeyValues __deprecated_msg("Use initWithSDKConfig:auctionID:testGroupName: instead");

@end

NS_ASSUME_NONNULL_END 
