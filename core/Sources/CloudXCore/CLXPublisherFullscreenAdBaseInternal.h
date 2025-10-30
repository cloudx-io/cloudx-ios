/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherFullscreenAdBaseInternal.h
 * @brief Internal methods for CLXPublisherFullscreenAdBase subclasses
 * 
 * This header exposes internal methods that subclasses (CLXInterstitial, CLXRewarded) can use.
 * This header should NOT be included in the public framework headers.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXPublisherFullscreenAdBase.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal category exposing protected methods for subclasses
 */
@interface CLXPublisherFullscreenAdBase (Internal)

// State management
- (void)transitionToIdleState;
- (void)transitionToReadyState;

// Ad object creation
- (CLXAd *)createAdObject;

// Event firing
- (void)fireLoadSuccessEventForBidID:(NSString *)bidID price:(double)price;
- (void)fireLosingBidLurls;
- (void)fireRenderSuccessEventForBidID:(NSString *)bidID adType:(NSInteger)adType;

// Loss notification
- (void)sendLossNotificationForFailedAd;

// Ad close handling
- (void)handleAdClose;
- (void)handleClickTracking;

// Access to private properties (read-only)
@property (nonatomic, strong, readonly, nullable) CLXBidAdSourceResponse *lastBidResponse;

@end

NS_ASSUME_NONNULL_END

