//
//  CloudXGAMRewarded.h
//  CloudXGAMPrebid
//

#import <UIKit/UIKit.h>
#import "CLXGamFacadeCore.h"
#import "CloudXGAMInterstitial.h"

@class GADResponseInfo;
@class CLXAd;
@class CLXReward;
@protocol CloudXGAMRewardedListener;

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM-side rewarded lifecycle bridge. Extends the fullscreen bridge with the
 * reward grant so the custom event can forward it to GAM's rewarded callback.
 */
@protocol CLXGamRewardedGamBridge <CLXGamFullscreenGamBridge>
- (void)reportUserRewarded:(CLXAd *)ad reward:(CLXReward *)reward;
@end

/**
 * Prebid rewarded facade.
 *
 * `load` runs a single CloudX auction; on fill the listener receives the
 * key-values to attach to the next GAM request. When GAM selects the CloudX
 * line item, its custom event calls `showFromGamWithViewController:bridge:` to
 * present the cached creative and receive the reward.
 */
@interface CloudXGAMRewarded : CLXGamFacadeCore

- (instancetype)initWithPlacement:(NSString *)placement
                         listener:(id<CloudXGAMRewardedListener>)listener;

/** @brief Run one CloudX auction; key-values arrive via the listener. */
- (void)load;

/**
 * @brief Report the GAM auction result from the publisher's GAM load callback.
 * @param responseInfo The response from the rewarded's GAM load, or nil on failure.
 */
- (void)notifyGamResponse:(nullable GADResponseInfo *)responseInfo;

@end

/** Custom event hooks; not publisher API. */
@interface CloudXGAMRewarded (Internal)

/**
 * @brief YES while the cached ad is loaded and ready — the same gate
 *   `showFromGamWithViewController:bridge:` applies.
 *
 * Checked at dispatch, before the registration is consumed, so an ad CloudXCore has already
 * expired fails the dispatch instead of recording a won event for a render that cannot happen.
 */
- (BOOL)isCxAdReady;

/**
 * @brief Present the loaded CloudX creative for GAM, installing the bridge.
 * @return NO when no ad is ready; the custom event should then fail its render.
 */
- (BOOL)showFromGamWithViewController:(UIViewController *)viewController
                              bridge:(id<CLXGamRewardedGamBridge>)bridge;

@end

NS_ASSUME_NONNULL_END
