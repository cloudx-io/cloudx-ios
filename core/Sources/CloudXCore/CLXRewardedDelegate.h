/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewardedDelegate.h
 * @brief Rewarded ad delegate protocol
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdDelegate.h>

@class CLXRewardedInterstitial;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXRewardedDelegate
 * @brief Delegate protocol for rewarded ad events
 * 
 * Extends BaseAdDelegate with rewarded-specific callbacks.
 */
@protocol CLXRewardedDelegate <CLXAdDelegate>

/**
 * Called when user is rewarded.
 * @param ad ad that was rewarded
 */
- (void)userRewarded:(CLXAd *)ad;

/**
 * Called when rewarded video started.
 * @param ad ad that was started
 */
- (void)rewardedVideoStarted:(CLXAd *)ad;

/**
 * Called when rewarded video completed.
 * @param ad ad that was completed
 */
- (void)rewardedVideoCompleted:(CLXAd *)ad;

@end

NS_ASSUME_NONNULL_END 