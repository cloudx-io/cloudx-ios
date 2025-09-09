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
@class CLXBidAdSource;
@class CLXBidAdSourceResponse;
@class CLXConfigImpressionModel;

/**
 * Centralized service responsible for setting up and sending Rill analytics events.
 * Follows single responsibility principle and provides clean, testable interface.
 */
@interface CLXRillTrackingService : NSObject

/**
 * Initializes the Rill tracking service with required dependencies
 * @param reportingService The service used to send tracking events
 */
- (instancetype)initWithReportingService:(id<CLXAdEventReporting>)reportingService;

/**
 * Sets up Rill tracking data and sends bid request event
 * @param bidResponse The bid response containing ad data
 * @param impModel The impression model containing account information
 * @param placementID The placement identifier
 * @param loadCount The load attempt count
 * @return YES if setup was successful, NO otherwise
 */
- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                             placementID:(NSString *)placementID
                               loadCount:(NSInteger)loadCount;

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
 * Checks if tracking data is properly configured
 * @return YES if ready to send events, NO otherwise
 */
- (BOOL)isReadyForTracking;

@end

NS_ASSUME_NONNULL_END
