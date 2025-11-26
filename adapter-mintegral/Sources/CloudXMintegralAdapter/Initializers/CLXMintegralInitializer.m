#import "CLXMintegralInitializer.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CloudXCore.h>
#import <MTGSDK/MTGSDK.h>
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralBidTokenSource.h"

@interface CLXMintegralInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;
@end

@implementation CLXMintegralInitializer

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"7.6.3"; // Mintegral SDK version (update as needed)

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXMintegralInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    NSString *version = [[MTGSDK sharedInstance] sdkVersion];
    return version ?: kSDKVersion;
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
        [self.logger info:@"Mintegral SDK already initialized"];
        if (completion) completion(YES, nil);
        return;
    }
    
    // Extract Mintegral-specific credentials
    // Mintegral typically requires App ID and App Key
    NSString *appID = config.initializationData[@"appID"];
    NSString *appKey = config.initializationData[@"appKey"];
    
    if (!appID || appID.length == 0 || !appKey || appKey.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"Missing Mintegral App ID or App Key"];
        [self.logger error:@"Failed to initialize Mintegral: missing App ID or App Key"];
        if (completion) completion(NO, error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [self.logger debug:[NSString stringWithFormat:@"Initializing Mintegral SDK with AppID: %@", appID]];
            
            // Configure privacy settings BEFORE SDK initialization
            [self configurePrivacySettings];
            
            // Initialize Mintegral SDK
            [[MTGSDK sharedInstance] setAppID:appID ApiKey:appKey];
            
            [self.logger info:[NSString stringWithFormat:@"Mintegral SDK initialized with version: %@", 
                             [[MTGSDK sharedInstance] sdkVersion] ?: @"unknown"]];
            
            // Register factories with CloudX Core
            [self registerFactories];
            
            isInitialized = YES;
            [self.logger success:@"Mintegral adapter initialized successfully"];
            
            if (completion) completion(YES, nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInternalError
                                         description:exception.reason ?: @"Unknown initialization error"];
            [self.logger error:[NSString stringWithFormat:@"Mintegral initialization failed: %@", exception.reason]];
            if (completion) completion(NO, error);
        }
    });
}

- (void)configurePrivacySettings {
    // GDPR - Mintegral automatically reads IAB TCF strings from UserDefaults
    // Keys: IABTCF_TCString, IABTCF_gdprApplies, IABTCF_PurposeConsents
    [self.logger debug:@"Mintegral reads GDPR consent from IAB TCF strings (UserDefaults)"];
    
    // CCPA - Mintegral automatically reads IAB US Privacy String from UserDefaults
    // Key: IABUSPrivacy_String
    [self.logger debug:@"Mintegral reads CCPA from IAB US Privacy String (UserDefaults)"];
}

- (void)registerFactories {
    [self.logger debug:@"Registering Mintegral ad format factories"];
    
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralInterstitialFactory createInstance]
                                        forAdType:CLXAdTypeInterstitial];
    
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralBannerFactory createInstance]
                                        forAdType:CLXAdTypeBanner];
    
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMintegralRewardedFactory createInstance]
                                        forAdType:CLXAdTypeRewarded];
    
    [self.logger info:@"Registered 3 Mintegral ad format factories"];
}

#pragma mark - Static Framework Class Loading

// Ensure all classes are loaded when using static frameworks
__attribute__((visibility("default"))) void CloudXMintegralAdapterRegister(void) {
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"MintegralAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Mintegral adapter classes"];
    
    // Force load all classes by referencing them
    [CLXMintegralInitializer class];
    [CLXMintegralBannerFactory class];
    [CLXMintegralInterstitialFactory class];
    [CLXMintegralRewardedFactory class];
    [CLXMintegralBidTokenSource class];
    
    [registrationLogger debug:@"Mintegral adapter classes loaded successfully"];
}

+ (void)load {
    CloudXMintegralAdapterRegister();
}

@end

