//
//  CLXUnityInitializer.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityInitializer.h>)
#import <CloudXUnityAdapter/CLXUnityInitializer.h>
#else
#import "CLXUnityInitializer.h"
#endif

#if __has_include(<CloudXUnityAdapter/CLXUnityAdapterVersion.h>)
#import <CloudXUnityAdapter/CLXUnityAdapterVersion.h>
#else
#import "CLXUnityAdapterVersion.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXVersion.h>
#import <UnityAds/UnityAds.h>

@interface CLXUnityInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@end

static NSString * const CLXUnityAdapterErrorDomain = @"CLXUnityAdapter";

@implementation CLXUnityInitializer

static NSObject *CLXUnitySDKLock;
static BOOL CLXUnitySDKInitialized = NO;
static BOOL CLXUnitySDKInitializing = NO;

+ (void)initialize {
    [super initialize];
    CLXUnitySDKLock = [[NSObject alloc] init];
}

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityInitializer"];
    });
    return logger;
}

+ (BOOL)isInitialized {
    @synchronized (CLXUnitySDKLock) {
        return CLXUnitySDKInitialized;
    }
}

+ (instancetype)createInstance {
    return [[CLXUnityInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return [UnityAds getVersion];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXUnityInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityInitializer"];
    }
    return self;
}

- (NSString *)network {
    return @"unity";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    @synchronized (CLXUnitySDKLock) {
        if (CLXUnitySDKInitialized) {
            [[CLXUnityInitializer logger] debug:@"Unity SDK already initialized"];
            if (completion) {
                completion(YES, nil);
            }
            return;
        }

        if (CLXUnitySDKInitializing) {
            [[CLXUnityInitializer logger] debug:@"Unity SDK initialization in progress"];
            if (completion) {
                NSError *error = [NSError errorWithDomain:CLXUnityAdapterErrorDomain
                                                     code:-2
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unity SDK initialization already in progress"}];
                completion(NO, error);
            }
            return;
        }

        CLXUnitySDKInitializing = YES;
    }

    NSString *gameId = nil;
    if (config && config.initializationData) {
        gameId = config.initializationData[@"game_id"];
    }

    if (!gameId || gameId.length == 0) {
        [[CLXUnityInitializer logger] error:@"Unity game_id is missing from initialization data"];
        @synchronized (CLXUnitySDKLock) {
            CLXUnitySDKInitializing = NO;
        }
        if (completion) {
            NSError *error = [NSError errorWithDomain:CLXUnityAdapterErrorDomain
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Missing game_id in initialization data"}];
            completion(NO, error);
        }
        return;
    }

    [[CLXUnityInitializer logger] debug:[NSString stringWithFormat:@"Initializing Unity Ads SDK with game id: %@", gameId]];
    [[CLXUnityInitializer logger] info:[NSString stringWithFormat:@"Test mode: %@", testMode ? @"YES" : @"NO"]];

    // Unity does NOT auto-read IAB strings from NSUserDefaults — set privacy before init
    [self configurePrivacy];
    UADSMediationInfo *mediationInfo = [[UADSMediationInfo alloc] initWithName:@"cloudx"
                                                                      version:CLXSDKVersion
                                                               adapterVersion:CLXUnityAdapterVersion];

    UADSInitializationConfiguration *initConfig = [[[[[UADSInitializationConfigurationBuilder alloc]
        initWithGameId:gameId]
        withTestMode:testMode]
        withMediationInfo:mediationInfo]
        build];

    [UnityAds initialize:initConfig completion:^(id<UnityAdsError> _Nullable error) {
        if (error) {
            [[CLXUnityInitializer logger] error:[NSString stringWithFormat:@"Unity Ads SDK init failed: %@",
                                                 error.message ?: @"Unknown error"]];

            @synchronized (CLXUnitySDKLock) {
                CLXUnitySDKInitializing = NO;
            }

            if (completion) {
                NSError *nsError = [NSError errorWithDomain:CLXUnityAdapterErrorDomain
                                                       code:error.code
                                                   userInfo:@{NSLocalizedDescriptionKey: error.message ?: @"Unknown initialization error"}];
                completion(NO, nsError);
            }
        } else {
            [[CLXUnityInitializer logger] info:@"Unity Ads SDK initialized"];

            @synchronized (CLXUnitySDKLock) {
                CLXUnitySDKInitializing = NO;
                CLXUnitySDKInitialized = YES;
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
        [[CLXUnityInitializer logger] debug:[NSString stringWithFormat:@"Unity privacy: setUserConsent:%@",
                                             hasConsent ? @"YES" : @"NO"]];
    }

    // CCPA: derive do-not-sell from IAB US Privacy String
    NSString *usPrivacy = [defaults stringForKey:@"IABUSPrivacy_String"];
    if (usPrivacy.length >= 3) {
        unichar optOut = [usPrivacy characterAtIndex:2];
        BOOL doNotSell = (optOut == 'Y');
        [UnityAds setUserOptOut:doNotSell];
        [[CLXUnityInitializer logger] debug:[NSString stringWithFormat:@"Unity privacy: setUserOptOut:%@",
                                             doNotSell ? @"YES" : @"NO"]];
    }
}

@end
