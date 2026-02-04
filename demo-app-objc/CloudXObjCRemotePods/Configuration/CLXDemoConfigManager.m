#import "CLXDemoConfigManager.h"

@implementation CLXDemoConfig

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
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
        // Production Configuration (MetaTestApp - bundle: cloudx.CloudXObjCRemotePods)
        _currentConfig = [[CLXDemoConfig alloc]
            initWithAppKey:@"ihtOXvp3X9JlMQ5p0_RYL"
            hashedUserId:@"test-user-123"
            bannerAdUnitId:@"demo-banner-1"
            mrecAdUnitId:@"demo-mrec-1"
            interstitialAdUnitId:@"demo-interstitial-1"
            nativeAdUnitId:@"-"
            nativeBannerAdUnitId:@"-"
            rewardedAdUnitId:@"-"
            rewardedInterstitialAdUnitId:@"-"];
    }
    return self;
}

@end
