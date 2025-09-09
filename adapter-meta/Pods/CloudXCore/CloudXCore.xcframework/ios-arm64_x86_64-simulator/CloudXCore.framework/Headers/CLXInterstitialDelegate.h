/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXInterstitialDelegate.h
 * @brief Interstitial ad delegate protocol
 */

#import <Foundation/Foundation.h>

@class CloudXInterstitial;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CloudXInterstitialDelegate
 * @brief Delegate protocol for interstitial ad events
 * 
 * Extends BaseAdDelegate with interstitial-specific callbacks.
 */
@protocol CLXInterstitialDelegate <CLXBaseAdDelegate>

@end

NS_ASSUME_NONNULL_END 