#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXDemoEnvironment) {
    CLXDemoEnvironmentDev,
    CLXDemoEnvironmentStaging,
    CLXDemoEnvironmentProduction
};

@interface CLXDemoConfig : NSObject

@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *hashedUserId;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *bannerPlacement;
@property (nonatomic, copy, readonly) NSString *mrecPlacement;
@property (nonatomic, copy, readonly) NSString *interstitialPlacement;
@property (nonatomic, copy, readonly) NSString *nativePlacement;
@property (nonatomic, copy, readonly) NSString *nativeBannerPlacement;
@property (nonatomic, copy, readonly) NSString *rewardedPlacement;
@property (nonatomic, copy, readonly) NSString *rewardedInterstitialPlacement;

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
                      baseURL:(NSString *)baseURL
               bannerPlacement:(NSString *)bannerPlacement
                 mrecPlacement:(NSString *)mrecPlacement
         interstitialPlacement:(NSString *)interstitialPlacement
               nativePlacement:(NSString *)nativePlacement
         nativeBannerPlacement:(NSString *)nativeBannerPlacement
             rewardedPlacement:(NSString *)rewardedPlacement
   rewardedInterstitialPlacement:(NSString *)rewardedInterstitialPlacement;

@end

@interface CLXDemoConfigManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) CLXDemoEnvironment currentEnvironment;
@property (nonatomic, strong, readonly) CLXDemoConfig *currentConfig;

- (void)setEnvironment:(CLXDemoEnvironment)environment;
- (CLXDemoConfig *)configForEnvironment:(CLXDemoEnvironment)environment;
- (NSString *)environmentName:(CLXDemoEnvironment)environment;

@end

NS_ASSUME_NONNULL_END
