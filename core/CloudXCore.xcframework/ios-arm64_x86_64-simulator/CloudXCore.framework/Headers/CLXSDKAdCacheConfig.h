/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXSDKAdCacheConfig.h
 * @brief Global kill-switch envelope for the warm ad cache (destroy-keeps-fill).
 *
 * Parsed from the top-level `adCacheConfig` object on the SDK init response.
 * The cache is reactive-only (it never initiates auctions); `enabled` is the
 * global on/off, while the per-ad-unit `adCacheEnabled` flag on
 * `CLXSDKConfigAdUnit` is the routine gate. Default OFF: when the server omits
 * the `adCacheConfig` envelope the SDK keeps today's byte-identical destroy
 * behavior (nothing deposited). An explicit `{"enabled": true}` turns the
 * feature on globally; each ad unit still opts in via `adCacheEnabled`.
 *
 * `preloadEnabled` and `preloadCommitRateFloorPct` are parsed and stored now
 * but consumed in a later phase (impression-triggered warm preload).
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC
@interface CLXSDKAdCacheConfig : NSObject

/** Global kill-switch. When NO, the cache deposits and adopts nothing. */
@property (nonatomic, readonly) BOOL enabled;

/**
 * @brief Global gate for impression-triggered warm preload (phase 4). Parsed
 *        and stored now; not yet consumed by the SDK runtime.
 */
@property (nonatomic, readonly) BOOL preloadEnabled;

/**
 * @brief Server-driven floor (0-100) below which the SDK auto-disables preload
 *        for an ad unit whose observed commit rate falls under it. 0 means the
 *        floor is disabled. Parsed and stored now; consumed in phase 4.
 */
@property (nonatomic, readonly) NSInteger preloadCommitRateFloorPct;

- (instancetype)initWithEnabled:(BOOL)enabled
                  preloadEnabled:(BOOL)preloadEnabled
        preloadCommitRateFloorPct:(NSInteger)preloadCommitRateFloorPct NS_DESIGNATED_INITIALIZER;

/**
 * @brief SDK-published defaults used when the server omits `adCacheConfig`.
 *        `enabled` defaults to NO so an unconfigured host keeps today's
 *        destroy behavior (nothing deposited).
 */
+ (instancetype)defaultConfig;

/**
 * @brief Parses a `CLXSDKAdCacheConfig` from the `adCacheConfig` JSON object.
 * @param dict The `adCacheConfig` object from the SDK init response. May be nil.
 * @return A config whose fields mirror the server payload, or nil when `dict`
 *         is nil / not a dictionary so the caller can fall back to
 *         `+defaultConfig`. Absent or wrong-type fields fall back to defaults.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dict;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
