//
//  CLXInMobiAdView.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiAdView : CLXAdapterAdView <IMBannerDelegate>

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                              size:(CGSize)size
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
