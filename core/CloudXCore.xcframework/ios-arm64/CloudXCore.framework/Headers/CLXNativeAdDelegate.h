/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXError;
@class CLXNativeAdView;

/**
 * Delegate for native ad lifecycle events.
 *
 * The required callbacks (load, fail, click) fire for all native adapters.
 * The optional callbacks are adapter-dependent — not every ad network provides
 * the underlying events. When the winning adapter does not support an optional
 * callback, it simply never fires. Implement optional methods defensively and
 * do not rely on them for correctness-critical logic.
 *
 * All callbacks are delivered on the main queue.
 */
@protocol CLXNativeAdDelegate <NSObject>

@required

/**
 * Called when a native ad has been loaded.
 *
 * @param nativeAdView The rendered native ad view, or nil for late-binding flow.
 *   Non-nil when: (a) loadAdIntoAdView: was used (same view returned), or
 *   (b) loadAd was used and the ad unit is configured for template rendering server-side.
 *   Nil when: loadAd was used and no template is configured (late-binding).
 * @param ad The ad metadata object. Access ad.nativeAd for native-specific assets.
 */
- (void)didLoadNativeAd:(nullable CLXNativeAdView *)nativeAdView forAd:(CLXAd *)ad
    NS_SWIFT_NAME(didLoadNativeAd(_:for:));

/**
 * Called when a native ad fails to load.
 * @param adUnitId The ad unit identifier that failed
 * @param error The error describing the failure
 */
- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitId error:(CLXError *)error
    NS_SWIFT_NAME(didFailToLoadNativeAd(forAdUnitIdentifier:error:));

/**
 * Called when the user clicks the native ad.
 * @param ad The ad that was clicked
 */
- (void)didClickNativeAd:(CLXAd *)ad
    NS_SWIFT_NAME(didClickNativeAd(_:));

@optional

/**
 * Called when a loaded native ad expires before being rendered.
 * The publisher should destroy the ad and reload.
 * @param ad The ad that expired
 */
- (void)didExpireNativeAd:(CLXAd *)ad
    NS_SWIFT_NAME(didExpireNativeAd(_:));

/**
 * Called when the user hides or reports the ad via the ad network's opt-out control
 * (e.g., AdChoices). The ad creative is invalidated after this fires — remove it
 * from the UI and optionally load a replacement. In a feed context, advance to
 * the next item.
 *
 * Only fires on user-initiated opt-out, not on scroll or programmatic destroy.
 *
 * @note Adapter-dependent. Only fires when the underlying ad network provides an
 *       ad-hidden/ad-reported callback. Currently supported by Meta Audience Network.
 *       Not all adapters will fire this callback. If the winning ad comes from an
 *       adapter that does not support it, this method is never called.
 * @param ad The ad that was hidden/reported
 */
- (void)didCloseNativeAd:(CLXAd *)ad
    NS_SWIFT_NAME(didCloseNativeAd(_:));

@end

NS_ASSUME_NONNULL_END
