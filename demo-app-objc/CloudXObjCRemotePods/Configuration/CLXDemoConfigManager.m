#import "CLXDemoConfigManager.h"

@implementation CLXDemoConfig

- (instancetype)initWithAppKey:(NSString *)appKey
                 hashedUserId:(NSString *)hashedUserId
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
            bannerPlacement:@"demo-banner-1"
            mrecPlacement:@"demo-mrec-1"
            interstitialPlacement:@"demo-interstitial-1"
            nativePlacement:@"-"
            nativeBannerPlacement:@"-"
            rewardedPlacement:@"-"
            rewardedInterstitialPlacement:@"-"];
    }
    return self;
}

@end
