/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidResponseExtModels.h
 * @brief Immutable value types for typed ext configuration objects.
 *
 * These models represent nested JSON structures in bid response ext fields.
 * All properties are readonly — instances are created via +configFromDictionary:
 * and are immutable after construction (thread-safe by design).
 *
 * This file hosts the nested ext configuration types. The top-level bid response
 * classes live in CLXBidResponse.h and forward-declare these types.
 *
 * Emission convention used in `-toDictionary` across these types:
 *   - Leaf scalars (BOOL flags on Render and AutoStore) are always emitted so
 *     parse → marshal → reparse preserves the value, including `false`.
 *   - Optional nested containers (PlayerConfig.audio/close/skip/dec/cta,
 *     Render.autoStore/playerConfig) are emitted only when set or non-default.
 *     PlayerConfig audio preserves an explicitly provided value, including
 *     `muted_by_default: false`.
 *   - Optional strings (provider, ctaText, orientation, etc.) are emitted only
 *     when non-nil.
 */

#import <Foundation/Foundation.h>

@class CLXDoubleEndCardConfig, CLXPlayerConfig, CLXAutoStoreConfig, CLXSKOverlayConfig;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Double End Card Config

/**
 * Double End Card creative metadata from player_config.dec.
 *
 * Only the identity/attribution fields are parsed here; URL-based impression and
 * click tracking is handled by the renderer's event layer (not part of this DTO).
 */
@interface CLXDoubleEndCardConfig : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *appIconURL;
@property (nonatomic, copy, readonly, nullable) NSString *appName;
@property (nonatomic, copy, readonly, nullable) NSString *ctaText;
@property (nonatomic, copy, readonly, nullable) NSString *clickThrough;

/**
 * @brief Constructs an immutable CLXDoubleEndCardConfig from a parsed JSON dictionary.
 * @param dictionary The `dec` sub-object from `ext.cloudx.render.player_config`.
 *                   May be `nil` or any non-NSDictionary type — both produce a `nil` return.
 * @return A new instance with optional string fields, or `nil` if `dictionary` is malformed.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dictionary;

/**
 * @brief Marshals this config back to a JSON-equivalent dictionary.
 * @return A dictionary containing only the non-nil string fields. Empty if every field was nil.
 */
- (NSDictionary *)toDictionary;

@end

#pragma mark - SKOverlay Config

/**
 * StoreKit overlay configuration from `bid.ext.skadn.skoverlay`.
 *
 * Unlike the rest of this file, this block is **DSP-supplied**: it is the IAB
 * SKAdNetwork extension shape, not an SSP-injected placement setting, so it
 * lives under `skadn` rather than `cloudx.render`. DSPs send it today and the
 * exchange preserves it, which is why SKOverlay needs no schema work.
 *
 * Delay semantics follow the IAB convention and are NOT interchangeable:
 *   -1  disables the overlay for that phase
 *    0  presents immediately when the phase begins
 *   >0  presents that many seconds into the phase
 */
@interface CLXSKOverlayConfig : NSObject

/// Screen position. 0 = bottom, 1 = bottom-raised. Out-of-range values resolve
/// to bottom rather than throwing — a malformed position must not cost the
/// impression.
@property (nonatomic, assign, readonly) NSInteger position;

/// Whether the user may dismiss the overlay. Absent means dismissible.
@property (nonatomic, assign, readonly) BOOL dismissible;

/// Seconds into video playback before presenting. -1 disables during video.
@property (nonatomic, assign, readonly) NSTimeInterval videoDelay;

/// Seconds into the end card before presenting. -1 disables on the end card.
@property (nonatomic, assign, readonly) NSTimeInterval companionDelay;

/// Seconds before the overlay self-dismisses. -1 leaves it up for the phase.
@property (nonatomic, assign, readonly) NSTimeInterval skDismissDelay;

/// YES when either phase opts in, i.e. there is anything to schedule.
@property (nonatomic, assign, readonly) BOOL isEnabled;

/**
 * @brief Constructs an immutable CLXSKOverlayConfig from a parsed JSON dictionary.
 * @param dictionary The `skoverlay` sub-object from `bid.ext.skadn`. May be `nil`
 *                   or any non-NSDictionary type — both produce a `nil` return.
 * @return A new instance, or `nil` if `dictionary` is malformed.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dictionary;

/// @brief Marshals this config back to a JSON-equivalent dictionary.
- (NSDictionary *)toDictionary;

@end

#pragma mark - Auto Store Config

/**
 * StoreKit auto-overlay behavior from ext.cloudx.render.auto_store.
 */
