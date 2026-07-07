/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterParams.h>
#import <CloudXCore/CLXBannerType.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC_ADAPTER
@interface CLXAdViewAdapterParams : CLXAdapterParams

/// Publisher ad unit identifier for the banner load.
@property (nonatomic, copy, readonly) NSString *adUnitId;

/// Publisher ad unit name for human-readable logging/error context.
@property (nonatomic, copy, readonly) NSString *adUnitName;

/// Bid markup provided by the winning bid.
@property (nonatomic, copy, readonly) NSString *adm;

/// Requested CloudX banner size/type.
@property (nonatomic, assign, readonly) CLXBannerType bannerType;

@end

NS_ASSUME_NONNULL_END
