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

/**
 * Creates a CLXConfigImpressionModel from SDK configuration response
 * @param sdkConfig The SDK configuration response containing environment-specific values
 * @param auctionID The unique auction identifier for this impression
 * @return Configured impression model instance
 */
- (instancetype)initWithSDKConfig:(CLXSDKConfigResponse *)sdkConfig
                        auctionID:(NSString *)auctionID;

/**
 * Convenience initializer for testing purposes - creates instance with mock values
 * @return Test impression model instance with default values
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
