//
//  CLXGamFacadeCore.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import "CLXGamAdFormat.h"
#import "CLXGamTokenRegistry.h"

@class CloudXGAMKeyValues;
@class CLXGamPriceBucketFormatter;
@class CLXGamResponseEvent;

NS_ASSUME_NONNULL_BEGIN

/**
 * Shared prebid facade logic: token registration, GAM response handling, and
 * telemetry emission. Format facades subclass and implement `releaseCxAd`, which runs only
 * from `destroy` — loss, no-fill, and expiry settle the token's telemetry and never touch
 * the ad, whose lifetime belongs to CloudXCore.
 *
 * Thread safety: methods are not mutually atomic; drive one facade instance
 * from a single thread (typically main). GAM render callbacks arrive on main.
 */
@interface CLXGamFacadeCore : NSObject

- (instancetype)initWithPlacement:(NSString *)placement
                           format:(CLXGamAdFormat)format
                         registry:(CLXGamTokenRegistry *)registry
                  bucketFormatter:(CLXGamPriceBucketFormatter *)bucketFormatter
                        telemetry:(nullable void (^)(CLXGamResponseEvent *event))telemetry;

/** Convenience taking a fixed formatter; `scheduler` and `responseHoldSeconds` are for tests. */
- (instancetype)initWithPlacement:(NSString *)placement
                           format:(CLXGamAdFormat)format
                         registry:(CLXGamTokenRegistry *)registry
                  bucketFormatter:(CLXGamPriceBucketFormatter *)bucketFormatter
                        telemetry:(nullable void (^)(CLXGamResponseEvent *event))telemetry
                        scheduler:(nullable CLXGamScheduler)scheduler
              responseHoldSeconds:(NSTimeInterval)responseHoldSeconds;

/**
 * Designated initializer. `bucketFormatterProvider` is resolved per use rather than captured
 * once, so a `CloudXGAMConfig` applied after the facade was created still governs the buckets
 * it emits — the same freshness the registry's TTL path has always had.
 */
- (instancetype)initWithPlacement:(NSString *)placement
                           format:(CLXGamAdFormat)format
                         registry:(CLXGamTokenRegistry *)registry
          bucketFormatterProvider:(CLXGamPriceBucketFormatter *(^)(void))bucketFormatterProvider
                        telemetry:(nullable void (^)(CLXGamResponseEvent *event))telemetry
                        scheduler:(nullable CLXGamScheduler)scheduler
              responseHoldSeconds:(NSTimeInterval)responseHoldSeconds
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Optional slot name for publishers showing multiple ads of the same format at once.
 * Must match the `{"slot": "..."}` value in the GAM custom event's static parameter;
 * leave nil for the default single-instance setup. Set before calling load.
 */
@property (nonatomic, copy, nullable) NSString *slot;

/**
 * @brief Report the GAM auction result so CloudX can settle the bid's telemetry.
 * @param loadedAdapterClassName The winning adapter class name from the GAM response, or nil on no fill.
 * @param adSourceName The winning ad source display name, or nil.
 * @param gamResponseId The GAM response identifier, or nil.
 */
- (void)notifyGamResponseWithAdapterClassName:(nullable NSString *)loadedAdapterClassName
                                 adSourceName:(nullable NSString *)adSourceName
                                gamResponseId:(nullable NSString *)gamResponseId;

/** @brief Convenience for a failed GAM request (no winner). */
- (void)notifyGamRequestFailed;

/**
 * @brief Forward a GAM paid event into CloudX impression-level revenue reporting.
 *
 * Call from your GAM paid-event handler, passing the winner identity read from the SAME
 * ad object inside the handler (`responseInfo.loadedAdNetworkResponseInfo`). The winner
 * class gates the report statelessly: paid events for CloudX-won impressions are dropped
 * because CloudX reports its own impressions natively — forwarding them would double count
 * revenue and poison realized-price pricing. Unknown winners are dropped conservatively.
 *
 * @param valueMicros Revenue in micro-units, as provided by GAM's `GADAdValue`.
 * @param currencyCode ISO currency code from `GADAdValue`, or nil.
 * @param precision GAM `GADAdValuePrecision` constant (0 unknown, 1 estimated,
 *   2 publisher-provided, 3 precise).
 * @param winnerAdapterClassName The winning adapter class name at paid-event time.
 * @param adSourceName The winning ad source display name at paid-event time, or nil.
 * @param gamAdUnitId The GAM ad unit the paying ad was requested under — read `adUnitID`
 *   off the same GAM ad object (`GADBannerView`, `GADInterstitialAd`, `GADRewardedAd`,
 *   `GADAdLoader`). This is what reporting joins on; pass nil to fall back to the CloudX
 *   placement. GMA never hands the ad unit to a mediation adapter, so only the publisher
 *   holding the ad object can supply it.
 * @return YES if the event was forwarded to CloudX revenue reporting.
 */
- (BOOL)reportGamPaidEventWithValueMicros:(int64_t)valueMicros
                             currencyCode:(nullable NSString *)currencyCode
                                precision:(NSInteger)precision
                   winnerAdapterClassName:(nullable NSString *)winnerAdapterClassName
                             adSourceName:(nullable NSString *)adSourceName
                              gamAdUnitId:(nullable NSString *)gamAdUnitId
    NS_SWIFT_NAME(reportGamPaidEvent(valueMicros:currencyCode:precision:winnerAdapterClassName:adSourceName:gamAdUnitId:));

