/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterInterstitial.h
 * @brief Abstract base class for interstitial adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXAdapterShowParams.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterInterstitialDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for interstitial adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -showFromViewController:, @c -destroy. Subclasses update @c _isReady or
 * override @c -isReady to report SDK readiness.
 * The @c delegate retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterInterstitial : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterInterstitialDelegate> _Nullable _delegate;
    BOOL _isReady;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/// Whether the ad is ready to be shown.
@property (nonatomic, assign, readonly) BOOL isReady;

/// Loads the adapter interstitial. Subclass MUST override.
- (void)loadWithParams:(CLXAdapterLoadParams *)loadParams;

/// Shows the adapter interstitial. Subclass MUST override.
- (void)showWithParams:(CLXAdapterShowParams *)showParams;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

@end

/**
 * Delegate for the interstitial adapter.
 *
 * The @c extras parameter is reserved for adapter-provided callback metadata.
 * Adapters must pass an empty dictionary (@c @{}) when no metadata is available.
 */
@protocol CLXAdapterInterstitialDelegate <NSObject>

- (void)didLoadInterstitial:(NSDictionary<NSString *, id> *)extras;
- (void)didFailToLoadInterstitialWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)didDisplayInterstitial:(NSDictionary<NSString *, id> *)extras;
- (void)didFailToDisplayInterstitialWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)didTrackInterstitialImpression:(NSDictionary<NSString *, id> *)extras;
- (void)didHideInterstitial:(NSDictionary<NSString *, id> *)extras;
- (void)didClickInterstitial:(NSDictionary<NSString *, id> *)extras;
- (void)didExpireInterstitial:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
