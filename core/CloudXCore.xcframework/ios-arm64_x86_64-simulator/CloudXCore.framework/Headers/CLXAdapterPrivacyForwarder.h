/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacyForwarder.h
 * @brief Discovers adapter privacy handlers and forwards resolved privacy settings
 * @details Uses NSClassFromString to discover CLX{Name}PrivacyHandler classes,
 *          mirrors the adapter discovery pattern in CLXAdapterFactoryResolver.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXAdapterPrivacyForwarder
 * @brief Discovers adapter privacy handlers and pushes resolved settings to them
 * @discussion Observes IAB privacy keys in NSUserDefaults via KVO to auto-push on CMP changes.
 *             Call pushCurrentPrivacySettings after manual consent changes.
 */
@interface CLXAdapterPrivacyForwarder : NSObject

/**
 * @brief Shared singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * @brief Builds CLXAdapterPrivacySettings from resolver and pushes to all discovered handlers
 */
- (void)pushCurrentPrivacySettings;

/**
 * @brief Stops observing NSUserDefaults changes
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
