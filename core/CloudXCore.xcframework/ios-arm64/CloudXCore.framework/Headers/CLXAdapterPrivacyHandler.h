/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacyHandler.h
 * @brief Protocol for adapter-specific privacy settings handling
 * @details Each ad network adapter implements this protocol to receive
 *          resolved privacy settings and forward them to its SDK.
 */

#import <Foundation/Foundation.h>

@class CLXAdapterPrivacySettings;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXAdapterPrivacyHandler
 * @brief Protocol that adapter privacy handlers implement to receive privacy updates
 * @discussion Adapters that need privacy settings implement this protocol.
 *             The CLXAdapterPrivacyForwarder discovers handlers via NSClassFromString
 *             and calls updatePrivacySettings: when settings change.
 */
@protocol CLXAdapterPrivacyHandler <NSObject>

@required

/**
 * @brief Called when resolved privacy settings change
 * @param settings The current resolved privacy settings
 */
- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings;

@end

NS_ASSUME_NONNULL_END
