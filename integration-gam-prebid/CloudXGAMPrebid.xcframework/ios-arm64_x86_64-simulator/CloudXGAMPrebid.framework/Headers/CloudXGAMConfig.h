//
//  CloudXGAMConfig.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

#import "CLXGamPriceTier.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Price bucket configuration for the GAM prebid integration.
 *
 * The bucket ladder must match the `cx_price` key-value targeting set up on the publisher's
 * GAM line items: CloudX floors each bid's eCPM to a multiple of the step that applies at that
 * price and caps it at the top of the ladder, and GAM only has a line item to select if that
 * keyword exists.
 *
 * Apply the configuration before creating any facade; the defaults (a single tier of step 0.10
 * up to 20.0) match the line-item set the GAM setup documentation generates.
 */
@interface CloudXGAMConfig : NSObject

/**
 * @brief The bucket ladder, in ascending order of `max`.
 *
 * Each tier covers the eCPM range above the previous tier's `max` up to its own `max`, with the
 * first tier starting at 0. The last tier's `max` is the ceiling: bids above it are reported
 * there. Ladders with coarse high tiers keep the GAM line-item count manageable while still
 * reaching a high eCPM.
 */
@property (nonatomic, copy) NSArray<CLXGamPriceTier *> *priceBucketTiers;

/**
 * @brief Bucket width in USD eCPM, as a single-tier shorthand for `priceBucketTiers`.
 *
 * Setting it replaces the whole ladder with one tier of this step up to the current ceiling.
 * Reading it returns the first tier's step, which is the step of the whole ladder only when
 * the ladder has a single tier. Must be positive, finite, and a whole number of cents.
 */
@property (nonatomic, assign) double priceBucketStep;

/**
 * @brief Highest bucket in USD eCPM, as a single-tier shorthand for `priceBucketTiers`.
 *
 * Setting it replaces the whole ladder with one tier of the current step up to this ceiling.
 * Reading it returns the last tier's `max`, which is the ceiling of any ladder. Bids above it
 * are reported at the ceiling.
 */
@property (nonatomic, assign) double priceBucketCeiling;

/**
 * @brief The configuration new facades are created with.
 *
 * Reading returns a copy; mutating it has no effect until it is applied.
 */
@property (class, nonatomic, readonly) CloudXGAMConfig *current;

/**
 * @brief Installs `config` as the configuration new facades are created with.
 *
 * Raises an exception for an empty ladder, tier maximums that are not strictly ascending,
 * positive and finite, a step that is not positive and finite, a step below one cent or not
 * cent-aligned, or a step above its own tier's maximum.
 */
+ (void)apply:(CloudXGAMConfig *)config;

@end

NS_ASSUME_NONNULL_END
