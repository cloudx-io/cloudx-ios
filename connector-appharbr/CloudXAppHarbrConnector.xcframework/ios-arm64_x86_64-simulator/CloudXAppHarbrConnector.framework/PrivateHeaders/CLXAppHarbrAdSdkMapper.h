/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAppHarbrAdSdkMapper.h
 * @brief Translates a CloudX ad-network name to AppHarbr's @c AdSdk enum case.
 *
 * CloudX resolves the winning bid's ad network as a string (the @c CLXAdNetwork
 * wire values, e.g. "meta", "vungle", "googleWaterfall") and forwards it on
 * @c CLXAdQualityRequest.adNetwork. AppHarbr's @c analyzeAd requires an @c AdSdk
 * enum case identifying the underlying network SDK — not the mediation layer.
 * This mapper is the single source of truth for that translation.
 *
 * Unknown / unmapped networks map to @c CLXAppHarbrAdSdkNone, which AppHarbr
 * rejects with result 7 (unsupportedAdNetwork) — the correct, observable
 * outcome for a network AppHarbr genuinely does not support. The connector
 * fails open on result 7.
 */

#import <Foundation/Foundation.h>
#import "CLXAppHarbrSDKBridge.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Stateless translator from a CloudX ad-network name (a @c CLXAdNetwork wire
 * value) to the AppHarbr @c AdSdk enum case for the same underlying network SDK.
 *
 * Thread-safe: no mutable state. Returns @c CLXAppHarbrAdSdkNone for nil, empty,
 * or unrecognized networks.
 */
@interface CLXAppHarbrAdSdkMapper : NSObject

/**
 * Maps a CloudX ad-network name to the AppHarbr @c AdSdk enum case.
 *
 * @param networkName A @c CLXAdNetwork wire value (e.g. "meta", "vungle",
 *                   "googleWaterfall"), nil, or empty. Comparison is
 *                   case-sensitive against the canonical wire values.
 * @return The matching @c CLXAppHarbrAdSdk case, or @c CLXAppHarbrAdSdkNone
 *         when the network is unknown, nil, or empty.
 */
+ (CLXAppHarbrAdSdk)adSdkForNetworkName:(nullable NSString *)networkName;

@end

NS_ASSUME_NONNULL_END
