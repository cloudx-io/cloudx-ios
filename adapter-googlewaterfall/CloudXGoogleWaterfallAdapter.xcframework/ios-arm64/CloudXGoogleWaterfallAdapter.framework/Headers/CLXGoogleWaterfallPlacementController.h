#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "CLXGoogleWaterfallFillState.h"
#import "CLXGoogleWaterfallAdLoader.h"

@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXGoogleWaterfallControllerState) {
    CLXGoogleWaterfallControllerStateIdle = 0,
    CLXGoogleWaterfallControllerStateLoading,
    CLXGoogleWaterfallControllerStateCached,
    CLXGoogleWaterfallControllerStateBackoff,
    CLXGoogleWaterfallControllerStatePermanentFail,
};

@interface CLXGoogleWaterfallPlacementController : NSObject

@property (nonatomic, strong, readonly) CLXGoogleWaterfallPlacementConfig *config;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallControllerState state;
@property (nonatomic, assign, readonly) uint64_t loadingStartedAtMs;
@property (nonatomic, assign, readonly) uint64_t backoffNextAttemptAtMs;
@property (nonatomic, assign, readonly) uint64_t cachedAtMs;

- (instancetype)initWithConfig:(CLXGoogleWaterfallPlacementConfig *)config
                adLoaderFactory:(id<CLXGoogleWaterfallAdLoader> (^)(CLXGoogleWaterfallPlacementConfig *config))adLoaderFactory
                          queue:(dispatch_queue_t)queue
                          clock:(uint64_t (^)(void))clock
                         logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startLoad;
- (void)markLoadTimedOut;
- (void)markBackoffElapsed;
- (BOOL)markFillExpired;
- (void)maybeStartRefresh;
- (nullable id)acquire;
- (nullable CLXGoogleWaterfallFillEntry *)currentFillEntry;
- (void)pause;
- (void)resume;
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
