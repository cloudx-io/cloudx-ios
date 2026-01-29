//
//  CLXMetaInitializer.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#import "CLXMetaInitializer.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBannerFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBannerFactory.h>
#else
#import "CLXMetaBannerFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitialFactory.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitialFactory.h>
#else
#import "CLXMetaInterstitialFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaRewardedFactory.h>)
#import <CloudXMetaAdapter/CLXMetaRewardedFactory.h>
#else
#import "CLXMetaRewardedFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBidTokenSource.h>)
#import <CloudXMetaAdapter/CLXMetaBidTokenSource.h>
#else
#import "CLXMetaBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXVersion.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#if __has_include(<CloudXMetaAdapter/CLXMetaAdapterVersion.h>)
#import <CloudXMetaAdapter/CLXMetaAdapterVersion.h>
#else
#import "CLXMetaAdapterVersion.h"
#endif
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@interface CLXMetaInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
+ (CLXLogger *)logger;
@end

@implementation CLXMetaInitializer

static BOOL CLXMetaSDKInitialized = NO;

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInitializer"];
    });
    return logger;
}

+ (BOOL)isInitialized {
    return CLXMetaSDKInitialized;
}

+ (instancetype)createInstance {
    return [[CLXMetaInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return FB_AD_SDK_VERSION;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXMetaInitializer sdkVersion];
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    if (CLXMetaSDKInitialized) {
        [[CLXMetaInitializer logger] debug:@"Meta SDK already initialized"];
        if (completion) {
            completion(YES, nil);
        }
        return;
    }

    [self configureAdvertiserTrackingEnabled];
    [self configureTestSettings:testMode];

    [[CLXMetaInitializer logger] debug:@"Initializing Meta Audience Network"];
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"Test mode: %@", testMode ? @"YES" : @"NO"]];

    NSArray<NSString *> *placementIDs = [self extractPlacementIDsFromConfig:config];
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"Initializing with placements: %@", placementIDs]];

    void (^facebookCompletionHandler)(FBAdInitResults *results) = ^(FBAdInitResults *initResult) {
        if ([initResult isSuccess]) {
            [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"Meta SDK initialized: %@", initResult.message ?: @"OK"]];
            CLXMetaSDKInitialized = YES;
            if (completion) {
                completion(YES, nil);
            }
        } else {
            [[CLXMetaInitializer logger] error:[NSString stringWithFormat:@"Meta SDK init failed: %@", initResult.message ?: @"Unknown error"]];
            CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                          description:initResult.message ?: @"Meta SDK initialization failed"];
            if (completion) {
                completion(NO, error);
            }
        }
    };

    // Format: CLOUDX_{CoreSDKVersion}:{AdapterVersion}
    NSString *mediationIdentifier = [NSString stringWithFormat:@"CLOUDX_%@:%@", CLXSDKVersion, CLXMetaAdapterVersion];
    FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIDs mediationService:mediationIdentifier];
    [FBAudienceNetworkAds initializeWithSettings:initSettings completionHandler:facebookCompletionHandler];
}

#pragma mark - Private Methods

- (NSArray<NSString *> *)extractPlacementIDsFromConfig:(nullable CLXBidderConfig *)config {
    if (config && config.initializationData) {
        NSArray *configPlacementIDs = config.initializationData[@"placementIds"];
        if ([configPlacementIDs isKindOfClass:[NSArray class]] && configPlacementIDs.count > 0) {
            return configPlacementIDs;
        }
    }
    return @[];
}

- (void)configureAdvertiserTrackingEnabled {
    BOOL idfaAllowed = [CLXAdTrackingService isIDFAAccessAllowed];
    [FBAdSettings setAdvertiserTrackingEnabled:idfaAllowed];
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"ATE: %@", idfaAllowed ? @"YES" : @"NO"]];
}

// Test mode controlled via server deviceConfig (whitelist device IFA on CloudX dashboard).
// iOS uses addTestDevice: (unlike Android's setTestMode).
- (void)configureTestSettings:(BOOL)enable {
    if (enable) {
        NSString *deviceHash = [FBAdSettings testDeviceHash];
        if (deviceHash && deviceHash.length > 0) {
            [FBAdSettings addTestDevice:deviceHash];
            [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Test device: %@", deviceHash]];
        }
        [FBAdSettings setLogLevel:FBAdLogLevelLog];
    } else {
        [FBAdSettings clearTestDevices];
    }

    BOOL isTestMode = [FBAdSettings isTestMode];
    [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Meta test mode: %@", isTestMode ? @"enabled" : @"disabled"]];
}

@end 
