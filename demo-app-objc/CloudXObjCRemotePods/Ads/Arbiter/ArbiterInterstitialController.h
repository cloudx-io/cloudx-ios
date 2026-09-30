#import <UIKit/UIKit.h>

@class CLXArbiterPlatform;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ArbiterEventType) {
    ArbiterEventTypeLoaded,
    ArbiterEventTypeLoadFailed,
    /** A round finished. `platform` is `CLXArbiterPlatform.none` when no winner was selected. */
    ArbiterEventTypeArbiterCompleted,
    /** Both platforms settled without a fill, so there is nothing to arbitrate. */
    ArbiterEventTypeNoCandidates,
    ArbiterEventTypeShown,
    ArbiterEventTypeShowFailed,
    ArbiterEventTypeClosed,
    ArbiterEventTypeClicked,
    ArbiterEventTypeRevenueReported,
};

/**
 * An event from the arbiter flow. `platform` names the platform it came from and is nil for
 * NoCandidates and RevenueReported. `message` is set for the failures, `bidCount` for
 * ArbiterCompleted, and `revenue`, `currencyCode` and `accepted` for RevenueReported.
 */
@interface ArbiterEvent : NSObject

@property (nonatomic, readonly) ArbiterEventType type;
@property (nonatomic, strong, readonly, nullable) CLXArbiterPlatform *platform;
@property (nonatomic, copy, readonly, nullable) NSString *message;
@property (nonatomic, readonly) NSInteger bidCount;
@property (nonatomic, readonly) double revenue;
@property (nonatomic, copy, readonly, nullable) NSString *currencyCode;
@property (nonatomic, readonly) BOOL accepted;

- (instancetype)init NS_UNAVAILABLE;

@end

typedef void (^ArbiterEventHandler)(ArbiterEvent *event);

/**
 * Trusted Arbiter for interstitials. CloudX and AdMob load in parallel, the ones that fill become
 * bids, and `-[CloudXCore arbiterWithConfiguration:completion:]` picks the platform to show.
 *
 * The arbiter runs as soon as both platforms have settled (loaded or failed) and the winner is
 * stored, so `show` makes no arbiter or network call. It returns nil when no winner is prepared,
 * and the app carries on without an ad. Call `load` after an ad closes to start the next round; it
 * reloads only the platform that has no fill.
 *
 * AdMob bids carry no price. CloudX prices them from the revenue this controller forwards after
 * every AdMob impression through `-[CloudXCore reportRevenueData:]`, so that forwarding is a
 * required part of the integration, not analytics.
 *
 * Pass NO for `cloudXAvailable` when CloudX initialization failed or did not answer. AdMob is then
 * the only candidate and wins each round here, without a call into an SDK that is not initialized.
 * Both SDKs report on the main queue, so `onEvent` is called there too.
 */
@interface ArbiterInterstitialController : NSObject

- (instancetype)initWithViewController:(UIViewController *)viewController
                        cloudXAdUnitId:(NSString *)cloudXAdUnitId
                         adMobAdUnitId:(NSString *)adMobAdUnitId
                       cloudXAvailable:(BOOL)cloudXAvailable
                               onEvent:(ArbiterEventHandler)onEvent NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/** YES from a show call until that ad closes or fails to show. */
@property (nonatomic, readonly, getter=isShowing) BOOL showing;

/** YES while a load or an arbiter round is in flight, so another event is still coming. */
@property (nonatomic, readonly, getter=isBusy) BOOL busy;

/**
 * Loads each platform that holds no fill, then runs a new round once both have settled. Does
 * nothing while a round is in flight or an ad is showing.
 */
- (void)load;

/**
 * Shows the stored winner and returns its platform. Returns nil when there is nothing to show:
 * no winner is prepared, an ad is already showing (check `isShowing`), or the winner's ad expired,
 * in which case `load` reloads that platform and runs a new round.
 */
- (nullable CLXArbiterPlatform *)show;

- (void)dispose;

@end

NS_ASSUME_NONNULL_END
