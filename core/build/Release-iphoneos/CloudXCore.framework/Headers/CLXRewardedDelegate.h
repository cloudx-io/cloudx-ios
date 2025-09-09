/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewardedDelegate.h
 * @brief Rewarded ad delegate protocol
 */

#import <Foundation/Foundation.h>

@class CLXRewardedInterstitial;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXRewardedDelegate
 * @brief Delegate protocol for rewarded ad events
 * 
 * Extends BaseAdDelegate with rewarded-specific callbacks.
 */
@protocol CLXRewardedDelegate <CLXBaseAdDelegate>

/**
 * Called when user is rewarded.
 * @param ad ad that was rewarded
 */
- (void)userRewarded:(id<CLXAd>)ad;

/**
 * Called when rewarded video started.
 * @param ad ad that was started
 */
- (void)rewardedVideoStarted:(id<CLXAd>)ad;

/**
 * Called when rewarded video completed.
 * @param ad ad that was completed
 */
- (void)rewardedVideoCompleted:(id<CLXAd>)ad;

@end

NS_ASSUME_NONNULL_END 