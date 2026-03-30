//
//  CLXMetaRewarded.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaRewarded : NSObject <FBRewardedVideoAdDelegate, CLXAdapterRewarded>

@property (nonatomic, strong, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

@end

NS_ASSUME_NONNULL_END 