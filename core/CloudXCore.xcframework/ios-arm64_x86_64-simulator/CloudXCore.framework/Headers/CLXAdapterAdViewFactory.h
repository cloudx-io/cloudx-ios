/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterAdViewFactory.h
 * @brief Abstract base class for banner adapter factories
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdViewAdapterParams.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterAdView;

/// Abstract base class for banner adapter factories.
/// Subclass MUST override @c -createWithParams:.
/// The wrapper attaches itself as the adapter's delegate after construction.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterAdViewFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterAdView *)createWithParams:(CLXAdViewAdapterParams *)params;

@end

NS_ASSUME_NONNULL_END
