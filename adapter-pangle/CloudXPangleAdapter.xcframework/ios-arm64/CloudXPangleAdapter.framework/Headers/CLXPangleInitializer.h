//
//  CLXPangleInitializer.h
//  CloudXPangleAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Pangle (ByteDance) advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXPangleInitializer : CLXAdNetworkInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

/// Refreshes PA consent on the shared PAGConfig.
/// Call before every ad load and signal collection to pick up mid-session
/// consent changes; Pangle SDK does not poll IAB strings between calls.
+ (void)refreshPrivacySettings;

/// Placements map stashed during init: CloudX ad unit ID → Pangle placement ID.
+ (NSDictionary<NSString *, NSString *> *)storedPlacements;

/// First placement ID from the stashed map (used for bid token collection).
+ (nullable NSString *)firstPlacementId;

/// Resolve placement ID: checks @c serverExtras[@"placement_id"] first,
/// falls back to the stashed map keyed by @c adUnitId.
+ (nullable NSString *)resolvePlacementIdFromExtras:(NSDictionary *)extras adUnitId:(NSString *)adUnitId;

@end

NS_ASSUME_NONNULL_END
