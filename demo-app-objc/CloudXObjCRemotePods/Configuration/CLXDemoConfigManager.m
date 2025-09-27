#import "CLXDemoConfigManager.h"

@implementation CLXDemoConfig

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
                      baseURL:(NSString *)baseURL
               bannerPlacement:(NSString *)bannerPlacement
                 mrecPlacement:(NSString *)mrecPlacement
         interstitialPlacement:(NSString *)interstitialPlacement
               nativePlacement:(NSString *)nativePlacement
         nativeBannerPlacement:(NSString *)nativeBannerPlacement
             rewardedPlacement:(NSString *)rewardedPlacement
   rewardedInterstitialPlacement:(NSString *)rewardedInterstitialPlacement {
    
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _hashedUserId = [hashedUserId copy];
        _baseURL = [baseURL copy];
        _bannerPlacement = [bannerPlacement copy];
        _mrecPlacement = [mrecPlacement copy];
        _interstitialPlacement = [interstitialPlacement copy];
        _nativePlacement = [nativePlacement copy];
        _nativeBannerPlacement = [nativeBannerPlacement copy];
        _rewardedPlacement = [rewardedPlacement copy];
        _rewardedInterstitialPlacement = [rewardedInterstitialPlacement copy];
    }
    return self;
}

@end

@interface CLXDemoConfigManager ()
@property (nonatomic, strong) NSDictionary<NSNumber *, CLXDemoConfig *> *configurations;
@end

@implementation CLXDemoConfigManager

+ (instancetype)sharedManager {
    static CLXDemoConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupConfigurations];
        _currentEnvironment = CLXDemoEnvironmentDev; // Default to dev
    }
    return self;
}

- (void)setupConfigurations {
    // Dev Configuration (current production values)
    CLXDemoConfig *devConfig = [[CLXDemoConfig alloc] 
        initWithAppKey:@"g0PdN9_0ilfIcuNXhBopl"
        hashedUserId:@"test-user-123"
        baseURL:@"https://pro-dev.cloudx.io/sdk"
        bannerPlacement:@"metaBanner"
        mrecPlacement:@"metaMREC"
        interstitialPlacement:@"metaInterstitial"
        nativePlacement:@"metaNative"
        nativeBannerPlacement:@"metaNative"
        rewardedPlacement:@"metaRewarded"
        rewardedInterstitialPlacement:@"metaRewarded"];
    
    // Staging Configuration
    CLXDemoConfig *stagingConfig = [[CLXDemoConfig alloc] 
        initWithAppKey:@"9o_9omGptuyS2n5wV0QJu"
        hashedUserId:@"test-user-123-staging"
        baseURL:@"https://pro-stage.cloudx.io/sdk"
        bannerPlacement:@"metaBanner"
        mrecPlacement:@"metaMREC"
        interstitialPlacement:@"metaInterstitial"
        nativePlacement:@"metaNative"
        nativeBannerPlacement:@"metaNative"
        rewardedPlacement:@"metaRewarded"
        rewardedInterstitialPlacement:@"metaRewarded"];
    
    // Production Configuration (placeholders)
    CLXDemoConfig *prodConfig = [[CLXDemoConfig alloc] 
        initWithAppKey:@"PROD_APP_KEY_PLACEHOLDER"
        hashedUserId:@"prod-user-placeholder"
        baseURL:@"https://pro.cloudx.io/sdk"
        bannerPlacement:@"prodBanner"
        mrecPlacement:@"prodMREC"
        interstitialPlacement:@"prodInterstitial"
        nativePlacement:@"prodNative"
        nativeBannerPlacement:@"prodNative"
        rewardedPlacement:@"prodRewarded"
        rewardedInterstitialPlacement:@"prodRewarded"];
    
    _configurations = @{
        @(CLXDemoEnvironmentDev): devConfig,
        @(CLXDemoEnvironmentStaging): stagingConfig,
        @(CLXDemoEnvironmentProduction): prodConfig
    };
}

- (void)setEnvironment:(CLXDemoEnvironment)environment {
    _currentEnvironment = environment;
}

- (CLXDemoConfig *)currentConfig {
    return [self configForEnvironment:_currentEnvironment];
}

- (CLXDemoConfig *)configForEnvironment:(CLXDemoEnvironment)environment {
    return _configurations[@(environment)];
}

- (NSString *)environmentName:(CLXDemoEnvironment)environment {
    switch (environment) {
        case CLXDemoEnvironmentDev:
            return @"Development";
        case CLXDemoEnvironmentStaging:
            return @"Staging";
        case CLXDemoEnvironmentProduction:
            return @"Production";
    }
}

@end
