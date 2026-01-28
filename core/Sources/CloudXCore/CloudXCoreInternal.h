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

// SDK Configuration (internal)
#import <CloudXCore/CLXSDKConfigEndpointObject.h>

// Initialization
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXDIContainer.h>

// Bidding
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>

// Tracking Services
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillImpressionDefaultModel.h>
#import <CloudXCore/CLXRillImpressionProperties.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>

// Metrics & Events
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXPayloadBuilder.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEventDaoImpl.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsDebugger.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXEventType.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>

// Session Management
#import <CloudXCore/CLXSession.h>
#import <CloudXCore/CLXSessionDaoImpl.h>
#import <CloudXCore/CLXSessionMetrics.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>

// Database
#import <CloudXCore/CLXDatabaseProtocol.h>
#import <CloudXCore/CLXDatabaseSchema.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXDaoProtocols.h>
#import <CloudXCore/CLXBaseDao.h>

// Performance
#import <CloudXCore/CLXPerformanceMetric.h>
#import <CloudXCore/CLXPerformanceDaoImpl.h>

// Network Services
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXEndpointResolver.h>
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
@interface CloudXCore (Internal)

/**
 * Track SDK errors for analytics reporting
 * @param error The error to track
 * @discussion Internal method used by CLXErrorReporter - not part of public API
 */
+ (void)trackSDKError:(NSError *)error;

#pragma mark - Native Ads (Internal - not part of public API)

/**
 * Create a native ad (internal use only)
 * @param placement The placement name
 * @param viewController The view controller for presentation
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object or nil if placement is invalid
 * @discussion This API is internal and not exposed publicly. For adapter and testing use only.
 */
- (nullable CLXNativeAdView *)createNativeAdWithPlacement:(NSString *)placement
                                           viewController:(UIViewController *)viewController
                                                 delegate:(nullable id<CLXNativeDelegate>)delegate;

/**
 * Create a native banner ad (internal use only)
 * @param placement The placement name
 * @param viewController The view controller for presentation
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object or nil if placement is invalid
 * @discussion This API is internal and not exposed publicly. For adapter and testing use only.
 */
- (nullable CLXNativeAdView *)createNativeBannerWithPlacement:(NSString *)placement
                                               viewController:(UIViewController *)viewController
                                                     delegate:(nullable id<CLXNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
