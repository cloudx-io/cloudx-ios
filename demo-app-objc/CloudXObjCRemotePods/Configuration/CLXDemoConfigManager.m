#import "CLXDemoConfigManager.h"

@implementation CLXDemoConfig

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
               bannerAdUnitId:(NSString *)bannerAdUnitId
                 mrecAdUnitId:(NSString *)mrecAdUnitId
         interstitialAdUnitId:(NSString *)interstitialAdUnitId
               nativeAdUnitId:(NSString *)nativeAdUnitId
         nativeBannerAdUnitId:(NSString *)nativeBannerAdUnitId
             rewardedAdUnitId:(NSString *)rewardedAdUnitId {
    
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _hashedUserId = [hashedUserId copy];
        _bannerAdUnitId = [bannerAdUnitId copy];
        _mrecAdUnitId = [mrecAdUnitId copy];
        _interstitialAdUnitId = [interstitialAdUnitId copy];
        _nativeAdUnitId = [nativeAdUnitId copy];
        _nativeBannerAdUnitId = [nativeBannerAdUnitId copy];
        _rewardedAdUnitId = [rewardedAdUnitId copy];
    }
    return self;
}

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
        // QA can pin a specific app key / ad unit id at launch via
        // `simctl launch ... -DemoApp.<Key> <value>` (NSArgumentDomain). Unset ->
        // the hardcoded defaults below. Read once here (launch args are fixed for
        // the process lifetime); nothing is written, so overrides never persist.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *(^overrideOrDefault)(NSString *, NSString *) = ^NSString *(NSString *key, NSString *fallback) {
            NSString *value = [defaults stringForKey:key];
            return (value.length > 0) ? value : fallback;
        };
        NSLog(@"📱 [DemoApp] launch overrides: appKey=%@ banner=%@ mrec=%@ interstitial=%@ rewarded=%@",
              [defaults stringForKey:@"DemoApp.AppKey"] ?: @"(none)",
              [defaults stringForKey:@"DemoApp.BannerAdUnitId"] ?: @"(none)",
              [defaults stringForKey:@"DemoApp.MrecAdUnitId"] ?: @"(none)",
              [defaults stringForKey:@"DemoApp.InterstitialAdUnitId"] ?: @"(none)",
              [defaults stringForKey:@"DemoApp.RewardedAdUnitId"] ?: @"(none)");

        // Production Configuration (ObjCDemoApp - bundle: cloudx.CloudXObjCRemotePods)
        _currentConfig = [[CLXDemoConfig alloc]
            initWithAppKey:overrideOrDefault(@"DemoApp.AppKey", @"ihtOXvp3X9JlMQ5p0_RYL")
            hashedUserId:@"test-user-123"
            bannerAdUnitId:overrideOrDefault(@"DemoApp.BannerAdUnitId", @"1pfZEjeYFB31WGsaRMIOE")
            mrecAdUnitId:overrideOrDefault(@"DemoApp.MrecAdUnitId", @"f3vNAyybeLZw3tmrLDnfp")
            interstitialAdUnitId:overrideOrDefault(@"DemoApp.InterstitialAdUnitId", @"SKva576GixtRW5DL_jS_D")
            nativeAdUnitId:@"5NN7ZlBorm4ZoRkL6bsz9"
            nativeBannerAdUnitId:@"-2_Lw2b4QTlu7x6tKZ6Ww"
            rewardedAdUnitId:overrideOrDefault(@"DemoApp.RewardedAdUnitId", @"jKOcqM-eHbGBwg76RQmsA")];
    }
    return self;
}

@end
