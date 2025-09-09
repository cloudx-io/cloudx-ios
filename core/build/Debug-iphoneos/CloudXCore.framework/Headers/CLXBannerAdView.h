/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerAdView.h
 * @brief Banner ad view class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXBaseAd.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBanner;

/**
 * CLXBannerAdView represents a banner ad view in the CloudX SDK.
 */
@interface CLXBannerAdView : UIView <CLXAd, CLXBannerDelegate, CLXBaseAdDelegate>

/**
 * A weak reference to the object that implements CLXBannerDelegate protocol. 
 * This object will receive events related to the banner ad.
 */
@property (nonatomic, weak, nullable) id<CLXBannerDelegate> delegate;

/**
 * A boolean indicating whether the ad is loaded and ready to be shown.
 */
@property (nonatomic, assign, readonly) BOOL isReady;

/**
 * A boolean indicating whether to suspend preloading the ad when it's not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

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
 * It should be called once after the banner is created.
 * Banner will be automatically reloaded after each show based on placement settings.
 */
- (void)load;

/**
 * Removes the view from its superview and destroys the banner ad.
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 