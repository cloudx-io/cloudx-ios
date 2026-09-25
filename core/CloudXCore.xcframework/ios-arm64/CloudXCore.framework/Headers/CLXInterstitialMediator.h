/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorParams.h>
#import <CloudXCore/CLXMediatorTypes.h>

@class CLXInterstitialMediator;
@protocol CLXInterstitialMediatorDelegate;

NS_ASSUME_NONNULL_BEGIN

/** Creates one interstitial mediator object for one load attempt. */
CLX_PUBLIC_MEDIATOR
@interface CLXInterstitialMediatorFactory : NSObject

+ (instancetype)createInstance;
/** Returns nil when the module cannot create an interstitial attempt. */
- (nullable CLXInterstitialMediator *)createWithParams:(CLXInterstitialMediatorParams *)params;

@end

/**
 * Base class for one interstitial mediator load attempt.
 *
 * One object represents one load attempt. A load must produce one terminal
 * result. Only Core can transfer the selected candidate to a publisher ad.
 *
 * The delegate is strong during asynchronous work. A subclass must call super
 * from destroy, clear third-party listeners, and release its SDK objects.
 * Destroy is terminal and idempotent. A module must not send callbacks after
 * destruction and must ignore duplicate terminal callbacks.
 *
 * Network callbacks can arrive on any thread. The module must serialize its
 * lifecycle state, delegate access, callback forwarding, and destruction.
 * Destroy must synchronously establish terminal state and clear the delegate;
 * callbacks racing with destruction must be dropped. Core will normalize
 * callbacks before it changes state or notifies publisher objects.
 *
 * A second show call must report an invalid-state failure. It must not destroy
 * an ad that is already being presented.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXInterstitialMediator : NSObject <CLXDestroyable> {
@protected
    id<CLXInterstitialMediatorDelegate> _Nullable _delegate;
    BOOL _isReady;
    BOOL _destroyed;
}

@property (nonatomic, strong, nullable) id<CLXInterstitialMediatorDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isReady;
@property (nonatomic, assign, readonly) CLXMediatorThreadRequirement loadThreadRequirement;
@property (nonatomic, assign, readonly) CLXMediatorThreadRequirement showThreadRequirement;

- (void)loadWithParams:(CLXMediatorLoadParams *)params;
- (void)showWithParams:(CLXMediatorShowParams *)params;
- (void)destroy;

@end

/**
 * Receives interstitial lifecycle events.
 *
 * Callback extras must be immutable and non-null. Use an empty dictionary when
 * no extras exist. Core enforces final exactly-once and generation gates in the
 * future mediator manager.
 */
@protocol CLXInterstitialMediatorDelegate <NSObject>

- (void)mediatorDidLoadInterstitial:(CLXMediatorAdInfo *)adInfo
                              extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidFailToLoadInterstitialWithError:(NSError *)error
                                             extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidDisplayInterstitial:(CLXMediatorAdInfo *)adInfo
                                 extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidFailToDisplayInterstitial:(nullable CLXMediatorAdInfo *)adInfo
                                       error:(NSError *)error
                                      extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidTrackInterstitialImpression:(CLXMediatorAdInfo *)adInfo
                                         extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidClickInterstitial:(CLXMediatorAdInfo *)adInfo
                               extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidHideInterstitial:(CLXMediatorAdInfo *)adInfo
                              extras:(NSDictionary<NSString *, id> *)extras;
- (void)mediatorDidPayInterstitialRevenue:(CLXMediatorAdInfo *)adInfo
                                    extras:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
