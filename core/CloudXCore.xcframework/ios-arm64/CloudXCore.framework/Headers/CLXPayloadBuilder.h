/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXTrackingFieldResolver;

/**
 * Centralizes payload construction for metrics events.
 * Builds raw payload strings from a base payload template.
 *
 * The base payload contains a {eventId} placeholder that gets replaced
 * with a unique UUID for each event, preventing backend deduplication.
 *
 * NOTE: iOS implements SDK init and error event tracking differently than Android.
 * Android's PayloadBuilder has buildSdkInitPayload, buildErrorPayload, and buildCrashPayload
 * but iOS handles these inline in CloudXCoreAPI.m (lines 368-390 for SDK init, 1264-1308 for errors).
 * iOS does NOT capture crashes. Only buildMetricPayload is used by MetricsTrackerImpl.
 */
@interface CLXPayloadBuilder : NSObject

/**
 * Factory method to create a PayloadBuilder instance.
 * Matches Android's PayloadBuilder.create() companion object method.
 *
 * @param accountId The account ID for this session
 * @param resolver The tracking field resolver used to build the base payload
 * @return A new PayloadBuilder instance with {eventId} placeholder in base payload
 */
+ (instancetype)createWithAccountId:(NSString *)accountId
              trackingFieldResolver:(CLXTrackingFieldResolver *)resolver;

/**
 * Build payload for metric events.
 * Matches Android's fun buildMetricPayload(eventId: String, metricName: String, metricDetail: String): String
 *
 * @param eventId Unique event ID (typically UUID) to replace {eventId} placeholder
 * @param metricName The metric type name (e.g., "method_create_banner")
 * @param metricDetail The metric detail string (e.g., "1/596" for counter/latency)
 * @return The payload string with {eventId} replaced and metric data appended
 */
- (NSString *)buildMetricPayloadWithEventId:(NSString *)eventId
                                 metricName:(NSString *)metricName
                               metricDetail:(NSString *)metricDetail;

/**
 * The account ID used for encryption.
 */
@property (nonatomic, copy, readonly) NSString *accountId;

// Private initializer - use factory method createWithAccountId:trackingFieldResolver: instead
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
