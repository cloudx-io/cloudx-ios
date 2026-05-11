/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRillTrackingService.h
 * @brief Centralized service for Rill analytics tracking across all ad formats
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdEventReporter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting;
@class CLXBidAdSourceResponse;
@class CLXConfigImpressionModel;

/**
 * Centralized service responsible for setting up and sending Rill analytics events.
 * Follows single responsibility principle and provides clean, testable interface.
 *
 * Two surface shapes are exposed: the legacy stateful `setupTrackingDataFromBidResponse:` +
 * `sendImpressionEvent` / `sendClickEvent` path (publisher-as-delegate Track A; survives
 * for legacy callers retained as a test surface), and the stateless
 * `sendImpressionEventWithAuctionId:...` / `sendClickEventWithAuctionId:...` path used
 * by the per-adapter wrapper. The stateless path takes the frozen attribution
 * identifiers directly so a late callback fired after publisher rotation still
 * attributes to the original auction.
 */
@interface CLXRillTrackingService : NSObject

/**
 * Initializes the Rill tracking service with required dependencies
 * @param reportingService The service used to send tracking events
 */
- (instancetype)initWithReportingService:(id<CLXAdEventReporting>)reportingService;

/**
 * Sets up winner-scoped Rill tracking data for subsequent impression/click events.
 * @param bidResponse The bid response containing ad data
 * @param impModel The impression model containing account information
 * @param adUnitId The ad unit identifier
 * @param loadCount The load attempt count
 * @return YES if setup was successful, NO otherwise
 */
- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                                adUnitId:(NSString *)adUnitId
                               loadCount:(NSInteger)loadCount;

/**
 * Sends the legacy bid request (`bidreqenc`) event for a completed auction attempt without a winning bid path,
 * matching Android legacy bid-request timing (success and failure).
 */
- (void)sendLegacyBidRequestAttemptIfPossibleWithImpModel:(CLXConfigImpressionModel *)impModel
                                                auctionId:(NSString *)auctionId;

/**
 * Sends bid request tracking event using previously set up data
 */
- (void)sendBidRequestEvent;

/**
 * Sends impression tracking event using previously set up data
 */
- (void)sendImpressionEvent;

/**
 * Sends click tracking event using previously set up data
 */
- (void)sendClickEvent;

/**
 * Stateless impression emission for the per-adapter wrapper path. Reads
 * attribution identifiers directly from the caller's frozen lifecycle context
 * (typically `CLXAdapterLifecycleContext`) instead of the service's mutable
 * per-instance state. Use this from a per-adapter wrapper so a late callback
 * fired after publisher rotation still attributes to the original auction.
 *
 * `campaignId` is derived inside the service via
 * `[CLXXorEncryption generateCampaignIdBase64:]` — callers do not need to
 * compute or pass it.
 *
 * Tracking-payload data (placement / customData / request / response JSON) is
 * resolved from `CLXTrackingFieldResolver`'s shared per-`auctionId` bucket;
 * the caller is responsible for ensuring that bucket has not been cleared
 * between adapter attach and emission.
 *
 * No-ops (with debug log only) when `auctionId` or `accountId` is nil/empty,
 * so the per-callback site can stay free of guard branches.
 */
- (void)sendImpressionEventWithAuctionId:(nullable NSString *)auctionId
                                   bidId:(nullable NSString *)bidId
                               accountId:(nullable NSString *)accountId;

/**
 * Stateless click emission counterpart to
 * `sendImpressionEventWithAuctionId:bidId:accountId:`. Same attribution semantics,
 * same no-op-on-missing-input behavior.
 */
- (void)sendClickEventWithAuctionId:(nullable NSString *)auctionId
                              bidId:(nullable NSString *)bidId
                          accountId:(nullable NSString *)accountId;

/**
 * Checks if tracking data is properly configured
 * @return YES if ready to send events, NO otherwise
 */
- (BOOL)isReadyForTracking;

@end

NS_ASSUME_NONNULL_END
