#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import "CLXGoogleWaterfallFillState.h"
#import "CLXGoogleWaterfallPreloaderFacade.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Runs one GMA preloader per provisioned fullscreen placement.
 *
 * Bid time reads a buffered ad's response info without consuming it. Show time
 * consumes the ad. Banner, MREC, and native placements are not handled here.
 */
@interface CLXGoogleWaterfallPreloaderRegistry : NSObject

/**
 * @brief Creates a registry over the provisioned placements.
 * @param placements Provisioned placements; non-fullscreen entries are ignored.
 * @param bufferSize Ads to buffer per placement.
 * @param facadeProvider Supplies the preloader for a format; nil result skips the placement.
 * @param logger Adapter logger.
 */
- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                        bufferSize:(NSUInteger)bufferSize
                    facadeProvider:(id<CLXGoogleWaterfallPreloaderFacade> _Nullable (^)(CLXGoogleWaterfallPlacementFormat format))facadeProvider
                            logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief Starts a preloader for every fullscreen placement.
 */
- (void)startAll;

/**
 * @brief Whether an ad unit is provisioned for preloading.
 * @param adUnitId Google ad unit.
 * @return YES when a preloader is configured for the ad unit.
 */
- (BOOL)hasAdUnit:(NSString *)adUnitId;

/**
 * @brief Reads the buffered ad's response info without consuming the ad.
 * @param adUnitId Google ad unit.
 * @return nil when no ad is buffered or the ad unit is not provisioned.
 */
- (nullable GADResponseInfo *)peekResponseInfoForAdUnit:(NSString *)adUnitId;

/**
 * @brief Consumes the buffered ad. Call only when the publisher intends to show.
 * @param adUnitId Google ad unit.
 * @return nil when no ad is buffered or the ad unit is not provisioned.
 * @note Each call consumes one buffered ad and triggers a refill.
 */
- (nullable id)pollAdForShow:(NSString *)adUnitId;

/**
 * @brief Snapshot of every buffered fill, for the bid token.
 * @return One entry per ad unit with a buffered ad.
 */
- (NSArray<CLXGoogleWaterfallFillEntry *> *)snapshotFills;

/**
 * @brief Stops every preloader and discards buffered ads.
 */
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
