/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBanner.h
 * @brief Banner ad protocol
 *
 * Note: Unlike fullscreen ads (interstitial/rewarded), banners do not expose
 * isReady or isLoading properties. This matches Android SDK behavior and
 * industry standards (AppLovin MAX). Banner load state is communicated via
 * delegate callbacks. isDestroyed is provided to check if the banner is still valid.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXBanner is a protocol for banner ads in the CloudX SDK.
 * Defines banner-specific properties and functionality.
 *
 * Banners are separate from fullscreen ads and do not share a common protocol.
 */
@protocol CLXBanner <NSObject>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for banner ad events.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * The type of banner ad.
 */
@property (nonatomic, readonly) CLXBannerType bannerType;

/**
 * Loads the banner ad.
 */
- (void)load;

/**
 * Destroys the banner ad and releases resources.
 */
- (void)destroy;

/**
 * Starts auto-refresh for the banner ad.
 */
- (void)startAutoRefresh;

/**
 * Stops auto-refresh for the banner ad.
 */
- (void)stopAutoRefresh;

/**
 * Indicates whether the banner ad has been destroyed and can no longer be used.
 */
@property (nonatomic, readonly) BOOL isDestroyed;

@end

NS_ASSUME_NONNULL_END 