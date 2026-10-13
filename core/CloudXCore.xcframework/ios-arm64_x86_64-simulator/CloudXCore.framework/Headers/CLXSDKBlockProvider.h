/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class CLXSDKBlock;

NS_ASSUME_NONNULL_BEGIN

/**
 * Single source of truth for [CLXSDKBlock] construction. Init request, bid request,
 * and the telemetry envelope all build the same block from the same providers —
 * building inline at each call site invites field drift between surfaces.
 *
 * Safe to share across threads after init. UIScreen / UIDevice values are
 * snapshotted inside init via a main-thread dispatch when the caller is not
 * main-thread — subsequent -create calls make no main-thread hop.
 */
@interface CLXSDKBlockProvider : NSObject

/**
 * @param sdkVersion CloudX SDK semantic version string.
 * @param pluginVersion Plumbed by callers from their plugin-bridge configuration
 *   (Flutter / React Native bridges write this to NSUserDefaults at SDK init; the
 *   SDK init path reads it and passes it here). Pass nil when not running under a
 *   plugin.
 * @param userAgent User-Agent string sent as deviceUA in every block this instance
 *   builds. Pass nil to omit deviceUA.
 */
- (instancetype)initWithSdkVersion:(NSString *)sdkVersion
                     pluginVersion:(nullable NSString *)pluginVersion
                         userAgent:(nullable NSString *)userAgent;

/**
 * Process-wide shared instance, lazy-resolved on first access. Reads sdkVersion
 * from CLXSystemInformation and pluginVersion from NSUserDefaults on first access.
 * Reads the user agent from the shared CLXUserAgentProvider at every -create;
 * deviceUA is omitted while that value is empty.
 */
+ (instancetype)shared;

/**
 * Builds an SDKBlock from current system state. Safe to call from any thread.
 *
 * Process-stable fields (devicePPI, deviceScreenW/H, deviceType) come from values
 * captured at init. deviceUA, deviceConnectionType and geoUtcoffset are read per call.
 */
- (CLXSDKBlock *)create;

@end

NS_ASSUME_NONNULL_END
