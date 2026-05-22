/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewardedDelegate.h
 * @brief Rewarded ad delegate protocol
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXFullscreenAdDelegate.h>

@class CLXReward;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXRewardedDelegate
 * @brief Delegate protocol for rewarded ad events
 *
 * Extends CLXFullscreenAdDelegate with rewarded-specific callbacks.
 * Mirrors AppLovin MAX SDK's MARewardedAdDelegate pattern.
 *
 * @note Threading contract: see `CLXAdDelegate`. All callbacks (inherited and
 * rewarded-specific) deliver on the main queue and may fire inline relative
 * to the SDK call that triggered them.
 */
@protocol CLXRewardedDelegate <CLXFullscreenAdDelegate>

/**
 * The SDK invokes this method when a user should be granted a reward.
 *
 * @param ad     Ad for which the user earned the reward.
 * @param reward The reward to be granted to the user (contains amount and label/currency).
 */
- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward NS_SWIFT_NAME(didRewardUser(for:with:));

@end

NS_ASSUME_NONNULL_END 