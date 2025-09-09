/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXAdapterBanner.h
 * @brief Protocol for banner adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>

@protocol CLXAdapterBannerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for banner adapters.
 * Banner adapters are responsible for loading and showing banner ads.
 */
@protocol CLXAdapterBanner <CLXDestroyable>

/**
 * Delegate for the adapter, used to notify about ad events.
 */
@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;

/**
 * Flag to indicate if the banner loading timed out.
 */
@property (nonatomic, assign) BOOL timeout;

/**
 * View containing the banner.
 */
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;

/**
 * SDK version of the adapter.
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Loads the banner.
 */
- (void)load;

/// Shows the banner ad from the given view controller.
- (void)showFromViewController:(UIViewController *)viewController;

/// Destroys the banner ad.
- (void)destroy;

@end

/**
 * Delegate for the banner adapter.
 * Provides callbacks for banner ad events.
 */
@protocol CLXAdapterBannerDelegate <NSObject>

/**
 * Called when the adapter has loaded the banner.
 * @param banner The banner that was loaded
 */
- (void)didLoadBanner:(id<CLXAdapterBanner>)banner;

/**
 * Called when the adapter failed to load the banner.
 * @param banner Banner that failed to load
 * @param error Error that caused the failure
 */
- (void)failToLoadBanner:(nullable id<CLXAdapterBanner>)banner error:(nullable NSError *)error;

/**
 * Called when the adapter has shown the banner.
 * @param banner The banner that was shown
 */
- (void)didShowBanner:(id<CLXAdapterBanner>)banner;

/**
 * Called when the adapter has tracked impression.
 * @param banner The banner that was shown
 */
- (void)impressionBanner:(id<CLXAdapterBanner>)banner;

/**
 * Called when the adapter has tracked click.
 * @param banner Banner that was clicked
 */
- (void)clickBanner:(id<CLXAdapterBanner>)banner;

/**
 * Called when the banner was closed by user action.
 * @param banner The banner that was closed
 */
- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner;

@optional

/**
 * Called when the banner expands.
 * @param banner The banner that expanded
 */
- (void)didExpandBanner:(id<CLXAdapterBanner>)banner;

/**
 * Called when the banner collapses.
 * @param banner The banner that collapsed
 */
- (void)didCollapseBanner:(id<CLXAdapterBanner>)banner;

@end

NS_ASSUME_NONNULL_END 