//
//  CLXMetaRewarded.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaRewarded : CLXAdapterRewarded <FBRewardedVideoAdDelegate>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

@end

NS_ASSUME_NONNULL_END
