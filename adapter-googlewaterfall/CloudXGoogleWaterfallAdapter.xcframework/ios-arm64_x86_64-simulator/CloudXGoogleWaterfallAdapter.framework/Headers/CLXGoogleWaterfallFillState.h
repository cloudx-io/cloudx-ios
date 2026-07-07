#import <Foundation/Foundation.h>

@class GADBannerView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXGoogleWaterfallPlacementFormat) {
    CLXGoogleWaterfallPlacementFormatBanner = 0,
    CLXGoogleWaterfallPlacementFormatMrec = 1,
    CLXGoogleWaterfallPlacementFormatInterstitial = 2,
    CLXGoogleWaterfallPlacementFormatRewarded = 3,
    CLXGoogleWaterfallPlacementFormatNative = 4,
    CLXGoogleWaterfallPlacementFormatAppOpen = 5,
};

BOOL CLXGoogleWaterfallPlacementFormatFromString(NSString * _Nullable s, CLXGoogleWaterfallPlacementFormat *outFormat);

#pragma mark - PlacementConfig

@interface CLXGoogleWaterfallPlacementConfig : NSObject
@property (nonatomic, copy, readonly) NSString *adUnitId;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallPlacementFormat format;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                          format:(CLXGoogleWaterfallPlacementFormat)format NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (NSArray<CLXGoogleWaterfallPlacementConfig *> *)placementsFromArray:(nullable NSArray *)array;
@end

#pragma mark - FillEntry

@interface CLXGoogleWaterfallFillEntry : NSObject
@property (nonatomic, copy, readonly) NSString *adUnitId;
@property (nonatomic, assign, readonly) CLXGoogleWaterfallPlacementFormat format;
@property (nonatomic, copy, readonly, nullable) NSString *winnerSourceName;
@property (nonatomic, copy, readonly, nullable) NSString *winnerInstanceName;
@property (nonatomic, copy, readonly, nullable) NSString *mediationGroupName;
@property (nonatomic, copy, readonly, nullable) NSString *creativeId;
@property (nonatomic, copy, readonly, nullable) NSString *responseId;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                          format:(CLXGoogleWaterfallPlacementFormat)format
                winnerSourceName:(nullable NSString *)winnerSourceName
              winnerInstanceName:(nullable NSString *)winnerInstanceName
              mediationGroupName:(nullable NSString *)mediationGroupName
                      creativeId:(nullable NSString *)creativeId
                      responseId:(nullable NSString *)responseId NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary<NSString *, id> *)toJSONObjectWithRealizedEcpm:(double)realizedEcpm;
@end

NS_ASSUME_NONNULL_END
