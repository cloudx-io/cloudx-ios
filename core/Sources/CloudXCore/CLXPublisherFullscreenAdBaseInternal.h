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
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXBidResponse.h>

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
- (void)sendLossNotificationForFailedAdWithError:(nullable NSError *)error;

// Adapter load latency tracking
- (void)trackAdapterLoadLatencyWithError:(nullable NSError *)error;

// Ad close handling
- (void)handleAdClose;
- (void)handleClickTracking;

/**
 * Cleans up state after show failure. Call before invoking didFailToDisplayAd callback.
 * Enables publishers to immediately reload ads in the failure callback.
 */
- (void)handleShowFailure;

// Adapter timeout configuration
- (int64_t)adLoadTimeoutMs;

// Access to private properties (read-only)
@property (nonatomic, copy, readonly, nullable) NSString *adUnitId;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, strong, readonly, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, strong, readonly, nullable) CLXBidResponse *currentBidResponse;
@property (nonatomic, strong, readonly) CLXLogger *logger;
@property (nonatomic, strong, readonly) id<CLXWinLossTracking> winLossTracker;

// Internal state properties (not part of public API)
@property (nonatomic, readonly) BOOL isLoading;

@end

NS_ASSUME_NONNULL_END

