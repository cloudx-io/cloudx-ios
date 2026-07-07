/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterBidderSignalsProvider.h
 * @brief Abstract base class for bidder signals providers
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsParams.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for networks that provide bidder signals for bid requests.
 *
 * Subclass MUST override @c -provideBidderSignalsWithParams:.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterBidderSignalsProvider : NSObject

+ (instancetype)createInstance;

/// Provides bidder signals from the ad network. Subclass MUST override.
- (void)provideBidderSignalsWithParams:(CLXAdapterBidderSignalsParams *)params;

@end

NS_ASSUME_NONNULL_END
