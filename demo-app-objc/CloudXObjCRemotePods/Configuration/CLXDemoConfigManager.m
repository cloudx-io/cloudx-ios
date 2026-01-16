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
        _currentEnvironment = CLXDemoEnvironmentProduction; // Default to production for rewarded testing
    }
    return self;
}

- (void)setupConfigurations {
    // Local Configuration (localhost testing - bundle: cloudx.CloudXObjCRemotePods)
    // App key from database (SELECT app_key FROM apps WHERE bundle_id = 'cloudx.CloudXObjCRemotePods')
    // Note: app_key != id. The YAML config shows id, but SDK needs the actual app_key column value
    CLXDemoConfig *localConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"E5RotGdN8i7hWhkax1e1o"
        hashedUserId:@"test-user-123"
        baseURL:@"http://localhost:8090/sdk"
        bannerPlacement:@"banner"
        mrecPlacement:@"mrec"
        interstitialPlacement:@"interstitial"
        nativePlacement:@"-"
        nativeBannerPlacement:@"-"
        rewardedPlacement:@"rewarded"
        rewardedInterstitialPlacement:@"rewarded"];
    
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
    
    // Dev Configuration (Test app - bundle: cloudx.CloudXObjCRemotePods)
    CLXDemoConfig *devConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"E-B3dlMk92hcrUT-9xmMu"
        hashedUserId:@"test-user-123"
        baseURL:@"https://provisioning-dev.cloudx.io/sdk"
        bannerPlacement:@"placement_1"
        mrecPlacement:@"place_2"
        interstitialPlacement:@"interstitial_home_entry"
        nativePlacement:@"-"
        nativeBannerPlacement:@"-"
        rewardedPlacement:@"objc-demo-rewarded"
        rewardedInterstitialPlacement:@"objc-demo-rewarded"];
    
    // Production Configuration (Blocky app - io.cloudx.Blocky)
    CLXDemoConfig *prodConfig = [[CLXDemoConfig alloc] 
        initWithAppKey:@"ihtOXvp3X9JlMQ5p0_RYL"
        hashedUserId:@"prod-user-123"
        baseURL:@"https://pro.cloudx.io/sdk"
        bannerPlacement:@"demo-banner-1"
        mrecPlacement:@"demo-mrec-1"
        interstitialPlacement:@"demo-interstitial-1"
        nativePlacement:@"demo-native-1"
        nativeBannerPlacement:@"demo-native-banner-1"
        rewardedPlacement:@"demo-rewarded-1"
        rewardedInterstitialPlacement:@"demo-rewarded-interstitial-1"];
    
    _configurations = @{
        @(CLXDemoEnvironmentLocal): localConfig,
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
        case CLXDemoEnvironmentLocal:
            return @"Local";
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
