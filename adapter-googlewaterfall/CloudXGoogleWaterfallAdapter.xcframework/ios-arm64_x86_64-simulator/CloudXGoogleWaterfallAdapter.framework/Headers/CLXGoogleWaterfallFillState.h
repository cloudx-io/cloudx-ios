#import <Foundation/Foundation.h>

@class GADBannerView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXGoogleWaterfallPlacementFormat) {
    CLXGoogleWaterfallPlacementFormatBanner = 0,
    CLXGoogleWaterfallPlacementFormatMrec = 1,
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

- (NSDictionary<NSString *, id> *)toJSONObject;
@end

NS_ASSUME_NONNULL_END
