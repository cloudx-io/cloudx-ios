//
//  CloudXGAMNative.h
//  CloudXGAMPrebid
//

#import <UIKit/UIKit.h>
#import "CLXGamFacadeCore.h"
#import "CLXGamNativeGamBridge.h"

@class GADResponseInfo;
@class CLXNativeAd;
@class CLXAd;
@protocol CloudXGAMAdListener;

NS_ASSUME_NONNULL_BEGIN

/**
 * Prebid native facade.
 *
 * `load` runs a single CloudX native auction; on fill the listener receives the
 * key-values to attach to the next GAM request. When GAM selects the CloudX
 * line item, its custom event reads the loaded native ad via the Internal
 * category to compose the GAD-facing native ad.
 */
@interface CloudXGAMNative : CLXGamFacadeCore

- (instancetype)initWithPlacement:(NSString *)placement
                         listener:(id<CloudXGAMAdListener>)listener;

/** @brief Run one CloudX native auction; key-values arrive via the listener. */
- (void)load;

/**
 * @brief Report the GAM auction result from the publisher's GAM load callback.
 * @param responseInfo The response from the native ad's GAM load, or nil on failure.
 */
- (void)notifyGamResponse:(nullable GADResponseInfo *)responseInfo;

@end

/** Custom event hooks; not publisher API. */
@interface CloudXGAMNative (Internal)

/**
 * @brief The loaded CloudX native ad for GAM to render.
 * @return nil when no ad is ready or the ad has expired.
 */
- (nullable CLXNativeAd *)nativeAdForGam;

/**
 * @brief The CloudX ad metadata backing the loaded native ad.
 * @return nil when no ad is ready or the native ad has expired.
 */
- (nullable CLXAd *)adForGam;

/**
 * @brief Bind the GAM mapper to the slot whose ad this dispatch just handed over.
 * @param bridge The mapper GAM will render the dispatched ad through.
 * @discussion Call after `onDispatchConsumed:`. The bridge rides the retired slot, so the
 * dispatched ad keeps reporting its click and impression to the mapper displaying it even
 * once the publisher's next load has started a fresh auction on a new slot.
 */
- (void)installNativeGamBridge:(id<CLXGamNativeGamBridge>)bridge;

@end

NS_ASSUME_NONNULL_END
