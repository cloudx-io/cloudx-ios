//
//  CloudXGAMInterstitial.h
//  CloudXGAMPrebid
//

#import <UIKit/UIKit.h>
#import "CLXGamFacadeCore.h"

@class GADResponseInfo;
@class CLXAd;
@class CLXError;
@protocol CloudXGAMAdListener;

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM-side fullscreen lifecycle bridge installed by the custom event when it
 * presents the CloudX creative. The facade fans the CloudX display lifecycle
 * out to this bridge so GAM sees the same events as its own mediated ads.
 */
@protocol CLXGamFullscreenGamBridge <NSObject>
- (void)reportDisplayed:(CLXAd *)ad;
- (void)reportClicked:(CLXAd *)ad;
- (void)reportHidden:(CLXAd *)ad;
- (void)reportDisplayFailed:(CLXAd *)ad error:(CLXError *)error;
@end

/**
 * Prebid interstitial facade.
 *
 * `load` runs a single CloudX auction; on fill the listener receives the
 * key-values to attach to the next GAM request. When GAM selects the CloudX
 * line item, its custom event calls `showFromGamWithViewController:bridge:` to
 * present the cached creative.
 */
@interface CloudXGAMInterstitial : CLXGamFacadeCore

- (instancetype)initWithPlacement:(NSString *)placement
                         listener:(id<CloudXGAMAdListener>)listener;

/** @brief Run one CloudX auction; key-values arrive via the listener. */
- (void)load;

/**
 * @brief Report the GAM auction result from the publisher's GAM load callback.
 * @param responseInfo The response from the interstitial's GAM load, or nil on failure.
 */
- (void)notifyGamResponse:(nullable GADResponseInfo *)responseInfo;

@end

/** Custom event hooks; not publisher API. */
@interface CloudXGAMInterstitial (Internal)

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
                              bridge:(id<CLXGamFullscreenGamBridge>)bridge;

@end

NS_ASSUME_NONNULL_END
