/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorParams.h>
#import <CloudXCore/CLXMediatorTypes.h>

@class CLXAdViewMediator;
@protocol CLXAdViewMediatorDelegate;

NS_ASSUME_NONNULL_BEGIN

/** Creates one banner or MREC mediator object for one load attempt. */
CLX_PUBLIC_MEDIATOR
@interface CLXAdViewMediatorFactory : NSObject
+ (instancetype)createInstance;
/** Returns nil when the module cannot create an ad-view attempt. */
- (nullable CLXAdViewMediator *)createWithParams:(CLXAdViewMediatorParams *)params;
@end

/**
 * Base class for one banner or MREC load. Core owns view attachment and refresh.
 * A module must disable automatic refresh and return one terminal load result.
 * UIView-owning implementations load and destroy on the main thread.
 *
 * The delegate stays strong during asynchronous work. Subclasses must serialize
 * callbacks and destruction, ignore duplicate terminal callbacks, clear network
 * listeners, release their view, and call super from destroy. Destroy is terminal
 * and idempotent; no callbacks may be forwarded afterward.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXAdViewMediator : NSObject <CLXDestroyable> {
@protected
    id<CLXAdViewMediatorDelegate> _Nullable _delegate;
    BOOL _destroyed;
}
@property (nonatomic, strong, nullable) id<CLXAdViewMediatorDelegate> delegate;
@property (nonatomic, assign, readonly) CLXMediatorThreadRequirement loadThreadRequirement;
/** Check runtime readiness and report a load failure when initialization is pending or failed. */
- (void)loadWithParams:(CLXAdViewMediatorLoadParams *)params;
- (void)destroy;
@end

/**
 * Receives ad-view events. Extras must be immutable and non-null.
 * Load success returns a view for Core to attach; it does not report an impression.
 */
@protocol CLXAdViewMediatorDelegate <NSObject>
- (void)mediatorDidLoadAdView:(UIView *)view adInfo:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidFailToLoadAdViewWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidFailToDisplayAdView:(nullable CLXMediatorAdInfo *)adInfo error:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidTrackAdViewImpression:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidClickAdView:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidExpandAdView:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidCollapseAdView:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidPayAdViewRevenue:(CLXMediatorAdInfo *)adInfo extras:(NSDictionary<NSString *, id> *)extras;
@end

NS_ASSUME_NONNULL_END
