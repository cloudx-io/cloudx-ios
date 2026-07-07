/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterAdView.h
 * @brief Abstract base class for ad view adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterAdViewDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for ad view adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -destroy. Subclasses pass the loaded view in
 * @c didLoadAdView:extras:. The @c delegate retain-cycle break must happen in
 * @c -destroy.
 *
 * @important Adapter implementations MUST NOT invoke any
 * @c CLXAdapterAdViewDelegate method from @c -init or other construction
 * paths. The factory (@c CLXAdapterAdViewFactory) constructs the adapter
 * with no delegate; the wrapper (@c CLXAdViewAdapterWrapper) attaches
 * itself as the adapter's delegate immediately after construction. Any
 * callback fired during @c -init will be silently dropped.
 *
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterAdView : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterAdViewDelegate> _Nullable _delegate;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterAdViewDelegate> delegate;

/// Loads the ad view. Subclass MUST override.
- (void)loadWithParams:(CLXAdapterLoadParams *)loadParams;

/// Destroys the ad view. Subclass MUST override.
/// Subclass MUST nil @c _delegate to break the retain cycle.
- (void)destroy;

/**
 * Called after a loaded banner/MREC view has been inserted into its
 * CLXBannerAdView container.
 *
 * Default: no-op. Override only for adapters whose SDK requires an explicit
 * post-container-attach lifecycle signal. This may be later than load success
 * when the publisher preloads while the banner view is off-screen.
 */
- (void)onAttachedToAdViewContainer;

@end

/**
 * Delegate for the banner adapter.
 * Provides callbacks for banner ad events.
 */
@protocol CLXAdapterAdViewDelegate <NSObject>

/// Called when the adapter has loaded the banner view.
/// @param bannerView Loaded banner view.
/// @param extras Additional adapter-provided callback details.
- (void)didLoadAdView:(UIView *)bannerView extras:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter failed to load the banner.
/// @param error The error that caused the failure.
/// @param extras Additional adapter-provided callback details.
- (void)didFailToLoadAdViewWithError:(nullable NSError *)error extras:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has shown the banner.
/// @param extras Additional adapter-provided callback details.
- (void)didDisplayAdView:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has tracked impression.
/// @param extras Additional adapter-provided callback details.
- (void)didTrackAdViewImpression:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has tracked click.
/// @param extras Additional adapter-provided callback details.
- (void)didClickAdView:(NSDictionary<NSString *, id> *)extras;

/// Called when the banner was hidden by user action.
/// @param extras Additional adapter-provided callback details.
- (void)didHideAdView:(NSDictionary<NSString *, id> *)extras;

@optional

/// Called when the banner expands.
/// @param extras Additional adapter-provided callback details.
- (void)didExpandAdView:(NSDictionary<NSString *, id> *)extras;

/// Called when the banner collapses.
/// @param extras Additional adapter-provided callback details.
- (void)didCollapseAdView:(NSDictionary<NSString *, id> *)extras;

/// Called when a banner that previously succeeded @c didLoadAdView:extras: enters a
/// terminal failure state (e.g. WebContent process termination after the
/// initial load callback). Distinct from @c didFailToLoadAdViewWithError:extras: which
/// signals pre-load failure; the protocol contract is
/// @c didLoadAdView:extras: xor @c didFailToLoadAdViewWithError:extras: on the initial load, and this
/// method is the post-load terminal-failure shape.
/// @param error The error that caused the failure.
/// @param extras Additional adapter-provided callback details.
- (void)didFailAdViewAfterLoadWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
