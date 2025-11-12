//
//  CLXPlacementLoopIndexTracker.h
//  CloudXCore
//
//  Created by CloudX on 2025-01-13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Tracks loop index (i.e., how many times an ad has sent BidRequest)
 * for each placement within the SDK runtime.
 *
 * Matches Android's PlacementLoopIndexTracker behavior:
 * - Separate counter per placement name
 * - Only incremented for Banner/MREC ads
 * - Interstitials/Rewarded use fixed value (don't increment)
 */
@interface CLXPlacementLoopIndexTracker : NSObject

/**
 * Shared singleton instance
 */
+ (instancetype)shared;

/**
 * Get the current loop index for a placement without incrementing.
 * Returns 0 if placement hasn't been tracked yet.
 *
 * @param placementName The placement name to get count for
 * @return Current loop index value
 */
- (NSInteger)getCountForPlacement:(NSString *)placementName;

/**
 * Get the current loop index and increment it for next time.
 * Used by Banner/MREC ads only.
 *
 * @param placementName The placement name to increment
 * @return Current loop index value (before increment)
 */
- (NSInteger)getAndIncrementForPlacement:(NSString *)placementName;

/**
 * Reset the loop index for a specific placement.
 * Used when banner is destroyed or closed.
 *
 * @param placementName The placement name to reset
 */
- (void)resetForPlacement:(NSString *)placementName;

/**
 * Reset all placement loop indices.
 * Used for testing or SDK reset scenarios.
 */
- (void)resetAll;

@end

NS_ASSUME_NONNULL_END

