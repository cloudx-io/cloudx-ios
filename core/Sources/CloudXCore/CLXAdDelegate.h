/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdDelegate.h
 * @brief Base protocol for all ad delegates
 */

#import <Foundation/Foundation.h>

@class CLXAd;

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
- (void)didLoadWithAd:(CLXAd *)ad;

/**
 * Called when ad fails to load with error.
 * @param ad The ad that failed to load
 * @param error The error that caused the failure
 */
- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error;

/**
 * Called when ad is shown.
 * @param ad The ad that was shown
 */
- (void)didShowWithAd:(CLXAd *)ad;

/**
 * Called when ad fails to show.
 * @param ad The ad that failed to show
 * @param error The error that caused the failure
 */
- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error;

/**
 * Called when ad is closed.
 * @param ad The ad that was closed
 */
- (void)didHideWithAd:(CLXAd *)ad;

/**
 * Called when ad is clicked.
 * @param ad The ad that was clicked
 */
- (void)didClickWithAd:(CLXAd *)ad;

/**
 * Called when ad impression is detected.
 * @param ad The ad that was shown
 */
- (void)impressionOn:(CLXAd *)ad;

/**
 * Called when revenue is paid for the ad.
 * Triggered after NURL is successfully sent to server endpoint.
 * @param ad The ad for which revenue was paid
 */
- (void)revenuePaid:(CLXAd *)ad;

/**
 * Called when ad is closed by user action.
 * @param ad The ad that was closed
 */
- (void)closedByUserActionWithAd:(CLXAd *)ad;

@end

NS_ASSUME_NONNULL_END
