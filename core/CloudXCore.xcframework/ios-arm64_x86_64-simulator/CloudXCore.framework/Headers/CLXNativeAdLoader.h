/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXNativeAdView;
@protocol CLXNativeAdDelegate;
@protocol CLXAdRevenueDelegate;

extern NSString *const CLXNativeVideoDisableFullScreenKey;
extern NSString *const CLXNativeVideoStartUnmutedKey;
extern NSString *const CLXNativeVideoHideMediaControlsKey;

/**
 * Loads and manages native ads for a single ad unit.
 *
 * @note Native ads currently only support Meta Audience Network (FAN).
 *       Loading a native ad unit whose winning bid comes from an unsupported
 *       adapter will fail with a load error. Additional adapter support
 *       (Mintegral, Pangle, etc.) is planned for future releases.
 */
@interface CLXNativeAdLoader : NSObject

#pragma mark - Properties

@property (nonatomic, weak, nullable) id<CLXNativeAdDelegate> nativeAdDelegate;
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;
@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *customData;
@property (nonatomic, copy, readonly) NSString *adUnitIdentifier;

#pragma mark - Video Configuration

/**
 * Video configuration properties control playback behavior for native video ads.
 *
 * These properties are adapter-dependent. Not all adapters support native video
 * or honor these settings. When the winning adapter does not support a given
 * property, the value is silently ignored — no error is raised.
 *
 * Currently supported by: Meta Audience Network (FAN).
 * All properties must be set before calling loadAd.
 */

/**
 * When YES, prevents video ads from entering fullscreen when tapped.
 * Default is NO (fullscreen enabled).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL disableVideoFullScreen;

/**
 * When YES, starts video playback with sound on.
 * Default is NO (muted).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL startVideoUnmuted;

/**
 * When YES, hides video media controls (play/pause, mute/unmute).
 * Default is NO (controls visible).
 * Must be set before calling loadAd.
 * @note Adapter-dependent. Ignored by adapters that do not support native video.
 */
@property (nonatomic, assign) BOOL hideVideoMediaControls;

#pragma mark - Initialization

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Ad Loading

/**
 * Load a native ad. If the ad unit is configured for template rendering server-side,
 * the SDK creates a template view and delivers it via the delegate (Flow A).
 * Otherwise, the view parameter in the delegate callback is nil (Flow C -- late binding).
 */
- (void)loadAd;

/**
 * Load a native ad and render it into the provided view (Flow B -- manual binding).
 * @param adView The native ad view to render into. Must not be nil.
 */
- (void)loadAdIntoAdView:(CLXNativeAdView *)adView;

#pragma mark - Rendering

/**
 * Render a previously loaded ad into a view (for late-binding flow).
 * @param adView The native ad view to render into
 * @param ad The ad to render (must have been received via didLoadNativeAd:forAd:)
 * @return YES if rendering succeeded, NO if the ad is expired or invalid
 */
- (BOOL)renderNativeAdView:(CLXNativeAdView *)adView withAd:(CLXAd *)ad;

#pragma mark - Lifecycle

/**
 * Destroy a loaded ad and release all resources.
 * Must be called for every loaded ad to prevent memory leaks.
 * @param ad The ad to destroy
 */
- (void)destroyAd:(CLXAd *)ad;

/**
 * Destroy the loader and all associated resources.
 */
- (void)destroy;

#pragma mark - Extra Parameters

/**
 * Set a server-side extra parameter to include in bid requests.
 * These are string-keyed, string-valued parameters forwarded to the ad server.
 * @note Currently stored for future bid request enrichment. Not yet included in bid payloads.
 */
- (void)setExtraParameterForKey:(NSString *)key value:(nullable NSString *)value;

/**
 * Set a client-side extra parameter passed directly to the adapter at creation time.
 * These are string-keyed, any-typed parameters forwarded to the adapter factory.
 * Use for adapter-specific configuration (e.g., Google ad view tags).
 */
- (void)setLocalExtraParameterForKey:(NSString *)key value:(nullable id)value;

@end

NS_ASSUME_NONNULL_END
