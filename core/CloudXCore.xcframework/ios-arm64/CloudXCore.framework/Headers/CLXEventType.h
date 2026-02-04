/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXEventType.h
 * @brief Event type constants matching Android's EventType enum exactly
 *
 * CRITICAL: These values must match Android's EventType.pathSegment values.
 * The server expects these exact strings to identify event types.
 * If you change these values, events will NOT be processed correctly!
 *
 * Android reference: io.cloudx.sdk.internal.tracker.EventType
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Event Type Path Segments (for URLs and JSON)

/**
 * SDK initialization event - sent when SDK initializes
 * Android: EventType.SDK_INIT.pathSegment
 */
extern NSString * const CLXEventTypePathSDKInit;          // "sdkinitenc"

/**
 * Click event - sent when user clicks an ad
 * Android: EventType.CLICK.pathSegment
 */
extern NSString * const CLXEventTypePathClick;            // "clickenc"

/**
 * Impression event - sent when ad is displayed
 * Android: EventType.IMPRESSION.pathSegment
 */
extern NSString * const CLXEventTypePathImpression;       // "sdkimpenc"

/**
 * Bid request event - sent when bid request is made
 * Android: EventType.BID_REQUEST.pathSegment
 */
extern NSString * const CLXEventTypePathBidRequest;       // "bidreqenc"

/**
 * SDK error event - sent when SDK encounters an error
 * Android: EventType.SDK_ERROR.pathSegment
 */
extern NSString * const CLXEventTypePathSDKError;         // "sdkerrorenc"

/**
 * SDK crash event - sent when SDK crashes
 * Android: EventType.SDK_CRASH.pathSegment
 */
extern NSString * const CLXEventTypePathSDKCrash;         // "sdkcrashenc"

/**
 * SDK metrics event - sent for performance metrics
 * Android: EventType.SDK_METRICS.pathSegment
 * CRITICAL: Must use this constant, NOT hardcoded "SDK_METRICS"
 */
extern NSString * const CLXEventTypePathSDKMetrics;       // "sdkmetricenc"

#pragma mark - Event Type Codes (for internal use)

extern NSString * const CLXEventTypeCodeSDKInit;          // "sdkinit"
extern NSString * const CLXEventTypeCodeClick;            // "click"
extern NSString * const CLXEventTypeCodeImpression;       // "imp"
extern NSString * const CLXEventTypeCodeBidRequest;       // "bidreq"
extern NSString * const CLXEventTypeCodeSDKError;         // "error"
extern NSString * const CLXEventTypeCodeSDKCrash;         // "crash"
extern NSString * const CLXEventTypeCodeSDKMetrics;       // "sdkmetricenc"

NS_ASSUME_NONNULL_END
