//
//  CLXDigitalTurbineUtils.h
//  CloudXDigitalTurbineAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterLogger;

/**
 * Helpers for translating CloudX server-side provisioning into spot identifiers
 * and shared per-request configuration.
 */
@interface CLXDigitalTurbineUtils : NSObject

/**
 * Resolves the placement spot ID for an ad load.
 * Prefers the `placement_id` value provided in server extras; falls back to
 * `spot_id` for legacy SSP versions; finally falls back to the CloudX `adId`
 * when extras are missing or empty.
 */
+ (NSString *)resolveSpotID:(NSDictionary<NSString *, NSString *> *)extras
               fallbackAdId:(NSString *)adId
                     logger:(id<CLXAdapterLogger>)logger;

/**
 * Resolves the canonical placement spot ID from server extras without legacy
 * fallbacks.
 */
+ (nullable NSString *)resolveSpotIDFromExtras:(NSDictionary<NSString *, id> *)extras;

/**
 * Resolves the per-load video mute preference from server extras.
 *
 * Reads the `is_muted` key, accepting common string-typed boolean
 * representations (`"true"`/`"false"`, `"yes"`/`"no"`, `"1"`/`"0"`). Returns
 * `nil` when the key is absent or the value cannot be interpreted — callers
 * should treat `nil` as "no override" and leave the SDK at its current mute
 * state, matching the Android adapter's convention.
 */
+ (nullable NSNumber *)isMutedFromExtras:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
