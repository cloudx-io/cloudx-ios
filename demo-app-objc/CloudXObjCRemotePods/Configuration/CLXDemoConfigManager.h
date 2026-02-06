#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXDemoEnvironment) {
    CLXDemoEnvironmentLocal,
    CLXDemoEnvironmentDev,
    CLXDemoEnvironmentStaging,
    CLXDemoEnvironmentProduction
};

@interface CLXDemoConfig : NSObject

@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *hashedUserId;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *bannerAdUnitId;
@property (nonatomic, copy, readonly) NSString *mrecAdUnitId;
@property (nonatomic, copy, readonly) NSString *interstitialAdUnitId;
@property (nonatomic, copy, readonly) NSString *nativeAdUnitId;
@property (nonatomic, copy, readonly) NSString *nativeBannerAdUnitId;
@property (nonatomic, copy, readonly) NSString *rewardedAdUnitId;
@property (nonatomic, copy, readonly) NSString *rewardedInterstitialAdUnitId;

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
                      baseURL:(NSString *)baseURL
               bannerAdUnitId:(NSString *)bannerAdUnitId
                 mrecAdUnitId:(NSString *)mrecAdUnitId
         interstitialAdUnitId:(NSString *)interstitialAdUnitId
               nativeAdUnitId:(NSString *)nativeAdUnitId
         nativeBannerAdUnitId:(NSString *)nativeBannerAdUnitId
             rewardedAdUnitId:(NSString *)rewardedAdUnitId
   rewardedInterstitialAdUnitId:(NSString *)rewardedInterstitialAdUnitId;

@end

@interface CLXDemoConfigManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) CLXDemoEnvironment currentEnvironment;
@property (nonatomic, strong, readonly) CLXDemoConfig *currentConfig;

- (void)setEnvironment:(CLXDemoEnvironment)environment;
- (CLXDemoConfig *)configForEnvironment:(CLXDemoEnvironment)environment;
- (NSString *)environmentName:(CLXDemoEnvironment)environment;
- (NSString *)buildSchemeName;
- (BOOL)isDebugBuild;
- (NSString *)enhancedErrorMessageForEnvironment:(CLXDemoEnvironment)environment 
                                  originalError:(NSString *)originalError;

@end

NS_ASSUME_NONNULL_END
