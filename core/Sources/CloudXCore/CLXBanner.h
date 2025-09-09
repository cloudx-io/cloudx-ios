/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBanner.h
 * @brief Banner ad protocol
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterBannerDelegate;

/**
 * CloudXBanner is a protocol for banner ads in the CloudX SDK.
 * Defines banner-specific properties and functionality.
 */
@protocol CLXBanner <CLXAdFormat>

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

@end

NS_ASSUME_NONNULL_END 