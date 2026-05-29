#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallFillState.h"

@class GADBannerView;
@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

/// Prefetch orchestrator for the AdMob waterfall adapter. Owns one controller
/// per provisioned adUnitId, ticks every second to drive loads/backoff/timeouts,
/// and exposes the cache for serve + bid-signal snapshots. Mirrors Android
/// GooglePrefetchWorker. All controller-map access is serialized on an internal
/// queue.
@interface CLXGoogleWaterfallPrefetchWorker : NSObject

- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                     adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory NS_DESIGNATED_INITIALIZER;

/// Testing initializer: inject the controller queue, clock, and tick interval.
- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                     adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory
                             queue:(dispatch_queue_t)queue
                             clock:(uint64_t (^)(void))clock
                      tickInterval:(NSTimeInterval)tickInterval;
- (instancetype)init NS_UNAVAILABLE;

/// Start the initial load for every placement and begin the tick loop.
- (void)start;

/// Run one tick of the loop synchronously on the worker queue (testing seam).
- (void)tickOnce;

/// Fills snapshot for the bid request. All Cached controllers, all formats.
- (NSArray<CLXGoogleWaterfallFillEntry *> *)snapshotFills;

/// Single-use cache hand-off for serve. Nil on miss/in-progress/backoff/unknown.
- (nullable GADBannerView *)acquireForLoad:(NSString *)adUnitId;

/// Whether this worker is provisioned for the given adUnitId.
- (BOOL)hasAdUnit:(NSString *)adUnitId;

/// Pause/resume all held views (process background/foreground).
- (void)pauseAll;
- (void)resumeAll;

/// Stop the tick loop and release all held views.
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
