//
//  CLXUnityAdsAdView.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXBannerType.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsAdView : CLXAdapterAdView <UADSBannerViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                              type:(CLXBannerType)type
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
