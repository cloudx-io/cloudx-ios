#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXDemoConfig : NSObject

@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *hashedUserId;
@property (nonatomic, copy, readonly) NSString *bannerAdUnitId;
@property (nonatomic, copy, readonly) NSString *mrecAdUnitId;
@property (nonatomic, copy, readonly) NSString *interstitialAdUnitId;
@property (nonatomic, copy, readonly) NSString *nativeAdUnitId;
@property (nonatomic, copy, readonly) NSString *nativeBannerAdUnitId;
@property (nonatomic, copy, readonly) NSString *rewardedAdUnitId;
@property (nonatomic, copy, readonly) NSString *appOpenAdUnitId;

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
               bannerAdUnitId:(NSString *)bannerAdUnitId
                 mrecAdUnitId:(NSString *)mrecAdUnitId
         interstitialAdUnitId:(NSString *)interstitialAdUnitId
               nativeAdUnitId:(NSString *)nativeAdUnitId
         nativeBannerAdUnitId:(NSString *)nativeBannerAdUnitId
             rewardedAdUnitId:(NSString *)rewardedAdUnitId
              appOpenAdUnitId:(NSString *)appOpenAdUnitId;

@end

@interface CLXDemoConfigManager : NSObject

+ (instancetype)sharedManager;

// Production-only configuration for remote pods demo
// Environment switching requires local source compilation with DEBUG flag
@property (nonatomic, strong, readonly) CLXDemoConfig *currentConfig;

@end

NS_ASSUME_NONNULL_END
