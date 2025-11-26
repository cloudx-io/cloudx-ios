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
- (void)userRewarded:(CLXAd *)ad NS_SWIFT_NAME(userRewarded(_:));

@end

NS_ASSUME_NONNULL_END 