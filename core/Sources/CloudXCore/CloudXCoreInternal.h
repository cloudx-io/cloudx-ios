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

// SDK Configuration (internal)
#import <CloudXCore/CLXSDKConfigEndpointObject.h>

// Initialization
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXInitMetrics.h>
#import <CloudXCore/CLXDIContainer.h>

// Bidding
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>

// Tracking Services
#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXRillTrackingServiceV2.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXRillImpressionDefaultModel.h>
#import <CloudXCore/CLXRillImpressionProperties.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>

// Metrics & Events
#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsTrackerProtocol.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEventDaoImpl.h>
#import <CloudXCore/CLXMetricsNetworkService.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsDebugger.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>

// Session Management
#import <CloudXCore/CLXSession.h>
#import <CloudXCore/CLXSessionDaoImpl.h>
#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXSessionMetrics.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXSessionMetricPerformance.h>

// Database
#import <CloudXCore/CLXDatabaseProtocol.h>
#import <CloudXCore/CLXDatabaseSchema.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXDaoProtocols.h>
#import <CloudXCore/CLXBaseDao.h>

// Rill Events
#import <CloudXCore/CLXRillEvent.h>
#import <CloudXCore/CLXRillEventDaoImpl.h>
#import <CloudXCore/CLXBaseEvent.h>

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

// Retry & Resilience
#import <CloudXCore/CLXRetryHelper.h>
#import <CloudXCore/CLXRetryManager.h>
#import <CloudXCore/CLXExponentialBackoffStrategy.h>

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

// Categories
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/NSDictionary+DynamicPath.h>
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

@end

NS_ASSUME_NONNULL_END
