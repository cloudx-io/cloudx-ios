//
//  CLXMetaAdView.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaAdView : CLXAdapterAdView <FBAdViewDelegate, CLXDestroyable>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                              type:(CLXBannerType)type
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