/**
 * @brief Forward a GAM paid event, reporting against the CloudX placement as the ad unit.
 *
 * Prefer the `gamAdUnitId:` variant: reporting joins on the GAM ad unit, and only the
 * publisher's GAM ad object knows it.
 */
- (BOOL)reportGamPaidEventWithValueMicros:(int64_t)valueMicros
                             currencyCode:(nullable NSString *)currencyCode
                                precision:(NSInteger)precision
                   winnerAdapterClassName:(nullable NSString *)winnerAdapterClassName
                             adSourceName:(nullable NSString *)adSourceName
    NS_SWIFT_NAME(reportGamPaidEvent(valueMicros:currencyCode:precision:winnerAdapterClassName:adSourceName:));

/**
 * @brief Terminal teardown: settle any owed telemetry and destroy every CloudX ad this
 *   facade holds, including one a dispatch handed to GAM.
 *
 * A still-pending registration is settled as `expired` so its token does not vanish
 * eventless; a dispatch already held emits its `won` event instead.
 */
- (void)destroy;

@end

/** Keys of the revenue-report dictionary handed to the facade's revenue reporter. */
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyPlatform;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyRevenue;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyAdFormat;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyCurrencyCode;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyPrecision;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyNetworkName;
FOUNDATION_EXPORT NSString *const CLXGamRevenueKeyAdUnitId;

/** Precision tokens carried in the revenue-report dictionary. */
FOUNDATION_EXPORT NSString *const CLXGamRevenuePrecisionEstimated;
FOUNDATION_EXPORT NSString *const CLXGamRevenuePrecisionPublisherDefined;
FOUNDATION_EXPORT NSString *const CLXGamRevenuePrecisionExact;
FOUNDATION_EXPORT NSString *const CLXGamRevenuePrecisionUndefined;

/**
 * Network display name for a paid event: the ad source name when present, else the winning
 * adapter class reduced to its simple name (GAM reports fully-qualified names for some
 * sources). Nil when neither yields a name.
 */
FOUNDATION_EXPORT NSString *_Nullable CLXGamNetworkNameFrom(NSString *_Nullable adSourceName,
                                                            NSString *_Nullable winnerAdapterClassName);

/** Maps a GAM `GADAdValuePrecision` constant onto a CloudX revenue precision token. */
FOUNDATION_EXPORT NSString *CLXGamRevenuePrecisionToken(NSInteger precision);

/** How long a dispatched win event waits for its GAM response id before emitting without one. */
FOUNDATION_EXPORT const NSTimeInterval CLXGamDefaultResponseHoldSeconds;

/**
 * Installs the process-wide sink new facades forward mapped paid-event reports to.
 * The CloudXCore-typed reporter registers itself at load; not publisher API.
 */
FOUNDATION_EXPORT void CLXGamSetDefaultRevenueReporter(
    BOOL (^reporter)(NSDictionary<NSString *, id> *report));

/** Subclass and internal hooks; not publisher API. */
@interface CLXGamFacadeCore (Internal)

/**
 * Sink for forwarded paid events, injectable for tests. Receives the mapped report as a
 * Foundation-only dictionary keyed by the CLXGamRevenueKey* constants and returns whether
 * CloudX accepted it. Defaults to the CloudXCore reporter.
 */
@property (nonatomic, copy) BOOL (^revenueReporter)(NSDictionary<NSString *, id> *report);

/** Registers the loaded bid; returns the key-values for the GAM request. */
- (CloudXGAMKeyValues *)onCxAdLoadedWithRevenue:(double)revenue;

/**
 * Registers the loaded bid along with the CloudX telemetry join payloads read off the loaded
 * ad; returns the key-values for the GAM request.
 */
- (CloudXGAMKeyValues *)onCxAdLoadedWithRevenue:(double)revenue
                        auctionTelemetryPayload:(nullable NSString *)auctionTelemetryPayload
                            bidTelemetryPayload:(nullable NSString *)bidTelemetryPayload;

/**
 * Custom event consumed this facade's token: hold the dispatched-shaped event until
 * `notifyGamResponse...` delivers the GAM response id, or the hold times out.
 */
- (void)onDispatchConsumed:(CLXGamRegistration *)registration;

/**
 * The underlying CloudX ad expired before GAM dispatched it: retire the registration,
 * cancel its TTL timer, and emit the expired-shaped event. The ad itself is CloudXCore's to
 * tear down — it just declared the expiry. A no-op once the registration is gone, so an
 * expiry arriving after a dispatch or a loss cannot emit a second event for the same token.
 */
- (void)onCxAdExpired;

/** Emits the expired-shaped event for an already-retired registration. */
- (void)emitExpiredForRegistration:(CLXGamRegistration *)registration;

/**
 * Subclass hook, terminal-only: called from `destroy` and nowhere else. Tears down every
 * CloudX object the facade holds — the pending ad, a dispatched ad GAM may still be
 * rendering, and the loader or view container kept across loads. Loss and expiry never
 * release the ad; CloudXCore owns ad lifetime and the next load reuses or replaces it.
 */
- (void)releaseCxAd;

@end

NS_ASSUME_NONNULL_END
