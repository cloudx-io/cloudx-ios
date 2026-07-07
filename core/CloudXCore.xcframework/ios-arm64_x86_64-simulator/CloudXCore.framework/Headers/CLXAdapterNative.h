/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterNative.h
 * @brief Abstract base class for native adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAd;
@protocol CLXAdapterNativeDelegate;

/**
 * Abstract base class for native adapters.
 *
 * Subclass per ad network. Required overrides: @c -load, @c -destroy.
 * Subclasses notify @c _delegate as native lifecycle events occur. The @c
 * delegate retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterNative : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterNativeDelegate> _Nullable _delegate;
}

@property (nonatomic, strong, nullable) id<CLXAdapterNativeDelegate> delegate;

/// Loads the native ad. Subclass MUST override.
- (void)loadWithParams:(CLXAdapterLoadParams *)loadParams;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

/**
 * Called after a native ad loaded through the banner/MREC bridge has been
 * inserted into its CLXBannerAdView container.
 *
 * Default: no-op. Override only for native adapters whose SDK requires an
 * explicit post-container-attach lifecycle signal when native is rendered in
 * an ad-view slot.
 */
- (void)onAttachedToAdViewContainer;

@end

/**
 * Delegate through which native adapters report lifecycle events to the core SDK.
 *
 * Required callbacks must be implemented by every delegate. Adapters call the
 * lifecycle event that matches the underlying SDK signal.
 */
@protocol CLXAdapterNativeDelegate <NSObject>

- (void)didLoadNativeAd:(CLXNativeAd *)nativeAd extras:(NSDictionary<NSString *, id> *)extras;
- (void)didFailToLoadNativeAdWithError:(nullable NSError *)error extras:(NSDictionary<NSString *, id> *)extras;
- (void)didDisplayNativeAd:(NSDictionary<NSString *, id> *)extras;
- (void)didClickNativeAd:(NSDictionary<NSString *, id> *)extras;
/// The network expired the native ad before it was rendered.
- (void)didExpireNativeAd:(NSDictionary<NSString *, id> *)extras;

/// User hid or reported the ad via the network's opt-out control (e.g., AdChoices).
- (void)didCloseNativeAd:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
