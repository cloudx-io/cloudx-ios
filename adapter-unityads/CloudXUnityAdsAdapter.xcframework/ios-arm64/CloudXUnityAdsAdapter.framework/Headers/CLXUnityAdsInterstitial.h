//
//  CLXUnityAdsInterstitial.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsInterstitial : CLXAdapterInterstitial <UADSInterstitialShowDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID;

@end

NS_ASSUME_NONNULL_END
