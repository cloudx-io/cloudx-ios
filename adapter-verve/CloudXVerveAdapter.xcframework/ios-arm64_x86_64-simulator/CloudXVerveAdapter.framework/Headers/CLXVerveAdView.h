/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXBannerType.h>
#import <HyBid/HyBid.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveAdView : CLXAdapterAdView <HyBidAdViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
                              type:(CLXBannerType)type
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
