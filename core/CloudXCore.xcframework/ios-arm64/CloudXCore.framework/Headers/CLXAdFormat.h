/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdFormat.h
 * @brief Common protocol for all ad formats with shared lifecycle methods
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Common protocol for all ad formats that defines shared lifecycle methods.
 * This protocol provides the basic interface that all ad types (banner, interstitial, rewarded, native) implement.
 */
@protocol CLXAdFormat <NSObject>

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
