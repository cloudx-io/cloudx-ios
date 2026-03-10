#import "CLXDemoConfigManager.h"

@implementation CLXDemoConfig

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
                      baseURL:(NSString *)baseURL
               bannerAdUnitId:(NSString *)bannerAdUnitId
                 mrecAdUnitId:(NSString *)mrecAdUnitId
         interstitialAdUnitId:(NSString *)interstitialAdUnitId
               nativeAdUnitId:(NSString *)nativeAdUnitId
         nativeBannerAdUnitId:(NSString *)nativeBannerAdUnitId
             rewardedAdUnitId:(NSString *)rewardedAdUnitId
   rewardedInterstitialAdUnitId:(NSString *)rewardedInterstitialAdUnitId {

    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _hashedUserId = [hashedUserId copy];
        _baseURL = [baseURL copy];
        _bannerAdUnitId = [bannerAdUnitId copy];
        _mrecAdUnitId = [mrecAdUnitId copy];
        _interstitialAdUnitId = [interstitialAdUnitId copy];
        _nativeAdUnitId = [nativeAdUnitId copy];
        _nativeBannerAdUnitId = [nativeBannerAdUnitId copy];
        _rewardedAdUnitId = [rewardedAdUnitId copy];
        _rewardedInterstitialAdUnitId = [rewardedInterstitialAdUnitId copy];
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
    // ==========================================================================
    // IMPORTANT: Ad unit identifiers must be the CloudX ad unit ID (not name)
    // The SDK now uses ad unit IDs for lookup (matching Android SDK behavior).
    // Get IDs from: CloudX dashboard or server config response's adUnits[].id
    // Example ID format: "um9Ek08ScJBWuzSMTyW3b" (not "demo-banner-1")
    // ==========================================================================

    // Local Configuration (localhost testing - bundle: cloudx.CloudXObjCRemotePods)
    // App key from database (SELECT app_key FROM apps WHERE bundle_id = 'cloudx.CloudXObjCRemotePods')
    // Note: app_key != id. The YAML config shows id, but SDK needs the actual app_key column value
    // TODO: Replace ad unit names with actual IDs from local server config
    CLXDemoConfig *localConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"E5RotGdN8i7hWhkax1e1o"
        hashedUserId:@"test-user-123"
        baseURL:@"http://localhost:8090/sdk"
        bannerAdUnitId:@"banner"
        mrecAdUnitId:@"mrec"
        interstitialAdUnitId:@"interstitial"
        nativeAdUnitId:@"-"
        nativeBannerAdUnitId:@"-"
        rewardedAdUnitId:@"rewarded"
        rewardedInterstitialAdUnitId:@"rewarded"];

    // Staging Configuration (MetaTestApp-9-22-25 - bundle: cloudx.CloudXObjCRemotePods)
    // TODO: Replace ad unit names with actual IDs from staging server config
    CLXDemoConfig *stagingConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"A7ovaBRCcAL8lapKtoZmm"
        hashedUserId:@"test-user-123"
        baseURL:@"https://pro-stage.cloudx.io/sdk"
        bannerAdUnitId:@"objcDemo-banner-1"
        mrecAdUnitId:@"objcDemo-mrec-1"
        interstitialAdUnitId:@"objcDemo-interstitial-1"
        nativeAdUnitId:@"-"
        nativeBannerAdUnitId:@"-"
        rewardedAdUnitId:@"-"
        rewardedInterstitialAdUnitId:@"-"];

    // Dev Configuration (Test app - bundle: cloudx.CloudXObjCRemotePods)
    // TODO: Replace ad unit names with actual IDs from dev server config
    CLXDemoConfig *devConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"E-B3dlMk92hcrUT-9xmMu"
        hashedUserId:@"test-user-123"
        baseURL:@"https://provisioning-dev.cloudx.io/sdk"
        bannerAdUnitId:@"placement_1"
        mrecAdUnitId:@"place_2"
        interstitialAdUnitId:@"interstitial_home_entry"
        nativeAdUnitId:@"-"
        nativeBannerAdUnitId:@"-"
        rewardedAdUnitId:@"objc-demo-rewarded"
        rewardedInterstitialAdUnitId:@"objc-demo-rewarded"];

    // Production Configuration (ObjCDemoApp - cloudx.CloudXObjCRemotePods)
    CLXDemoConfig *prodConfig = [[CLXDemoConfig alloc]
        initWithAppKey:@"WpSSEfm-f9U8rB03iN6eJ"
        hashedUserId:@"prod-user-123"
        baseURL:@"https://pro.cloudx.io/sdk"
        bannerAdUnitId:@"YyG8H2zPWdWoAu7ULGph9"
        mrecAdUnitId:@"ae5QwaAN5QMLZ9PsUplYx"
        interstitialAdUnitId:@"FjWHlfkKkxP0L0dxZCDV2"
        nativeAdUnitId:@"-"
        nativeBannerAdUnitId:@"-"
        rewardedAdUnitId:@"zOqLE6UgDGe6ZScH-Acb-"
        rewardedInterstitialAdUnitId:@"-"];
    
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
