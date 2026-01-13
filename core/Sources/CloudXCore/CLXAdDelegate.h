/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdDelegate.h
 * @brief Base protocol for all ad delegates
 */

#import <Foundation/Foundation.h>

@class CLXAd;
@class CLXError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base protocol for all ad delegates.
 * Provides common delegate methods for all ad types.
 */
@protocol CLXAdDelegate <NSObject>

/**
 * Called when ad is loaded.
 * @param ad The ad that was loaded
 */
- (void)didLoadAd:(CLXAd *)ad NS_SWIFT_NAME(didLoad(_:));

/**
 * Called when ad fails to load with error.
 * @param placementName The placement name that failed to load
 * @param error The CLXError containing error code, message, and optional underlying error
 */
- (void)didFailToLoadAd:(NSString *)placementName error:(CLXError *)error NS_SWIFT_NAME(didFailToLoadAd(_:error:));

/**
 * Called when ad is displayed.
 * @param ad The ad that was displayed
 */
- (void)didDisplayAd:(CLXAd *)ad NS_SWIFT_NAME(didDisplay(_:));

/**
 * Called when ad fails to display.
 * @param ad The ad that failed to display
 * @param error The CLXError containing error code, message, and optional underlying error
 */
- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error NS_SWIFT_NAME(didFailToDisplay(_:error:));

/**
 * Called when ad is hidden.
 * @param ad The ad that was hidden
 */
- (void)didHideAd:(CLXAd *)ad NS_SWIFT_NAME(didHide(_:));

/**
 * Called when ad is clicked.
 * @param ad The ad that was clicked
 */
- (void)didClickAd:(CLXAd *)ad NS_SWIFT_NAME(didClick(_:));

/**
 * Called when ad impression is detected.
 * @param ad The ad that was shown
 */
- (void)didRecordImpressionForAd:(CLXAd *)ad NS_SWIFT_NAME(didRecordImpression(for:));

/**
 * Called when revenue is paid for the ad.
 * Triggered after NURL is successfully sent to server endpoint.
 * @param ad The ad for which revenue was paid
 */
- (void)didPayRevenueForAd:(CLXAd *)ad NS_SWIFT_NAME(didPayRevenue(for:));

@end

NS_ASSUME_NONNULL_END
