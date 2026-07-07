/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXFullscreenAdDelegate.h
 * @brief Fullscreen ad delegate protocol for interstitial, rewarded, and app open ads
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdDelegate.h>

@class CLXAd;
@class CLXError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for fullscreen ad delegates (interstitial, rewarded, and app open).
 * Extends CLXAdDelegate with display lifecycle callbacks.
 *
 * @note Threading contract: see `CLXAdDelegate`. All callbacks (inherited and
 * fullscreen-specific) deliver on the main queue and may fire inline relative
 * to the SDK call that triggered them.
 */
@protocol CLXFullscreenAdDelegate <CLXAdDelegate>

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

@end

NS_ASSUME_NONNULL_END
