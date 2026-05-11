//
//  CLXMetaRewarded.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaRewarded : CLXAdapterRewarded <FBRewardedVideoAdDelegate>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID;

- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

@end

NS_ASSUME_NONNULL_END
