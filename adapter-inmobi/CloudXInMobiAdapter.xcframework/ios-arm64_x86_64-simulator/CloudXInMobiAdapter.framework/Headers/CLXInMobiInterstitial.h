//
//  CLXInMobiInterstitial.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiInterstitial : CLXAdapterInterstitial <IMInterstitialDelegate>

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
