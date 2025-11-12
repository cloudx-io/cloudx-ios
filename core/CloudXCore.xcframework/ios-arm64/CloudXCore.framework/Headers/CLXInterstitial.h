/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXInterstitial.h
 * @brief Interstitial ad class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXPublisherFullscreenAdBase.h>
#import <CloudXCore/CLXInterstitialDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXInterstitial represents an interstitial ad in the CloudX SDK.
 * Interstitial ads are full-screen ads that appear at natural transition points in an app.
 */
@interface CLXInterstitial : CLXPublisherFullscreenAdBase

/**
 * Delegate that receives events related to the interstitial ad.
 */
@property (nonatomic, weak, nullable) id<CLXInterstitialDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
