#import "CLXMintegralInitializer.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
// Placeholder for Mintegral SDK
// #import <MTGSDK/MTGSDK.h>
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralRewardedFactory.h"

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
    // TODO: Replace with actual Mintegral SDK version query
    // return [[MTGSDK sharedInstance] sdkVersion];
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
            [self.logger debug:[NSString stringWithFormat:@"Initializing Mintegral with AppID: %@", appID]];
            
            // Configure privacy settings BEFORE SDK initialization
            [self configurePrivacySettings];
            
            // TODO: Replace with actual Mintegral SDK initialization
            // [[MTGSDK sharedInstance] setAppID:appID AppKey:appKey];
            
            // Placeholder: Simulate successful initialization
            [self.logger info:@"Mintegral SDK initialization API would be called here"];
            
            // Register factories with CloudX Core
            [self registerFactories];
            
            isInitialized = YES;
            [self.logger info:@"Mintegral SDK initialized successfully"];
            
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
    // NOTE: Mintegral SDK is currently not integrated (commented out in Podfile)
    // When Mintegral SDK is integrated, update this method with actual privacy APIs
    //
    // Privacy Implementation Notes:
    // - Mintegral likely reads GDPR/CCPA from IAB standards (TCF/US Privacy String)
    // - Check Mintegral SDK documentation for explicit COPPA APIs when integrating
    // - Many ad networks removed explicit COPPA APIs in favor of IAB standard compliance
    //
    // Placeholder implementation for when SDK is integrated:
    
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    BOOL coppaEnabled = [privacyService isCoppaEnabled];
    
    [self.logger debug:@"Mintegral SDK not integrated - privacy settings cannot be configured"];
    [self.logger debug:[NSString stringWithFormat:@"COPPA status (for when SDK is integrated): %@", 
                       coppaEnabled ? @"enabled" : @"disabled"]];
    
    // TODO: When Mintegral SDK is integrated, add privacy API calls here
    // Example (update with actual Mintegral APIs):
    // if (coppaEnabled) {
    //     [[MTGSDK sharedInstance] setCoppaEnabled:YES];
    // }
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

@end

