//
//  CLXInMobiInitializer.m
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "CLXInMobiInitializer.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXSettings.h>
#import <InMobiSDK/InMobiSDK.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

// Import factory headers for registration
#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiBannerFactory.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiBannerFactory.h>
#import <CloudXMediationInMobiAdapter/CLXInMobiInterstitialFactory.h>
#import <CloudXMediationInMobiAdapter/CLXInMobiRewardedFactory.h>
#import <CloudXMediationInMobiAdapter/CLXInMobiNativeFactory.h>
#import <CloudXMediationInMobiAdapter/CLXInMobiBidTokenSource.h>
#else
#import "Banner/CLXInMobiBannerFactory.h"
#import "Interstitial/CLXInMobiInterstitialFactory.h"
#import "Rewarded/CLXInMobiRewardedFactory.h"
#import "Native/CLXInMobiNativeFactory.h"
#import "BidTokenSource/CLXInMobiBidTokenSource.h"
#endif

@interface CLXInMobiInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;
+ (CLXLogger *)logger;
@end

@implementation CLXInMobiInitializer

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"10.8.8"; // InMobi SDK version

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInitializer"];
    });
    return logger;
}

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXInMobiInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return kSDKVersion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXInMobiInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInitializer"];
    }
    return self;
}

- (NSString *)network {
    return @"inmobi";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [[CLXInMobiInitializer logger] debug:@"Initializing InMobi SDK adapter"];
    
    // Extract account ID from config
    NSString *accountID = nil;
    if (config && config.initializationData) {
        accountID = config.initializationData[@"accountId"];
        [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Account ID from config: %@", accountID ?: @"nil"]];
    }
    
    if (!accountID || accountID.length == 0) {
        [[CLXInMobiInitializer logger] error:@"InMobi account ID not provided in configuration"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"CLXInMobiInitializer" 
                                               code:-1 
                                           userInfo:@{NSLocalizedDescriptionKey: @"InMobi account ID is required"}];
            completion(NO, error);
        }
        return;
    }
    
    // Configure GDPR consent
    NSDictionary *consentDict = [self getConsentDictionary];
    
    // Initialize InMobi SDK
    [[CLXInMobiInitializer logger] info:[NSString stringWithFormat:@"Initializing InMobi SDK with account ID: %@", accountID]];
    
    // Note: InMobi SDK initialization is synchronous
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [IMSdk initWithAccountID:accountID consentDictionary:consentDict];
            
            // Set log level for debugging
            #ifdef DEBUG
            [IMSdk setLogLevel:kIMSDKLogLevelDebug];
            #else
            [IMSdk setLogLevel:kIMSDKLogLevelError];
            #endif
            
            isInitialized = YES;
            
            [[CLXInMobiInitializer logger] info:@"✅ InMobi SDK initialized successfully"];
            
            if (completion) {
                completion(YES, nil);
            }
        } @catch (NSException *exception) {
            [[CLXInMobiInitializer logger] error:[NSString stringWithFormat:@"InMobi SDK initialization failed: %@", exception.reason]];
            
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"CLXInMobiInitializer" 
                                                   code:-2 
                                               userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Unknown error"}];
                completion(NO, error);
            }
        }
    });
}

- (NSDictionary *)getConsentDictionary {
    NSMutableDictionary *consent = [NSMutableDictionary dictionary];
    
    // Get GDPR consent from CloudX Settings if available
    // InMobi expects keys: @"gdpr_consent_available", @"gdpr"
    // For now, return empty dict - can be enhanced later
    
    return [consent copy];
}

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXMediationInMobiAdapterRegister(void) {
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"InMobiAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading InMobi adapter classes"];
    
    // Force load all classes
    [CLXInMobiInitializer class];
    [CLXInMobiBannerFactory class];
    [CLXInMobiInterstitialFactory class];
    [CLXInMobiRewardedFactory class];
    [CLXInMobiNativeFactory class];
    [CLXInMobiBidTokenSource class];
    
    [registrationLogger debug:@"InMobi adapter classes loaded successfully"];
}

// Call registration during class load
+ (void)load {
    CloudXMediationInMobiAdapterRegister();
}

@end

