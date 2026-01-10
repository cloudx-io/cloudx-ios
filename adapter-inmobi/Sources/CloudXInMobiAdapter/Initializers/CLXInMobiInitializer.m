//
//  CLXInMobiInitializer.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
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
#if __has_include(<CloudXInMobiAdapter/CLXInMobiBannerFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBannerFactory.h>
#import <CloudXInMobiAdapter/CLXInMobiInterstitialFactory.h>
#import <CloudXInMobiAdapter/CLXInMobiRewardedFactory.h>
#import <CloudXInMobiAdapter/CLXInMobiNativeFactory.h>
#import <CloudXInMobiAdapter/CLXInMobiBidTokenSource.h>
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
static NSString *partnerName = nil; // tp parameter from server config
static NSArray<NSString *> *placementIds = nil; // Placement IDs from server config

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

+ (NSString *)partnerName {
    return partnerName;
}

+ (NSArray<NSString *> *)placementIds {
    return placementIds;
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
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Initializing InMobi SDK adapter (testMode: %@)", testMode ? @"YES" : @"NO"]];
    // Note: testMode parameter received from server deviceConfig
    
    // Extract configuration from initData
    NSString *accountID = nil;
    if (config && config.initializationData) {
        accountID = config.initializationData[@"accountId"];
        partnerName = config.initializationData[@"tp"];
        placementIds = config.initializationData[@"placementIds"];
        
        [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Account ID: %@", accountID ?: @"nil"]];
        [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Partner name (tp): %@", partnerName ?: @"nil"]];
        [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Placement IDs: %@", placementIds ?: @"nil"]];
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
            [IMSdk setLogLevel:IMSDKLogLevelDebug];
            #else
            [IMSdk setLogLevel:IMSDKLogLevelError];
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
    
    // InMobi reads privacy settings from IAB standards (TCF for GDPR, US Privacy String for CCPA)
    // The SDK automatically reads these from UserDefaults per IAB specifications:
    // - GDPR: IABTCF_TCString, IABTCF_gdprApplies
    // - CCPA: IABUSPrivacy_String
    //
    // We pass an empty consent dictionary and let InMobi SDK read IAB strings directly
    
    [[CLXInMobiInitializer logger] debug:@"InMobi will read GDPR/CCPA from IAB UserDefaults (TCF/US Privacy String)"];
    
    return [consent copy];
}

@end

