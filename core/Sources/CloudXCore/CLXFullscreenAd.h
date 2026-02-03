/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXFullscreenAd.h
 * @brief Protocol for fullscreen ad formats (interstitial, rewarded)
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for fullscreen ad formats that require explicit show() gating.
 * This protocol is used by interstitial and rewarded ads which need isReady
 * to determine when show() can be called.
 *
 * Note: Load state is communicated via delegate callbacks, matching the Android SDK.
 */
@protocol CLXFullscreenAd <NSObject>

/**
 * Indicates whether the ad is ready to be displayed.
 */
@property (nonatomic, readonly) BOOL isReady;

/**
 * Loads the ad. This method initiates the ad loading process.
 */
- (void)load;

/**
 * Destroys the ad and cleans up all associated resources.
 * After calling this method, the ad instance should not be used.
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
