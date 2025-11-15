#import "CLXMintegralInitializer.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXError.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralRewardedFactory.h"

@interface CLXMintegralInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;
@end

@implementation CLXMintegralInitializer

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"7.6.0";

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXMintegralInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return kSDKVersion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInitializer"];
    }
    return self;
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    [self.logger debug:@"Initializing Mintegral adapter"];
    
    if (isInitialized) {
        [self.logger info:@"SDK already initialized"];
        if (completion) completion(YES, nil);
        return;
    }
    
    NSString *appID = config.initializationData[@"appID"];
    NSString *appKey = config.initializationData[@"appKey"];
    
    if (!appID || appID.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"Missing appID in initialization data"];
        [self.logger error:@"Failed to initialize: missing appID"];
        if (completion) completion(NO, error);
        return;
    }
    
    if (!appKey || appKey.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"Missing appKey in initialization data"];
        [self.logger error:@"Failed to initialize: missing appKey"];
        if (completion) completion(NO, error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [self configurePrivacySettings];
            
            [[MTGSDK sharedInstance] setAppID:appID ApiKey:appKey];
            
            [MTGBiddingSDK sharedInstance];
            
            [self registerFactories];
            
            isInitialized = YES;
            [self.logger info:@"Mintegral SDK initialized successfully"];
            
            if (completion) completion(YES, nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInternalError
                                         description:exception.reason ?: @"Unknown initialization error"];
            [self.logger error:[NSString stringWithFormat:@"Initialization failed: %@", exception.reason]];
            if (completion) completion(NO, error);
        }
    });
}

- (void)configurePrivacySettings {
    CLXSettings *settings = [CLXSettings sharedInstance];
    
    if (settings.gdprConsentAvailable) {
        [[MTGSDK sharedInstance] setConsentStatus:settings.gdprConsentAccepted];
    }
    
    if (settings.usPrivacyString) {
        [[MTGSDK sharedInstance] setDoNotTrackStatus:!settings.ccpaOptIn];
    }
    
    if (settings.coppaEnabled) {
        [[MTGSDK sharedInstance] setCoppaStatus:YES];
    }
}

- (void)registerFactories {
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralInterstitialFactory createInstance] 
                                        forAdType:CLXAdTypeInterstitial];
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralBannerFactory createInstance] 
                                        forAdType:CLXAdTypeBanner];
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralRewardedFactory createInstance] 
                                        forAdType:CLXAdTypeRewarded];
}

@end

