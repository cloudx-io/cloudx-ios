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

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXRewarded represents a rewarded ad in the CloudX SDK.
 * Rewarded ads are full-screen video ads that users can watch in exchange for in-app rewards.
 */
@interface CLXRewarded : CLXPublisherFullscreenAdBase

/**
 * Delegate that receives events related to the rewarded ad.
 */
@property (nonatomic, weak, nullable) id<CLXRewardedDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

