#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallFillState.h"

@class GADRequest;
@class GADResponseInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Per-format wrapper over one GMA ad preloader singleton.
 *
 * Conforming objects hold no state: they are interchangeable handles onto the
 * format's GMA preloader singleton. Every method is keyed by preload ID.
 */
@protocol CLXGoogleWaterfallPreloaderFacade <NSObject>

/**
 * @brief Starts preloading for a preload ID.
 * @param preloadID Key for this set of preloaded ads.
 * @param adUnitId Google ad unit to request.
 * @param bufferSize Maximum ads buffered for this preload ID.
 * @param request Ad request to preload with.
 * @param delegate Receives preload events.
 * @return NO when the preloader rejected the start.
 */
- (BOOL)startPreloadID:(NSString *)preloadID
              adUnitId:(NSString *)adUnitId
            bufferSize:(NSUInteger)bufferSize
               request:(GADRequest *)request
              delegate:(id)delegate;

/**
 * @brief Reads the next preloaded ad's response info without removing it.
 * @param preloadID Key for this set of preloaded ads.
 * @return nil when no ad is buffered.
 */
- (nullable GADResponseInfo *)peekResponseInfoForPreloadID:(NSString *)preloadID;

/**
 * @brief Removes and returns the next preloaded ad.
 * @param preloadID Key for this set of preloaded ads.
 * @return nil when no ad is buffered.
 */
- (nullable id)pollAdForPreloadID:(NSString *)preloadID;

/**
 * @brief Stops preloading and discards buffered ads for a preload ID.
 * @param preloadID Key for this set of preloaded ads.
 */
- (void)stopAndRemoveForPreloadID:(NSString *)preloadID;

@end

/**
 * @brief Builds the facade for a fullscreen format.
 * @param format Placement format to wrap.
 * @return nil for a format with no GMA preloader.
 */
id<CLXGoogleWaterfallPreloaderFacade> _Nullable
CLXGoogleWaterfallPreloaderFacadeForFormat(CLXGoogleWaterfallPlacementFormat format);

/**
 * @brief Whether a format is served by the preloader path.
 * @param format Placement format to test.
 * @return YES for interstitial, rewarded, and app-open.
 */
BOOL CLXGoogleWaterfallFormatIsFullscreen(CLXGoogleWaterfallPlacementFormat format);

NS_ASSUME_NONNULL_END
