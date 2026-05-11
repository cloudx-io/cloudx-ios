//
//  CLXUnityAdsBanner.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsBanner : CLXAdapterBanner <UADSBannerAdDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type;

@end

NS_ASSUME_NONNULL_END
