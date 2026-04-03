/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAd;
@protocol CLXAdapterNativeDelegate;

@protocol CLXAdapterNative <NSObject>

@property (nonatomic, strong, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (void)load;
- (void)destroy;

@end

/**
 * Delegate through which native adapters report lifecycle events to the core SDK.
 *
 * Required callbacks must be called by every adapter. Optional callbacks are only
 * expected from adapters whose underlying SDK provides the corresponding event.
 * The core SDK checks respondsToSelector: before forwarding optional callbacks
 * to the publisher, so adapters may safely call them without coordination.
 */
@protocol CLXAdapterNativeDelegate <NSObject>

- (void)didLoadNativeAd:(CLXNativeAd *)nativeAd extraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;
- (void)didFailToLoadNativeAdWithError:(nullable NSError *)error;
- (void)didDisplayNativeAdWithExtraInfo:(nullable NSDictionary<NSString *, id> *)extraInfo;
- (void)didClickNativeAd;

@optional

/**
 * The user hid or reported the ad via the network's opt-out control (e.g., AdChoices).
 * Adapters should call this when the underlying SDK fires its ad-closed/ad-hidden
 * callback. Not all networks provide this event — only implement if the SDK supports it.
 */
- (void)didCloseNativeAd;

@end

NS_ASSUME_NONNULL_END
