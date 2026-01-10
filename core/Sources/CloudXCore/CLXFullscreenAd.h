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
 * Note: Banners do not use this protocol - they have their own CLXBanner protocol
 * without isReady/isLoading/isDestroyed, matching Android SDK patterns.
 */
@protocol CLXFullscreenAd <NSObject>

/**
 * Indicates whether the ad is ready to be displayed.
 */
@property (nonatomic, readonly) BOOL isReady;

/**
 * Indicates whether the ad is currently loading.
 */
@property (nonatomic, readonly) BOOL isLoading;

/**
 * Indicates whether the ad has been destroyed and can no longer be used.
 */
@property (nonatomic, readonly) BOOL isDestroyed;

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
