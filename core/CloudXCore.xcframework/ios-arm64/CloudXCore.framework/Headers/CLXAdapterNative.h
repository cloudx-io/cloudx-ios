/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterNative.h
 * @brief Abstract base class for native adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAd;
@protocol CLXAdapterNativeDelegate;

/**
 * Abstract base class for native adapters.
 *
 * Subclass per ad network. Required overrides: @c -load, @c -destroy.
 * Subclasses populate @c _sdkVersion and @c _delegate. The @c delegate
 * retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterNative : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterNativeDelegate> _Nullable _delegate;
    NSString *_sdkVersion;
    NSString *_network;
    NSString *_bidID;
}

@property (nonatomic, strong, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/// Network name of the adapter, e.g. @c "AdMob", @c "Facebook".
@property (nonatomic, copy, readonly) NSString *network;

/// Ad id from bid response.
@property (nonatomic, copy, readonly) NSString *bidID;

/// Loads the native ad. Subclass MUST override.
- (void)load;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

@end

/**
 * Delegate through which native adapters report lifecycle events to the core SDK.
 *
 * Required callbacks must be called by every adapter. Optional callbacks are only
 * expected from adapters whose underlying SDK provides the corresponding event.
 * The core SDK checks @c respondsToSelector: before forwarding optional callbacks
 * to the publisher, so adapters may safely call them without coordination.
 */
@protocol CLXAdapterNativeDelegate <NSObject>

- (void)didLoadNativeAd:(CLXNativeAd *)nativeAd extraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;
- (void)didFailToLoadNativeAdWithError:(nullable NSError *)error;
- (void)didDisplayNativeAdWithExtraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;
- (void)didClickNativeAd;

@optional

/// User hid or reported the ad via the network's opt-out control (e.g., AdChoices).
- (void)didCloseNativeAd;

@end

NS_ASSUME_NONNULL_END
