/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <HyBid/HyBid.h>

#if __has_include(<HyBid/HyBid-Swift.h>)
#import <HyBid/HyBid-Swift.h>
#else
#import "HyBid-Swift.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveInterstitial : CLXAdapterInterstitial <HyBidInterstitialAdDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
