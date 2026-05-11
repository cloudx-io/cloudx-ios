/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewarded.h
 * @brief Rewarded ad class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXPublisherFullscreenAdBase.h>
#import <CloudXCore/CLXRewardedDelegate.h>
#import <CloudXCore/CLXAdRevenueDelegate.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXRewarded represents a rewarded ad in the CloudX SDK.
 * Rewarded ads are full-screen video ads that users can watch in exchange for in-app rewards.
 */
CLX_PUBLIC
@interface CLXRewarded : CLXPublisherFullscreenAdBase

/**
 * Delegate that receives events related to the rewarded ad.
 */
@property (nonatomic, weak, nullable) id<CLXRewardedDelegate> delegate;

/**
 * Delegate that receives revenue events for the rewarded ad.
 */
@property (nonatomic, weak, nullable) id<CLXAdRevenueDelegate> revenueDelegate;

@end

NS_ASSUME_NONNULL_END



