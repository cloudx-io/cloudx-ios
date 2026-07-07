/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterParams.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC_ADAPTER
@interface CLXAdapterNativeParams : CLXAdapterParams

/// Publisher ad unit identifier for the native load.
@property (nonatomic, copy, readonly) NSString *adUnitId;

/// Publisher ad unit name for human-readable logging/error context.
@property (nonatomic, copy, readonly) NSString *adUnitName;

/// Bid markup provided by the winning bid.
@property (nonatomic, copy, readonly) NSString *adm;

@end

NS_ASSUME_NONNULL_END
