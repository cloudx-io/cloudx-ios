/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdDelegate.h
 * @brief Base protocol for all ad delegates
 */

#import <Foundation/Foundation.h>

@class CLXAd;
@class CLXError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base protocol for all ad delegates.
 * Provides common delegate methods for all ad types.
 *
 * @note Threading contract: all delegate methods declared by this protocol
 * (and protocols that extend it — `CLXBannerDelegate`, `CLXFullscreenAdDelegate`,
 * `CLXNativeDelegate`, `CLXInterstitialDelegate`, `CLXRewardedDelegate`,
 * `CLXAdRevenueDelegate`) are delivered on the main queue. The SDK does not
 * promise next-runloop deferral — when an SDK call originates on the main
 * queue, the delegate callback may fire inline before the SDK call returns.
 * Implementations that re-enter the SDK from a delegate method (e.g. calling
 * `[banner load]` from `didFailToLoadAd:`) must be re-entrant-safe.
 */
@protocol CLXAdDelegate <NSObject>

/**
 * Called when ad is loaded.
 * @param ad The ad that was loaded
 */
- (void)didLoadAd:(CLXAd *)ad NS_SWIFT_NAME(didLoad(_:));

/**
 * Called when ad fails to load with error.
 * @param adUnitId The ad unit ID that failed to load
 * @param error The CLXError containing error code, message, and optional underlying error
 */
- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error NS_SWIFT_NAME(didFailToLoadAd(_:error:));

/**
 * Called when ad is clicked.
 * @param ad The ad that was clicked
 */
- (void)didClickAd:(CLXAd *)ad NS_SWIFT_NAME(didClick(_:));

@end

NS_ASSUME_NONNULL_END
