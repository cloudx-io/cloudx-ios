/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRillTrackingServiceV2.h
 * @brief Enhanced Rill tracking service with SQLite persistence and Android parity
 * 
 * Features:
 * - Database-first architecture (matches Android EventTracker)
 * - Automatic retry with exponential backoff
 * - Bulk event processing
 * - Offline event queuing
 * - Comprehensive error handling
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXRillEventDao;
@protocol CLXDatabaseProtocol;
@class CLXRillEvent;
@class CLXBidAdSourceResponse;
@class CLXConfigImpressionModel;
@class CLXLogger;

/**
 * Event types matching Android EventType enum
 */
typedef NS_ENUM(NSInteger, CLXRillEventType) {
    CLXRillEventTypeSDKInit = 0,        // "sdkinitenc"
    CLXRillEventTypeClick = 1,          // "clickenc"
    CLXRillEventTypeImpression = 2,     // "sdkimpenc"
    CLXRillEventTypeBidRequest = 3,     // "bidreqenc"
    CLXRillEventTypeSDKError = 4,       // "sdkerrorenc"
    CLXRillEventTypeSDKMetrics = 5      // "sdkmetricenc"
};

/**
 * Enhanced Rill tracking service with Android EventTracker parity
 * Implements database-first architecture with automatic retry and bulk processing
 */
@interface CLXRillTrackingServiceV2 : NSObject

/**
 * Dependencies (injected for testability)
 */
@property (nonatomic, strong, readonly) id<CLXRillEventDao> eventDao;
@property (nonatomic, strong, readonly) CLXLogger *logger;

/**
 * Configuration
 */
@property (nonatomic, copy, nullable) NSString *baseEndpoint;
@property (nonatomic, copy, nullable) NSString *bulkEndpoint;

/**
 * Initialization
 */
- (instancetype)initWithEventDao:(id<CLXRillEventDao>)eventDao;

/**
 * Core tracking methods (matching Android EventTracker interface)
 */
- (void)sendWithEncoded:(NSString *)encoded
             campaignId:(NSString *)campaignId
             eventValue:(NSString *)eventValue
              eventType:(CLXRillEventType)eventType;

- (void)trySendingPendingTrackingEvents;

/**
 * Enhanced tracking methods with field resolution
 */
- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                             placementID:(NSString *)placementID
                               loadCount:(NSInteger)loadCount;

- (void)trackImpressionWithPlacementID:(NSString *)placementID;
- (void)trackClickWithPlacementID:(NSString *)placementID;
- (void)trackConversionWithPlacementID:(NSString *)placementID value:(nullable NSString *)value;

/**
 * Bulk processing
 */
- (void)processPendingEventsInBatch:(NSInteger)batchSize;
- (void)flushAllPendingEvents;

/**
 * Configuration
 */
- (void)setEndpoint:(nullable NSString *)endpointUrl;
- (void)setBulkEndpoint:(nullable NSString *)bulkEndpointUrl;

/**
 * Diagnostics and monitoring
 */
- (NSInteger)pendingEventCount;
- (NSArray<CLXRillEvent *> *)pendingEvents;
- (void)clearFailedEvents;

@end

NS_ASSUME_NONNULL_END
