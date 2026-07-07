//
//  CLXPangleInitializer.h
//  CloudXPangleAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Pangle (ByteDance) advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXPangleInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

/// Refreshes PA consent on the shared PAGConfig.
/// Call before every ad load and signal collection to pick up mid-session
/// consent changes; Pangle SDK does not poll IAB strings between calls.
+ (void)refreshPrivacySettings;

/// Placements map stashed during init: CloudX ad unit ID → Pangle placement ID.
+ (NSDictionary<NSString *, NSString *> *)storedPlacements;

/// Pangle placement ID for a CloudX ad unit ID, or @c nil when the stashed
/// map has no entry for it. Used by bidder-signals collection so each auction's
/// token carries the slot that belongs to the ad unit being requested.
+ (nullable NSString *)placementIdForAdUnitId:(NSString *)adUnitId;

/// Resolve placement ID: checks @c serverExtras[@"placement_id"] first,
/// falls back to the stashed map keyed by @c adUnitId.
+ (nullable NSString *)resolvePlacementIdFromExtras:(NSDictionary *)extras adUnitId:(NSString *)adUnitId;

@end

NS_ASSUME_NONNULL_END
