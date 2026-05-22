/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdRevenueDelegate.h
 * @brief Protocol for receiving ad revenue events
 */

#import <Foundation/Foundation.h>

@class CLXAd;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for receiving ad revenue events.
 * Set the revenueDelegate property on an ad instance to receive revenue callbacks.
 *
 * @note Threading contract: `didPayRevenueForAd:` is delivered on the main
 * queue and may fire inline relative to the SDK call that triggered it (see
 * `CLXAdDelegate` for the broader SDK threading contract). Implementations
 * must be re-entrant-safe if they invoke SDK methods from this callback.
 */
@protocol CLXAdRevenueDelegate <NSObject>

/**
 * Called when revenue is paid for the ad.
 * Triggered when an ad impression is recorded.
 * @param ad The ad for which revenue was paid
 */
- (void)didPayRevenueForAd:(CLXAd *)ad NS_SWIFT_NAME(didPayRevenue(for:));

@end

NS_ASSUME_NONNULL_END
