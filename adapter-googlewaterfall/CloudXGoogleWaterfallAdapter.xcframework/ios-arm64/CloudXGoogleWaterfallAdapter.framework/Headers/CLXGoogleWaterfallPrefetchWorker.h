#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import "CLXGoogleWaterfallFillState.h"
#import "CLXGoogleWaterfallAdLoader.h"

@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallPrefetchWorker : NSObject

- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                   adLoaderFactory:(id<CLXGoogleWaterfallAdLoader> (^)(CLXGoogleWaterfallPlacementConfig *config))adLoaderFactory
                            logger:(id<CLXAdapterLogger>)logger;

- (instancetype)initWithPlacements:(NSArray<CLXGoogleWaterfallPlacementConfig *> *)placements
                   adLoaderFactory:(id<CLXGoogleWaterfallAdLoader> (^)(CLXGoogleWaterfallPlacementConfig *config))adLoaderFactory
                             queue:(dispatch_queue_t)queue
                             clock:(uint64_t (^)(void))clock
                      tickInterval:(NSTimeInterval)tickInterval
                            logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)start;

- (void)tickOnce;

- (NSArray<CLXGoogleWaterfallFillEntry *> *)snapshotFills;

- (nullable id)acquireForLoad:(NSString *)adUnitId;

- (BOOL)hasAdUnit:(NSString *)adUnitId;

- (void)pauseAll;
- (void)resumeAll;

- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
