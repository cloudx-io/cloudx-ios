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
    // Staging Configuration (MetaTestApp-9-22-25 - bundle: cloudx.CloudXObjCRemotePods)
    CLXDemoConfig *stagingConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"A7ovaBRCcAL8lapKtoZmm"
        hashedUserId:@"test-user-123"
        baseURL:@"https://pro-stage.cloudx.io/sdk"
        bannerPlacement:@"objcDemo-banner-1"
        mrecPlacement:@"objcDemo-mrec-1"
        interstitialPlacement:@"objcDemo-interstitial-1"
        nativePlacement:@"-"
        nativeBannerPlacement:@"-"
        rewardedPlacement:@"-"
        rewardedInterstitialPlacement:@"-"];
    
    // Dev Configuration (MetaTestiOS - bundle: cloudx.CloudXObjCRemotePods)
    CLXDemoConfig *devConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"NddUgEiyx_bbYax2BQGI2"
        hashedUserId:@"test-user-123"
        baseURL:@"https://pro-dev.cloudx.io/sdk"
        bannerPlacement:@"inmobi-banner"
        mrecPlacement:@"inmobi-mrec"
        interstitialPlacement:@"inmobi-interstitial"
        nativePlacement:@"metaNative"
        nativeBannerPlacement:@"metaNative"
        rewardedPlacement:@"metaRewarded"
        rewardedInterstitialPlacement:@"metaRewarded"];
    
    // Production Configuration (Blocky app - io.cloudx.Blocky)
    CLXDemoConfig *prodConfig = [[CLXDemoConfig alloc] 
        initWithAppKey:@"ihtOXvp3X9JlMQ5p0_RYL"
        hashedUserId:@"prod-user-123"
        baseURL:@"https://pro.cloudx.io/sdk"
        bannerPlacement:@"demo-banner-1"
        mrecPlacement:@"demo-mrec-1"
        interstitialPlacement:@"demo-interstitial-1"
        nativePlacement:@"-"
        nativeBannerPlacement:@"-"
        rewardedPlacement:@"-"
        rewardedInterstitialPlacement:@"-"];
    
    _configurations = @{
        @(CLXDemoEnvironmentStaging): stagingConfig,
        @(CLXDemoEnvironmentDev): devConfig,
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

- (NSString *)buildSchemeName {
#ifdef DEBUG
    return @"Debug";
#else
    return @"Release";
#endif
}

- (BOOL)isDebugBuild {
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

- (NSString *)enhancedErrorMessageForEnvironment:(CLXDemoEnvironment)environment 
                                  originalError:(NSString *)originalError {
    BOOL isDebug = [self isDebugBuild];
    NSString *buildScheme = [self buildSchemeName];
    NSString *environmentName = [self environmentName:environment];
    
    if ([originalError containsString:@"Unauthorized"] || 
        [originalError containsString:@"Invalid app key"] ||
        [originalError containsString:@"malformed App Key"]) {
        
        if (environment == CLXDemoEnvironmentProduction && isDebug) {
            return [NSString stringWithFormat:@"Production init failed: Build scheme is set to '%@' but trying to use Production environment. Please switch to Release build scheme for Production, or use Dev/Staging environments with Debug builds.\n\nOriginal error: %@", 
                    buildScheme, originalError];
        }
        
        if (environment != CLXDemoEnvironmentProduction && !isDebug) {
            return [NSString stringWithFormat:@"%@ init failed: Build scheme is set to '%@' but trying to use %@ environment. Debug environments (Dev/Staging) require Debug build scheme, or switch to Production environment with Release builds.\n\nOriginal error: %@", 
                    environmentName, buildScheme, environmentName, originalError];
        }
        
        return [NSString stringWithFormat:@"%@ init failed with error: %@\n\nCurrent build scheme: %@\nEnvironment: %@", 
                environmentName, originalError, buildScheme, environmentName];
    }
    
    return originalError;
}

@end
