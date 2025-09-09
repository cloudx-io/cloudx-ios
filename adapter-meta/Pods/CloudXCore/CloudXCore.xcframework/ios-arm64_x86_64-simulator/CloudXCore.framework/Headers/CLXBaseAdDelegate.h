/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBaseAdDelegate.h
 * @brief Base protocol for all ad delegates
 */

#import <Foundation/Foundation.h>

@protocol CLXAd;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base protocol for all ad delegates.
 * Provides common delegate methods for all ad types.
 */
@protocol CLXBaseAdDelegate <NSObject>

/**
 * Called when ad is loaded.
 * @param ad The ad that was loaded
 */
- (void)didLoadWithAd:(id<CLXAd>)ad;

/**
 * Called when ad fails to load with error.
 * @param ad The ad that failed to load
 * @param error The error that caused the failure
 */
- (void)failToLoadWithAd:(id<CLXAd>)ad error:(NSError *)error;

/**
 * Called when ad is shown.
 * @param ad The ad that was shown
 */
- (void)didShowWithAd:(id<CLXAd>)ad;

/**
 * Called when ad fails to show.
 * @param ad The ad that failed to show
 * @param error The error that caused the failure
 */
- (void)failToShowWithAd:(id<CLXAd>)ad error:(NSError *)error;

/**
 * Called when ad is closed.
 * @param ad The ad that was closed
 */
- (void)didHideWithAd:(id<CLXAd>)ad;

/**
 * Called when ad is clicked.
 * @param ad The ad that was clicked
 */
- (void)didClickWithAd:(id<CLXAd>)ad;

/**
 * Called when ad impression is detected.
 * @param ad The ad that was shown
 */
- (void)impressionOn:(id<CLXAd>)ad;

/**
 * Called when ad is closed by user action.
 * @param ad The ad that was closed
 */
- (void)closedByUserActionWithAd:(id<CLXAd>)ad;

@end

NS_ASSUME_NONNULL_END 