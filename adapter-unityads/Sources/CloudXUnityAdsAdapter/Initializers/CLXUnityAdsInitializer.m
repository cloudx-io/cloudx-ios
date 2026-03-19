//
//  CLXUnityAdsInitializer.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsInitializer.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsInitializer.h>
#else
#import "CLXUnityAdsInitializer.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>
#else
#import "CLXUnityAdsAdapterVersion.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXVersion.h>
#import <UnityAds/UnityAds.h>

@interface CLXUnityAdsInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@end

static NSString * const CLXUnityAdsAdapterErrorDomain = @"CLXUnityAdsAdapter";

@implementation CLXUnityAdsInitializer

static NSObject *CLXUnityAdsSDKLock;
static BOOL CLXUnityAdsSDKInitialized = NO;
static BOOL CLXUnityAdsSDKInitializing = NO;

+ (void)initialize {
    [super initialize];
    CLXUnityAdsSDKLock = [[NSObject alloc] init];
}

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsInitializer"];
    });
    return logger;
}

+ (BOOL)isInitialized {
    @synchronized (CLXUnityAdsSDKLock) {
        return CLXUnityAdsSDKInitialized;
    }
}

+ (instancetype)createInstance {
    return [[CLXUnityAdsInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return [UnityAds getVersion];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXUnityAdsInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsInitializer"];
    }
    return self;
}

- (NSString *)network {
    return @"unityAds";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    @synchronized (CLXUnityAdsSDKLock) {
        if (CLXUnityAdsSDKInitialized) {
            [[CLXUnityAdsInitializer logger] debug:@"Unity Ads SDK already initialized"];
            if (completion) {
                completion(YES, nil);
            }
            return;
        }

        if (CLXUnityAdsSDKInitializing) {
            [[CLXUnityAdsInitializer logger] debug:@"Unity Ads SDK initialization in progress"];
            if (completion) {
                NSError *error = [NSError errorWithDomain:CLXUnityAdsAdapterErrorDomain
                                                     code:-2
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unity Ads SDK initialization already in progress"}];
                completion(NO, error);
            }
            return;
        }

        CLXUnityAdsSDKInitializing = YES;
    }

    NSString *gameId = nil;
    if (config && config.initializationData) {
        gameId = config.initializationData[@"game_id"];
    }

    if (!gameId || gameId.length == 0) {
        [[CLXUnityAdsInitializer logger] error:@"Unity Ads game_id is missing from initialization data"];
        @synchronized (CLXUnityAdsSDKLock) {
            CLXUnityAdsSDKInitializing = NO;
        }
        if (completion) {
            NSError *error = [NSError errorWithDomain:CLXUnityAdsAdapterErrorDomain
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Missing game_id in initialization data"}];
            completion(NO, error);
        }
        return;
    }

    [[CLXUnityAdsInitializer logger] debug:[NSString stringWithFormat:@"Initializing Unity Ads SDK with game id: %@", gameId]];
    [[CLXUnityAdsInitializer logger] info:[NSString stringWithFormat:@"Test mode: %@", testMode ? @"YES" : @"NO"]];

    // Unity Ads does NOT auto-read IAB strings from NSUserDefaults — set privacy before init
    [self configurePrivacy];
    UADSMediationInfo *mediationInfo = [[UADSMediationInfo alloc] initWithName:@"cloudx"
                                                                      version:CLXSDKVersion
                                                               adapterVersion:CLXUnityAdsAdapterVersion];

    UADSInitializationConfiguration *initConfig = [[[[[UADSInitializationConfigurationBuilder alloc]
        initWithGameId:gameId]
        withTestMode:testMode]
        withMediationInfo:mediationInfo]
        build];

    [UnityAds initialize:initConfig completion:^(id<UnityAdsError> _Nullable error) {
        if (error) {
            [[CLXUnityAdsInitializer logger] error:[NSString stringWithFormat:@"Unity Ads SDK init failed: %@",
                                                 error.message ?: @"Unknown error"]];

            @synchronized (CLXUnityAdsSDKLock) {
                CLXUnityAdsSDKInitializing = NO;
            }

            if (completion) {
                NSError *nsError = [NSError errorWithDomain:CLXUnityAdsAdapterErrorDomain
                                                       code:error.code
                                                   userInfo:@{NSLocalizedDescriptionKey: error.message ?: @"Unknown initialization error"}];
                completion(NO, nsError);
            }
        } else {
            [[CLXUnityAdsInitializer logger] info:@"Unity Ads SDK initialized"];

            @synchronized (CLXUnityAdsSDKLock) {
                CLXUnityAdsSDKInitializing = NO;
                CLXUnityAdsSDKInitialized = YES;
            }

            if (completion) {
                completion(YES, nil);
            }
        }
    }];
}

#pragma mark - Privacy

- (void)configurePrivacy {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // GDPR: derive consent from IAB TCF gdprApplies flag
    NSNumber *gdprApplies = [defaults objectForKey:@"IABTCF_gdprApplies"];
    if (gdprApplies != nil) {
        BOOL hasConsent = (gdprApplies.integerValue != 1);
        [UnityAds setUserConsent:hasConsent];
        [[CLXUnityAdsInitializer logger] debug:[NSString stringWithFormat:@"Unity Ads privacy: setUserConsent:%@",
                                             hasConsent ? @"YES" : @"NO"]];
    }

    // CCPA: derive do-not-sell from IAB US Privacy String
    NSString *usPrivacy = [defaults stringForKey:@"IABUSPrivacy_String"];
    if (usPrivacy.length >= 3) {
        unichar optOut = [usPrivacy characterAtIndex:2];
        BOOL doNotSell = (optOut == 'Y');
        [UnityAds setUserOptOut:doNotSell];
        [[CLXUnityAdsInitializer logger] debug:[NSString stringWithFormat:@"Unity Ads privacy: setUserOptOut:%@",
                                             doNotSell ? @"YES" : @"NO"]];
    }
}

@end
