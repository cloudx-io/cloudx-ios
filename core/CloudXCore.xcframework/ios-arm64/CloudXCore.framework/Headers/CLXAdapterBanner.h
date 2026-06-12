/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterBanner.h
 * @brief Abstract base class for banner adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterBannerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for banner adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -showFromViewController:, @c -destroy. Subclasses populate @c _bannerView
 * during the load lifecycle. The @c delegate retain-cycle break must happen in
 * @c -destroy.
 *
 * @important Adapter implementations MUST NOT invoke any
 * @c CLXAdapterBannerDelegate method from @c -init or other construction
 * paths. The factory (@c CLXAdapterBannerFactory) constructs the adapter
 * with no delegate; the wrapper (@c CLXBannerAdapterWrapper) attaches
 * itself as the adapter's delegate immediately after construction. Any
 * callback fired during @c -init will be silently dropped.
 *
 * To be renamed to @c CLXAdapterAdView under CXD-1403.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterBanner : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterBannerDelegate> _Nullable _delegate;
    UIView * _Nullable _bannerView;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterBannerDelegate> delegate;

/// View containing the banner.
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;

/// Loads the banner. Subclass MUST override.
- (void)load;

/// Shows the banner ad from the given view controller. Subclass MUST override.
/// @param viewController View controller from which the banner is shown.
- (void)showFromViewController:(UIViewController *)viewController;

/// Destroys the banner ad. Subclass MUST override.
/// Subclass MUST nil @c _delegate to break the retain cycle.
- (void)destroy;

@end

/**
 * Delegate for the banner adapter.
 * Provides callbacks for banner ad events.
 */
@protocol CLXAdapterBannerDelegate <NSObject>

/// Called when the adapter has loaded the banner.
- (void)didLoadBanner:(CLXAdapterBanner *)banner;

/// Called when the adapter failed to load the banner.
- (void)failToLoadBanner:(nullable CLXAdapterBanner *)banner error:(nullable NSError *)error;

/// Called when the adapter has shown the banner.
- (void)didShowBanner:(CLXAdapterBanner *)banner;

/// Called when the adapter has tracked impression.
- (void)impressionBanner:(CLXAdapterBanner *)banner;

/// Called when the adapter has tracked click.
- (void)clickBanner:(CLXAdapterBanner *)banner;

/// Called when the banner was closed by user action.
- (void)closedByUserActionBanner:(CLXAdapterBanner *)banner;

@optional

/// Called when the banner expands.
- (void)didExpandBanner:(CLXAdapterBanner *)banner;

/// Called when the banner collapses.
- (void)didCollapseBanner:(CLXAdapterBanner *)banner;

/// Called when a banner that previously succeeded @c didLoadBanner: enters a
/// terminal failure state (e.g. WebContent process termination after the
/// initial load callback). Distinct from @c failToLoadBanner:error: which
/// signals pre-load failure; the protocol contract is
/// @c didLoadBanner: xor @c failToLoadBanner: on the initial load, and this
/// method is the post-load terminal-failure shape.
- (void)bannerDidFailAfterLoad:(CLXAdapterBanner *)banner error:(NSError *)error;

/// Called when the adapter tracked an impression and has per-impression extras
/// to report (e.g. realized revenue keys: @c revenue (dollars), @c currencyCode).
/// Adapters that report impression-level revenue call this instead of
/// @c impressionBanner:. The wrapper treats a nil/absent @c extraInfo
/// identically to @c impressionBanner:.
- (void)impressionBanner:(CLXAdapterBanner *)banner extraInfo:(nullable NSDictionary *)extraInfo;

@end

NS_ASSUME_NONNULL_END
