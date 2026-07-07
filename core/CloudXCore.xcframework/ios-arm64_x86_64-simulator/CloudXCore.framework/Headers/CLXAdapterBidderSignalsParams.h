/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterParams.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Completion block adapters call after attempting to provide bidder signals.

 Pass a non-empty bidder signals dictionary when bidder signal fields are available. Pass an
 error when bidder signal collection fails. Pass @c nil for the first two values when
 the adapter has no bidder signals for the current request and auction should continue
 without treating that as a failure. The extras dictionary is reserved for
 adapter-provided callback metadata.
 */
typedef void (^CLXAdapterBidderSignalsCompletion)(NSDictionary<NSString *, NSString *> * _Nullable bidderSignals,
                                             NSError * _Nullable error,
                                             NSDictionary<NSString *, id> * _Nullable extras);

CLX_PUBLIC_ADAPTER
@interface CLXAdapterBidderSignalsParams : CLXAdapterParams

/// Publisher ad unit identifier for the auction requesting bidder signals.
@property (nonatomic, copy, readonly) NSString *adUnitId;

/// CloudX ad type for the auction requesting bidder signals.
@property (nonatomic, assign, readonly) CLXAdType adType;

/// Completion adapters must call exactly once with bidder signals, an error, or neither.
@property (nonatomic, copy, readonly) CLXAdapterBidderSignalsCompletion completion;

@end

NS_ASSUME_NONNULL_END
