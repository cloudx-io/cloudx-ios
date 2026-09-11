//
//  CLXUnityAdsRewarded.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsRewarded : CLXAdapterRewarded <UADSRewardedShowDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
