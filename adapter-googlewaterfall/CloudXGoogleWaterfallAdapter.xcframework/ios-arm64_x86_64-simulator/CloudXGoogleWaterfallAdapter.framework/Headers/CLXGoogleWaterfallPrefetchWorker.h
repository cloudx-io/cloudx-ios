#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallFillState.h"

@class GADBannerView;
@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallPrefetchWorker : NSObject

- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                     adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                     adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory
                             queue:(dispatch_queue_t)queue
                             clock:(uint64_t (^)(void))clock
                      tickInterval:(NSTimeInterval)tickInterval;
- (instancetype)init NS_UNAVAILABLE;

- (void)start;

- (void)tickOnce;

- (NSArray<CLXGoogleWaterfallFillEntry *> *)snapshotFills;

- (nullable GADBannerView *)acquireForLoad:(NSString *)adUnitId;

- (BOOL)hasAdUnit:(NSString *)adUnitId;

- (void)pauseAll;
- (void)resumeAll;

- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
