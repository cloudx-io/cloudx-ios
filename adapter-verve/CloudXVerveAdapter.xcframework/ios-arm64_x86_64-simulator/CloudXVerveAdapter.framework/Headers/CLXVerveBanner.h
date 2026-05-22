/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXBannerType.h>
#import <HyBid/HyBid.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveBanner : CLXAdapterBanner <HyBidAdViewDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type;

@end

NS_ASSUME_NONNULL_END
