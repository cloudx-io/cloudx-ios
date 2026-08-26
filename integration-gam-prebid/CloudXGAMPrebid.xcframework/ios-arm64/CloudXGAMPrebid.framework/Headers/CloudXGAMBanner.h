//
//  CloudXGAMBanner.h
//  CloudXGAMPrebid
//

#import <UIKit/UIKit.h>
#import "CLXGamFacadeCore.h"

@class GADResponseInfo;
@protocol CloudXGAMAdListener;

NS_ASSUME_NONNULL_BEGIN

/** Banner sizes supported by the GAM prebid banner facade. */
typedef NS_ENUM(NSInteger, CloudXGAMBannerFormat) {
    CloudXGAMBannerFormatBanner,
    CloudXGAMBannerFormatMREC,
};

/** GAM-side lifecycle bridge installed by the custom event at render time. */
@protocol CLXGamBannerGamBridge <NSObject>
/** Forward the CloudX impression into GAM; the bridge reports it to GMA at most once. */
- (void)reportImpression;
- (void)reportClicked;
- (void)reportOpened;
- (void)reportClosed;
@end

/**
 * Prebid banner/MREC facade.
 *
 * `load` runs a single CloudX auction for the next GAM refresh cycle — GAM owns
 * the refresh cadence, so auto-refresh is disabled before every load and the
 * publisher re-runs `load` per cycle for fresh key-values.
 */
@interface CloudXGAMBanner : CLXGamFacadeCore

- (instancetype)initWithPlacement:(NSString *)placement
                           format:(CloudXGAMBannerFormat)format
                         listener:(id<CloudXGAMAdListener>)listener;

/** @brief Run one CloudX auction; key-values arrive via the listener. */
- (void)load;

/**
 * @brief Report the GAM auction result from the publisher's GAM load callback.
 * @param responseInfo The response from the banner's GAM load, or nil on failure.
 */
- (void)notifyGamResponse:(nullable GADResponseInfo *)responseInfo;

@end

/** Custom event hooks; not publisher API. */
@interface CloudXGAMBanner (Internal)

/**
 * Returns the view GAM should render, parking the bridge that will report for it; nil when
 * not ready. Call BEFORE consuming the registration and before `onDispatchConsumed:`, so a
 * missing view fails the dispatch with the registration still pending. `onDispatchConsumed:`
 * then retires the view and the bridge together.
 */
- (nullable UIView *)viewForGamWithBridge:(id<CLXGamBannerGamBridge>)bridge;

@end

NS_ASSUME_NONNULL_END
