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
 *     Render.autoStore/playerConfig) are emitted only when set or non-default
 *     because their primitive types cannot distinguish "absent" from
 *     "default-valued"; this matches the convention of the surrounding fields
 *     within each class. The trade-off is documented at each call site, and
 *     the round-trip test in `CLXAdaptercodeResolutionTests` pins the behavior.
 *   - Optional strings (provider, ctaText, orientation, etc.) are emitted only
 *     when non-nil.
 */

#import <Foundation/Foundation.h>

@class CLXDoubleEndCardConfig, CLXPlayerConfig, CLXAutoStoreConfig;

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
 * @return A dictionary containing only the fields whose primitive types signal "set":
 *         delays > 0, mutedByDefault == YES, non-nil decConfig/ctaText/orientation.
 *         See the file-level emission convention for the absent-vs-default trade-off.
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
