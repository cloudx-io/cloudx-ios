/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdExpirationDelegate.h
 * @brief Protocol for receiving expired-ad reload events
 */

#import <Foundation/Foundation.h>

@class CLXAd;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for receiving fullscreen ads that the SDK reloaded after the loaded ad expired unshown.
 * Set the expirationDelegate property on an interstitial, rewarded or app open ad to receive it.
 *
 * @note Delivered on the main queue.
 */
@protocol CLXAdExpirationDelegate <NSObject>

/**
 * Called when the SDK replaced an expired ad with a newly loaded one. If the expired ad
 * was being shown, this arrives after it is dismissed.
 * @param expiredAd The ad that expired
 * @param newAd The replacement ad, now ready to show
 */
- (void)didReloadExpiredAd:(CLXAd *)expiredAd withNewAd:(CLXAd *)newAd NS_SWIFT_NAME(didReloadExpiredAd(_:with:));

@end

NS_ASSUME_NONNULL_END