@interface CLXAutoStoreConfig : NSObject

@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, assign, readonly) BOOL onSkip;
@property (nonatomic, assign, readonly) BOOL onClose;

/**
 * @brief Constructs an immutable CLXAutoStoreConfig from a parsed JSON dictionary.
 * @param dictionary The `auto_store` sub-object from `ext.cloudx.render`.
 *                   May be `nil` or any non-NSDictionary type — both produce a `nil` return.
 * @return A new instance with the three boolean flags (defaulting to `NO` when absent),
 *         or `nil` if `dictionary` is malformed.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dictionary;

/**
 * @brief Marshals this config back to a JSON-equivalent dictionary.
 * @return A dictionary containing all three boolean fields, always emitted so
 *         `false` survives the round-trip.
 */
- (NSDictionary *)toDictionary;

@end

#pragma mark - Player Config

/**
 * Video player configuration from ext.cloudx.render.player_config.
 *
 * Parsed but unused until the renderer's video pipeline lands — M1.1 surfaces
 * the typed shape so later PRs can consume it without changing the DTO.
 */
@interface CLXPlayerConfig : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval closeDelay;
@property (nonatomic, assign, readonly) NSTimeInterval skipDelay;
@property (nonatomic, strong, readonly, nullable) CLXDoubleEndCardConfig *decConfig;
@property (nonatomic, assign, readonly) BOOL mutedByDefault;
@property (nonatomic, copy, readonly, nullable) NSString *ctaText;
@property (nonatomic, copy, readonly, nullable) NSString *orientation;

/**
 * @brief Constructs an immutable CLXPlayerConfig from a parsed JSON dictionary.
 * @param dictionary The `player_config` sub-object from `ext.cloudx.render`.
 *                   May be `nil` or any non-NSDictionary type — both produce a `nil` return.
 * @return A new instance with the optional nested fields populated where present, or `nil`
 *         if `dictionary` is malformed.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dictionary;

/**
 * @brief Marshals this config back to a JSON-equivalent dictionary.
 * @return A dictionary containing only set fields: delays > 0, explicitly
 *         provided mutedByDefault, and non-nil decConfig/ctaText/orientation.
 */
- (NSDictionary *)toDictionary;

@end

#pragma mark - CloudX Render Config

/**
 * SSP-injected publisher placement settings from ext.cloudx.render.
 *
 * DSPs cannot set these — they are controlled by the publisher's dashboard
 * configuration. Only `provider` and the `crtype` on the sibling ext field
 * are consumed today; `networkEndcard`, `clickableVideo`, `autoStore`, and
 * `playerConfig` are parsed placeholders for the renderer pipeline that
 * lands in later M1/M2/M3 PRs.
 */
@interface CLXBidResponseCloudXRender : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *provider;
@property (nonatomic, assign, readonly) BOOL networkEndcard;
@property (nonatomic, assign, readonly) BOOL clickableVideo;
@property (nonatomic, strong, readonly, nullable) CLXAutoStoreConfig *autoStore;
@property (nonatomic, strong, readonly, nullable) CLXPlayerConfig *playerConfig;

/**
 * @brief Constructs an immutable CLXBidResponseCloudXRender from a parsed JSON dictionary.
 * @param dictionary The `render` sub-object from `ext.cloudx`. May be `nil` or any
 *                   non-NSDictionary type — both produce a `nil` return.
 * @discussion Returns a non-nil instance even when the dictionary is empty so callers
 *             can distinguish "render block present but malformed/partial" from
 *             "render block absent" via `provider`. The renderer routing layer
 *             (CLXBidRoute, M1.2) checks `provider == \@"cloudx"`, not `render != nil`.
 * @return A new instance, or `nil` if `dictionary` is malformed.
 */
+ (nullable instancetype)configFromDictionary:(nullable NSDictionary *)dictionary;

/**
 * @brief Marshals this config back to a JSON-equivalent dictionary.
 * @return A dictionary with `provider` (when non-nil), `network_endcard` and
 *         `clickable_video` (always emitted so `false` survives round-trip),
 *         and the nested `auto_store` / `player_config` (when non-nil).
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
