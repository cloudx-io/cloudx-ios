//
//  CLXSessionMetrics.h
//  CloudXCore
//
//  Created by CloudX iOS Team
//  Copyright (c) 2024 CloudX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Data model for session metrics snapshot.
 * Represents impression frequency and duration for current session.
 *
 * Immutable value object following SOLID principles:
 * - Single Responsibility: Only holds session metric data
 * - Open/Closed: Extensible through composition, closed for modification
 * - Immutable: All properties readonly for thread safety
 */
@interface CLXSessionMetrics : NSObject

/// Total impression count across all ad formats
@property (nonatomic, assign, readonly) float depth;

/// Banner impression count
@property (nonatomic, assign, readonly) float bannerDepth;

/// Medium Rectangle (MREC) impression count
@property (nonatomic, assign, readonly) float mediumRectangleDepth;

/// Fullscreen (interstitial) impression count
@property (nonatomic, assign, readonly) float fullDepth;

/// Native ad impression count
@property (nonatomic, assign, readonly) float nativeDepth;

/// Rewarded ad impression count
@property (nonatomic, assign, readonly) float rewardedDepth;

/// App open ad impression count
@property (nonatomic, assign, readonly) float appOpenDepth;

/// Session duration in seconds since first impression
@property (nonatomic, assign, readonly) float durationSeconds;

/**
 * Designated initializer for session metrics.
 *
 * @param depth Total impression count
 * @param bannerDepth Banner impression count
 * @param mediumRectangleDepth MREC impression count
 * @param fullDepth Fullscreen impression count
 * @param nativeDepth Native impression count
 * @param rewardedDepth Rewarded impression count
 * @param appOpenDepth App open impression count
 * @param durationSeconds Session duration in seconds
 * @return Initialized session metrics instance
 */
- (instancetype)initWithDepth:(float)depth
                  bannerDepth:(float)bannerDepth
         mediumRectangleDepth:(float)mediumRectangleDepth
                    fullDepth:(float)fullDepth
                  nativeDepth:(float)nativeDepth
                rewardedDepth:(float)rewardedDepth
                 appOpenDepth:(float)appOpenDepth
              durationSeconds:(float)durationSeconds NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a zero-initialized session metrics instance.
 * Used for new sessions with no impressions yet.
 */
+ (instancetype)zeroMetrics;

@end

NS_ASSUME_NONNULL_END

