/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXInterstitialDelegate.h
 * @brief Interstitial ad delegate protocol
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdDelegate.h>

@class CLXInterstitial;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXInterstitialDelegate
 * @brief Delegate protocol for interstitial ad events
 * 
 * Extends BaseAdDelegate with interstitial-specific callbacks.
 */
@protocol CLXInterstitialDelegate <CLXAdDelegate>

@end

NS_ASSUME_NONNULL_END 