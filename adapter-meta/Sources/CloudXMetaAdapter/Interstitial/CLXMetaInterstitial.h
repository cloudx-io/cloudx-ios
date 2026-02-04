//
//  CLXMetaInterstitial.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaInterstitial : NSObject <FBInterstitialAdDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 
