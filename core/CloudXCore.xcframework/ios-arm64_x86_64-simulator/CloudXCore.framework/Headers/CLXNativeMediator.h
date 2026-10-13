/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorParams.h>
#import <CloudXCore/CLXMediatorTypes.h>
#import <CloudXCore/CLXNativeAd.h>

@class CLXNativeMediator;
@protocol CLXNativeMediatorDelegate;

NS_ASSUME_NONNULL_BEGIN

/** Creates one native mediator object for one load attempt. */
CLX_PUBLIC_MEDIATOR
@interface CLXNativeMediatorFactory : NSObject
+ (instancetype)createInstance;
/** Returns nil when the module cannot create a native attempt. */
- (nullable CLXNativeMediator *)createWithParams:(CLXNativeMediatorParams *)params;
@end

/**
 * Base class for one native load. Core owns presentation of the returned assets.
 * The delegate stays strong during asynchronous work. Subclasses must serialize
 * callbacks and destruction, ignore duplicate terminal callbacks, clear network
 * listeners, release their ad, and call super from destroy. Destroy is terminal
 * and idempotent; no callbacks may be forwarded afterward.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXNativeMediator : NSObject <CLXDestroyable> {
@protected
    id<CLXNativeMediatorDelegate> _Nullable _delegate;
    BOOL _destroyed;
}
@property (nonatomic, strong, nullable) id<CLXNativeMediatorDelegate> delegate;
@property (nonatomic, assign, readonly) CLXMediatorThreadRequirement loadThreadRequirement;
/** Check runtime readiness and report a load failure when initialization is pending or failed. */
- (void)loadWithParams:(CLXNativeMediatorLoadParams *)params;
- (void)destroy;
@end

/**
 * Receives native events. Extras must be immutable and non-null.
 * Load success returns assets for Core to present; it does not report an impression.
 */
@protocol CLXNativeMediatorDelegate <NSObject>
- (void)mediatorDidLoadNativeAd:(CLXNativeAd *)nativeAd adInfo:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidFailToLoadNativeAdWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidTrackNativeAdImpression:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidClickNativeAd:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidPayNativeAdRevenue:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidExpireNativeAd:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
@end

NS_ASSUME_NONNULL_END
