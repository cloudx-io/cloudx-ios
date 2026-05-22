/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class CLXSDKBlock;

NS_ASSUME_NONNULL_BEGIN

/**
 * Single source of truth for [CLXSDKBlock] construction. Init request, bid request,
 * and any future surface (arbiter, telemetry envelope) all build the same
 * block from the same providers — building inline at each call site invites field
 * drift between surfaces.
 *
 * Immutable after construction; safe to share across threads after init. UIScreen /
 * UIDevice values are snapshotted inside init via a main-thread dispatch when the
 * caller is not main-thread — subsequent -create calls are pure reads with no
 * main-thread hop, so the bid path is not charged per-request.
 */
@interface CLXSDKBlockProvider : NSObject

/**
 * @param sdkVersion CloudX SDK semantic version string.
 * @param pluginVersion Plumbed by callers from their plugin-bridge configuration
 *   (Flutter / React Native bridges write this to NSUserDefaults at SDK init; the
 *   SDK init path reads it and passes it here). Pass nil when not running under a
 *   plugin.
 * @param userAgent WebView-derived User-Agent string captured at SDK init. Stable
 *   per process lifetime — locking at provider init matches the Android wire-parity
 *   pattern (process-cached UA) and avoids re-resolving WKWebView on each create.
 *   Pass nil if UA resolution is deferred; deviceUA will be omitted from the block.
 */
- (instancetype)initWithSdkVersion:(NSString *)sdkVersion
                     pluginVersion:(nullable NSString *)pluginVersion
                         userAgent:(nullable NSString *)userAgent;

/**
 * Process-wide shared instance, lazy-resolved on first access. Reads sdkVersion
 * from CLXSystemInformation, pluginVersion from NSUserDefaults, and userAgent
 * from the shared CLXUserAgentProvider — callers don't need to thread these
 * values manually, and both the init request and bid request paths get the
 * same provider (matches Android's DI-injected single instance).
 *
 * @warning Ordering contract: the first call wins lazy resolution and freezes
 *   the snapshot for the SDK lifetime. CLXUserAgentProvider must be warmed via
 *   prepareWithCompletion: BEFORE the first +shared call, otherwise the
 *   singleton captures an empty userAgent and deviceUA is permanently omitted
 *   from every wire payload. The init path in CLXSDKInitNetworkService
 *   guarantees this ordering today; any new caller that resolves +shared
 *   (telemetry init, eager metric trackers, tests) must verify the UA cache
 *   is populated first.
 */
+ (instancetype)shared;

/**
 * Builds an SDKBlock from current system state. Safe to call from any thread —
 * UIKit values are already snapshotted in init.
 *
 * Process-stable fields (deviceUA, devicePPI, deviceScreenW/H, deviceType) come
 * from values captured at init. Dynamic fields (deviceConnectionType, geoUtcoffset)
 * are read fresh per call.
 */
- (CLXSDKBlock *)create;

@end

NS_ASSUME_NONNULL_END
