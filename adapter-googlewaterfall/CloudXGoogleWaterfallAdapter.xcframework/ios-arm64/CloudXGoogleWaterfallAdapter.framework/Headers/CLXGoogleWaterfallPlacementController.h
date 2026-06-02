#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "CLXGoogleWaterfallFillState.h"

@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXGoogleWaterfallControllerState) {
    CLXGoogleWaterfallControllerStateIdle = 0,
    CLXGoogleWaterfallControllerStateLoading,
    CLXGoogleWaterfallControllerStateCached,
    CLXGoogleWaterfallControllerStateBackoff,
    CLXGoogleWaterfallControllerStatePermanentFail,
};

@interface CLXGoogleWaterfallPlacementController : NSObject <GADBannerViewDelegate>

@property (nonatomic, strong, readonly) CLXGoogleWaterfallPlacementConfig *config;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallControllerState state;
@property (nonatomic, assign, readonly) uint64_t loadingStartedAtMs;
@property (nonatomic, assign, readonly) uint64_t backoffNextAttemptAtMs;

- (instancetype)initWithConfig:(CLXGoogleWaterfallPlacementConfig *)config
                  adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory
                          queue:(dispatch_queue_t)queue
                          clock:(uint64_t (^)(void))clock NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startLoad;
- (void)markLoadTimedOut;
- (void)markBackoffElapsed;
- (nullable GADBannerView *)acquire;
- (nullable CLXGoogleWaterfallFillEntry *)currentFillEntry;
- (void)pause;
- (void)resume;
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
