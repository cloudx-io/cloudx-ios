/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXCoreInternal.h
 * @brief Internal headers for CloudXCore - not part of the public API.
 *
 * These headers are accessible via direct import but are subject to change
 * without notice. Use the main CloudXCore.h umbrella for stable public APIs.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCoreAPI.h>

// Forward declarations for internal types
@class CLXAdNetworkFactories;
@class CLXConfigImpressionModel;

// =============================================================================
// MARK: - Internal Implementation Headers
// =============================================================================
// These are imported here to ensure module compatibility.
// They are NOT part of the public API and may change without notice.

// Publisher Ad Implementations
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXPublisherNative.h>

// Native (internal - not exposed in public API)
#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeDelegate.h>
#import <CloudXCore/CLXNativeAdView.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>

// Initialization
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXDIContainer.h>

// Bidding
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>

// ILRD (Impression Level Revenue Data)
#import <CloudXCore/CLXIlrdProvider.h>
#import <CloudXCore/CLXAlIlrd.h>
#import <CloudXCore/CLXIlrdService.h>
#import <CloudXCore/CLXIlrdNetworkService.h>
#import <CloudXCore/CLXIlrdTracker.h>

// Tracking Services
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>
#import <CloudXCore/CLXSessionTracker.h>
#import <CloudXCore/CLXSessionNetworkService.h>

// Metrics & Events
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXPayloadBuilder.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsDebugger.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXEventType.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>

// Session Management (in-memory tracking, no database)
#import <CloudXCore/CLXSessionMetrics.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>

// Database
#import <CloudXCore/CLXSQLiteDatabase.h>

// Network Services
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXReachabilityService.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXSKAdNetworkService.h>

// State & Storage
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXLogStore.h>

// Timers
#import <CloudXCore/CLXBackgroundTimer.h>
#import <CloudXCore/CLXBannerTimerService.h>

// Utilities
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXUIApplicationProxy.h>

// Categories
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/URLSession+CLX.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal extension of CloudXCore for SDK-internal use only
 */
@class CLXAdNetworkFactories;
@class CLXConfigImpressionModel;

@interface CloudXCore (Internal)

/**
 * Check if a specific adapter has completed initialization
 * @param adapterName The name of the adapter (e.g., "meta", "vungle")
 * @return YES if the adapter is ready, NO otherwise
 * @discussion Internal API used by bid request logic to avoid race conditions during SDK initialization
 */
- (BOOL)isAdapterReady:(NSString *)adapterName;

/**
 * Create an impression model for tracking
 * @param auctionID The auction ID for the impression
 * @return Impression model or nil if creation fails
 * @discussion Internal API used by ad objects for impression tracking
 */
- (nullable CLXConfigImpressionModel *)createImpModelWithAuctionID:(NSString *)auctionID;

/**
 * Track SDK errors for analytics reporting
 * @param error The error to track
 * @discussion Internal method used by CLXErrorReporter - not part of public API
 */
+ (void)trackSDKError:(NSError *)error;

#pragma mark - Ad Unit Configuration (Internal)

/**
 * Get ad unit configuration by ID
 * @param adUnitId The ad unit ID to look up (e.g., "um9Ek08ScJBWuzSMTyW3b")
 * @return The ad unit configuration or nil if not found
 * @discussion Internal method for looking up ad unit configs - not part of public API
 */
- (nullable CLXSDKConfigAdUnit *)adUnitConfigForId:(NSString *)adUnitId;

/**
 * Get all available ad unit IDs
 * @return Array of ad unit IDs, or empty array if SDK not initialized
 * @discussion Internal method for error messaging - not part of public API
 */
- (NSArray<NSString *> *)availableAdUnitIds;

#pragma mark - Internal SDK Properties and Methods

/**
 * Ad network factories for creating adapter instances
 * @discussion Internal property for adapter creation - not part of public API
 */
@property (nonatomic, strong, readonly) CLXAdNetworkFactories *adNetworkFactories;

#pragma mark - Native Ads (Internal - not part of public API)

/**
 * Create a native ad (internal use only)
 * @param adUnitId The ad unit identifier
 * @param viewController The view controller for presentation
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object or nil if ad unit is invalid
 * @discussion This API is internal and not exposed publicly. For adapter and testing use only.
 */
- (nullable CLXNativeAdView *)createNativeAdWithAdUnitId:(NSString *)adUnitId
                                          viewController:(UIViewController *)viewController
                                                delegate:(nullable id<CLXNativeDelegate>)delegate;

/**
 * Create a native banner ad (internal use only)
 * @param adUnitId The ad unit identifier
 * @param viewController The view controller for presentation
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object or nil if ad unit is invalid
 * @discussion This API is internal and not exposed publicly. For adapter and testing use only.
 */
- (nullable CLXNativeAdView *)createNativeBannerWithAdUnitId:(NSString *)adUnitId
                                              viewController:(UIViewController *)viewController
                                                    delegate:(nullable id<CLXNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
