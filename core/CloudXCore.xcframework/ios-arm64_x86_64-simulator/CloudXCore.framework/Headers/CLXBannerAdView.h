/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerAdView.h
 * @brief Banner ad view class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>


NS_ASSUME_NONNULL_BEGIN

@protocol CLXBanner;

/**
 * CLXBannerAdView represents a banner ad view in the CloudX SDK.
 * It contains a CLXAd instance for state management and delegates to it for ad lifecycle.
 */
@interface CLXBannerAdView : UIView <CLXBannerDelegate, CLXAdDelegate>

/**
 * The underlying banner ad instance that manages state and lifecycle
 */
@property (nonatomic, strong, readonly) CLXAd *ad;

/**
 * A weak reference to the object that implements CLXBannerDelegate protocol. 
 * This object will receive events related to the banner ad.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * A boolean indicating whether the ad is loaded and ready to be shown.
 * Delegates to the underlying ad instance.
 */
@property (nonatomic, assign, readonly) BOOL isReady;

/**
 * A boolean indicating whether to suspend preloading the ad when it's not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * The ad unit identifier for this banner ad view.
 */
@property (nonatomic, copy, readonly) NSString *adUnitIdentifier;

/**
 * The ad format for this banner ad view.
 */
@property (nonatomic, assign, readonly) CLXBannerType adFormat;

/**
 * The placement identifier for this banner ad view.
 * 
 * Note: This is currently a stub implementation for MAX SDK compatibility.
 * The value can be set but is not yet used in reporting or analytics.
 * Contact CloudX support if you need this functionality enabled.
 */
@property (nonatomic, copy, nullable) NSString *placement;

/**
 * Initializes a new CLXBannerAdView with the given banner, type, and delegate.
 * The frame of the view is set based on the size of the banner type.
 * @param banner The banner instance
 * @param type The banner type
 * @param delegate The delegate to receive events
 * @return Initialized banner ad view
 */
- (instancetype)initWithBanner:(id<CLXBanner>)banner 
                         type:(CLXBannerType)type 
                     delegate:(nullable id<CLXBannerDelegate>)delegate;

/**
 * Starts banner loading process.
 * Delegates to the underlying ad instance.
 * It should be called once after the banner is created.
 * Banner will be automatically reloaded after each show based on placement settings.
 */
- (void)load;

/**
 * Removes the view from its superview and destroys the banner ad.
 * Delegates to the underlying ad instance.
 */
- (void)destroy;

/**
 * Starts auto-refresh for the banner ad.
 * Auto-refresh will continue based on the placement configuration until stopped.
 */
- (void)startAutoRefresh;

/**
 * Stops auto-refresh for the banner ad.
 * The banner will no longer automatically refresh until startAutoRefresh is called again.
 */
- (void)stopAutoRefresh;

@end

NS_ASSUME_NONNULL_END 