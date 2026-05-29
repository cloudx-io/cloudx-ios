#import <Foundation/Foundation.h>

@class GADBannerView;

NS_ASSUME_NONNULL_BEGIN

/// Banner formats this adapter prefetches. Mirrors the Android PlacementFormat.
typedef NS_ENUM(NSInteger, CLXGoogleWaterfallPlacementFormat) {
    CLXGoogleWaterfallPlacementFormatBanner = 0,
    CLXGoogleWaterfallPlacementFormatMrec = 1,
};

/// Parse a server `format` string (case-insensitive `banner`/`mrec`).
/// Returns NO and leaves `outFormat` untouched for unknown values.
BOOL CLXGoogleWaterfallPlacementFormatFromString(NSString * _Nullable s, CLXGoogleWaterfallPlacementFormat *outFormat);

#pragma mark - PlacementConfig

/// One provisioned AdMob placement to prefetch. Mirrors Android PlacementConfig.
/// `type` must be `admob` (the only supported value in v1); validated at parse.
@interface CLXGoogleWaterfallPlacementConfig : NSObject
@property (nonatomic, copy, readonly) NSString *adUnitId;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallPlacementFormat format;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                          format:(CLXGoogleWaterfallPlacementFormat)format NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Parse the `googleWaterfallPlacements` array (array of dicts with
/// `type`/`adUnitId`/`format`). Skips entries with a non-`admob` type, a blank
/// adUnitId, or an unknown format. Returns an empty array for nil/empty input.
+ (NSArray<CLXGoogleWaterfallPlacementConfig *> *)placementsFromArray:(nullable NSArray *)array;
@end

#pragma mark - FillEntry

/// Snapshot emitted into the bid request's `bidderSignals.googleWaterfall.fills[]`.
/// Carries the raw probe-trigger labels for server-side min(parsed) proxyPrice.
@interface CLXGoogleWaterfallFillEntry : NSObject
@property (nonatomic, copy, readonly) NSString *adUnitId;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallPlacementFormat format;
@property (nonatomic, copy, readonly) NSArray<NSString *> *probesTriggered;
@property (nonatomic, copy, readonly, nullable) NSString *winnerSourceName;
@property (nonatomic, copy, readonly, nullable) NSString *winnerInstanceName;
@property (nonatomic, copy, readonly, nullable) NSString *mediationGroupName;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                          format:(CLXGoogleWaterfallPlacementFormat)format
                 probesTriggered:(NSArray<NSString *> *)probesTriggered
                winnerSourceName:(nullable NSString *)winnerSourceName
              winnerInstanceName:(nullable NSString *)winnerInstanceName
              mediationGroupName:(nullable NSString *)mediationGroupName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// JSON object for the fills array. No `format` key — format is client-side
/// filtering state only (matches Android FillEntry.toJson).
- (NSDictionary<NSString *, id> *)toJSONObject;
@end

NS_ASSUME_NONNULL_END
