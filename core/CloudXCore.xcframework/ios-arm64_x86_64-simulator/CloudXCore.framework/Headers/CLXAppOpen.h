/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAppOpen.h
 * @brief App open ad class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXPublisherFullscreenAdBase.h>
#import <CloudXCore/CLXAppOpenDelegate.h>
#import <CloudXCore/CLXAdRevenueDelegate.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXAppOpen represents an app open ad in the CloudX SDK.
 * App open ads are full-screen ads shown while an app is loading or returning to the foreground.
 */
CLX_PUBLIC
@interface CLXAppOpen : CLXPublisherFullscreenAdBase

/**
 * Delegate that receives events related to the app open ad.
 */
@property (nonatomic, weak, nullable) id<CLXAppOpenDelegate> delegate;

/**
 * Delegate that receives revenue events for the app open ad.
 */
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;

@end

NS_ASSUME_NONNULL_END
