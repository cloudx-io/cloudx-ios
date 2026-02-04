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
 * @param adUnitId The ad unit ID that failed to load
 * @param error The CLXError containing error code, message, and optional underlying error
 */
- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error NS_SWIFT_NAME(didFailToLoadAd(_:error:));

/**
 * Called when ad is clicked.
 * @param ad The ad that was clicked
 */
- (void)didClickAd:(CLXAd *)ad NS_SWIFT_NAME(didClick(_:));

@end

NS_ASSUME_NONNULL_END
