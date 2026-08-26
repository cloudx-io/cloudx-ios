//
//  CLXGamPriceTier.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief One range of a price bucket ladder: bucket width `step` up to and including `max`.
 *
 * A tier covers the eCPM range above the previous tier's `max` up to its own `max`; the first
 * tier in a ladder starts at 0. Coarser steps in the higher tiers keep the number of GAM line
 * items manageable when the ladder has to reach a high eCPM.
 */
@interface CLXGamPriceTier : NSObject

/** @brief Highest USD eCPM this tier covers, inclusive. */
@property (nonatomic, readonly) double max;

/** @brief Bucket width in USD eCPM inside this tier. */
@property (nonatomic, readonly) double step;

/**
 * @brief Creates a tier covering up to `max` in increments of `step`.
 *
 * @param max Highest USD eCPM the tier covers, inclusive.
 * @param step Bucket width in USD eCPM.
 * @return The tier.
 */
- (instancetype)initWithMax:(double)max step:(double)step NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
