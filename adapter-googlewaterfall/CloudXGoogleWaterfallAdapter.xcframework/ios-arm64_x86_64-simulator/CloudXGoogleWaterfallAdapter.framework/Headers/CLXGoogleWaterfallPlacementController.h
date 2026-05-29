#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "CLXGoogleWaterfallFillState.h"

@class CLXGoogleWaterfallFillEntry;

NS_ASSUME_NONNULL_BEGIN

/// Coarse lifecycle state for a single placement. Mirrors Android FillState.
typedef NS_ENUM(NSInteger, CLXGoogleWaterfallControllerState) {
    CLXGoogleWaterfallControllerStateIdle = 0,
    CLXGoogleWaterfallControllerStateLoading,
    CLXGoogleWaterfallControllerStateCached,
    CLXGoogleWaterfallControllerStateBackoff,
    CLXGoogleWaterfallControllerStatePermanentFail,
};

/// Manages the prefetch + cache lifecycle for a single AdMob placement. Holds at
/// most one GADBannerView. All state mutation is serialized on the injected
/// queue. Mirrors Android PlacementController.
@interface CLXGoogleWaterfallPlacementController : NSObject <GADBannerViewDelegate>

@property (nonatomic, strong, readonly) CLXGoogleWaterfallPlacementConfig *config;
/// Current coarse state. Read on the controller's queue for a consistent snapshot.
@property (nonatomic, assign, readonly) CLXGoogleWaterfallControllerState state;
/// Monotonic ms timestamp the current Loading started (0 when not Loading).
@property (nonatomic, assign, readonly) uint64_t loadingStartedAtMs;
/// Monotonic ms timestamp the current Backoff next-attempt is due (0 when not Backoff).
@property (nonatomic, assign, readonly) uint64_t backoffNextAttemptAtMs;

/// @param adViewFactory Builds a fresh GADBannerView for this placement (sized
///        per format). The controller owns load + destroy of the returned view.
/// @param queue Serial queue for all state mutation.
/// @param clock Returns current time in ms (injectable for tests).
- (instancetype)initWithConfig:(CLXGoogleWaterfallPlacementConfig *)config
                  adViewFactory:(GADBannerView *(^)(CLXGoogleWaterfallPlacementConfig *config))adViewFactory
                          queue:(dispatch_queue_t)queue
                          clock:(uint64_t (^)(void))clock NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Start an AdMob load. Caller (worker) guarantees Idle. No-op otherwise.
- (void)startLoad;
/// Worker calls when a Loading has exceeded the stuck-load threshold.
- (void)markLoadTimedOut;
/// Worker calls when the Backoff delay has elapsed (Backoff → Idle).
- (void)markBackoffElapsed;
/// Hand off the cached view to a serve consumer (Cached → Idle). Nil if not Cached.
/// Single-use: caller owns the view (including destroy) afterward.
- (nullable GADBannerView *)acquire;
/// Read-only fills snapshot. Nil unless Cached. Zero probes → ["Probe_F0"].
- (nullable CLXGoogleWaterfallFillEntry *)currentFillEntry;
/// Pause/resume the held view (app background/foreground). No-op when none held.
- (void)pause;
- (void)resume;
/// Release any held view. Called on worker teardown / re-init.
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
