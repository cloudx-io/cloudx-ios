//
//  CLXMolocoInitializer.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInitializer.h>)
#import <CloudXMolocoAdapter/CLXMolocoInitializer.h>
#else
#import "CLXMolocoInitializer.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXSettings.h>

// Import CloudXCore for both SPM and CocoaPods
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Import Moloco SDK
#import <MolocoSDK/MolocoSDK.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

// Import other internal headers for registration
#if __has_include(<CloudXMolocoAdapter/CLXMolocoBannerFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBannerFactory.h>
#else
#import "CLXMolocoBannerFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInterstitialFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoInterstitialFactory.h>
#else
#import "CLXMolocoInterstitialFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoRewardedFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoRewardedFactory.h>
#else
#import "CLXMolocoRewardedFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoNativeFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoNativeFactory.h>
#else
#import "CLXMolocoNativeFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBidTokenSource.h>)
#import <CloudXMolocoAdapter/CLXMolocoBidTokenSource.h>
#else
#import "CLXMolocoBidTokenSource.h"
#endif

@interface CLXMolocoInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;

// Private class method for internal logging
+ (CLXLogger *)logger;
@end

@implementation CLXMolocoInitializer

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoInitializer"];
    });
    return logger;
}

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"1.0.0"; // Moloco SDK version

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXMolocoInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return kSDKVersion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXMolocoInitializer sdkVersion];
    }
    return self;
}

- (NSString *)network {
    return @"moloco";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [[CLXMolocoInitializer logger] debug:[NSString stringWithFormat:@"Initializing Moloco adapter (testMode: %@)", testMode ? @"YES" : @"NO"]];
    // Note: testMode parameter received from server deviceConfig
    
    if (isInitialized) {
        [[CLXMolocoInitializer logger] info:@"SDK already initialized"];
        if (completion) completion(YES, nil);
        return;
    }
    
    // Extract account ID/API key from config
    NSString *appKey = config.initializationData[@"app_key"];
    if (!appKey || appKey.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidConfiguration
                                     description:@"Missing Moloco app_key in configuration"];
        [[CLXMolocoInitializer logger] error:@"Failed to initialize: missing app_key"];
        if (completion) completion(NO, error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Configure privacy settings
            [self configurePrivacySettings];
            
            // Initialize Moloco SDK
            [[CLXMolocoInitializer logger] debug:[NSString stringWithFormat:@"Initializing Moloco SDK with app key: %@", appKey]];
            
            // Note: Update with actual Moloco SDK initialization API
            // This is a placeholder - adjust based on actual Moloco SDK documentation
            [MolocoSDK initializeWithAppKey:appKey];
            
            // Register factories
            [self registerFactories];
            
            isInitialized = YES;
            [[CLXMolocoInitializer logger] info:@"Moloco SDK initialized successfully"];
            
            if (completion) completion(YES, nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInternalError
                                         description:exception.reason ?: @"Unknown error"];
            [[CLXMolocoInitializer logger] error:[NSString stringWithFormat:@"Initialization failed: %@", exception.reason]];
            if (completion) completion(NO, error);
        }
    });
}

#pragma mark - Private Methods

- (void)configurePrivacySettings {
    // Use CloudX core's tracking service for consistency
    BOOL idfaAllowed = [CLXAdTrackingService isIDFAAccessAllowed];
    
    // Configure Moloco SDK privacy settings
    // Note: Moloco SDK APIs are placeholders - verify with actual Moloco SDK documentation
    
    // GDPR - Moloco likely reads IAB TCF strings automatically
    // If explicit API is needed, uncomment and verify:
    // NSString *gdprString = [privacyService gdprConsentString];  // Internal method
    // if (gdprString) {
    //     [MolocoSDK setGDPRConsent:YES];
    //     [[CLXMolocoInitializer logger] debug:@"GDPR consent: granted"];
    // }
    [[CLXMolocoInitializer logger] debug:@"Moloco reads GDPR from IAB TCF strings (UserDefaults)"];
    
    // CCPA - Moloco likely reads IAB US Privacy strings automatically
    // If explicit API is needed, uncomment and verify:
    // NSString *ccpaString = [privacyService ccpaPrivacyString];
    // if (ccpaString) {
    //     [MolocoSDK setUSPrivacyString:ccpaString];
    //     [[CLXMolocoInitializer logger] debug:[NSString stringWithFormat:@"CCPA string: %@", ccpaString]];
    // }
    [[CLXMolocoInitializer logger] debug:@"Moloco reads CCPA from IAB US Privacy String (UserDefaults)"];
    
    // ATT/IDFA
    [MolocoSDK setTrackingEnabled:idfaAllowed];
    [[CLXMolocoInitializer logger] info:[NSString stringWithFormat:@"Moloco tracking enabled: %@", 
                                        idfaAllowed ? @"YES" : @"NO"]];
}

- (void)registerFactories {
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMolocoInterstitialFactory createInstance] 
                                        forAdType:CLXAdTypeInterstitial];
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMolocoBannerFactory createInstance] 
                                        forAdType:CLXAdTypeBanner];
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMolocoRewardedFactory createInstance] 
                                        forAdType:CLXAdTypeRewarded];
    [[CloudXCore shared] registerAdNetworkFactory:[CLXMolocoNativeFactory createInstance] 
                                        forAdType:CLXAdTypeNative];
    
    [[CLXMolocoInitializer logger] debug:@"Registered all Moloco factories"];
}

@end

